class SessionsController < ApplicationController

  def create
    customer = Customer.from_omniauth(env["omniauth.auth"])
    session[:customer_id] = customer.id
    redirect_to :controller => :content, :action => :index
  end

  def destroy
    reset_session
  end

end
