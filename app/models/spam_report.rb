class SpamReport < ApplicationRecord
  belongs_to :forum_post
  belongs_to :user

  validates :forum_post_id, :user_id, :reason, presence: true
  validates :details, presence: true, if: -> { reason == "others" }

  enum :reason, {
    sexual_content: 0,
    violent_content: 1,
    irrelevant_content: 2,
    misleading_content: 3,
    others: 4
  }
end
