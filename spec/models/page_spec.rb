require "rails_helper"

RSpec.describe Page, type: :model do
  describe "validations" do
    subject { build(:page) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_uniqueness_of(:slug).case_insensitive }
  end

  describe "friendly_id slug generation" do
    it "auto-generates a slug from the title on create" do
      page = create(:page, title: "About IMPACT Ministry")
      expect(page.slug).to eq("about-impact-ministry")
    end

    it "regenerates the slug when the title changes" do
      page = create(:page, title: "First title")
      original_slug = page.slug

      page.update!(title: "Second title")
      expect(page.slug).not_to eq(original_slug)
      expect(page.slug).to eq("second-title")
    end

    it "does not regenerate the slug when other attributes change" do
      page = create(:page, title: "Stable title")
      original_slug = page.slug

      page.update!(published: false)
      expect(page.slug).to eq(original_slug)
    end

    it "uses the slug as the to_param value (URL identifier)" do
      page = create(:page, title: "Statement of faith")
      expect(page.to_param).to eq(page.slug)
    end
  end

  describe ".published scope" do
    it "returns only published pages" do
      published   = create(:page, title: "Visible")
      unpublished = create(:page, :unpublished, title: "Hidden")

      expect(Page.published).to include(published)
      expect(Page.published).not_to include(unpublished)
    end
  end

  describe "ActionText body" do
    it "stores rich text content" do
      page = create(:page, title: "With body")
      page.body = "<p>Hello, <strong>world</strong>.</p>"
      page.save!

      expect(page.reload.body.to_plain_text).to include("Hello, world.")
    end

    it "allows blank body" do
      page = build(:page, title: "Empty")
      page.body = ""
      expect(page).to be_valid
    end
  end

  describe "seo_meta jsonb" do
    it "defaults to an empty hash at the DB level" do
      page = Page.create!(title: "Bare", body: "<p>hi</p>")
      expect(page.reload.seo_meta).to eq({})
    end

    it "round-trips arbitrary keys" do
      page = create(:page, seo_meta: { "description" => "x", "og_image_url" => "y" })
      expect(page.reload.seo_meta).to eq({ "description" => "x", "og_image_url" => "y" })
    end
  end
end
