# Site-wide search across devotionals, podcast episodes, resources, and stories.
#
# Two endpoints:
# - GET /search/overlay  — bare overlay shell (input + empty frame). The Stimulus
#                          controller pulls this once on first open if it wants to
#                          render server-side; for now we keep markup in the nav
#                          partial so this is mostly a no-JS fallback entry point.
# - GET /search          — runs the query and renders `_results.html.erb`. Used
#                          both as a Turbo Frame target and a no-JS full page.
#
# pg_search note: Devotional / PodcastEpisode / Resource each declare their own
# `search_text` scope (tsearch + trigram). Testimony does not — we fall back to
# ILIKE on `body` and `location` so the wall is still searchable.
class SearchController < ApplicationController
  # Empty overlay shell. Renders just the input + an empty results region so a
  # no-JS visitor landing on /search/overlay still sees a working search box.
  def overlay
    @query = ""
    @devotionals = []
    @podcasts    = []
    @resources   = []
    @testimonies = []
    render :overlay, layout: false
  end

  # Search across all four surfaces. Blank query returns curated suggestions so
  # the overlay never looks empty on first open.
  def index
    @query = params[:q].to_s.strip

    if @query.blank?
      load_suggestions
    else
      load_results(@query)
    end

    respond_to do |format|
      format.html { render :index }
    end
  end

  private

  def load_suggestions
    @devotionals = Devotional.published.recent_first.limit(4)
    @podcasts    = PodcastEpisode.published.recent_first.limit(3)
    @resources   = Resource.published.recent_first.limit(3)
    @testimonies = Testimony.approved.recent_first.limit(2)
  end

  def load_results(query)
    @devotionals = Devotional.published.search_text(query).limit(6)
    @podcasts    = PodcastEpisode.published.search_text(query).limit(4)
    @resources   = Resource.published.search_text(query).limit(4)
    # Testimony has no pg_search_scope — ILIKE on body + location is good enough
    # for the small wall and avoids touching the model.
    pattern = "%#{Testimony.sanitize_sql_like(query)}%"
    @testimonies = Testimony.approved
                            .where("body ILIKE :q OR location ILIKE :q OR name ILIKE :q", q: pattern)
                            .recent_first
                            .limit(3)
  end
end
