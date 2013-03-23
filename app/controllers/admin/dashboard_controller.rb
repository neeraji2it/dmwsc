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
    @payment = @customer.payments.find(session[:payment]) unless session[:payment].nil? rescue nil
    @payment = @customer.payments.find(session[:free_payment]) unless session[:free_payment].nil? rescue nil
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
      payment = Payment.new(:flavor => 1, :customer_id => session[:customer_id],:internal_user_id => 1, :amount => session[:hours].split('_')[1].to_i, :location_id => 1)
      if payment.save
        payment.update_column(:minutes, (session[:hours].split('_')[0].to_i*60))
        session[:hours], session[:payment_option] = nil, nil
        session[:payment] = payment.id
        redirect_to customer_dashboard_admin_dashboard_index_path
      else
        redirect_to :back
      end
    when "edit"
      redirect_to add_hours_admin_dashboard_index_path
    when "cancel"
      session[:hours], session[:payment_option] = nil, nil
      redirect_to add_hours_admin_dashboard_index_path
    end
  end

  def pos_conformation_step

  end

  def pos_conformation
    payment = Payment.find(session[:payment])
    customer = Customer.find(session[:customer_id])
    customer.add_remining_minutes(payment.minutes)
    payment.pos_status = params["confomation"]
    payment.staff_details = params["staf"]
    if payment.save
      session[:payment] = nil
    redirect_to customer_dashboard_admin_dashboard_index_path
    else
      redirect_to :back
    end
  end

  def add_free_hours

  end

  def add_free_hours_info
    @customer = Customer.find(session[:customer_id]) 
    session[:hours] = params["num_hours"]
    session[:description] = params["description"]
    session[:staff_details] = params["staff_details"]
  end

  def conform_free_hours
    case params["selected"]
    when "conform"
      payment = Payment.new(:flavor => 1, :customer_id => session[:customer_id], :description => session[:description],
                            :internal_user_id => 1, :amount => 0, :location_id => 1, :staff_details => session[:staff_details])
      if payment.save
        payment.update_column(:minutes, (session[:hours].to_i*60))
        session[:free_payment] = payment.id
        customer = Customer.find(session[:customer_id])
        customer.add_remining_minutes((session[:hours].to_i*60))
        session[:hours], session[:payment_option] = nil, nil
        redirect_to customer_dashboard_admin_dashboard_index_path
      else
        redirect_to :back
      end
    when "edit"
      redirect_to add_free_hours_admin_dashboard_index_path
    when "cancel"
      session[:hours], session[:description], session[:staff_details]  = nil, nil, nil
      redirect_to add_free_hours_admin_dashboard_index_path
    end
  end

  def payment_list
    customer = Customer.find(session[:customer_id])
    @availabule_minits = customer.time_sheet_entries.last.remining_minits
    @payments = customer.payments
  end

  def payment_refund
    
  end
end
