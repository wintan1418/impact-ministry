class UsersController < ApplicationController
  # Public sign-up flow. Rails 8's `bin/rails generate authentication`
  # ships sessions + passwords but not registration — this is ours.

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.role         = "subscriber"
    @user.confirmed_at = Time.current

    if @user.save
      start_new_session_for @user
      redirect_to account_path, notice: "Welcome to IMPACT."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :name)
  end
end
