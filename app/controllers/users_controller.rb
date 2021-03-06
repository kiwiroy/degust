class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :correct_user?, :except => [:index]

  def index
    if current_user.admin?
      @users = User.all
    else
      redirect_to root_url, :alert => "Access denied."
    end
  end

  def show
    if params[:id] == 'me'
      @user = current_user
    else
      @user = User.find(params[:id])
    end
  end

  def reset_token
    @user.create_upload_token()
    @user.save!
    redirect_to user_path(@user)
  end

  def delete_token
    @user.delete_upload_token()
    @user.save!
    redirect_to user_path(@user)
  end

end
