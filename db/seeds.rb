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

# =================================================================
# Sample content for development only.
# Idempotent — re-runs safely. Skipped in production so live seeds
# stay clean and the team writes real devotionals via /admin.
# =================================================================
if Rails.env.development?
  admin_user = User.find_by(role: "admin") or abort("Need an admin user before seeding sample content")

  # --- Devotionals: today + 13 days back + 3 days ahead -------------
  devotionals = [
    { offset:  3, title: "A Word for the Week You Haven't Lived Yet", scripture: "Ecclesiastes 3:1",     tags: %w[seasons hope] },
    { offset:  2, title: "When the Calendar Tightens",                 scripture: "James 4:13–15",       tags: %w[time waiting] },
    { offset:  1, title: "Tomorrow's Bread",                           scripture: "Matthew 6:34",        tags: %w[trust provision] },
    { offset:  0, title: "When the Vision Tarries",                    scripture: "Habakkuk 2:1–4",      tags: %w[waiting habakkuk] },
    { offset: -1, title: "Quieted by His Love",                        scripture: "Zephaniah 3:17",      tags: %w[rest love] },
    { offset: -2, title: "The Long Obedience",                         scripture: "Hebrews 12:1–2",      tags: %w[endurance] },
    { offset: -3, title: "A Lamp at Midnight",                         scripture: "Psalm 119:105",       tags: %w[scripture night] },
    { offset: -4, title: "The Patience of Joseph",                     scripture: "Genesis 50:20",       tags: %w[providence forgiveness] },
    { offset: -5, title: "What the Watchman Saw",                      scripture: "Isaiah 21:11–12",     tags: %w[waiting watchful] },
    { offset: -6, title: "Bread for the Day",                          scripture: "Matthew 6:11",        tags: %w[provision] },
    { offset: -7, title: "Manna in the Morning",                       scripture: "Exodus 16:21",        tags: %w[provision morning] },
    { offset: -8, title: "The Yoke is Easy",                           scripture: "Matthew 11:28–30",    tags: %w[rest invitation] },
    { offset: -9, title: "Streams in the Wasteland",                   scripture: "Isaiah 43:19",        tags: %w[renewal] },
    { offset: -10, title: "All Things Hold Together",                   scripture: "Colossians 1:17",     tags: %w[providence christ] },
    { offset: -11, title: "If These Were Silent, the Stones Would Cry", scripture: "Luke 19:40",          tags: %w[praise] },
    { offset: -12, title: "He Restores My Soul",                        scripture: "Psalm 23:3",          tags: %w[restoration] },
    { offset: -13, title: "Be Still, and Know",                         scripture: "Psalm 46:10",         tags: %w[stillness] }
  ]

  devotional_excerpts = {
    "When the Vision Tarries" =>
      "Waiting is not the absence of God's word. It is the long, slow work of trusting that what He has spoken still stands — even when the answer takes its time.",
    "Quieted by His Love" =>
      "There is a kind of quiet you cannot manufacture. It comes only when Someone larger than your worry leans in close and decides not to leave.",
    "The Long Obedience" =>
      "Faith is rarely a single decision. It is a thousand small mornings of choosing to put one foot down where the last one was.",
    "Be Still, and Know" =>
      "Stillness is not idleness. It is the holy work of letting God be God while you remember, slowly, that you are not.",
    "Bread for the Day" =>
      "He did not promise a year's supply. He promised today. And today, that has always been enough."
  }

  devotional_bodies = {
    default: <<~HTML,
      <p>The prophet stood his watch. He did not pace, he did not panic — he stood. He climbed the tower and waited for an answer, even though the news from the lowlands was bad and the silence from heaven was longer than he had hoped.</p>
      <p>What we forget about waiting is that it is also work. The watchman is doing a job. The vision he is waiting for has already been spoken; his task is not to manufacture it, but to receive it when it comes. <em>For still the vision awaits its appointed time.</em> Not yours. Not ours. <em>Its.</em></p>
      <p>You do not have to make tomorrow happen. You only have to be awake when it arrives.</p>
    HTML
    "When the Vision Tarries" => <<~HTML,
      <p>Habakkuk stood his watch. He did not pace, he did not panic — he stood. And he wrote down what God said, even though the answer was slow.</p>
      <p>The hardest thing about waiting on God is not the not-knowing. It is the suspicion, late at night, that maybe nothing is coming at all. That what was spoken has been forgotten. That the silence is the answer.</p>
      <p>But the text gives us a different word. <em>The vision awaits its appointed time; it hastens to the end — it will not lie.</em> Not your timing. Its. And not your strength to hold it up — its own strength to arrive when the soil is right.</p>
      <p>Today, your job is small. Stand the watch. Keep faith with what was spoken. The vision will not lie.</p>
    HTML
    "Quieted by His Love" => <<~HTML,
      <p>Zephaniah closes a brutal book with a tender line. After the warnings, after the fire, after the bones of judgment have been laid out plain, the prophet sets down a sentence that does not sound like the same God: <em>he will quiet you by his love</em>.</p>
      <p>Not <em>cheer you up</em>. Not <em>distract you</em>. Quiet. The kind of quiet that comes when someone larger than your worry leans in close and decides not to leave.</p>
      <p>If your morning is loud — and most are — let this word fall first.</p>
    HTML
    "Be Still, and Know" => <<~HTML
      <p>The psalm does not promise rescue from the trouble. It promises a kind of knowing that arrives in stillness, in the middle of trouble. The nations rage. The mountains slip into the heart of the sea. And right there — in the middle of all that — <em>be still, and know that I am God</em>.</p>
      <p>The stillness is not the goal. The knowing is the goal. The stillness is the soil the knowing grows in.</p>
      <p>Take two minutes. Close the laptop. Read the verse once. Let it sit.</p>
    HTML
  }

  devotionals.each do |spec|
    date = Date.current + spec[:offset].days
    next if Devotional.exists?(scheduled_for: date)

    d = Devotional.new(
      title:                spec[:title],
      scripture_reference:  spec[:scripture],
      excerpt:              devotional_excerpts[spec[:title]] ||
                            "A short word for #{date.strftime('%A')} morning — read in under two minutes.",
      author:               admin_user,
      scheduled_for:        date,
      tags:                 spec[:tags]
    )
    d.body = devotional_bodies[spec[:title]] || devotional_bodies[:default]
    # Publish anything from today and earlier; leave the next 3 days as scheduled-draft.
    d.published_at = Time.current if spec[:offset] <= 0
    d.save!
    state = d.published_at ? "published" : "scheduled"
    puts "Seeded devotional (#{state}): #{d.scheduled_for} · #{d.title}"
  end

  # --- Email subscribers (sample audience for stats) ---------------
  TARGET_SUBSCRIBERS = 80
  sources = EmailSubscriber::SOURCES - %w[manual]  # spread across capture surfaces
  existing = EmailSubscriber.count

  if existing < TARGET_SUBSCRIBERS
    needed = TARGET_SUBSCRIBERS - existing
    attempts = 0
    created = 0
    while created < needed && attempts < needed * 4
      attempts += 1
      email = Faker::Internet.email(domain: %w[example.com example.org test.local].sample)
      next if EmailSubscriber.exists?(email: email.downcase)

      EmailSubscriber.create!(
        email:          email,
        name:           Faker::Name.name,
        source:         sources.sample,
        subscribed_at:  rand(30.days).seconds.ago
      )
      created += 1
    end
    puts "Seeded #{created} sample email subscribers — now #{EmailSubscriber.count} total."
  else
    puts "Email subscribers already populated (#{existing})."
  end

  # --- Podcast episodes (sample season 1) --------------------------
  podcast_seeds = [
    { ep: 8, offset_days:   5, photo: "microphone", title: "Sermons That Don't Outshout the Text",
      guests: [ "Wendell Anders" ],
      desc: "A homiletics professor on the long-lost art of preaching that lets the passage breathe — and what happens to a congregation when the preacher gets out of the way." },
    { ep: 7, offset_days:  -3, photo: "doorway-light", title: "The Long Obedience of Building Something Good",
      guests: [ "Dr. Anita Keys" ],
      desc: "Dr. Anita Keys joins to talk about staying faithful through the years where nothing seems to grow — and what waiting taught her about leadership in a season of urgency." },
    { ep: 6, offset_days: -10, photo: "path-pines",  title: "Mississippi Mornings",
      guests: [ "Pastor Reuben Hollis" ],
      desc: "What the Delta teaches you about scripture, slowness, and the particular kind of dignity small places carry. A long conversation with the founder of IMPACT." },
    { ep: 5, offset_days: -17, photo: "open-bible",  title: "A Bible You Can Lean On",
      guests: [ "Sarah-Beth Kim" ],
      desc: "Our devotional editor on why translation choices matter, what we lose when we hurry, and how to teach a teenager to slow down and read for a lifetime." },
    { ep: 4, offset_days: -24, photo: "handshake",   title: "When a Small Church Hires a Designer",
      guests: [ "Marcus Levine", "Renée Bowman" ],
      desc: "Our partner-churches director and a graphic designer who left a corporate gig to help five rural congregations rebuild their visual language. What surprised them, what didn't, and what's still hard." },
    { ep: 3, offset_days: -31, photo: "praying-hands", title: "Praying When You Don't Feel It",
      guests: [ "Father James Lloyd" ],
      desc: "A Catholic monk turned street pastor on the daily office, the dryness, and the discipline of speaking when there is nothing inside you that wants to speak." },
    { ep: 2, offset_days: -38, photo: "morning-desk", title: "On Writing a Word Worth Reading",
      guests: [ "Editorial round-table" ],
      desc: "The whole devotional team in one room. How a paragraph gets to your inbox at 5am — the false starts, the rewrites, the cut darlings." },
    { ep: 1, offset_days: -45, photo: "delta-sunrise", title: "Why a Podcast, Why Now",
      guests: [ "Pastor Reuben Hollis", "Sarah-Beth Kim" ],
      desc: "The pilot. A short conversation about what this show is, what it isn't, and why we're starting it in 2026 instead of waiting until everything was perfect." }
  ]

  podcast_seeds.each do |s|
    next if PodcastEpisode.exists?(season: 1, episode_number: s[:ep])
    date = Date.current + s[:offset_days].days
    ep = PodcastEpisode.new(
      title:             s[:title],
      season:            1,
      episode_number:    s[:ep],
      description:       s[:desc],
      guest_names:       s[:guests],
      duration_seconds:  (32 + rand(20)) * 60,    # 32–52 min
      scheduled_for:     date,
      cover_photo_slug:  s[:photo]
    )
    ep.published_at = Time.current if s[:offset_days] < 0
    ep.save!
    state = ep.published_at ? "published" : "scheduled"
    puts "Seeded podcast (#{state}): S#{ep.season} E#{ep.episode_number} · #{ep.title}"
  end

  # --- Devotional deliveries (open rate visualization) ------------
  # For each published devotional, create a delivery row per subscriber if missing.
  # ~58% open rate, ~12% click rate to feel realistic.
  if DevotionalDelivery.count < (Devotional.published.count * EmailSubscriber.active.count * 0.5)
    published_devotionals = Devotional.published.where("scheduled_for <= ?", Date.current)
    active_subs           = EmailSubscriber.active.to_a
    created = 0

    published_devotionals.find_each do |d|
      active_subs.each do |sub|
        next if DevotionalDelivery.exists?(devotional_id: d.id, email_subscriber_id: sub.id)
        sent = d.scheduled_for.to_time.change(hour: 5, min: rand(0..10)) + rand(0..30 * 60).seconds
        opened  = rand < 0.58 ? sent + rand(60..6.hours).seconds : nil
        clicked = (opened && rand < 0.22) ? opened + rand(30..600).seconds : nil
        DevotionalDelivery.create!(
          devotional: d,
          email_subscriber: sub,
          sent_at: sent,
          opened_at: opened,
          clicked_at: clicked,
          postmark_message_id: "seed-#{d.id}-#{sub.id}"
        )
        created += 1
      end
    end
    puts "Seeded #{created} delivery rows (open ~58%, click ~12%)."
  else
    puts "Delivery history already populated."
  end

  # --- Prayer wall (sample requests across statuses) ----------------
  TARGET_PRAYERS = 12
  if PrayerRequest.count < TARGET_PRAYERS
    # Mix of named + anonymous, status spread across new/praying/answered,
    # is_public mostly true so the wall looks alive in development.
    prayer_seeds = [
      { status: "praying",  is_public: true,  is_anonymous: true,  name: nil,          prayed: 47, age: 12.minutes },
      { status: "praying",  is_public: true,  is_anonymous: false, name: "Daniel R.",  prayed: 23, age: 38.minutes },
      { status: "praying",  is_public: true,  is_anonymous: true,  name: nil,          prayed: 112, age: 1.hour },
      { status: "answered", is_public: true,  is_anonymous: false, name: "Marie K.",   prayed: 284, age: 3.hours },
      { status: "praying",  is_public: true,  is_anonymous: true,  name: nil,          prayed: 91, age: 5.hours },
      { status: "praying",  is_public: true,  is_anonymous: false, name: "Pastor T.",  prayed: 156, age: 1.day },
      { status: "answered", is_public: true,  is_anonymous: true,  name: nil,          prayed: 76, age: 2.days },
      { status: "praying",  is_public: true,  is_anonymous: false, name: "Lena W.",    prayed: 18, age: 2.days },
      { status: "praying",  is_public: true,  is_anonymous: true,  name: nil,          prayed: 8,  age: 4.days },
      { status: "answered", is_public: true,  is_anonymous: false, name: "Marcus J.",  prayed: 41, age: 6.days },
      # New (awaiting moderation) — won't show on the wall but seed admin queue.
      { status: "new",      is_public: false, is_anonymous: true,  name: nil,          prayed: 0,  age: 20.minutes },
      { status: "new",      is_public: false, is_anonymous: false, name: "Esther B.",  prayed: 0,  age: 2.hours }
    ]

    prayer_bodies = [
      "For my mother, after the diagnosis. Pray that she would feel held. Pray that I would know what to say.",
      "I start a new job Monday after a year of looking. Grateful, terrified. Pray I would do good work without making it an idol.",
      "For my marriage. We are not okay but we are still talking. That feels like grace.",
      "Praising the Lord — the scan came back clear after eighteen months of waiting. He is faithful.",
      "For a son who has stopped coming home. The Father in the parable kept watching the road. Help me keep watching.",
      "Our small church in Greenwood lost its building this week. Pray for our people and that we'd remember the building was never the church.",
      "Pray we'd remember how to be quiet together in the evenings without screens. The kids need it. So do we.",
      "Asking for clarity on a hard conversation I have to have tomorrow. Words that are honest and kind.",
      "Pray for my friend who is grieving. I don't have anything to say. I'm just sitting with her.",
      "He answered our prayer for housing — we move in next week. Thanking him for the long wait that made the answer holy."
    ]

    created = 0
    prayer_seeds.take(TARGET_PRAYERS).each_with_index do |spec, i|
      body = prayer_bodies[i] ||
             Faker::Lorem.sentences(number: rand(1..3)).join(" ").truncate(280)
      pr = PrayerRequest.new(
        name:         spec[:name],
        body:         body,
        status:       spec[:status],
        is_public:    spec[:is_public],
        is_anonymous: spec[:is_anonymous],
        prayed_count: spec[:prayed]
      )
      pr.save!
      # Backdate created_at so the wall looks aged-in.
      ts = spec[:age].ago
      PrayerRequest.where(id: pr.id).update_all(created_at: ts, updated_at: ts)
      created += 1
    end
    puts "Seeded #{created} prayer requests — now #{PrayerRequest.count} total."
  else
    puts "Prayer requests already populated (#{PrayerRequest.count})."
  end

  # --- Events + RSVPs ---------------------------------------------
  # 4 upcoming gatherings + 1 past one so /events is populated.
  event_seeds = [
    { title: "First Light Devotional Brunch",
      offset_weeks: 3,
      duration_hours: 2,
      location: "Jackson, MS",
      capacity: 60,
      cover: "morning-desk",
      description:
        "A slow Saturday morning together — coffee, scripture, and a single short reading. " \
        "We meet downtown and walk to the coffee bar after. Kids welcome." },
    { title: "Podcast Live: Season One Wrap",
      offset_weeks: 5,
      duration_hours: 1,
      virtual_link: "https://zoom.us/j/impact-podcast-live",
      cover: "microphone",
      description:
        "Reuben and Sarah-Beth host a live recording wrapping our first season. " \
        "Bring your questions. We'll take them in real time and edit the best into the episode." },
    { title: "Partners Roundtable",
      offset_weeks: 7,
      duration_hours: 3,
      location: "Greenville, MS",
      capacity: 24,
      cover: "handshake",
      description:
        "Lunch and a long conversation with leaders from partner churches and nonprofits across the Delta. " \
        "By invitation; reach out if you'd like to be invited next time." },
    { title: "Holy Week Walk",
      offset_weeks: 8,
      duration_hours: 4,
      location: "Natchez Trace, MS",
      capacity: 200,
      cover: "path-pines",
      description:
        "A four-hour walk through a quiet stretch of the Trace, with stops to read the Passion narrative aloud. " \
        "Bring water, sturdy shoes, and a friend who needs the quiet." }
  ]

  event_seeds.each do |spec|
    event = Event.find_or_initialize_by(title: spec[:title])
    starts = Time.current + spec[:offset_weeks].weeks
    event.assign_attributes(
      description:      spec[:description],
      starts_at:        starts,
      ends_at:          starts + spec[:duration_hours].hours,
      location:         spec[:location],
      virtual_link:     spec[:virtual_link],
      capacity:         spec[:capacity],
      cover_photo_slug: spec[:cover],
      published:        true
    )
    if event.changed? || event.new_record?
      event.save!
      puts "Seeded event: #{event.starts_at.strftime('%Y-%m-%d')} · #{event.title}"
    else
      puts "Event already present: #{event.title}"
    end

    # Sample RSVPs — 4 to 10 attendees per event.
    target_rsvps = rand(4..10)
    existing_rsvps = event.event_rsvps.count
    needed = [ target_rsvps - existing_rsvps, 0 ].max
    needed.times do
      email = Faker::Internet.email(domain: %w[example.com example.org test.local].sample)
      next if event.event_rsvps.exists?(email: email.downcase)

      party = [ 1, 1, 1, 2 ].sample
      next if event.capacity && (event.rsvp_seat_count + party) > event.capacity

      event.event_rsvps.create!(
        name:       Faker::Name.name,
        email:      email,
        party_size: party,
        notes:      [ nil, nil, "Excited!", "Bringing a friend.", "First time." ].sample
      )
    end
  end

  # --- Feedback messages (sample contact-form queue) --------------
  TARGET_FEEDBACK = 5
  if FeedbackMessage.count < TARGET_FEEDBACK
    feedback_seeds = [
      { kind: "general",     name: "Esther B.",  subject: "Thank you for what you write",
        age: 4.hours,  replied: false,
        body: "Just wanted to say thank you. The Habakkuk piece met me on a hard morning. I read it on the porch and cried, then drank cold coffee and got the kids to school." },
      { kind: "prayer",      name: "Daniel R.",  subject: nil,
        age: 1.day,    replied: false,
        body: "Could you all pray for my mother? We are waiting on a diagnosis and the silence is loud. I don't need the answer to come quickly — I just need to remember God is in the waiting." },
      { kind: "partnership", name: "Marcus L.",  subject: "Lenten series collaboration",
        age: 2.days,   replied: true,  reply_age: 1.day,
        body: "Our small church in Greenwood would love to talk about partnering on a Lenten series. We have about sixty people who would read the devotional together on Wednesday nights." },
      { kind: "press",       name: "Renée Bowman", subject: "Quick question for a story",
        age: 3.days,   replied: false,
        body: "I'm writing a piece on small Christian publishers in the South. Would one of you have ten minutes for a phone call this week? Happy to send questions in advance." },
      { kind: "bug",         name: "Pastor T.",  subject: "Unsubscribe link broken on mobile",
        age: 6.hours,  replied: false,
        body: "A friend just told me she couldn't unsubscribe from her phone — the link in the footer of the email didn't load. I tried it from my Android and got a blank page. Wanted to flag." }
    ]

    created = 0
    feedback_seeds.take(TARGET_FEEDBACK).each_with_index do |spec, i|
      email = "writer#{i + 1}@example.com"
      next if FeedbackMessage.exists?(email: email, subject: spec[:subject])

      msg = FeedbackMessage.create!(
        name:    spec[:name],
        email:   email,
        subject: spec[:subject],
        body:    spec[:body],
        kind:    spec[:kind],
        replied: spec[:replied] || false,
        replied_at: (spec[:replied] ? (spec[:reply_age] || 1.day).ago : nil)
      )
      ts = spec[:age].ago
      FeedbackMessage.where(id: msg.id).update_all(created_at: ts, updated_at: ts)
      created += 1
    end
    puts "Seeded #{created} feedback messages — now #{FeedbackMessage.count} total."
  else
    puts "Feedback messages already populated (#{FeedbackMessage.count})."
  end

  # One past event so the past-list is populated.
  past_event = Event.find_or_initialize_by(title: "Lenten Retreat 2026")
  past_starts = 6.weeks.ago
  past_event.assign_attributes(
    description:
      "A two-day retreat in the pines — silence, scripture, and a few long conversations around a fire. " \
      "We left rested and we wrote about it for weeks afterward.",
    starts_at:        past_starts,
    ends_at:          past_starts + 36.hours,
    location:         "Tishomingo, MS",
    capacity:         40,
    cover_photo_slug: "path-pines",
    published:        true
  )
  if past_event.changed? || past_event.new_record?
    past_event.save!
    puts "Seeded past event: #{past_event.starts_at.strftime('%Y-%m-%d')} · #{past_event.title}"
  end

  # --- Testimonies (sample wall — 3 featured, 3 approved, 1 unapproved) ---
  TARGET_TESTIMONIES = 7
  if Testimony.count < TARGET_TESTIMONIES
    testimony_seeds = [
      { featured: true,  approved: true,  name: "Marcus L.",   location: "Jackson, MS",      age: 2.months,
        body: "I hadn't opened a Bible in nine years. The morning email didn't ask me to. It just showed up, gentle, like a friend who knew I'd be back. Three weeks in I started reading the actual passages. Six weeks in I was praying again. Nothing dramatic — just a slow, daily mercy I didn't know how to thank Him for." },
      { featured: true,  approved: true,  name: "Lena W.",     location: "Tupelo, MS",       age: 3.weeks,
        body: "The Habakkuk piece broke me wide open. We had been waiting on a diagnosis for almost a year. I read it on the porch at five-thirty and cried, then prayed, then drank cold coffee and got the kids to school. The answer didn't come that day. But something else did, and it has held me since." },
      { featured: true,  approved: true,  name: nil,           location: "Birmingham, AL",   age: 5.weeks,
        body: "I started reading anonymously. I am a pastor in a small town and I needed someone to feed me without knowing my name. IMPACT did that for almost two months before I told anyone. It is the kind of writing that does not flatter or scare. It just tells the truth." },
      { featured: false, approved: true,  name: "Daniel R.",   location: "Hattiesburg, MS",  age: 6.weeks,
        body: "My wife signed me up without asking. I was annoyed for about a day. Now I read it before I check the news. That switch alone has changed the shape of my mornings. Thank you for keeping it short and serious." },
      { featured: false, approved: true,  name: "Esther B.",   location: "Atlanta, GA",      age: 9.weeks,
        body: "I came out of a hard church season last fall. I was not sure I wanted devotionals from anyone. But your voice never tried to sell me anything. It just reminded me, quietly, that the Bible is still good and so is God. I am slowly believing both things again." },
      { featured: false, approved: true,  name: nil,           location: "Mobile, AL",       age: 4.months,
        body: "I print the Sunday devotional and read it to my grandmother at the nursing home. She does not say much these days but she always squeezes my hand at the scripture. Thank you for writing something an eighty-nine-year-old can still receive." },
      # Awaiting moderation — seeds the admin queue.
      { featured: false, approved: false, name: "Pastor T.",   location: "Greenwood, MS",   age: 6.hours,
        body: "Just wanted to write and say thank you. Our small church has been using your devotionals in our prayer meetings on Wednesday nights. Several folks have started showing up earlier just to read it together before we begin." }
    ]

    created = 0
    testimony_seeds.take(TARGET_TESTIMONIES).each do |spec|
      t = Testimony.new(
        name:     spec[:name],
        location: spec[:location],
        body:     spec[:body],
        featured: spec[:featured],
        approved: spec[:approved]
      )
      t.submitted_at = spec[:age].ago
      t.approved_at  = spec[:age].ago + 1.day if spec[:approved]
      t.save!
      # Backdate created_at so the wall looks aged-in.
      ts = spec[:age].ago
      Testimony.where(id: t.id).update_all(created_at: ts, updated_at: ts)
      created += 1
    end
    puts "Seeded #{created} testimonies — now #{Testimony.count} total."
  else
    puts "Testimonies already populated (#{Testimony.count})."
  end

  # --- Resource library (sample shelves) -------------------------------
  # Six resources across categories — a mix of email-gated and open downloads.
  # Files are NOT attached in seeds (ActiveStorage in seeds is flaky); the team
  # uploads the real PDF/MP3 via /admin/resources after seeding.
  resource_seeds = [
    {
      title: "30 Days of Habakkuk — a printable devotional companion",
      category: "devotional_collection",
      featured: true,
      requires_email: true,
      cover: "open-bible",
      description:
        "Thirty short readings drawn from the book of Habakkuk — one for each morning of the month, paired with the scripture, a paragraph of commentary, and a single prayer.\n\nPrint it, bind it with two staples, leave it next to the coffee maker. By the end of the month you will have read the whole book, slowly, and you will know why it has held the church for two thousand years."
    },
    {
      title: "Reading the Psalms slowly — a 4-week guide",
      category: "study",
      featured: true,
      requires_email: true,
      cover: "morning-desk",
      description:
        "A four-week reading plan that moves through the Psalms at the pace they were meant to be read — one or two per morning, with notes on form, history, and how to pray each one back.\n\nDesigned for individuals or small groups. Includes a single-page introduction, four weekly check-ins, and a final reflection."
    },
    {
      title: "Three sermons on waiting",
      category: "sermon",
      featured: false,
      requires_email: false,
      cover: "doorway-light",
      description:
        "A short trilogy preached at a small Mississippi church in the long winter of 2025 — Habakkuk, Lamentations, and the closing chapters of Revelation. Audio plus transcript.\n\nFree to use in your own congregation. We only ask that you credit the preacher and don't sell it."
    },
    {
      title: "A small group curriculum on James",
      category: "curriculum",
      featured: false,
      requires_email: true,
      cover: "handshake",
      description:
        "Eight sessions on the book of James, written for living-room small groups. Each session: a passage, two paragraphs of orientation, four discussion questions, and a closing practice.\n\nField-tested across a handful of churches across the South. Leader notes included."
    },
    {
      title: "Notes on praying when you don't feel it",
      category: "guide",
      featured: true,
      requires_email: true,
      cover: "praying-hands",
      description:
        "A short, honest guide to keeping the daily office when the well runs dry — written for the season every believer eventually meets and rarely talks about.\n\nFive practices, four prayers, and one paragraph of encouragement from a Catholic monk turned street pastor. Read in twenty minutes; useful for years."
    },
    {
      title: "The Mississippi morning playlist",
      category: "media",
      featured: false,
      requires_email: false,
      cover: "delta-sunrise",
      description:
        "A two-hour playlist of music to read scripture by — hymns, instrumentals, and a few old recordings we couldn't bear to leave off. Curated by the IMPACT editorial team for the long mornings on the porch.\n\nStream from any service. The links are inside."
    }
  ]

  resource_seeds.each do |spec|
    resource = Resource.find_or_initialize_by(title: spec[:title])
    resource.assign_attributes(
      description:      spec[:description],
      category:         spec[:category],
      featured:         spec[:featured],
      requires_email:   spec[:requires_email],
      cover_photo_slug: spec[:cover]
    )
    # Only set published_at on first seed so subsequent re-seeds don't churn.
    resource.published_at ||= rand(2..40).days.ago

    if resource.new_record?
      resource.downloads_count = rand(5..400)
      resource.save!
      puts "Seeded resource: #{resource.category_label} · #{resource.title} (#{resource.downloads_count} downloads)"
    elsif resource.changed?
      resource.save!
      puts "Updated resource: #{resource.title}"
    else
      puts "Resource already present: #{resource.title}"
    end
  end

  # -----------------------------------------------------------
  # Demo subscriber + saved highlights so /account looks alive.
  # Sign in:  subscriber@impactministry.local  /  read-along
  # -----------------------------------------------------------
  demo_email = "subscriber@impactministry.local"
  demo = User.find_or_initialize_by(email_address: demo_email)
  if demo.new_record?
    demo.password       = "read-along"
    demo.name           = "Demo Subscriber"
    demo.role           = "subscriber"
    demo.confirmed_at   = Time.current
    demo.current_streak = 7
    demo.longest_streak = 12
    demo.last_read_on   = Date.current
    demo.save!
    puts "Seeded demo subscriber: #{demo.email_address} (password: read-along)"
  else
    changed = false
    if demo.current_streak.to_i < 1
      demo.current_streak = 7
      demo.longest_streak = [ demo.longest_streak.to_i, 12 ].max
      changed = true
    end
    if demo.last_read_on.nil? || demo.last_read_on < Date.current - 2.days
      demo.last_read_on = Date.current
      changed = true
    end
    demo.save! if changed
    puts "Demo subscriber already present: #{demo.email_address}"
  end

  highlight_snippets = [
    "Waiting is not the absence of God's word.",
    "There is a kind of quiet you cannot manufacture.",
    "Faith is rarely a single decision.",
    "Today, your job is small. Stand the watch."
  ]
  Devotional.published.recent_first.limit(4).to_a.each_with_index do |devo, i|
    next if demo.devotional_highlights.exists?(devotional_id: devo.id)
    text = highlight_snippets[i] || "A line worth saving."
    demo.devotional_highlights.create!(
      devotional: devo,
      text_range: { start: 40, end: 40 + text.length, text: text }.to_json,
      saved_at:   (i + 1).hours.ago
    )
  end
  puts "Demo highlights present: #{demo.devotional_highlights.count}"

  # --- Partnerships (sample inbox across types + statuses) ---------------
  # Five intakes so /admin/partnerships looks alive in development.
  TARGET_PARTNERSHIPS = 5
  if Partnership.count < TARGET_PARTNERSHIPS
    partnership_seeds = [
      {
        organization_type: "church",
        organization_name: "Cedar Grove Baptist",
        contact_name:      Faker::Name.name,
        interests:         %w[devotionals content],
        status:            "new",
        age:               3.hours,
        message:           "We'd love to co-publish a four-week Advent series for our Wednesday gatherings. " \
                           "About sixty people read together; we'd provide the printable, you'd provide the words."
      },
      {
        organization_type: "nonprofit",
        organization_name: "Delta Hope Collective",
        contact_name:      Faker::Name.name,
        interests:         %w[grants volunteers],
        status:            "in_review",
        age:               1.day,
        message:           "Exploring a small operational grant for our after-school literacy program in Greenville. " \
                           "Happy to share our 990 and a one-page program summary if there's interest."
      },
      {
        organization_type: "school",
        organization_name: "Greenwood Christian Academy",
        contact_name:      Faker::Name.name,
        interests:         %w[content],
        status:            "engaged",
        age:               4.days,
        message:           "Our chaplain has been using your devotionals in our middle-school chapel. " \
                           "Could we talk about a custom series shaped for adolescents? Eight to ten readings would be plenty."
      },
      {
        organization_type: "business",
        organization_name: "Threshold Coffee Roasters",
        contact_name:      Faker::Name.name,
        interests:         %w[podcast],
        status:            "new",
        age:               6.hours,
        message:           "Family-owned roastery in Hattiesburg. We'd like to underwrite a season of the podcast " \
                           "and send beans to anyone who subscribes during the run. Tell us what you'd need from us."
      },
      {
        organization_type: "other",
        organization_name: "First Light Editorial",
        contact_name:      Faker::Name.name,
        interests:         %w[content other],
        status:            "declined",
        age:               2.weeks,
        message:           "Pitching a guest essay swap with our small Christian publication. Open to any cadence. " \
                           "We can share readership numbers privately if helpful."
      }
    ]

    created = 0
    partnership_seeds.each_with_index do |spec, i|
      email = "partner#{i + 1}@example.com"
      next if Partnership.exists?(contact_email: email)

      p = Partnership.create!(
        organization_name: spec[:organization_name],
        organization_type: spec[:organization_type],
        contact_name:      spec[:contact_name],
        contact_email:     email,
        contact_phone:     ([ nil, "601-555-0#{100 + i}" ].sample),
        interest_areas:    spec[:interests],
        message:           spec[:message],
        status:            spec[:status]
      )
      ts = spec[:age].ago
      Partnership.where(id: p.id).update_all(created_at: ts, updated_at: ts)
      created += 1
    end
    puts "Seeded #{created} partnerships — now #{Partnership.count} total."
  else
    puts "Partnerships already populated (#{Partnership.count})."
  end
