module PhotoHelper
  # Returns a CDN URL for stock photography used in placeholder/card surfaces.
  # In dev we use Unsplash's CDN with stable photo IDs hand-picked to match
  # the brief's photographic direction (cinematic, desaturated, warm).
  # Production will swap to ActiveStorage attachments managed via /admin.
  #
  #   photo_url("delta-sunrise", w: 800, h: 1000)
  PHOTO_IDS = {
    "delta-sunrise"   => "1469474968028-56623f02e42e", # broad landscape, warm horizon
    "open-bible"      => "1481627834876-b7833e8f5570", # open book on wood, candlelight
    "morning-desk"    => "1455390582262-044cdead277a", # journal + coffee, golden hour
    "microphone"      => "1485808191679-5f86510681a2", # podcast mic close-up, navy mood
    "portrait-man"    => "1507003211169-0a1dd7228f2d", # warm male portrait, profile
    "portrait-woman"  => "1494790108377-be9c29b29330", # warm female portrait
    "praying-hands"   => "1499728603263-13726abce5fd", # hands folded, intimate
    "path-pines"      => "1518837695005-2083093ee35b", # path through trees, Mississippi mood
    "doorway-light"   => "1507525428034-b723cf961d3e", # light through a doorway/window
    "handshake"       => "1521791136064-7986c2920216", # warm handshake/meeting
    "hands-open"      => "1488521787991-ed7bbaae773c"  # open hands ready to serve
  }.freeze

  def photo_url(slug, w: 1200, h: 800, fit: "crop")
    id = PHOTO_IDS[slug] || PHOTO_IDS["delta-sunrise"]
    "https://images.unsplash.com/photo-#{id}?w=#{w}&h=#{h}&fit=#{fit}&auto=format&q=72"
  end

  # Wraps photo_url with sensible card defaults + a CSS `background-image`.
  # Useful for filling decorative cards without an actual <img>.
  def photo_bg_style(slug, w:, h:)
    "background-image: url('#{photo_url(slug, w: w, h: h)}'); background-size: cover; background-position: center;"
  end
end
