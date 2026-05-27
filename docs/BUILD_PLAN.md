# BUILD_PLAN.md — Phased ticket breakdown

Source of truth for *what gets built when*. CLAUDE.md describes the rules; this file describes the order.

Each ticket below is small enough to ship in one PR. Dependencies flow downward — don't jump ahead.

---

## Phase 0 — Foundation (before Phase 1 starts)

These are not in the brief's four phases because the brief assumes a working scaffold. They need to land first.

- **0.1 — Gem stack alignment.** Add to `Gemfile`: `pg_search`, `friendly_id`, `pundit`, `activeadmin`, `postmark-rails`, `stripe`, `aws-sdk-s3`, `noticed`, `rack-attack`, `dotenv-rails`, `rspec-rails`, `factory_bot_rails`, `faker`, `view_component`. Bundle. `rails db:create`.
- **0.2 — RSpec install.** `rails g rspec:install`. Configure `spec/rails_helper.rb` with FactoryBot, DatabaseCleaner-equivalent transactional fixtures. Add `spec/support/` autoload.
- **0.3 — Rails 8 native auth.** `bin/rails generate authentication`. Add `name`, `role` (string enum) to `User`. Set `confirmed_at`. Wire `current_user`, `authenticate_user!`. Pundit `ApplicationPolicy`.
- **0.4 — ActiveAdmin install** at `/admin`. Seed first admin user. Custom auth integration with Rails 8 auth (not Devise). Lock down by `User#admin?` and `User#editor?`.
- **0.5 — Tailwind v4 + design tokens.** Configure `tailwind.config.js` with the color tokens, font stacks (Fraunces / Inter / Lora via `tailwindcss-rails`'s font setup or `@font-face` in `application.tailwind.css`), and the easing curve as a CSS variable.
- **0.6 — Postmark + ActionMailer.** Configure SMTP/API. Wire `ApplicationMailer` with default `from`. Add development mailer interceptor (letter_opener or Postmark's preview).
- **0.7 — R2 / ActiveStorage.** Configure `config/storage.yml` with S3-compatible R2 endpoint. Add dev/prod buckets. Smoke-test an upload.
- **0.8 — Solid Queue + Solid Cache + Solid Cable.** Already in Rails 8 defaults; verify schemas and `bin/jobs` runs.
- **0.9 — Rack::Attack baseline.** Throttle: 5 req/sec/IP on POST `/subscribe`, `/prayer_requests`, `/contact`, `/testimonies`, `/partnerships`. 10 req/min/IP on sign-in.
- **0.10 — Turnstile helper.** Stimulus controller + form partial that renders the Turnstile widget. Server-side verification in a `TurnstileVerifier` service.
- **0.11 — CI scaffold.** GitHub Actions: bundle install, db setup, rspec, rubocop, brakeman, bundler-audit. Green on `main`.

---

## Phase 1 — Devotional engine & first-visit conversion (weeks 1–4)

### Models & data

- **1.1 — `Devotional` model + migration.** All columns from CLAUDE.md §4. Unique index on `scheduled_for`. `friendly_id` on `:slug`. `pg_search_scope` on title + scripture_reference + excerpt. ActionText for `body`. Factory + model spec.
- **1.2 — `EmailSubscriber` model.** Unique index on `email`. `source` string enum. Token generated on create. Factory + model spec.
- **1.3 — `Page` model + seed for `/about`, `/beliefs`, `/contact`, `/privacy`, `/terms`.** ActionText body, `seo_meta` jsonb.
- **1.4 — `Setting` model** (key/value, string-typed). Helper `Setting.get(:key)` with cache. Seeds for initial flags.

### Devotional reading surface

- **1.5 — `DevotionalsController#show`** at `/devotionals/:slug`. Renders title, scripture ref, body, audio player if `audio_blob.attached?`, share buttons, tomorrow-teaser.
- **1.6 — `/devotionals/today` redirect** to today's published devotional or a graceful fallback page if none.
- **1.7 — `/devotionals` archive** — paginated list (most recent first), filterable by tag.
- **1.8 — Devotional show — long-form typography pass.** Lora for body, generous line-height, drop-cap on first paragraph. Verify against design.

### Daily dispatch

- **1.9 — `DevotionalDispatchJob`** — finds today's scheduled devotional, publishes it, enqueues `DevotionalDeliveryJob` per active subscriber. Recurring config via Solid Queue cron.
- **1.10 — `DevotionalMailer#daily`** + Postmark template. Records `DevotionalDelivery`.
- **1.11 — Postmark webhook receiver** at `/postmark/webhooks` — updates `opened_at`/`clicked_at`. Signature-verified. Queued.
- **1.12 — Failsafe alert** — 06:00 job that emails `ADMIN_NOTIFICATION_EMAIL` if today's devotional wasn't dispatched.

### Email capture

- **1.13 — `EmailSubscribersController#create`** — Turbo Stream POST. Turnstile-verified. Idempotent on email (re-subscribes if previously unsubscribed). Enqueues `WelcomeEmailJob`.
- **1.14 — Email capture partial** — used in footer, inline, exit-intent, prayer-form upsell. Each variant passes a different `source`.
- **1.15 — `WelcomeEmailJob` + `SubscriberMailer#welcome`** — links to today's devotional.
- **1.16 — Unsubscribe flow** — `/unsubscribe/:token` GET → confirm page → POST → `unsubscribed_at` set. No login required.

### Homepage

- **1.17 — `HomeController#show`** at `/` — hero (today's devotional teaser), prayer wall preview (Phase 2 stub OK), partnership CTA, email capture.

### Admin (editor)

- **1.18 — ActiveAdmin: Devotional.** Schedule, draft, publish, attach featured image / audio. Bulk actions: publish, unpublish. Filter by `scheduled_for`.
- **1.19 — ActiveAdmin: EmailSubscriber.** Read-only list + manual unsubscribe + export CSV.
- **1.20 — ActiveAdmin: Page.** Edit body, slug, seo_meta.

### Polish & exit criteria

- **1.21 — Plausible integration.** Snippet in layout, no PII. Custom event for email signup with `source`.
- **1.22 — Error pages** — 404, 422, 500 in design system.
- **1.23 — robots.txt, sitemap.xml** (sitemap generated from published devotionals + pages).
- **1.24 — End-to-end test** — visitor lands on `/`, signs up via footer form, receives welcome (asserted via Postmark test mode), clicks link to today's devotional.

---

## Phase 2 — Podcast, prayer wall, testimonies, share cards (weeks 5–8)

### Podcast

- 2.1 — `PodcastEpisode` model + migration. friendly_id, pg_search.
- 2.2 — `PodcastEpisodesController` index + show. Audio player. Transcript collapse.
- 2.3 — `/podcast` index page with hero (latest episode) + grid of past episodes.
- 2.4 — RSS feed at `/podcast.rss` (Apple Podcasts spec-compliant).
- 2.5 — ActiveAdmin: PodcastEpisode (schedule, publish, attach audio).
- 2.6 — `PODCAST_LIVE_ENABLED=false` placeholder page.

### Prayer wall

- 2.7 — `PrayerRequest` model + migration. status enum (string).
- 2.8 — `PrayerRequestsController#create` — Turbo Stream, Turnstile, Rack::Attack.
- 2.9 — `/pray` — public wall of approved + public requests. Pagination.
- 2.10 — "I prayed for this" Turbo button — increments counter, session-deduped.
- 2.11 — ActiveAdmin: PrayerRequest — moderate, mark answered, mark public.
- 2.12 — Editor notification email on new submission (Noticed).

### Testimonies

- 2.13 — `Testimony` model + migration.
- 2.14 — `TestimoniesController#create` + `/testify` form (with photo upload).
- 2.15 — `/testimonies` index — approved only, featured first.
- 2.16 — ActiveAdmin: Testimony — approve, feature.

### Share cards

- 2.17 — Decide rendering path: `grover` (Puppeteer in-process) vs. external browserless. Default to `grover` for now.
- 2.18 — `/devotionals/:slug/share_card.png` — HTML template → PNG. Cached via Solid Cache for 30 days.
- 2.19 — Open Graph tags on devotional show pages point at the share card.

### Feedback / contact

- 2.20 — `FeedbackMessage` model + `/contact` form + admin notification + admin index.

---

## Phase 3 — Partnerships, resources, accounts, Stripe (test mode) (weeks 9–12)

### Partnerships

- 3.1 — `Partnership` form object + model + `/partner` page.
- 3.2 — ActiveAdmin: Partnership inbox with status enum.

### Resources

- 3.3 — `Resource` model + R2-backed file_blob.
- 3.4 — `/resources` index, `/resources/:slug` show.
- 3.5 — Email-gated downloads when `requires_email: true` — creates EmailSubscriber via download flow.
- 3.6 — ActiveAdmin: Resource.

### User accounts

- 3.7 — `Account::DashboardController#show` at `/account`.
- 3.8 — `/account/highlights` — list of `DevotionalHighlight` records grouped by devotional.
- 3.9 — Stimulus `highlight_controller.js` — captures Range selection on devotional body, POSTs to `HighlightsController#create`.
- 3.10 — Streak calculation job (`StreakRecalculationJob`) — runs at 02:00 daily. Considers devotional reads + email opens.
- 3.11 — Streak display on `/account` and on devotional show (when signed in).
- 3.12 — Pundit policies — `DevotionalHighlightPolicy` (owner only).

### Stripe (test mode)

- 3.13 — `Donor` + `Donation` + `DonationCampaign` models + migrations.
- 3.14 — `GIVING_ENABLED=false` placeholder at `/give`.
- 3.15 — `GivingController#show` — live form when flag is true. Designation dropdown, amount, frequency.
- 3.16 — `GivingController#create` — builds Stripe::CheckoutSession, redirects.
- 3.17 — `Stripe::WebhooksController#create` — signature-verified, enqueues `Stripe::ProcessWebhookJob`.
- 3.18 — `Stripe::ProcessWebhookJob` — idempotent per `event.id`. Handles `checkout.session.completed`, `invoice.paid`, `customer.subscription.deleted`.
- 3.19 — `DonationReceiptMailer` + Postmark template.
- 3.20 — Customer portal link for recurring donors on `/account`.
- 3.21 — ActiveAdmin: Donation + Donor (admin role only).

---

## Phase 4 — Launch (weeks 13–16+)

- 4.1 — Stripe live keys + production webhook endpoint + smoke test with $1 transaction.
- 4.2 — `DonationCampaign` listing + show pages + progress bar (cached `raised_cents`).
- 4.3 — `Event` + `EventRsvp` models + `/events` + `/events/:slug` + RSVP form.
- 4.4 — Launch event landing page (one-off design, May/June 2026).
- 4.5 — AppSignal or Honeybadger wired up, alerts to on-call.
- 4.6 — Backup verification (Hatchbox managed Postgres backups + R2 versioning).
- 4.7 — Load test homepage + devotional show + share-card render.
- 4.8 — Pre-launch accessibility audit (axe-core, keyboard nav, screen reader).
- 4.9 — DNS cutover + warm cache.

---

## Cross-phase, ongoing

- Documentation in `docs/` stays current. When a flow changes, the doc changes in the same PR.
- Every PR runs the test/lint/security gauntlet (see CLAUDE.md §8).
- No work begins on a phase until the previous phase's exit criteria are met.
