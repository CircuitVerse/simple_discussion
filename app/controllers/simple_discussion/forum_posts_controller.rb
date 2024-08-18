class SimpleDiscussion::ForumPostsController < SimpleDiscussion::ApplicationController
  before_action :authenticate_user!
  before_action :set_forum_thread
  before_action :set_forum_post, only: [:edit, :update, :destroy]
  before_action :require_mod_or_author_for_post!, only: [:edit, :update, :destroy]
  before_action :require_mod_or_author_for_thread!, only: [:solved, :unsolved]

  POINTS = {
    create_post: 10, # on forum post creation
    delete_post: -10, # on forum post deletion
    marked_as_solution: 100, # if forum thread author/moderator marked the post as solved
    unmarked_as_solution: -100, # undoing the marked as solution
    delete_reported_post: -100 # if moderator deletes the post hence it is spam post
  }

  def create
    @forum_post = @forum_thread.forum_posts.new(forum_post_params)
    @forum_post.user_id = current_user.id

    ActiveRecord::Base.transaction do
      if @forum_post.save
        update_leaderboard(current_user, POINTS[:create_post])
        SimpleDiscussion::ForumPostNotificationJob.perform_later(@forum_post)
        redirect_to simple_discussion.forum_thread_path(@forum_thread, anchor: "forum_post_#{@forum_post.id}")
      else
        render template: "simple_discussion/forum_threads/show", status: :unprocessable_entity
      end
    end
  end

  def edit
  end

  def update
    if @forum_post.update(forum_post_params)
      redirect_to simple_discussion.forum_thread_path(@forum_thread)
    else
      render action: :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # if @forum_post is first post of forum_thread then we need to destroy forum_thread
    is_first_post = @forum_thread.forum_posts.first == @forum_post

    ActiveRecord::Base.transaction do
      if is_first_post
        @forum_thread.destroy!
      else
        @forum_post.destroy!
      end

      # leaderboard points distribution
      if is_moderator? && (@forum_post.user != current_user)
        update_leaderboard(@forum_post.user, POINTS[:delete_reported_post])
        # further we can distribute points if needed to the user who reported the post

        # spam_report = SpamReport.find_by(forum_post: @forum_post)
        # update_leaderboard(spam_report.user, POINTS[:report_spam]) if spam_report
      else
        update_leaderboard(@forum_post.user, POINTS[:delete_post])
      end
    end

    redirect_to redirect_after_delete_path(is_first_post)
  end

  def solved
    ActiveRecord::Base.transaction do
      @forum_post = @forum_thread.forum_posts.find(params[:id])

      # update the previously solved post's author's leaderboard points
      previously_solved_posts = @forum_thread.forum_posts.where(solved: true)
      previously_solved_posts.each do |post|
        update_user_leaderboard(post.user, POINTS[:unmarked_as_solution])
      end

      # update the current post's author leaderboard points
      update_leaderboard(@forum_post.user, POINTS[:marked_as_solution])
      @forum_thread.forum_posts.update_all(solved: false)
      @forum_post.update_column(:solved, true)
      @forum_thread.update_column(:solved, true)
    end

    redirect_to simple_discussion.forum_thread_path(@forum_thread, anchor: ActionView::RecordIdentifier.dom_id(@forum_post))
  end

  def unsolved
    ActiveRecord::Base.transaction do
      @forum_post = @forum_thread.forum_posts.find(params[:id])
      update_leaderboard(@forum_post.user, POINTS[:unmarked_as_solution])
      @forum_thread.forum_posts.update_all(solved: false)
      @forum_thread.update_column(:solved, false)
    end

    redirect_to simple_discussion.forum_thread_path(@forum_thread, anchor: ActionView::RecordIdentifier.dom_id(@forum_post))
  end

  def report_spam
    @forum_post = @forum_thread.forum_posts.find(params[:id])
    @spam_report = SpamReport.new(forum_post: @forum_post, user: current_user, reason: params[:reason], details: params[:details])

    if @spam_report.save
      redirect_to simple_discussion.forum_thread_path(@forum_thread, anchor: ActionView::RecordIdentifier.dom_id(@forum_post))
    else
      render template: "simple_discussion/forum_threads/show"
    end
  end

  private

  def set_forum_thread
    @forum_thread = ForumThread.friendly.find(params[:forum_thread_id])
  end

  def set_forum_post
    @forum_post = if is_moderator?
      @forum_thread.forum_posts.find(params[:id])
    else
      current_user.forum_posts.find(params[:id])
    end
  end

  def forum_post_params
    params.require(:forum_post).permit(:body)
  end

  def update_leaderboard(user, points)
    leaderboard = user.forum_leaderboard || user.build_forum_leaderboard
    leaderboard.points += points
    leaderboard.save!
  end

  def redirect_after_delete_path(is_first_post)
    if params[:from] == "moderators_page"
      simple_discussion.spam_reports_forum_threads_path
    elsif is_first_post
      simple_discussion.root_path
    else
      simple_discussion.forum_thread_path(@forum_thread)
    end
  end
end
