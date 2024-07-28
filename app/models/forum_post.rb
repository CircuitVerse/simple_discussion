require "language_filter"
class ForumPost < ApplicationRecord
  belongs_to :forum_thread, counter_cache: true, touch: true
  belongs_to :user
  has_many :spam_reports, dependent: :destroy

  validates :user_id, :body, presence: true
  validate :clean_body, if: -> { SimpleDiscussion.profanity_filter }

  scope :sorted, -> { order(:created_at) }

  after_update :solve_forum_thread, if: :solved?

  def clean_body
    filters = [:profanity, :sex, :violence, :hate]
    detected_words = Set.new

    filters.each do |matchlist|
      filter = LanguageFilter::Filter.new(matchlist: matchlist)
      detected_words.merge(filter.matched(body)) if filter.match?(body)
    end

    if detected_words.any?
      errors.add(:body, I18n.t(".inappropriate_language_error_message", words: detected_words.to_a.join(", ")))
    end
  end

  def solve_forum_thread
    forum_thread.update(solved: true)
  end
end
