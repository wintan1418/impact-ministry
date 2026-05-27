Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  # --- System ---
  get "up" => "rails/health#show", as: :rails_health_check

  # --- Letter Opener (dev only) ---
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # --- Auth (Rails 8 native) ---
  resource :session
  resources :passwords, param: :token

  # --- Public ---
  root "home#show"

  # See docs/ROUTES.md for the full URL surface plan. Routes get added per phase.

  # PWA (disabled until needed)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
