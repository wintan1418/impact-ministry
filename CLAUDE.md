# CLAUDE.md — IMPACT Ministry

Read this before doing anything. It is the contract for how this project is built. If a request contradicts something in this file, surface the contradiction before acting.

---

## 1. What this project is

A Rails 8 application for **IMPACT Ministry, Inc.** — a Mississippi-based Christian ministry launching mid-2026. The site is **not a brochure**. It is a habit-forming spiritual product that delivers daily devotionals, hosts a podcast, captures and retains an email audience, accepts donations (Stripe, gated until 501(c)(3) is granted), and supports prayer requests, testimonies, partnerships, and a resource library.

It must be:

- **Convertible** on first visit (email capture across every surface).
- **Habit-forming** for subscribers (streaks, highlights, daily ritual design).
- **Trustworthy** at the gate of giving (dignified, never pushy).
- **Editable by non-developers** via an ActiveAdmin CMS — Juwon's client/team publishes content; we do not deploy to publish.

---

## 2. Stack — non-negotiable

| Layer | Choice |
|---|---|
| Framework | Rails 8, Ruby 3.4.9 |
| Database | PostgreSQL 16+ |
| Background jobs | Solid Queue (no Sidekiq, no Redis) |
| Cache | Solid Cache |
| WebSockets | Solid Cable |
| Frontend | Hotwire (Turbo + Stimulus), Tailwind CSS v4, importmap |
| Admin CMS | ActiveAdmin at `/admin` |
| Auth | Rails 8 native `bin/rails generate authentication` — **NOT Devise** |
| Authorization | Pundit policies |
| Search | pg_search + Postgres full-text + pg_trgm |
| Slugs | friendly_id |
| Email | Postmark via `postmark-rails` (transactional + daily devotional sends) |
| Payments | Stripe (Checkout + Customer Portal + Webhooks) |
| Media storage | Cloudflare R2 via ActiveStorage (S3-compatible) |
| Notifications | Noticed gem (in-app + email orchestration) |
| Throttling | Rack::Attack |
| Bot defense | Cloudflare Turnstile on all public forms |
| Testing | RSpec + FactoryBot + Faker |
| Deployment | Hatchbox (or Kamal 2) |
| Monitoring | AppSignal or Honeybadger |
| Analytics | Plausible (privacy-respecting) |

**Do not introduce:** Devise, Sidekiq, Redis, React, Vue, Node-based bundlers, Inertia, GraphQL, custom CSS frameworks. If a problem seems to require one of these, **stop and propose the change before implementing**.

---

## 3. Conventions

### Code organisation

- **Service objects** in `app/services/` for any flow that touches more than two models or coordinates external IO. Single public method `.call`. Return a result object, not a boolean.
- **Form objects** in `app/forms/` for multi-model submissions (e.g. `PartnershipForm`).
- **Query objects** in `app/queries/` when a scope chain exceeds ~3 conditions.
- **Jobs** in `app/jobs/` — every external IO (email send, Stripe call, image gen, webhook side-effect) goes through a job. Controllers never block on IO.
- **Mailers** in `app/mailers/` with views in `app/views/<mailer>/`. All mailers inherit from `ApplicationMailer` and use Postmark message streams.
- **Policies** in `app/policies/` (Pundit). One policy per resource. Admin namespace uses ActiveAdmin's own auth, not Pundit.
- **Components** — use ViewComponent if a partial gets logic; otherwise plain partials in `app/views/shared/`. Don't reach for ViewComponent prematurely.
- **Stimulus controllers** in `app/javascript/controllers/`, one file per controller, small and focused. Prefer Turbo over Stimulus when both could solve the problem.

### Database & models

- Always add `null: false` and DB defaults at the migration level — don't rely on Rails validations alone for integrity.
- Use `enum` for state fields; always backed by **string** columns, never integers.
- Every public-facing model uses `friendly_id` with a `:slug` column.
- Soft delete only when product requires it. Default to hard delete.
- All timestamps use `t.timestamps` (`created_at` + `updated_at`). Add semantic timestamps (`published_at`, `confirmed_at`, `replied_at`) as nullable datetimes.
- Foreign keys: always `foreign_key: true`, always indexed.
- Use ActionText for body fields that need rich editing in admin.

