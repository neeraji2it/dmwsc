# NJS - make this more RESTful
class TimeSheetController < ApplicationController
  protect_from_forgery
  layout 'application'

  before_filter :login_required

  def index
    # intentionally blank
  end

  # NJS - put this in a better controller now that it's also checking hail / order status
  def current_status
    status = nil
    ts = @customer.current_time_sheet

    if @customer.current_seat_reservation
      status = "seatRequested"
    elsif ts.blank?
      status = "out"
    elsif ts.current_seat.blank?
      status = "inAndRoaming"
    elsif ts.filled_by_internal_user? && ts.time_sheet_entries.size == 1
      status = "seatReserved"
    else
      status = "inAndSeated"
    end

    hail_status = nil
    if ts.blank?
      hailStatus = "notCheckedIn"
    elsif @customer.pending_initiated_hail
      hail_status = "hailPending"
    else
      hail_status = "checkedInAndNoPendingHail"
    end

    respond_to do |format|
      format.json { render json: {
          status: status,
          currentSeat: (status == "inAndSeated" ? @customer.current_time_sheet.current_seat.id : nil),
          seatReservation: (status == "seatRequested" ? @customer.current_seat_reservation.id : nil),
          hailStatus: hail_status
        }}
    end
  end

  # NJS - put this in a better controller
  # come up w/ a more secure customer_id channel
  def my_channel_id
    respond_to do |format|
      format.json { render json: {
          channel_id: @customer.id
        }}
    end
  end

  def check_in
    # don't check in again if customer is already checked in
    ts = @customer.current_time_sheet || TimeSheet.check_in(@customer)
    #    ts = TimeSheet.check_in(@customer)

    respond_to do |format|
      format.json { render json: {status: ts.id}}      
    end
  end

  def check_out
    # NJS - make sure the customer even has a current time sheet
    ts = @customer.checkout_time_sheet
    ts.check_out

    respond_to do |format|
      format.json { render json: {status: ts.id}}      
    end
  end

  # NJS - fix this route and others in this controller to only accept POSTs or PUTs or whatever
  def tell_us_here
    ts = @customer.current_time_sheet
    ts.update_seat(@customer.current_seat)

    # NJS - what to return back? just a success msg?    
    respond_to do |format|
      format.json { render json: {seat_id: @customer.current_seat.try(:id)}} 
    end
  end

  def update_seat
    # NJS - make sure seat is actually available

    ts = @customer.current_time_sheet
    begin
      ts.update_seat(params[:seat_numbers])
    rescue TimeSheetEntry::SeatTaken => e
      error = "Seat is already by someone else. Unable to update"
    end

    # NJS - what to return back? just a success msg?
    respond_to do |format|
      format.json { render json: {
          seat_id: @customer.current_seat.try(:id),
          error: error
        }} 
    end
  end
end
