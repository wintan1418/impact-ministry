class HighlightsController < ApplicationController
  before_action :require_authentication

  def create
    @devotional = Devotional.published.find(params[:devotional_id])
    @highlight  = current_user.devotional_highlights.build(
      devotional: @devotional,
      text_range: params[:text_range].to_s
    )

    if @highlight.save
      respond_to do |format|
        format.turbo_stream
        format.json { render json: { ok: true, id: @highlight.id } }
        format.html { redirect_to devotional_path(@devotional.slug), notice: "Saved." }
      end
    else
      respond_to do |format|
        format.json { render json: { ok: false, errors: @highlight.errors.full_messages }, status: :unprocessable_entity }
        format.any  { redirect_to devotional_path(@devotional.slug), alert: @highlight.errors.full_messages.to_sentence }
      end
    end
  end

  def destroy
    @highlight = current_user.devotional_highlights.find(params[:id])
    @highlight.destroy

    respond_to do |format|
      format.turbo_stream
      format.json { head :no_content }
      format.html { redirect_to account_highlights_path, notice: "Removed." }
    end
  end
end
