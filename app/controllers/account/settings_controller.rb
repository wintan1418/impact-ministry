class Account::SettingsController < Account::BaseController
  def show
  end

  def update
    if current_user.update(settings_params)
      redirect_to account_settings_path, notice: "Saved."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    params.require(:user).permit(:name)
  end
end
