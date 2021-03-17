require 'sidekiq/web'

Rails.application.routes.draw do
  root to: 'documents#index'

  resources :documents

  resources :profiles, only: %i[ show ] do
    resources :publish_watches, only: %i[] do
      collection do
        post :subscribe
        post :unsubscribe
      end
    end
  end

  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
    draw :madmin
  end

  devise_for :users

  mount LetterOpenerWeb::Engine, at: "/_mail" if Rails.env.development?
end
