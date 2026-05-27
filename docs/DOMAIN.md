# DOMAIN.md — Model relationships & lifecycle

Companion to CLAUDE.md §4. CLAUDE.md lists the columns; this file shows the *relationships*, *indices*, and *lifecycle states* that you can't see from a column list alone.

---

## Relationship map (text ERD)

```
User ─┬─< Devotional (as author)
      ├─< DevotionalHighlight >── Devotional
      ├── Donor (0..1, nullable link)
      └── (Session — Rails 8 built-in)

Devotional ─< DevotionalDelivery >── EmailSubscriber

EmailSubscriber  (no FK to User by design — capture-first, claim later)

PrayerRequest   (anonymous — no FK to User)
Testimony       (anonymous — no FK to User)
FeedbackMessage (anonymous — no FK to User)

Donor ─< Donation
DonationCampaign  (standalone; Donations may reference via designation+campaign_id later)

Partnership       (form submission, no FK)
Event ─< EventRsvp

Page              (standalone)
Resource          (standalone; tracks downloads via counter)
Setting           (key/value)
```

---

## Index plan (beyond Rails defaults)

| Table | Index | Reason |
|---|---|---|
| `users` | `email` UNIQUE | login |
| `users` | `role` | admin/editor scopes |
| `devotionals` | `scheduled_for` UNIQUE | one per day |
| `devotionals` | `slug` UNIQUE | friendly_id |
| `devotionals` | `published_at` | archive ordering |
| `devotionals` | GIN on `tags` | array search |
| `devotionals` | pg_trgm on `title` | fuzzy search |
| `email_subscribers` | `email` UNIQUE | dedupe |
| `email_subscribers` | `unsubscribed_at` | active-subscriber scope |
| `email_subscribers` | `token` UNIQUE | unsubscribe link |
| `devotional_deliveries` | (`devotional_id`, `email_subscriber_id`) UNIQUE | idempotent dispatch |
| `devotional_deliveries` | `sent_at` | analytics |
| `prayer_requests` | (`status`, `is_public`) | wall query |
| `prayer_requests` | `created_at DESC` | feed ordering |
| `testimonies` | (`approved`, `featured`) | public list |
| `donors` | `stripe_customer_id` UNIQUE | webhook lookup |
| `donations` | `stripe_payment_intent_id` UNIQUE | idempotency |
| `donations` | `stripe_subscription_id` | recurring lookup |
| `donations` | `donated_at` | reporting |
| `donation_campaigns` | `slug` UNIQUE | friendly_id |
| `donation_campaigns` | (`starts_on`, `ends_on`) | active campaigns |
| `events` | `slug` UNIQUE | friendly_id |
| `event_rsvps` | (`event_id`, `email`) UNIQUE | dedupe RSVPs |
| `devotional_highlights` | (`user_id`, `devotional_id`) | account view |
| `pages` | `slug` UNIQUE | router |
| `settings` | `key` UNIQUE | lookup |

---

## Lifecycle / state notes

### `Devotional`
- States: **draft** (`scheduled_for` set, `published_at` nil) → **scheduled** (date assigned) → **published** (`published_at` set, dispatch ran) → **archived** (older than X days, kept indefinitely).
- Hard rule: only one devotional per `scheduled_for` date.
- Dispatch is *the* publishing trigger in production. In admin, "publish now" sets `published_at` immediately and skips email.

### `EmailSubscriber`
- States: **active** (`subscribed_at` set, `unsubscribed_at` nil) → **unsubscribed** (`unsubscribed_at` set). Re-subscribe wipes `unsubscribed_at`.
- `source` is set on first signup and never changes. Track conversion attribution.
- `preferences` jsonb leaves room for granular opt-outs later without a migration.

### `PrayerRequest`
- `status` enum: `new` (submitted, awaiting moderation) → `praying` (approved + visible) → `answered` (still public, gets badge) → `archived` (hidden).
- `is_public` is independently toggleable — admin may approve a request to be prayed for internally without surfacing it.
- `prayed_count` increments per click, deduped per session via a Rails session cookie (Phase 2 detail).

### `Donation`
- `status` mirrors Stripe payment intent / subscription states: `pending`, `succeeded`, `failed`, `refunded`.
- Webhook is the only writer for `status` post-creation. Controllers never mutate `status` directly.
- `receipt_sent_at` set by `DonationReceiptMailer` job; if nil after 5 minutes, retry once.

### `Donor`
- Created on first successful Stripe checkout. Linked to `User` if the donor was signed in.
- Anonymous donors are first-class — no User required.

### `User#role`
- String enum: `visitor` (placeholder; signed-in users default to `subscriber`), `subscriber`, `editor`, `admin`.
- Promotion to `editor`/`admin` happens only in console or via admin UI by another admin. Never self-service.

### `Setting`
- Reads cached for 60s via `Rails.cache`.
- Writes invalidate cache for that key.
- Known keys (seed at install): `homepage_hero_quote`, `giving_placeholder_copy`, `prayer_wall_visible`.

---

## Soft-delete decisions

Per CLAUDE.md: hard delete by default. Soft-delete where ministry/audit needs require it:

- `Donation` — never deleted. Refunds adjust `status`, not the row.
- `Donor` — never deleted. Anonymized if requested.
- `PrayerRequest`, `Testimony`, `FeedbackMessage` — hard delete on archive/spam.
- `EmailSubscriber` — hard delete only on explicit GDPR-style request; otherwise `unsubscribed_at` is enough.
- Everything else — hard delete.

---

## Things that are intentionally NOT in the schema (yet)

- Comments / threaded discussion on devotionals — would require moderation infrastructure; not in Phase 1–4.
- Multiple-author bylines on devotionals — single author for now.
- A/B testing tables — defer to Plausible custom events first.
- Tiered subscriber paywall — not in scope for launch.
- User-to-user follow / social graph — not in scope.

If a ticket implies one of these, push back to scope.
