Rails.application.routes.draw do
  # Bare domain redirects to default locale
  get "/", to: redirect("/en")

  scope ":locale", locale: /en|es/ do
    root "landing#index"

    get "login/individual", to: "authentication/sessions#new_individual"
    get "login/adopter", to: redirect(path: "/%{locale}/login/individual"), status: :moved_permanently
    get "login/shelter",  to: "authentication/sessions#new_shelter"
    get "login", to: "authentication/sessions#new", as: :new_session

    resource :session, only: [ :create, :destroy ], controller: "authentication/sessions"

    resource :registration, only: [ :new, :create ], controller: "authentication/registrations" do
      get :check_email, on: :collection
    end

    resources :password_resets, only: [ :new, :create, :edit, :update ], controller: "authentication/passwords" do
      get :check_email, on: :collection
    end

    resource :verification, only: [ :show ], controller: "authentication/verifications"

    resource :profile, only: [ :edit, :update ], controller: "authentication/profiles"

    get "profile/onboarding", to: "onboarding/individual/questions#show",
                              as: :profile_onboarding,
                              defaults: { from_profile: "true" }
    get "profile/shelter_onboarding", to: "onboarding/shelter/questions#show",
                                      as: :profile_shelter_onboarding,
                                      defaults: { from_profile: "true" }

    # ── Dashboard ──────────────────────────────────────────────
    get "dashboard", to: "dashboard#index", as: :user_dashboard
    # ────────────────────────────────────────────────────────────

    # ── Notifications ───────────────────────────────────────────
    resources :notifications, only: [ :index, :show ] do
      collection do
        patch :mark_all_read
        get :unread_count
      end
      member do
        patch :mark_read
      end
    end

    resource :notification_preferences, only: [ :edit, :update ]
    # ────────────────────────────────────────────────────────────

    namespace :onboarding do
      namespace :individual do
        resource :questions, only: [ :show, :update ]
        resource :completion, only: [ :create ]
      end

      # Legacy "adopter" namespace — deprecated alias for "individual".
      # Kept only as permanent redirects so bookmarked legacy URLs keep working;
      # no controller exists for these routes.
      namespace :adopter, as: :adopter_onboarding do
        get "questions", to: redirect(path: "/%{locale}/onboarding/individual/questions", status: :moved_permanently)
        get "completion", to: redirect(path: "/%{locale}/onboarding/individual/completion", status: :moved_permanently)
      end

      namespace :shelter do
        resource :questions, only: [ :show, :update ]
        resource :completion, only: [ :create ]
      end
    end

    resources :pets, only: [ :index, :show ] do
      resource :save, only: [ :create, :destroy ], controller: "pets/saves"
      resource :life_preview, only: [ :show ], controller: "life_previews"
    end

    resources :saved_pets, only: [ :index ] do
      collection do
        post :import
      end
    end

    resources :shelters, only: [ :index, :show, :new, :create, :edit, :update ] do
      resource :dashboard, only: [ :show ], controller: "shelters/dashboard" do
        post :dismiss_checklist
        delete :restore_checklist
      end
      resources :staff, only: [ :index, :create, :destroy ], controller: "shelters/staff"
      resources :invitations, only: [ :create ], controller: "shelters/invitations"
      resource :policies, only: [ :edit, :update ], controller: "shelters/policies"
    end

    # Legacy anonymous adoption applications (kept for existing data status checks)
    resource :application_status, only: [ :show ], controller: "adoption_applications/status"

    resources :adoption_requests, only: [ :index, :show, :new, :create ] do
      member do
        patch :withdraw
      end
    end

    resources :shelters, only: [] do
      resources :rag_queries, only: [ :create ], controller: "ai/rag_queries"
    end

    resources :adoption_applications, only: [] do
      resources :rag_queries, only: [ :create ], controller: "ai/rag_queries"
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

      resources :adoption_requests, only: [ :index, :show ] do
        resource :decision, only: [ :new, :create ], controller: "adoption_requests/decisions"
      end

      namespace :ai do
        resources :documents, only: [ :index, :new, :create, :destroy ]
      end
    end

    # ── Individual Publisher Routes ─────────────────────────────
    namespace :my do
      resources :pets do
        member do
          patch :change_status
        end
      end

      resources :adoption_requests, only: [ :index, :show ] do
        resource :decision, only: [ :new, :create ], controller: "adoption_requests/decisions"
      end
    end
    # ────────────────────────────────────────────────────────────
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
