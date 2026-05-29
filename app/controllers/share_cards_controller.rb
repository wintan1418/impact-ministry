# Server-rendered Open Graph / Twitter Card images for shareable content.
# Public endpoint (no auth) — scrapers and social previews hit this directly.
# Cached aggressively per CLAUDE.md §5: key includes the record's updated_at
# so editor changes bust the cache for free.
class ShareCardsController < ApplicationController
  allow_unauthenticated_access if respond_to?(:allow_unauthenticated_access)
  skip_before_action :verify_authenticity_token, raise: false

  def devotional
    @devotional = Devotional.friendly.find(params[:slug])
    raise ActiveRecord::RecordNotFound unless @devotional.published?

    binary = Rails.cache.fetch(cache_key(@devotional), expires_in: 7.days) do
      svg = render_to_string(
        template: "share_cards/devotional",
        layout: false,
        formats: [ :html ],
        locals: { devotional: @devotional }
      )
      ShareCardRenderer.call(svg: svg)
    end

    expires_in 1.day, public: true
    send_data binary, type: "image/png", disposition: "inline", filename: "devotional-#{@devotional.slug}.png"
  end

  private

  def cache_key(devotional)
    "share_card/devotional/#{devotional.id}/#{devotional.updated_at.to_i}"
  end
end
