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

  # --- Static editor-managed pages (Page model) ---
  # Top-level slugs are explicit so they stay short, memorable, and reservable.
  # See docs/ROUTES.md and CLAUDE.md §10.
  get "about",   to: "pages#show", defaults: { slug: "about" },   as: :about_page
  get "beliefs", to: "pages#show", defaults: { slug: "beliefs" }, as: :beliefs_page
  get "contact", to: "pages#show", defaults: { slug: "contact" }, as: :contact_page
  get "privacy", to: "pages#show", defaults: { slug: "privacy" }, as: :privacy_page
  get "terms",   to: "pages#show", defaults: { slug: "terms" },   as: :terms_page

  # Catch-all for editor-created pages (anything published via /admin/pages).
  get "pages/:slug", to: "pages#show", as: :page

  # --- Devotionals (Phase 1.A) ---
  get "devotionals/today" => "devotionals#today", as: :devotionals_today
  resources :devotionals, only: [ :index, :show ], param: :slug

  # --- Stub surfaces (placeholder pages until Phase 2/3 controllers land) ---
  # Each links from the nav and renders a real designed page with email capture.
  get "podcast"        => "podcast_episodes#index", as: :podcast
  get "podcast/:slug"  => "podcast_episodes#show",  as: :podcast_episode
  get "pray"    => "prayer_requests#index",  as: :pray
  get "partner" => "partnerships#new",       as: :partner
  get "give"    => "giving#show",            as: :give

  # --- Email capture (Phase 1.B) ---
  post   "subscribe"          => "email_subscribers#create",              as: :subscribe
  get    "unsubscribe/:token" => "email_subscribers#confirm_unsubscribe", as: :confirm_unsubscribe
  delete "unsubscribe/:token" => "email_subscribers#destroy",             as: :unsubscribe

  # --- Postmark webhooks (Phase 1.E) ---
  # POST /postmark/webhooks — Open, Click, Bounce, SpamComplaint, Delivery.
  # Always returns 200 (Postmark retries on non-2xx).
  namespace :postmark do
    resources :webhooks, only: [ :create ]
  end

  # --- Sitemap + error pages (Phase 1.F) ---
  get "sitemap.xml" => "sitemaps#show", as: :sitemap, defaults: { format: :xml }

  # Exception pages — wired via `config.exceptions_app = routes` in application.rb.
  match "/404", to: "errors#not_found",             via: :all
  match "/422", to: "errors#unprocessable_entity",  via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  # See docs/ROUTES.md for the full URL surface plan. Routes get added per phase.

  # PWA (disabled until needed)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