### Naming

- Tables and models use Rails conventions — no prefixes.
- Boolean columns are positive (`is_anonymous`, not `non_anonymous`) and end in `?` when read in Ruby.
- Routes are RESTful by default; only add custom action verbs when REST genuinely doesn't fit.

### Controllers

- Skinny controllers. Move logic into services, form objects, or query objects.
- One controller per resource. Namespaced (`Admin::`, `Account::`) when scope changes.
- Use `before_action :authenticate_user!` (or admin equivalent) explicitly per controller. Never globally in `ApplicationController`.
- Strong params live in private methods, named `<resource>_params`.

### Views & styling

- Tailwind utility classes only — no custom CSS files except for one `application.tailwind.css` with `@theme` tokens.
- Design tokens live in `tailwind.config.js` and mirror the design brief:

```js
colors: {
  navy:    "#1B2A4E",  // Cathedral Navy
  cream:   "#FAF7F2",  // Communion Cream
  crimson: "#C8102E",  // Sanctuary Crimson
  linen:   "#E8DFD0",
  olive:   "#8B7355",
  ink:     "#1F1B16",
}
```

- Typography stack:
  - Display: **Fraunces** (variable serif)
  - Body UI: **Inter**
  - Long-form devotional: **Lora**
- Easing curve constant: `cubic-bezier(0.22, 1, 0.36, 1)` — use everywhere.
- Never use bouncy springs. Never use spinners. Use shimmer skeletons on cream.

### Forms

- All public forms (prayer, testimony, partnership, contact, email signup) are Turnstile-protected and Rack::Attack-throttled.
- Form errors render inline (no shake animation, no toast). Crimson hairline border, olive-wood help text below the field.
- Submission feedback uses Turbo Streams, not full-page reloads.

### Background jobs

- All jobs inherit from `ApplicationJob`.
- Queue names: `:default`, `:mailers`, `:devotionals`, `:stripe_webhooks`, `:low`.
- Idempotent by default — every job assumes it may be re-run.
- External IO (Stripe, Postmark) calls are wrapped with retry-on-network-error.

### Feature flags

- Use a simple `Setting` model (key/value) for ministry-controllable flags. **Do NOT add Flipper.**
- Hard flags via ENV: `GIVING_ENABLED`, `PODCAST_LIVE_ENABLED`, etc.

---

## 4. Domain models — current shape

*(Names final; columns illustrative — add/remove fields per ticket, but keep the overall shape stable.)*

### Identity

- **User** — `id`, `email_address` (Rails 8 convention), `password_digest`, `name`, `role` (enum: `visitor`, `subscriber`, `editor`, `admin`), `confirmed_at`
- **Session** — Rails 8 built-in

### Content

- **Devotional** — `title`, `slug`, `scripture_reference`, `body` (ActionText), `excerpt`, `author_id`, `scheduled_for` (date, UNIQUE), `published_at`, `featured_image`, `audio_blob`, `tags` (array)
- **PodcastEpisode** — `title`, `slug`, `season`, `episode_number`, `description` (ActionText), `audio_blob`, `video_url`, `duration_seconds`, `scheduled_for`, `published_at`, `guest_names` (array), `transcript`, `show_notes` (ActionText)
- **Resource** — `title`, `slug`, `description`, `category` (enum), `file_blob`, `downloads_count`, `requires_email` (bool), `published_at`
- **Page** — `slug`, `title`, `body` (ActionText), `seo_meta` (jsonb), `published`

### Audience

- **EmailSubscriber** — `email` (UNIQUE), `name`, `subscribed_at`, `unsubscribed_at`, `source` (enum), `preferences` (jsonb), `token`
- **DevotionalDelivery** — `devotional_id`, `email_subscriber_id`, `sent_at`, `opened_at`, `clicked_at`
- **PrayerRequest** — `name`, `email`, `is_anonymous`, `body`, `status` (enum: `new`, `praying`, `answered`, `archived`), `is_public`, `prayed_count`
- **Testimony** — `name`, `location`, `body`, `featured`, `approved`, `photo_blob`, `submitted_at`, `approved_at`
- **FeedbackMessage** — `name`, `email`, `subject`, `body`, `replied`
- **DevotionalHighlight** — `user_id`, `devotional_id`, `text_range`, `saved_at`

