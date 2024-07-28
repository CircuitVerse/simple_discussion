class SimpleDiscussion::ForumPostsController < SimpleDiscussion::ApplicationController
  before_action :authenticate_user!
  before_action :set_forum_thread
  before_action :set_forum_post, only: [:edit, :update, :destroy]
  before_action :require_mod_or_author_for_post!, only: [:edit, :update, :destroy]
  before_action :require_mod_or_author_for_thread!, only: [:solved, :unsolved]

  def create
    @forum_post = @forum_thread.forum_posts.new(forum_post_params)
    @forum_post.user_id = current_user.id

    if @forum_post.save
      SimpleDiscussion::ForumPostNotificationJob.perform_later(@forum_post)
      redirect_to simple_discussion.forum_thread_path(@forum_thread, anchor: "forum_post_#{@forum_post.id}")
    else
      render template: "simple_discussion/forum_threads/show", status: :unprocessable_entity
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
    if @forum_thread.forum_posts.first == @forum_post
      @forum_thread.destroy!
      if params[:from] == "moderators_page"
        redirect_to simple_discussion.spam_reports_forum_threads_path
      else
        redirect_to simple_discussion.root_path
      end
    else
      @forum_post.destroy!
      if params[:from] == "moderators_page"
        redirect_to simple_discussion.spam_reports_forum_threads_path
      else
        redirect_to simple_discussion.forum_thread_path(@forum_thread)
      end
    end
  end

  def solved
    @forum_post = @forum_thread.forum_posts.find(params[:id])

    @forum_thread.forum_posts.update_all(solved: false)
    @forum_post.update_column(:solved, true)
    @forum_thread.update_column(:solved, true)

    redirect_to simple_discussion.forum_thread_path(@forum_thread, anchor: ActionView::RecordIdentifier.dom_id(@forum_post))
  end

  def unsolved
    @forum_post = @forum_thread.forum_posts.find(params[:id])

    @forum_thread.forum_posts.update_all(solved: false)
    @forum_thread.update_column(:solved, false)

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
end
