class SimpleDiscussion::ForumThreadsController < SimpleDiscussion::ApplicationController
  before_action :authenticate_user!, only: [:mine, :participating, :new, :create]
  before_action :set_forum_thread, only: [:show, :edit, :update, :destroy]
  before_action :require_mod_or_author_for_thread!, only: [:edit, :update, :destroy]
  before_action :require_mod!, only: [:spam_reports]

  POINTS = {
    create_thread: 20, # on forum thread creation
    delete_thread: -20, # on forum thread deletion
    delete_reported_thread_by_moderator: -100 # if moderator deletes the thread hence it is spam post
  }

  def index
    @forum_threads = ForumThread.pinned_first.sorted.includes(:user, :forum_category).paginate(page: page_number)
  end

  def answered
    @forum_threads = ForumThread.solved.sorted.includes(:user, :forum_category).paginate(page: page_number)
    render action: :index
  end

  def unanswered
    @forum_threads = ForumThread.unsolved.sorted.includes(:user, :forum_category).paginate(page: page_number)
    render action: :index
  end

  def mine
    @forum_threads = ForumThread.where(user: current_user).sorted.includes(:user, :forum_category).paginate(page: page_number)
    render action: :index
  end

  def participating
    @forum_threads = ForumThread.includes(:user, :forum_category).joins(:forum_posts).where(forum_posts: {user_id: current_user.id}).distinct(forum_posts: :id).sorted.paginate(page: page_number)
    render action: :index
  end

  def spam_reports
    @spam_reports = SpamReport.includes(:forum_post).paginate(page: page_number)
    render action: :spam_reports
  end

  def leaderboard
    @ranked_users = ForumLeaderboard.order(points: :desc).paginate(page: page_number)
  end

  def show
    @forum_post = ForumPost.new
    @forum_post.user = current_user
  end

  def new
    @forum_thread = ForumThread.new
    @forum_thread.forum_posts.new
  end

  def create
    @forum_thread = current_user.forum_threads.new(forum_thread_params)
    @forum_thread.forum_posts.each { |post| post.user_id = current_user.id }

    ActiveRecord::Base.transaction do
      if @forum_thread.save
        update_leaderboard(current_user, POINTS[:create_thread])
        SimpleDiscussion::ForumThreadNotificationJob.perform_later(@forum_thread)
        redirect_to simple_discussion.forum_thread_path(@forum_thread)
      else
        render action: :new, status: :unprocessable_entity
      end
    end
  end

  def edit
  end

  def update
    if @forum_thread.update(forum_thread_params)
      redirect_to simple_discussion.forum_thread_path(@forum_thread), notice: I18n.t("your_changes_were_saved")
    else
      render action: :edit, status: :unprocessable_entity
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      @forum_thread.destroy!
      if is_moderator? && (@forum_thread.user != current_user)
        update_leaderboard(@forum_thread.user, POINTS[:delete_reported_thread_by_moderator])
      else
        update_leaderboard(@forum_thread.user, POINTS[:delete_thread])
      end
    end

    redirect_to simple_discussion.forum_threads_path
  end

  private

  def set_forum_thread
    @forum_thread = ForumThread.friendly.find(params[:id])
  end

  def forum_thread_params
    params.require(:forum_thread).permit(:title, :forum_category_id, forum_posts_attributes: [:body])
  end

  def update_leaderboard(user, points)
    leaderboard = user.forum_leaderboard || user.build_forum_leaderboard
    leaderboard.points += points
    leaderboard.save!
  end
end
