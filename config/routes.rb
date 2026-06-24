Rails.application.routes.draw do
  scope "(:locale)", locale: /en|es/ do
    root "landing#index"

    get "login/adopter", to: "authentication/sessions#new_adopter"
    get "login/shelter",  to: "authentication/sessions#new_shelter"
    get "login", to: redirect("/"), as: :new_session

    resource :session, only: [ :create, :destroy ], controller: "authentication/sessions"

    resource :registration, only: [ :new, :create ], controller: "authentication/registrations" do
      get :check_email, on: :collection
    end

    resources :password_resets, only: [ :new, :create, :edit, :update ], controller: "authentication/passwords" do
      get :check_email, on: :collection
    end

    resource :verification, only: [ :show ], controller: "authentication/verifications"

    resource :profile, only: [ :edit, :update ], controller: "authentication/profiles"

    get "profile/onboarding", to: "onboarding/adopter/questions#show",
                              as: :profile_onboarding,
                              defaults: { from_profile: "true" }
    get "profile/shelter_onboarding", to: "onboarding/shelter/questions#show",
                                      as: :profile_shelter_onboarding,
                                      defaults: { from_profile: "true" }

    namespace :onboarding do
      namespace :adopter do
        resource :questions, only: [ :show, :update ]
        resource :completion, only: [ :create ]
      end
      namespace :shelter do
        resource :questions, only: [ :show, :update ]
        resource :completion, only: [ :create ]
      end
    end

    resources :pets, only: [ :index, :show ]

    resources :shelters, only: [ :index, :show, :new, :create, :edit, :update ] do
      resource :dashboard, only: [ :show ], controller: "shelters/dashboard"
      resources :staff, only: [ :index, :create, :destroy ], controller: "shelters/staff"
      resources :invitations, only: [ :create ], controller: "shelters/invitations"
      resource :policies, only: [ :edit, :update ], controller: "shelters/policies"
    end

    resources :adoption_applications, only: [ :new, :create ] do
      resources :rag_queries, only: [:create], controller: "ai/rag_queries"
    end
    resource :application_status, only: [ :show ], controller: "adoption_applications/status"

    resources :shelters, only: [] do
      resources :rag_queries, only: [:create], controller: "ai/rag_queries"
    end

    namespace :shelter do
      resources :pets do
        member do
          patch :change_status
        end
        collection do
          patch :bulk_update
        end
        resources :photos, only: [ :create, :destroy, :update ]
      end

      resources :adoption_applications, only: [ :index, :show, :update ] do
        resources :notes, only: [ :create ], controller: "adoption_applications/notes"
        member do
          patch :approve
          patch :reject
          patch :request_info
          patch :finalize
          patch :cancel
        end
      end

      namespace :ai do
        resources :documents, only: [:index, :new, :create, :destroy]
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
