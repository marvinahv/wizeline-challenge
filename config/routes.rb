Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication routes
      post 'auth/login', to: 'authentication#login'
      
      # Project routes
      resources :projects do
        # Nested task routes for project-specific tasks
        resources :tasks, only: [:index, :create]
      end
      
      # Task routes that don't need project context
      resources :tasks, only: [:show, :update, :destroy] do
        # Custom route for updating task status
        member do
          put 'status', action: 'update_status', as: 'status'
        end
      end
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
