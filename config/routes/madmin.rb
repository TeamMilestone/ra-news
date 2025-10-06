# Below are the routes for madmin
namespace :madmin do
  resources :preferences
  resources :comments
  resources :tags
  resources :articles do
    member do
      put :discard
      put :restore
    end
  end
  resources :sites
  resources :users

  # Social 메뉴 - OAuth 인증
  get "social", to: "social#index", as: :social_index
  get "social/xcom/authorize", to: "social#xcom_authorize", as: :social_xcom_authorize
  get "social/xcom/callback", to: "social#xcom_callback", as: :social_xcom_callback

  root to: "dashboard#show"
end
