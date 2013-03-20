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
    session[:customer_id] = params[:id] unless params[:id].nil?
    @customer = Customer.find(session[:customer_id])
    @time_sheets = @customer.time_sheet_entries.except(:order).order('start_time desc')
  end

  def add_hours
    @customer = Customer.find(session[:customer_id]) 
  end

  def add_hours_info
    session[:hours] = params["hours_amount"]
    session[:payment_option] = params["payment_option"]
    
  end

  def conform_purchase
    case params["selected"]
    when "conform"
      payment = Payment.new(:flavor => 1, :customer_id => session[:customer_id],:internal_user_id => 1, :amount => session[:hours].split('_')[1].to_i, :minutes => session[:hours].split('_')[0].to_i, :location_id => 1)
      if payment.save
        redirect_to customer_dashboard_admin_dashboard_index_path
      else
        p payment.errors
        redirect_to :back
      end
    when "edit"
      redirect_to add_hours_admin_dashboard_index_path
    when "cancel"
      session[:hours], session[:payment_option] = nil, nil
      redirect_to add_hours_admin_dashboard_index_path
    end
  end
end
