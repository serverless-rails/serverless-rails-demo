namespace :madmin do
  resources :documents
  resources :publish_watches
  resources :users
  root to: "dashboard#show"
end