### Giving (Stripe — dormant until `GIVING_ENABLED=true`)

- **Donor** — `user_id` (nullable), `stripe_customer_id`, `name`, `email`, `address` (jsonb)
- **Donation** — `donor_id`, `amount_cents`, `currency`, `frequency` (enum: `once`, `monthly`), `designation` (enum: `general`, `youth`, `education`, `missions`), `stripe_payment_intent_id`, `stripe_subscription_id`, `status`, `donated_at`, `receipt_sent_at`
- **DonationCampaign** — `title`, `slug`, `goal_cents`, `raised_cents` (cached), `starts_on`, `ends_on`, `body` (ActionText), `published`

### Community

- **Partnership** — `organization_name`, `contact_name`, `contact_email`, `contact_phone`, `organization_type` (enum), `interest_areas` (array), `message`, `status` (enum)
- **Event** — `title`, `slug`, `description`, `starts_at`, `ends_at`, `location`, `virtual_link`, `capacity`, `published`
- **EventRsvp** — `event_id`, `name`, `email`, `party_size`, `notes`

---

## 5. Key flows — implementation notes

### Daily devotional dispatch

1. A recurring Solid Queue job (`DevotionalDispatchJob`) runs at **05:00 America/Chicago** daily.
2. It finds `Devotional.where(scheduled_for: Date.current, published_at: nil)`.
3. Publishes it (`update!(published_at: Time.current)`).
4. Enqueues `DevotionalDeliveryJob` per active `EmailSubscriber`.
5. Each delivery creates a `DevotionalDelivery` row, sends via Postmark.
6. Postmark webhooks update `opened_at` / `clicked_at`.
7. If no devotional is scheduled, send a Slack/email alert to editors at 06:00 (failsafe).

### Email capture

- Multiple surfaces (footer, exit intent, inline mid-content, prayer-form upsell).
- All POST to `/subscribe` (or via Turbo Stream to `EmailSubscribersController#create`).
- Every signup records a `source` enum so we can attribute conversions.
- Welcome email goes out immediately via job, includes link to today's devotional.

### Habit mechanics

- **Streak** = consecutive days a logged-in user has loaded `/devotionals/today` OR opened the email (Postmark webhook). Stored on `User`. Recalculated by a daily job.
- **Highlight & save** — user drags a selection in the devotional body; a Stimulus controller captures the range and POSTs to `/highlights`. Renders on `/account/highlights`.
- **Share card** — at `/devotionals/:slug/share_card.png`, server-side renders an HTML template to PNG (via `grover` or a separate browserless service). Cached aggressively.
- **Tomorrow teaser** — bottom of every devotional shows the scripture book/chapter (not verse) for `scheduled_for = Date.current + 1`. One line.

### Giving (Stripe)

- `GIVING_ENABLED=false` → `/give` renders the "pre-501(c)(3)" placeholder page with email capture.
- `GIVING_ENABLED=true` → `/give` renders the live donation form.
- Flow: form → `Stripe::CheckoutSession.create` (server-side) → redirect to Stripe → webhook back to `/stripe/webhooks` → create `Donor` + `Donation` records → email receipt.
- Customer Portal handled by `Stripe::BillingPortal::Session.create` for recurring donors.
- All Stripe webhooks are queued (`:stripe_webhooks` queue), signed-verified, and idempotent.

### Prayer wall

- Submission writes a `PrayerRequest`. If `is_public` and approved, appears on `/pray`.
- "I prayed for this" button → Turbo Stream POST → increments `prayed_count` → re-renders the counter.
- Admin can mark requests as `answered`. Answered + public ones get a badge.

---

## 6. Roles & permissions

