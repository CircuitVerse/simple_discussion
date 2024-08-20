require "language_filter"
class ForumThread < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged

  belongs_to :forum_category
  belongs_to :user
  has_many :forum_posts, dependent: :destroy
  has_many :forum_subscriptions
  has_many :optin_subscribers, -> { where(forum_subscriptions: {subscription_type: :optin}) }, through: :forum_subscriptions, source: :user
  has_many :optout_subscribers, -> { where(forum_subscriptions: {subscription_type: :optout}) }, through: :forum_subscriptions, source: :user
  has_many :users, through: :forum_posts

  accepts_nested_attributes_for :forum_posts

  validates :forum_category, presence: true
  validates :user_id, :title, presence: true
  validates_associated :forum_posts

  validate :clean_title, if: -> { SimpleDiscussion.profanity_filter }

  scope :pinned_first, -> { order(pinned: :desc) }
  scope :solved, -> { where(solved: true) }
  scope :sorted, -> { order(updated_at: :desc) }
  scope :unpinned, -> { where.not(pinned: true) }
  scope :unsolved, -> { where.not(solved: true) }

  if ActiveRecord::Base.connection.adapter_name.downcase.start_with?('postgresql')
    include PgSearch::Model
    pg_search_scope :basic_search,
                    against: %i[title],
                    using: {
                      tsearch: {
                        dictionary: 'english',
                        tsvector_column: 'searchable_data'
                      }
                    }

    after_save :generate_searchable

    def generate_searchable
      require 'redcarpet'
      require 'redcarpet/render_strip'

      markdown_renderer = Redcarpet::Render::StripDown.new
      plain_body = Redcarpet::Markdown.new(markdown_renderer).render(forum_posts.first&.body.to_s)

      searchable_content = "#{title} #{plain_body}"

      tsvector_query = ActiveRecord::Base.send(:sanitize_sql_array,
                                               ["SELECT to_tsvector('english', ?)", searchable_content])
      self.searchable_data = ActiveRecord::Base.connection.execute(tsvector_query).getvalue(0, 0)
      # Save the changes without triggering callbacks to avoid infinite loop
      update_column(:searchable_data, self.searchable_data)
    end
  else
    def self.basic_search(query)
      joins(:forum_posts)
        .where("forum_threads.title LIKE :query OR forum_posts.body LIKE :query", query: "%#{query}%")
        .distinct
    end
  end

  def update_searchable
    if ActiveRecord::Base.connection.adapter_name.downcase.start_with?('postgresql')
      generate_searchable
      save
    end
  end

  def clean_title
    filters = [:profanity, :sex, :violence, :hate]

    detected_words = Set.new

    filters.each do |matchlist|
      filter = LanguageFilter::Filter.new(matchlist: matchlist)
      detected_words.merge(filter.matched(title)) if filter.match?(title)
    end

    if detected_words.any?
      errors.add(:title, I18n.t(".inappropriate_language_error_message", words: detected_words.to_a.join(", ")))
    end
  end

  def subscribed_users
    (users + optin_subscribers).uniq - optout_subscribers
  end

  def subscription_for(user)
    return nil if user.nil?
    forum_subscriptions.find_by(user_id: user.id)
  end

  def subscribed?(user)
    return false if user.nil?

    subscription = subscription_for(user)

    if subscription.present?
      subscription.subscription_type == "optin"
    else
      forum_posts.where(user_id: user.id).any?
    end
  end

  def toggle_subscription(user)
    subscription = subscription_for(user)

    if subscription.present?
      subscription.toggle!
    elsif forum_posts.where(user_id: user.id).any?
      forum_subscriptions.create(user: user, subscription_type: "optout")
    else
      forum_subscriptions.create(user: user, subscription_type: "optin")
    end
  end

  def subscribed_reason(user)
    return I18n.t(".not_receiving_notifications") if user.nil?

    subscription = subscription_for(user)

    if subscription.present?
      if subscription.subscription_type == "optout"
        I18n.t(".ignoring_thread")
      elsif subscription.subscription_type == "optin"
        I18n.t(".receiving_notifications_because_subscribed")
      end
    elsif forum_posts.where(user_id: user.id).any?
      I18n.t(".receiving_notifications_because_posted")
    else
      I18n.t(".not_receiving_notifications")
    end
  end

  # These are the users to notify on a new thread. Currently this does nothing,
  # but you can override this to provide whatever functionality you like here.
  #
  # For example: You might use this to send all moderators an email of new threads.
  def notify_users
    []
  end
end
