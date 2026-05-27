# Idempotent seed — safe to run repeatedly in every environment.
# See `db:seed` task.

# -----------------------------------------------------------
# Bootstrap admin (override email/password via ENV in prod).
# -----------------------------------------------------------
admin_email = ENV.fetch("BOOTSTRAP_ADMIN_EMAIL", "admin@impactministry.local")
admin_pw    = ENV.fetch("BOOTSTRAP_ADMIN_PASSWORD", "change-me-immediately")

admin = User.find_or_initialize_by(email_address: admin_email)
if admin.new_record?
  admin.password = admin_pw
  admin.name = "IMPACT Admin"
  admin.role = "admin"
  admin.confirmed_at = Time.current
  admin.save!
  puts "Seeded admin: #{admin.email_address} (password from BOOTSTRAP_ADMIN_PASSWORD or default — rotate in prod)"
else
  puts "Admin user already present: #{admin.email_address}"
end

# -----------------------------------------------------------
# Static pages — editor-managed via /admin/pages.
# Copy is dignified, second-person, never lorem ipsum (CLAUDE.md §11).
# -----------------------------------------------------------
page_seeds = [
  {
    slug:  "about",
    title: "About IMPACT Ministry",
    body:  <<~HTML.strip,
      <p>IMPACT Ministry was started in 2026 by a small group of pastors, writers, and neighbors in Mississippi. We wanted to make something the internet didn't already have: a quiet, daily place to think about God without being sold a conference ticket.</p>
      <p>Our daily devotional reaches readers across the country. Our podcast goes deeper, slower. Our prayer wall is full of strangers who have agreed to carry each other's weight for a few minutes a day.</p>
      <p>Our mission is simple: to put scripture in the hands of people who would not otherwise pick it up, and to do it with the warmth and weight the scripture itself deserves.</p>
    HTML
    seo:   { "description" => "A small Mississippi ministry making a quiet, daily place to meet God." }
  },
  {
    slug:  "beliefs",
    title: "What we believe",
    body:  <<~HTML.strip,
      <p>We hold the historic Christian confession: one God in three Persons, one scripture trustworthy and true, one gospel of grace through Jesus, one Spirit at work in those who follow Him, one table open to every nation, and one commission to love our neighbors well.</p>
      <p>We are not a denomination and we do not aim to become one. We work alongside local churches across Mississippi and beyond. When you read us, you should hear something familiar — the same faith that has held the church for two thousand years, written for a Tuesday morning.</p>
    HTML
    seo:   { "description" => "The historic Christian faith, written for a Tuesday morning." }
  },
  {
    slug:  "contact",
    title: "Contact us",
    body:  <<~HTML.strip,
      <p>If you have a question, a correction, or a story you'd like us to hear, we'd be glad to receive it.</p>
      <p>Email us at <a href="mailto:hello@impactministry.org">hello@impactministry.org</a>. We read everything. We reply to most of it within a few days, though sometimes the morning gets ahead of the inbox.</p>
      <p>If your note is a prayer request, you're also welcome to send it through our prayer wall — it goes to the same small group of people, and you can keep it anonymous.</p>
    HTML
    seo:   { "description" => "Write to us. We read everything." }
  },
  {
    slug:  "privacy",
    title: "Privacy",
    body:  <<~HTML.strip,
      <p>We collect as little about you as we can. When you sign up for the daily devotional we store your email address, the date you signed up, and where on the site you signed up from — nothing more. We never sell, share, or rent your email to anyone, full stop.</p>
      <p>We use Plausible to count visitors. It is privacy-respecting and does not use cookies. We do not run third-party ad tracking.</p>
      <p>You can unsubscribe at any time from the bottom of any email, or by writing to us. Once you unsubscribe, we keep your email only long enough to make sure we do not accidentally email you again.</p>
    HTML
    seo:   { "description" => "We collect as little about you as we can." }
  },
  {
    slug:  "terms",
    title: "Terms of use",
    body:  <<~HTML.strip,
      <p>This site is offered as a gift to whoever finds it useful. You are welcome to read, save, print, and share what we publish for personal or church use. If you want to reprint something in a book or other commercial work, please write first.</p>
      <p>We try hard to be accurate. We will correct errors quickly when you tell us about them. Nothing on this site is medical, legal, or financial advice. If you are in crisis, please call a trusted friend or 988.</p>
      <p>IMPACT Ministry, Inc. is a Mississippi nonprofit corporation. We are pursuing 501(c)(3) status; until that is granted, donations are not tax-deductible.</p>
    HTML
    seo:   { "description" => "How to use what we publish." }
  }
]

page_seeds.each do |attrs|
  page = Page.find_or_initialize_by(slug: attrs[:slug])
  page.title     = attrs[:title]
  # Lock the slug to the canonical short value; friendly_id would otherwise
  # derive "about-impact-ministry" from the title, breaking /about.
  page.slug      = attrs[:slug]
  page.seo_meta  = attrs[:seo]
  page.published = true
  page.body      = attrs[:body] if page.body.blank?
  if page.changed? || page.new_record?
    page.save!
    puts "Seeded page: /#{page.slug}"
  else
    puts "Page already present: /#{page.slug}"
  end
end

# -----------------------------------------------------------
# Initial settings (see docs/DOMAIN.md — Setting).
# Use Setting.set so the cache is invalidated atomically.
# -----------------------------------------------------------
setting_seeds = [
  {
    key:  "homepage_hero_quote",
    kind: "string",
    value: "For still the vision awaits its appointed time. — Habakkuk 2:3",
    description: "Hero scripture displayed at the top of the homepage."
  },
  {
    key:  "giving_placeholder_copy",
    kind: "string",
    value: "We are pursuing 501(c)(3) status. Once granted, you'll be able to give here. " \
           "Until then, leave your email and we'll write the moment giving opens.",
    description: "Copy shown on /give while GIVING_ENABLED is false."
  },
  {
    key:  "prayer_wall_visible",
    kind: "boolean",
    value: true,
    description: "Show the public prayer wall on /pray. Set to false to hide it temporarily."
  }
]

setting_seeds.each do |attrs|
  existing = Setting.find_by(key: attrs[:key])
  if existing
    # Don't overwrite ministry-edited values on re-seed; only re-align kind + description.
    changed = false
    if existing.kind != attrs[:kind]
      existing.kind = attrs[:kind]
      changed = true
    end
    if existing.description != attrs[:description]
      existing.description = attrs[:description]
      changed = true
    end
    if changed
      existing.save!
      puts "Updated setting metadata: #{attrs[:key]}"
    else
      puts "Setting already present: #{attrs[:key]}"
    end
  else
    Setting.set(attrs[:key], attrs[:value], kind: attrs[:kind])
    Setting.find_by(key: attrs[:key]).update!(description: attrs[:description])
    puts "Seeded setting: #{attrs[:key]}"
  end
end
