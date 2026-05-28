require "rails_helper"

# Drag-select "Save highlight" wiring on the devotional show page
# (CLAUDE.md §5 — Highlight & save).
#
# We don't drive an actual text selection here: headless Chrome's selection
# API is flaky and the controller logic is exercised end-to-end by the
# request spec on POST /highlights. What we DO need to guarantee is that
# the view ships the Stimulus controller wiring whenever the reader is
# signed in — and ships nothing when they aren't.
#
# Driven with rack_test (no JS): all we inspect is the rendered HTML,
# specifically the data-* attributes on the devotional body container.
RSpec.describe "Devotional drag-select highlight wiring", type: :system do
  let(:author)     { create(:user, :admin) }
  let(:subscriber) { create(:user, :confirmed, password: "secret123") }
  let(:devotional) do
    create(:devotional, :published, :with_body,
           author: author,
           title: "A Quiet Word")
  end

  def sign_in_as(user)
    visit "/session/new"
    session_form = find_field("Password").ancestor("form")
    within(session_form) do
      fill_in "Email address", with: user.email_address
      fill_in "Password", with: "secret123"
      find("input[type=submit]").click
    end
  end

  it "wires the highlight Stimulus controller onto the body when signed in" do
    sign_in_as(subscriber)
    visit devotional_path(devotional.slug)

    body = find(".devotional-body", match: :first)
    expect(body["data-controller"]).to include("highlight")
    expect(body["data-highlight-target"]).to eq("body")
    expect(body["data-highlight-devotional-id-value"]).to eq(devotional.id.to_s)
  end

  it "omits the highlight wiring for anonymous readers" do
    visit devotional_path(devotional.slug)

    body = find(".devotional-body", match: :first)
    expect(body["data-controller"]).to be_nil
    expect(body["data-highlight-target"]).to be_nil
    expect(body["data-highlight-devotional-id-value"]).to be_nil
  end
end
