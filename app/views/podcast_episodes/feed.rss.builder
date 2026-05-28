xml.instruct!
xml.rss(
  version: "2.0",
  "xmlns:itunes" => "http://www.itunes.com/dtds/podcast-1.0.dtd",
  "xmlns:content" => "http://purl.org/rss/1.0/modules/content/"
) do
  xml.channel do
    xml.title       "IMPACT Ministry"
    xml.link        "#{@protocol}://#{@host}/podcast"
    xml.language    "en-us"
    xml.description "Conversations on faith, work, and waiting. A slow podcast from a small Mississippi ministry."
    xml.copyright   "© #{Date.current.year} IMPACT Ministry, Inc."

    xml.itunes :author,  "IMPACT Ministry"
    xml.itunes :summary, "Conversations on faith, work, and waiting."
    xml.itunes :owner do
      xml.itunes :name,  "IMPACT Ministry"
      xml.itunes :email, ENV.fetch("ADMIN_NOTIFICATION_EMAIL", "team@impactministry.org")
    end
    xml.itunes :explicit, "false"
    xml.itunes :category, text: "Religion & Spirituality" do
      xml.itunes :category, text: "Christianity"
    end
    xml.itunes :image, href: "#{@protocol}://#{@host}#{ActionController::Base.helpers.image_path('/icon.svg')}"

    @episodes.each do |ep|
      xml.item do
        xml.title ep.title
        xml.link  "#{@protocol}://#{@host}/podcast/#{ep.slug}"
        xml.guid  "#{@protocol}://#{@host}/podcast/#{ep.slug}", isPermaLink: "true"
        xml.pubDate((ep.published_at || ep.scheduled_for.to_time).rfc822)
        xml.description ep.description.to_s

        xml.content :encoded do
          notes = ep.description.to_s.dup
          if ep.guest_names.present? && ep.guest_names.any?
            notes << "<p><strong>Guests:</strong> #{ep.guest_names.to_sentence}</p>"
          end
          xml.cdata!(notes)
        end

        if ep.audio_url.present?
          xml.enclosure url: ep.audio_url, type: "audio/mpeg", length: "0"
        end

        if ep.duration_seconds.to_i.positive?
          secs = ep.duration_seconds.to_i
          xml.itunes :duration, format("%02d:%02d:%02d", secs / 3600, (secs / 60) % 60, secs % 60)
        end

        xml.itunes :season,   ep.season
        xml.itunes :episode,  ep.episode_number
        xml.itunes :explicit, "false"

        if ep.cover_photo_slug.present?
          cover_id = PhotoHelper::PHOTO_IDS[ep.cover_photo_slug]
          if cover_id
            xml.itunes :image, href: "https://images.unsplash.com/photo-#{cover_id}?w=1400&h=1400&fit=crop&auto=format&q=72"
          end
        end
      end
    end
  end
end
