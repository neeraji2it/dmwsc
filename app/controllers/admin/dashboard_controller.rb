class Admin::DashboardController < ApplicationController
  protect_from_forgery
  layout 'admin'

  # NJS - make sure user is logged in as an internal_user

  def index
    
  end

  def fetch_users
    @customers=Customer.where("LOWER(first_name) LIKE ? or LOWER(last_name) LIKE ?", "%#{params[:staf_user].downcase}%", "%#{params[:staf_user].downcase}%").limit(5).order(:first_name)
         
      respond_to do |format|
        format.js {}
      end
  end

  def customer_dashboard
    session[:customer_id] = params[:id]
    @customer = Customer.find(session[:customer_id])
    @time_sheets = @customer.time_sheet_entries.except(:order).order('start_time desc')
  end

end
