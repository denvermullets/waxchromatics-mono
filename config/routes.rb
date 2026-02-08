Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: '/jobs'

  resource :session, only: %i[new create destroy]
  resource :registration, only: %i[new create]
  resources :passwords, param: :token
  resources :releases, only: %i[index new create]
  get 'artists/search', to: 'artists#search', as: :search_artists
  get 'release_groups/search', to: 'release_groups#search', as: :search_release_groups
  resources :artists, only: %i[show new create edit update] do
    get :discography_section, on: :member
    get 'discography/:release_type', action: :discography_type, as: :discography_type, on: :member
    resources :release_groups, only: %i[show], path: 'release-groups' do
      resources :releases, only: %i[show]
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  get 'search', to: 'dashboard#search'
  get 'search/external', to: 'dashboard#external_search', as: :external_search
  post 'search/ingest', to: 'dashboard#ingest_artist', as: :ingest_artist

  # Authenticated users land here; unauthenticated go to login
  root 'dashboard#show'
end
