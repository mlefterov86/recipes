Rails.application.routes.draw do
  # API routes
  namespace :api do
    namespace :v1 do
      # Add your API endpoints here
      # Example: resources :recipes
    end
  end

  # Health check endpoint
  get "health", to: proc { [ 200, {}, [ "OK" ] ] }
end
