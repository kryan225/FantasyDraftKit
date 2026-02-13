Rails.application.routes.draw do
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # Web UI routes (Hotwire/HTML)
  root "leagues#index"

  resources :leagues, only: [:index, :show, :new, :create, :update] do
    member do
      get :settings
    end
    # Nested draft board route with explicit league_id
    get "draft_board", to: "draft_board#show", as: :league_draft_board
    get "draft_history", to: "draft_board#history", as: :league_draft_history
    get "draft_analyzer", to: "draft_analyzer#show", as: :league_draft_analyzer
    get "standings", to: "standings#index", as: :standings

    # Data control routes (scoped to league)
    get "data_control", to: "data_control#show", as: :data_control
    post "data_control/import_players", to: "data_control#import_players", as: :import_players
    post "data_control/undraft_all_players", to: "data_control#undraft_all_players", as: :undraft_all_players
    delete "data_control/delete_all_players", to: "data_control#delete_all_players", as: :delete_all_players
    post "recalculate_values", to: "data_control#recalculate_values", as: :recalculate_values

    # Players routes (scoped to league)
    get "players", to: "players#index", as: :players

    # Teams routes (scoped to league)
    get "teams", to: "teams#index", as: :teams
  end

  resources :teams, only: [:show, :index]
  resources :players, only: [:index, :edit, :update] do
    member do
      post :toggle_interested
    end
  end

  # Draft picks (with Turbo Streams support)
  resources :draft_picks, only: [:create, :update, :destroy]

  # Data control routes
  get "data_control", to: "data_control#show", as: :data_control
  post "data_control/import_players", to: "data_control#import_players", as: :import_players
  post "data_control/undraft_all_players", to: "data_control#undraft_all_players", as: :undraft_all_players
  delete "data_control/delete_all_players", to: "data_control#delete_all_players", as: :delete_all_players

  # Standalone draft board route (uses auto-resolution for single league)
  get "draft_board", to: "draft_board#show", as: :draft_board
  get "draft_history", to: "draft_board#history", as: :draft_history
  get "draft_analyzer", to: "draft_analyzer#show", as: :draft_analyzer
  get "standings", to: "standings#index", as: :standings

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
