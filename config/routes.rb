Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: "users/sessions" }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # 利用規約・プライバシーポリシーはDBを使用しない静的ページとして表示する。
  get "terms", to: "legal#terms", as: :terms
  get "privacy_policy", to: "legal#privacy_policy", as: :privacy_policy
  get "mypage", to: "users#mypage", as: :mypage
  resources :users, only: :show
  resources :elements, only: %i[index show]
  # 学習の入口と元素名4択クイズ。問題セットはブラウザセッションに保持する。
  get "learning", to: "learning#index"
  get "learning/quiz", to: "learning#show", as: :learning_quiz
  post "learning/answer", to: "learning#answer", as: :learning_answer
  post "learning/next", to: "learning#next_question", as: :learning_next
  get "learning/result", to: "learning#result", as: :learning_result
  post "learning/restart", to: "learning#restart", as: :learning_restart
  resources :illustrations do
    collection do
      get :liked
      get :popular
    end

    resource :like, only: %i[create destroy]
    resource :encyclopedia_entry, only: %i[create destroy]
  end
  resources :encyclopedia_entries, only: :index

  namespace :admin do
    root "dashboard#show"
    resources :users, only: %i[index show destroy]
    resources :illustrations, only: %i[index show destroy] do
      member do
        patch :toggle_published
      end
    end
  end

  # Defines the root path route ("/")
  root "home#index"
end
