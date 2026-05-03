Rails.application.routes.draw do
  root "forums#index"

  get    "signup",  to: "registrations#new",  as: :signup
  post   "signup",  to: "registrations#create"
  get    "login",   to: "sessions#new",       as: :login
  post   "login",   to: "sessions#create"
  delete "logout",  to: "sessions#destroy",   as: :logout

  resources :forums, only: [:index, :show, :new, :create] do
    resources :posts, only: [:create]
  end

  resources :posts, only: [:show] do
    resources :posts, only: [:create], path: :replies, as: :replies
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
