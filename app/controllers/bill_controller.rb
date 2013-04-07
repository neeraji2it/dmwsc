class BillController < ApplicationController
  protect_from_forgery
  layout 'application'

  before_filter :login_required

  def pay_at_register

  end

  def register_confirm
    @customer.pay_plan = params["hours_amount"]
    @customer.save
    session[:redirect_home]=true
    # current_bill
    # redirect_to root_path
  end

  def current_charges
    @customer

    respond_to do |format|
      format.json { render json: {balance: @customer.balance, 
                                  current_charges: @customer.current_charges}}
    end
  end

  def current_bill
    # payment confirmation message if payment recently made
    if (@customer.payments.size > 0) && (Time.now - @customer.payments.first.created_at < 5.minutes)
      flash.now[:notice] = "Thank you for your #{view_context.number_to_currency(@customer.payments.first.amount)} payment."
    end

    @line_items = []
    
    # get the charges out of these
    @line_items << @customer.time_sheets
    @line_items << @customer.payments
    @line_items.flatten!
    
    # @line_items.reject! do |li|
    #   (li.kind_of? TimeSheet) && (!li.has_charges?)
    # end
    begin 
    @line_items.sort_by! do |li|
      if (li.kind_of? TimeSheet)
        # has charges at this point
        li.start_time        
      elsif li.kind_of? Payment
        li.created_at
      else
        # NJS - handle this
        raise "not a known time of line item"
      end
    end
  rescue
  end

    # NJS - previous balance stuff. Put back in later
    # @line_items << @customer.current_charges

    @line_items.reverse!
    
    render "bill/current_bill", :layout => nil
  end

  def visit_summary
    @time_sheet = @customer.time_sheets.last

    render "bill/visit_summary", :layout => nil
  end

  def index
    # intentially blank
  end
  
  # NJS - make this accept POSTs and AJAX requests only  
  def create
    # set your secret key: remember to change this to your live secret key in production
    # see your keys here https://manage.stripe.com/account
    # NJS - will want to move this to a global somewhere that pulls values based on
    # test, development, or production environment
    Stripe.api_key = "sk_kGI38LpjtG08rZwNURQSbiniH0dAY"
    
    # get the credit card details submitted by the form
    token = params[:stripeToken]
    
    # create the charge on Stripe's servers - this will charge the user's card
    # NJS - move this to a background process
    @charge = Stripe::Charge.create(
                                  :amount => dollars_to_cents(params[:amount]),
                                  :currency => "usd",
                                  :card => token,
                                  :description => params[:description])

    if @charge.failure_message
      # NJS - do something here on failures
    else
      iu = InternalUser.first   # XXX: test hack; get the real internal_user
      @customer.record_stripe_payment(@charge, iu)
      @charge
    end
    
    respond_to do |format|
      # NJS - nothing is actually done with this message
      format.json { render json: {message: 'Thank you. We are processing your payment.'}}
    end
  end

end
