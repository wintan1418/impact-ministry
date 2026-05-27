require "rails_helper"

# End-to-end happy paths for IMPACT Ministry — Phase 1.G.
#
# These exercise the actual middleware stack via rack_test (no JS), so a
# regression in routing, Turbo Stream rendering, or the Authentication
# concern will fail loudly here before it ever ships.

RSpec.describe "Happy paths", type: :system do
  let(:author) { create(:user, :admin) }

  describe "first-time visitor signs up via the homepage" do
    it "captures the email and enqueues the welcome" do
      # Today's devotional makes the hero feel alive — but the homepage
      # must also render gracefully without one.
      create(:devotional, :published, :with_body,
             author: author,
             scheduled_for: Date.current,
             title: "When the Vision Tarries",
             scripture_reference: "Habakkuk 2:1–4",
             excerpt: "Waiting is not the absence of God's word.")

      visit "/"

      expect(page).to have_content("Start your day")
      expect(page).to have_content("When the Vision Tarries")
      expect(page).to have_content("Habakkuk 2:1–4")

      # The inline capture sits in the middle of the page with source=inline.
      within("turbo-frame#email-capture-inline") do
        fill_in "Email address", with: "wanderer@example.com"
        find("button[type=submit]").click
      end

      subscriber = EmailSubscriber.find_by(email: "wanderer@example.com")
      expect(subscriber).to be_present
      expect(subscriber.source).to eq("inline")
      expect(subscriber).to be_active

      # Welcome email is enqueued, not delivered inline.
      expect(WelcomeEmailJob).to have_been_enqueued.with(subscriber.id)
    end
  end

  describe "visitor reads today's devotional" do
    it "redirects /devotionals/today to the published devotional and renders the body" do
      d = create(:devotional, :published, :with_body,
                 author: author,
                 scheduled_for: Date.current,
                 title: "A Quiet Word")

      visit "/devotionals/today"

      expect(page).to have_current_path("/devotionals/#{d.slug}")
      expect(page).to have_content("A Quiet Word")
    end

    it "renders a graceful fallback when nothing is scheduled" do
      visit "/devotionals/today"
      expect(page.status_code).to eq(200)
      expect(page).to have_content(/Tomorrow|sunrise/i)
    end
  end

  describe "visitor opens a static page" do
    it "renders /about with editorial layout" do
      # Page seeds normally provide this, but we don't rely on db:seed in tests.
      Page.find_or_create_by!(slug: "about") do |p|
        p.title = "About IMPACT Ministry"
        p.published = true
      end

      visit "/about"
      expect(page.status_code).to eq(200)
      expect(page).to have_content(/IMPACT|Mississippi/i)
    end
  end

  describe "subscriber unsubscribes via token link" do
    it "marks them unsubscribed and shows a quiet acknowledgement" do
      subscriber = create(:email_subscriber, email: "leaver@example.com")

      visit "/unsubscribe/#{subscriber.token}"
      expect(page).to have_content(subscriber.email)
      click_button("Yes, unsubscribe me")

      expect(subscriber.reload).not_to be_active
      expect(page).to have_content(/won['']t hear|see you/i)
    end
  end

  describe "staff signs into /admin" do
    let(:editor) { create(:user, :editor, :confirmed, password: "secret123") }

    it "lets editors into the admin dashboard" do
      visit "/session/new"

      # Sign-in form has both labelled email + password fields; the footer
      # email-capture has only email. Find the form via the password field.
      session_form = find_field("Password").ancestor("form")
      within(session_form) do
        fill_in "Email address", with: editor.email_address
        fill_in "Password", with: "secret123"
        find("input[type=submit]").click
      end

      visit "/admin"
      expect(page.status_code).to eq(200)
      expect(page).to have_content(/IMPACT Ministry|Dashboard/i)
    end

    it "redirects visitors away from /admin to /session/new" do
      visit "/admin"
      expect(page).to have_current_path("/session/new")
    end
  end
end
