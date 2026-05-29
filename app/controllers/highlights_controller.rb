class HighlightsController < ApplicationController
  before_action :require_authentication

  def create
    @devotional = Devotional.published.find(params[:devotional_id])
    @highlight  = current_user.devotional_highlights.build(
      devotional: @devotional,
      text_range: params[:text_range].to_s
    )
    authorize @highlight, :create?

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
    # Scoping through current_user keeps the existing 404 contract for foreign
    # ids; the `authorize` call is belt-and-suspenders so a future refactor
    # (e.g. broadening the scope) can't accidentally remove the ownership check.
    @highlight = current_user.devotional_highlights.find(params[:id])
    authorize @highlight, :destroy?
    @highlight.destroy

    respond_to do |format|
      format.turbo_stream
      format.json { head :no_content }
      format.html { redirect_to account_highlights_path, notice: "Removed." }
    end
  end
end
