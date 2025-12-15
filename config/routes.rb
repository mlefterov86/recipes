Rails.application.routes.draw do
  # API routes
  namespace :api do
    namespace :v1 do
      resources :recipes, only: [ :index, :show ]
      resources :categories, only: [ :index ]
      resources :authors, only: [ :index ]
    end
  end

  # Health check endpoint
  get "health", to: "health#show"
end
