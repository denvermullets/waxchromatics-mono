Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: '/jobs'

  resource :session, only: %i[new create destroy]
  resource :registration, only: %i[new create]
  resources :passwords, param: :token
  resources :releases, only: %i[index new create]
  get 'artists/search', to: 'artists#search', as: :search_artists
  get 'release_groups/search', to: 'release_groups#search', as: :search_release_groups
  resources :artists, only: %i[index show new create edit update] do
    get :discography_section, on: :member
    get 'discography/:release_type', action: :discography_type, as: :discography_type, on: :member
    resources :release_groups, only: %i[show], path: 'release-groups' do
      resources :releases, only: %i[show]
    end
  end

  get 'connections', to: 'connections#show', as: :connections
  get 'connections/search', to: 'connections#search', as: :search_connections
  get 'trade-finder', to: 'trade_finder#show', as: :trade_finder

  resources :trades, only: %i[index show new create destroy] do
    member do
      patch :propose
      patch :accept
      patch :decline
      patch :cancel
    end
    collection do
      get :search_users
      get :search_collection
      get :search_recipient_collection
    end
  end

  post 'collection_items/toggle', to: 'collection_items#toggle'
  post 'wantlist_items/toggle', to: 'wantlist_items#toggle'
  post 'trade_list_items/toggle', to: 'trade_list_items#toggle'
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  get 'search', to: 'dashboard#search'
  get 'search/external', to: 'dashboard#external_search', as: :external_search
  post 'search/ingest', to: 'dashboard#ingest_artist', as: :ingest_artist

  # Authenticated users land here; unauthenticated go to login
  root 'dashboard#show'

  # Username-scoped routes — must be last to avoid conflicts
  constraints(username: /[a-zA-Z0-9_-]+/) do
    get ':username', to: 'profiles#show', as: :profile
    get ':username/settings', to: 'settings#show', as: :user_settings
    patch ':username/settings', to: 'settings#update'
    get ':username/crates', to: 'collection#show', as: :crates
    scope ':username/collections' do
      resources :imports, only: %i[new create show], controller: 'collection_imports', as: :collection_imports do
        post :retry_failed, on: :member
      end
    end
  end
end
