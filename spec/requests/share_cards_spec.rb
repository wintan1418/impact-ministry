require "rails_helper"

RSpec.describe "Share cards", type: :request do
  describe "GET /devotionals/:slug/share_card.png" do
    before do
      allow(Rails.cache).to receive(:fetch).and_yield
      allow(ShareCardRenderer).to receive(:call).and_return("\x89PNG\r\n\x1a\n" + "stub")
    end

    it "returns a PNG for a published devotional" do
      d = create(:devotional, :published, :with_body, title: "When the Vision Tarries")
      get devotional_share_card_path(d.slug)
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to start_with("image/png")
      expect(ShareCardRenderer).to have_received(:call).with(svg: a_string_including("IMPACT"))
    end

    it "404s when the devotional is unpublished" do
      d = create(:devotional, :for_today)
      get devotional_share_card_path(d.slug)
      expect(response).to have_http_status(:not_found)
    end

    it "caches by id + updated_at" do
      d = create(:devotional, :published, :with_body)
      expect(Rails.cache).to receive(:fetch).with(
        "share_card/devotional/#{d.id}/#{d.updated_at.to_i}",
        hash_including(expires_in: 7.days)
      ).and_yield
      get devotional_share_card_path(d.slug)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "OG meta on devotional show" do
    it "exposes the share card URL via og:image" do
      d = create(:devotional, :published, :with_body, title: "Quiet Word")
      get devotional_path(d)
      expect(response.body).to include('property="og:image"')
      expect(response.body).to include("/devotionals/#{d.slug}/share_card.png")
      expect(response.body).to include('name="twitter:card"')
    end
  end
end

RSpec.describe ShareCardRenderer do
  describe ".solid_png" do
    it "produces a syntactically valid PNG header" do
      png = described_class.solid_png(10, 10, 0xFA, 0xF7, 0xF2)
      expect(png[0, 8].bytes).to eq([ 137, 80, 78, 71, 13, 10, 26, 10 ])
      expect(png).to include("IHDR")
      expect(png).to include("IDAT")
      expect(png).to include("IEND")
    end
  end

  describe ".call fallback" do
    it "returns the solid PNG when libvips is not available" do
      allow_any_instance_of(described_class).to receive(:require).with("vips").and_raise(LoadError)
      result = described_class.call(svg: "<svg/>", width: 10, height: 10)
      expect(result[0, 8].bytes).to eq([ 137, 80, 78, 71, 13, 10, 26, 10 ])
    end
  end
end
