SimpleDiscussion::Engine.routes.draw do
  scope module: :simple_discussion do
    resources :forum_threads, path: :threads do
      collection do
        get :answered
        get :unanswered
        get :mine
        get :participating
        get :spam_reports
        get "category/:id", to: "forum_categories#index", as: :forum_category
      end

      resources :forum_posts, path: :posts do
        member do
          put :solved
          put :unsolved
          post :report_post
        end
      end

      resource :notifications
    end
  end

  root to: "simple_discussion/forum_threads#index"
end
