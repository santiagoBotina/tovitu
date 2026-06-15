Rails.application.routes.draw do
  resource :registration, only: [:new, :create], controller: "authentication/registrations" do
    get :check_email, on: :collection
  end

  resource :session, only: [:new, :create, :destroy], controller: "authentication/sessions"

  resources :password_resets, only: [:new, :create, :edit, :update], controller: "authentication/passwords" do
    get :check_email, on: :collection
  end

  resource :verification, only: [:show], controller: "authentication/verifications"

  resource :profile, only: [:edit, :update], controller: "authentication/profiles"

  get "up" => "rails/health#show", as: :rails_health_check

  root to: "dashboard#index"
end
