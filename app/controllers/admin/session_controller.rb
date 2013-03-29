class Admin::SessionController < ApplicationController
  protect_from_forgery
  layout 'admin'
  before_filter :check_for_staff, :only => :destroy
  # NJS - make sure user is logged in as an internal_user

  def new
    redirect_to admin_dashboard_index_path unless session[:user_id].nil?
  end

  def create
  unless params[:email].blank?
    user = Admin.where(:email => params[:email]).first
    if user and user.password_is?(params[:password])
      session[:user_id] = user.id
      redirect_to admin_dashboard_index_path
    else
      flash[:alert] = "Email or password are invalid."
      render :new
    end
  end
  end

  def destroy
    session[:user_id] = nil
    redirect_to new_admin_session_path
  end

end
