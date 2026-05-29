# Renders a 1200x630 PNG from an SVG string suitable for Open Graph / Twitter
# Card use. Tries ruby-vips (which needs libvips42 apt-installed on the host)
# first; on production hosts where libvips is present we get the editorial
# card with the real Fraunces/Inter rasterized. When libvips is unavailable
# (local dev without the system lib) we return a valid solid-cream PNG so the
# endpoint always answers image/png — the OG tag never 500s.
#
# Why a hand-rolled PNG fallback: chunky_png/mini_magick aren't in the bundle
# and we don't want to add a gem just to cover the dev path. Pure-stdlib zlib
# is enough for a solid-color PNG.
class ShareCardRenderer
  PNG_SIGNATURE = [ 137, 80, 78, 71, 13, 10, 26, 10 ].pack("C*").freeze
  CREAM_RGB     = [ 0xFA, 0xF7, 0xF2 ].freeze

  def self.call(svg:, width: 1200, height: 630)
    new(svg: svg, width: width, height: height).call
  end

  def initialize(svg:, width:, height:)
    @svg, @width, @height = svg, width, height
  end

  def call
    render_with_vips
  rescue LoadError, StandardError => e
    Rails.logger.warn("[ShareCardRenderer] vips unavailable (#{e.class}: #{e.message}); falling back to solid cream PNG. Install libvips42 in production for the real card.")
    self.class.solid_png(@width, @height, *CREAM_RGB)
  end

  def self.solid_png(width, height, r, g, b)
    ihdr_data = [ width, height, 8, 2, 0, 0, 0 ].pack("N N C C C C C")
    scanline  = [ 0 ].pack("C") + ([ r, g, b ].pack("CCC") * width)
    raw       = scanline * height
    idat_data = Zlib::Deflate.deflate(raw)

    PNG_SIGNATURE +
      chunk("IHDR", ihdr_data) +
      chunk("IDAT", idat_data) +
      chunk("IEND", "")
  end

  def self.chunk(type, data)
    type_bytes = type.b
    payload    = type_bytes + data.b
    [ data.bytesize ].pack("N") + payload + [ Zlib.crc32(payload) ].pack("N")
  end

  private

  def render_with_vips
    require "vips"
    Vips::Image.svgload_buffer(@svg.b, dpi: 144).write_to_buffer(".png")
  end
end