end

# --- Demo donors + donations ------------------------------------------------
# Only seeded when GIVING_ENABLED=true so an empty /admin/donations stays
# accurate during the pre-501(c)(3) state. Uses fake stripe test ids — no
# Stripe API calls are made here. Idempotent on email.
if ActiveModel::Type::Boolean.new.cast(ENV.fetch("GIVING_ENABLED", false))
  puts "GIVING_ENABLED=true — seeding demo donors + donations"

  demo_donor_specs = [
    { name: "Mary Reeves",        email: "mary.demo@example.com",    designation: "general",   amount_cents: 5_000,  frequency: "once",    age: 2.days.ago  },
    { name: "James Carrington",   email: "james.demo@example.com",   designation: "youth",     amount_cents: 10_000, frequency: "monthly", age: 5.days.ago  },
    { name: "Dorothy Pace",       email: "dorothy.demo@example.com", designation: "missions",  amount_cents: 25_000, frequency: "once",    age: 9.days.ago  },
    { name: "Marcus Lewis",       email: "marcus.demo@example.com",  designation: "education", amount_cents: 2_500,  frequency: "monthly", age: 21.days.ago }
  ]

  created = 0
  demo_donor_specs.each_with_index do |spec, i|
    next if Donor.exists?(email: spec[:email])

    donor = Donor.create!(
      name: spec[:name],
      email: spec[:email],
      stripe_customer_id: "cus_test_seed_#{i}_#{SecureRandom.hex(3)}"
    )

    donation_attrs = {
      donor: donor,
      amount_cents: spec[:amount_cents],
      currency: "usd",
      frequency: spec[:frequency],
      designation: spec[:designation],
      stripe_checkout_session_id: "cs_test_seed_#{i}_#{SecureRandom.hex(3)}",
      stripe_payment_intent_id: "pi_test_seed_#{i}_#{SecureRandom.hex(3)}",
      status: "succeeded",
      donated_at: spec[:age],
      receipt_sent_at: spec[:age]
    }
    if spec[:frequency] == "monthly"
      donation_attrs[:stripe_subscription_id] = "sub_test_seed_#{i}_#{SecureRandom.hex(3)}"
    end

    Donation.create!(donation_attrs)
    created += 1
  end

  puts "Seeded #{created} donors with one donation each — now #{Donor.count} donors / #{Donation.count} donations."
end
