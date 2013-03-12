class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :require_http_basic_auth 

  def require_http_basic_auth
    authenticate_or_request_with_http_basic do |login, password|
      login == "wc2013" && password=="wc2013"
    end
  end

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
