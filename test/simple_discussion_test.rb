require "test_helper"

class SimpleDiscussionTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::SimpleDiscussion::VERSION
  end
end
