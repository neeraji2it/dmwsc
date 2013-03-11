class ApplicationController < ActionController::Base
  protect_from_forgery

  private
  def find_customer
    @customer ||= Customer.find(session[:customer_id]) if session[:customer_id]
  end
  helper_method :find_customer

  def login_required
    find_customer
    if !@customer
      redirect_to '/auth/facebook'
    end
  end
  helper_method :login_required
end
