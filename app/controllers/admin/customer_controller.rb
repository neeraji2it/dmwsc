class Admin::CustomerController < ApplicationController
  protect_from_forgery
  layout 'admin'

  def index
    find_customer
    @all_customers = Customer.find(:all)
  end

  def login_as
    session[:customer_id] = params[:id]
    find_customer
  end

end
