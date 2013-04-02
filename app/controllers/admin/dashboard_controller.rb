class Admin::DashboardController < ApplicationController
  protect_from_forgery
  layout 'admin'
  before_filter :check_for_staff
  before_filter :find_customer, :except => [:customer_dashboard]
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
    find_customer
    @payment = @customer.payments.find(session[:payment]) unless session[:payment].nil? rescue nil
    @payment = @customer.payments.find(session[:free_payment]) unless session[:free_payment].nil? rescue nil
    @payment = @customer.payments.find(session[:refund_payment_id]) unless session[:refund_payment_id].nil? rescue nil
    @time_sheets = @customer.time_sheet_entries.except(:order).order('start_time desc')
  end

  def add_hours
    find_customer 
  end

  def add_hours_info
    session[:hours] = params["hours_amount"]
    session[:payment_option] = params["payment_option"]
    
  end

  def confirm_purchase
    case params["selected"]
    when "confirm"
      payment = Payment.new(:payment_type =>session[:payment_option], :flavor => 1, :customer_id => session[:customer_id],:internal_user_id => 1, :amount => session[:hours].split('_')[1].to_i, :location_id => 1)
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

  def pos_confirmation_step

  end

  def pos_confirmation
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
    find_customer
    session[:hours] = params["num_hours"]
    session[:description] = params["description"]
    session[:staff_details] = params["staff_details"]
  end

  def confirm_free_hours
    case params["selected"]
    when "confirm"
      payment = Payment.new(:payment_type => 2, :flavor => 1, :customer_id => session[:customer_id], :description => session[:description],
                            :internal_user_id => session[:user_id], :amount => 0, :location_id => 1, :staff_details => session[:staff_details])
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
    @availabule_minits = customer.time_sheet_entries.last.remining_minits rescue 0
    @payments = customer.payments
  end

  def payment_refund
    customer = Customer.find(session[:customer_id])
    session[:refund_payment] = params["payment"].split('_') unless params["payment"].nil?
    if session[:refund_payment][1] == 'free'
    flash[:alert] = "Can't refund free minutes"
    redirect_to :back
    elsif session[:refund_payment][1] == 'used'
    flash[:alert] = "Can't refund Already used minutes"
    redirect_to :back
    elsif session[:refund_payment][1] == 'refunded'
    flash[:alert] = "Can't refund Already refunded minutes"
    redirect_to :back
    else
      if session[:refund_payment][1].to_i < customer.refundable_minits
        @refund_payment = customer.payments.where(:id => session[:refund_payment][0].to_i).first
        if @refund_payment.nil?
          flash[:alert] = "You dont have this in your payment history."
          redirect_to :back
        else
          session[:refund_payment_id] = @refund_payment.id
        end
      else
        flash[:alert] = "You dont have sufficient payment history."
        redirect_to :back
      end
    end
  end

  def confirm_refund
    case params["selected"]
    when "confirm"
      payment = Payment.find(session[:refund_payment_id])
      payment.flavor = Payment::FLAVORS[:cc_refund]
      payment.pos_status = nil
      payment.save
      customer = Customer.find(session[:customer_id])
      customer.add_remining_minutes((-session[:refund_payment][1].to_i))
      redirect_to customer_dashboard_admin_dashboard_index_path
    when "edit"
      redirect_to payment_list_admin_dashboard_index_path
    when "cancel"
      session[:refund_payment], session[:refund_payment_id] = nil, nil
      redirect_to customer_dashboard_admin_dashboard_index_path
    end
  end

  def refund_confirmation_info
    @payment = Payment.find(session[:refund_payment_id])
  end

  def refund_confirmation_final
    payment = Payment.find(session[:refund_payment_id])
    payment.pos_status = params["confomation"]
    payment.description = params["description"]
    payment.staff_details = params["staff_details"]
    if payment.save
      session[:refund_payment] = nil
    redirect_to customer_dashboard_admin_dashboard_index_path
    else
      redirect_to :back
    end
  end

  def transaction_details
    @payment = Payment.where(:id => params[:id]).first
  end

end
