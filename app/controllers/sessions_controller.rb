class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:create_ldap]

  def new
    redirect_to '/auth/twitter'
  end

  def create
    auth = request.env["omniauth.auth"]
    user = User.where(:provider => auth['provider'],
                      :uid => auth['uid'].to_s).first || User.create_with_omniauth(auth)
    user.fill_missing_omniauth(auth)
    reset_session
    session[:user_id] = user.id

    page = request.env['omniauth.origin'] || root_url
    redirect_to page, :notice => 'Signed in!'
  end

  def create_ldap
    create
  end

  def destroy
    reset_session
    redirect_to :back, :notice => 'Signed out!'
  end

  def failure
    redirect_to root_url, :alert => "Authentication error: #{params[:message].humanize}"
  end

end
