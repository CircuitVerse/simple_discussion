module ApplicationHelper
  def user_profile_link(user)
    "/users/#{user.id}"
  end
end
