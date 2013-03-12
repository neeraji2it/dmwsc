class HailsController < ApplicationController
  protect_from_forgery
  layout 'application'

  before_filter :login_required

  def index
    @hails_grouped_by_customer = [] # This is an arrya of arrays, with each array containing hails of one customer
    Hail.order("state ASC, created_at DESC").each{|hail|
      # Check whether there are hails array with customer_id==hail.customer_id already present
      if (customer_hails = @hails_grouped_by_customer.find{|h| h.first.customer_id == hail.customer_id}).present?
        customer_hails << hail
      else
        # Create a new array of hails
        @hails_grouped_by_customer << [hail]
      end
    }
  end

  # create a new hail
  def create
    h = Hail.create_customer_initiated(@customer)

    # NJS - what to return back? just a success msg?
    respond_to do |format|
      format.json { render json: {hail_id: h.id}} 
    end
  end

  # customer can only cancel their own requests
  def update
    h = @customer.pending_initiated_hail
    if h
      h.mark_customer_canceled!
    end

    # NJS - what to return back? just a success msg?
    respond_to do |format|
      format.json { render json: {hail_id: h.try(:id)}} 
    end
  end

  def mark_done
    redirect_to :action => :index and return unless request.put?
 
    h = Hail.find(params[:id]) 
    # NJS - make sure sr isn't already closed 
 
    h.mark_done!(InternalUser.find(1)) 
 
    # NJS - what to return back? just a success msg? 
    respond_to do |format| 
      format.html {  
        flash[:notice] = "hail marked as done" 
        redirect_to :action => :index
      }
    end
  end


end