- **visitor** (anonymous) — read public content, submit forms.
- **subscriber** (signed in) — visitor + streaks, highlights, account page.
- **editor** — subscriber + ActiveAdmin access scoped to content (devotionals, podcasts, prayer moderation, testimonies). **Cannot see donations.**
- **admin** — full ActiveAdmin access including donations, settings, user roles.

ActiveAdmin scoping is enforced via `controller.authorize_resource` in each registration. Pundit handles public-side authorization.

---

## 7. Environments & ENV

```bash
# .env.development (loaded by dotenv-rails)
DATABASE_URL=postgres://localhost/impact_ministry_development
POSTMARK_API_TOKEN=POSTMARK_TEST_TOKEN
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
GIVING_ENABLED=false
PODCAST_LIVE_ENABLED=false
R2_ACCESS_KEY_ID=...
R2_SECRET_ACCESS_KEY=...
R2_BUCKET=impact-ministry-dev
R2_ENDPOINT=https://<account>.r2.cloudflarestorage.com
TURNSTILE_SITE_KEY=...
TURNSTILE_SECRET_KEY=...
DEVOTIONAL_SEND_HOUR=5      # 05:00 in DEVOTIONAL_TIMEZONE
DEVOTIONAL_TIMEZONE=America/Chicago
ADMIN_NOTIFICATION_EMAIL=team@impactministry.org
```

Production secrets live in Hatchbox env vars + Rails encrypted credentials. **Never commit `.env`.**

---

## 8. Testing posture

- RSpec, FactoryBot, Faker.
- Required coverage: every model (validations + key scopes), every service object, every job, every controller for happy path + error path, donation checkout (Stripe test mode).
- Do NOT chase 100% line coverage. Chase meaningful coverage of behaviour.
- Use `let` sparingly. Prefer explicit setup at the top of `describe` blocks.

Run before committing:

```bash
bundle exec rspec
bin/rubocop -A
bin/brakeman --no-pager
```

---

## 9. Phased build — current target

We are tracking against the brief's four phases:

- **Phase 1 (weeks 1–4):** scaffold + design system + homepage + devotional engine + email capture.
- **Phase 2 (weeks 5–8):** podcast + prayer wall + testimonies + share cards.
- **Phase 3 (weeks 9–12):** partnerships + resources + user accounts + streaks/highlights + Stripe (in test).
- **Phase 4 (weeks 13–16+):** Stripe live, donation campaigns, events, launch event landing.

When picking up a ticket, check which phase it belongs to. **Don't pull Phase 3 work into Phase 1** — it inflates scope and breaks the launch timeline.

See `docs/BUILD_PLAN.md` for the ticket-level breakdown.

---

## 10. Things to ask me about before implementing

- Adding a gem not in the stack table above.
- Changing the `role` enum or auth model.
- Anything that touches the Stripe webhook flow.
- Changing email send timing or the daily dispatch job.
- Adding new top-level routes outside the brief's surface list.
- Schema changes to `Devotional`, `EmailSubscriber`, or `Donation` once seeded.

For everything else: read this file, follow the conventions, ship the ticket, write the test, commit with a clear message.

---

## 11. Voice for any copy you write

If a ticket needs placeholder or real copy:

- **Warm but not cloying.** "Start your day with us" not "Welcome to your spiritual journey!"
- **Confident but not preachy.** "A short, true word" not "Be transformed by God's word."
- **Specific, second-person, quiet.** "We're praying with you." "Your seat is saved."
- **Never use lorem ipsum** in templates that ship — it hides design flaws.

---

## 12. Supporting docs

- `docs/BUILD_PLAN.md` — phased ticket breakdown, dependency order.
- `docs/DOMAIN.md` — model relationships, indices, lifecycle notes.
- `docs/ROUTES.md` — public, account, and admin URL surface.
- `docs/DESIGN_SYSTEM.md` — tokens, components, page templates (filled in once the design is in).
- `docs/ENVIRONMENT.md` — local setup + every ENV var explained.

---

*Last updated: May 2026. Maintained by Juwon. If this file disagrees with the design brief or build plan docs, the docs win and this file gets updated.*
