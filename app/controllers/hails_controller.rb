class HailsController < ApplicationController
  protect_from_forgery
  layout 'application'

  before_filter :login_required

  def index
    @times = TimeSheetEntry.all
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

end
