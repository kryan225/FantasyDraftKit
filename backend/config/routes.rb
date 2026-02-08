Rails.application.routes.draw do
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # Web UI routes (Hotwire/HTML)
  root "leagues#index"

  resources :leagues, only: [:index, :show, :new, :create] do
    # Nested draft board route with explicit league_id
    get "draft_board", to: "draft_board#show", as: :league_draft_board
  end

  resources :teams, only: [:show]
  resources :players, only: [:index, :edit, :update]

  # Draft picks (with Turbo Streams support)
  resources :draft_picks, only: [:create, :destroy]

  # Standalone draft board route (uses auto-resolution for single league)
  get "draft_board", to: "draft_board#show", as: :draft_board

  # API routes
  namespace :api do
    namespace :v1 do
      # League routes
      resources :leagues do
        # Nested routes under leagues
        resources :teams, only: [:index, :create]
        resources :draft_picks, only: [:index, :create]

        # Custom league actions
        member do
          post :recalculate_values
        end

        # Keeper-related routes
        get :keeper_history, to: "keeper_histories#index"
        post :import_keepers, to: "keeper_histories#import_keepers"
        get :check_keeper_eligibility, to: "keeper_histories#check_keeper_eligibility"
      end

      # Standalone team routes
      resources :teams, only: [:show] do
        member do
          get :category_analysis
        end
      end

      # Player routes
      resources :players, only: [:index] do
        collection do
          post :import
        end
      end

      # Draft pick routes
      resources :draft_picks, only: [:update, :destroy]
    end
  end
end
