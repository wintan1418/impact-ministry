# Register the `:rss` MIME type before routes load so `/podcast.rss` can be
# parsed and rendered as `application/rss+xml`. Rails 8 doesn't ship this MIME
# type out of the box, and `Mime::Type.register` raises on re-register, so we
# guard the lookup. Lives here (not in an initializer) because the podcast feed
# is the only consumer.
Mime::Type.register("application/rss+xml", :rss) unless Mime::Type.lookup_by_extension(:rss)

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
  resources :users, only: %i[ new create ]
  # Friendly alias so /signup works and the path helper reads naturally.
  get  "signup", to: "users#new",    as: :signup
  post "signup", to: "users#create"

  # --- Authenticated user account (Phase 3.7–3.11) ---
  get   "account"            => "account/dashboards#show",  as: :account
  get   "account/highlights" => "account/highlights#index", as: :account_highlights
  get   "account/settings"   => "account/settings#show",    as: :account_settings
  patch "account/settings"   => "account/settings#update"

  resources :highlights, only: %i[ create destroy ]

  # --- Public ---
  root "home#show"

  # --- Static editor-managed pages (Page model) ---
  # Top-level slugs are explicit so they stay short, memorable, and reservable.
  # See docs/ROUTES.md and CLAUDE.md §10.
  get "about",   to: "pages#show", defaults: { slug: "about" },   as: :about_page
  get "beliefs", to: "pages#show", defaults: { slug: "beliefs" }, as: :beliefs_page
  get  "contact", to: "pages#show",                 defaults: { slug: "contact" }, as: :contact_page
  post "contact", to: "feedback_messages#create",                                  as: :contact_create
  get "privacy", to: "pages#show", defaults: { slug: "privacy" }, as: :privacy_page
  get "terms",   to: "pages#show", defaults: { slug: "terms" },   as: :terms_page

  # Catch-all for editor-created pages (anything published via /admin/pages).
  get "pages/:slug", to: "pages#show", as: :page

  # --- Devotionals (Phase 1.A) ---
  get "devotionals/today" => "devotionals#today", as: :devotionals_today
  resources :devotionals, only: [ :index, :show ], param: :slug

  # --- Stub surfaces (placeholder pages until Phase 2/3 controllers land) ---
  # Each links from the nav and renders a real designed page with email capture.
  # NOTE: `.rss` must come BEFORE `podcast` so the format-suffixed URL is not
  # swallowed by the more permissive index route, which would otherwise match
  # `/podcast.rss` as `index` with format=rss.
  get "podcast.rss"    => "podcast_episodes#feed",  as: :podcast_feed, defaults: { format: :rss }
  get "podcast"        => "podcast_episodes#index", as: :podcast
  get "podcast/:slug"  => "podcast_episodes#show",  as: :podcast_episode
  # --- Prayer Wall (Phase 2.7–2.10) ---
  # /pray         GET   index (form + visible wall)
  # /pray         POST  create (Turbo Stream form submission)
  # /pray/:id/prayed POST  prayed (Turbo Stream counter increment)
  resources :prayer_requests, only: [ :index, :create ], path: "pray" do
    member do
      post :prayed
    end
  end
  # Keep the legacy `pray_path` helper working (was `get "pray"` before).
  get "pray", to: "prayer_requests#index", as: :pray

  # --- Partnerships (Phase 3.1–3.2) ---
  # /partner  GET   new    (editorial hero + audience cards + intake form)
  # /partner  POST  create (Turbo Stream submission)
  get  "partner" => "partnerships#new",    as: :partner
  post "partner" => "partnerships#create"

  get "give"    => "giving#show",            as: :give

  # --- Events + RSVPs (Phase 4.3) ---
  # /events             → events#index
  # /events/:slug       → events#show
  # POST /events/:slug/rsvp → event_rsvps#create
  resources :events, only: [ :index, :show ], param: :slug do
    resource :rsvp, only: [ :create ], controller: "event_rsvps", as: :rsvp
  end

  # --- Resources (Phase 3.3–3.6) ---
  # /resources                 GET   index   (featured + per-category)
  # /resources/:slug           GET   show    (with download gate)
  # /resources/:slug/download  POST  download (Turbo Stream)
  resources :resources, only: [ :index, :show ], param: :slug do
    member do
      post :download
    end
  end

  # --- Testimonies (Phase 2.13–2.15) ---
  # /testimonies  GET  index (public wall — approved only)
  # /testify      GET  new   (submission form)
  # /testimonies  POST create (Turbo Stream submission; always approved: false)
  get  "testimonies" => "testimonies#index",  as: :testimonies
  get  "testify"     => "testimonies#new",    as: :new_testimony
  post "testimonies" => "testimonies#create"

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

  # --- Site search (Phase 2) ---
  # /search          GET  index   — runs the query, renders grouped results.
  # /search/overlay  GET  overlay — bare overlay shell (no-JS entry point).
  get "search"         => "search#index",   as: :search
  get "search/overlay" => "search#overlay", as: :search_overlay

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
