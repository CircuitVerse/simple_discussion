require "font-awesome-sass"
require "friendly_id"
require "will_paginate"

require "simple_discussion/engine"
require "simple_discussion/forum_user"
require "simple_discussion/slack"
require "simple_discussion/version"
require "simple_discussion/will_paginate"

module SimpleDiscussion
  # Define who owns the subscription
  mattr_accessor :send_email_notifications
  mattr_accessor :send_slack_notifications
  mattr_accessor :profanity_filter
  mattr_accessor :markdown_circuit_embed
  mattr_accessor :markdown_video_embed
  mattr_accessor :markdown_user_tagging

  @@send_email_notifications = true
  @@send_slack_notifications = true
  @@profanity_filter = true
  @@markdown_circuit_embed = true
  @@markdown_video_embed = true
  @@markdown_user_tagging = true

  def self.setup
    yield self
  end
end
