class SeatReservationsController < ApplicationController
  protect_from_forgery
  layout 'application'

  before_filter :login_required

  # create a new reservation
  # NJS - make sure user doesn't already have a seat reservation made
  def create
    sr = SeatReservation.reserve_seat(@customer, params[:seat_id])

    # NJS - what to return back? just a success msg?
    respond_to do |format|
      format.json { render json: {reservation_id: sr.id}} 
    end
  end

  def update
    sr = SeatReservation.find(params[:id])
    # NJS - make sure sr isn't already closed
    # NJS - make sure the sr belongs to the logged in user

    # cutomers can only cancel their own reservations
    sr.close_reservation(SeatReservation::CLOSING_REASONS[:CANCELED])

    # NJS - what to return back? just a success msg?
    respond_to do |format|
      format.json { render json: {reservation_id: sr.id}}
    end
  end

  def taken_seats
    respond_to do |format|
      format.json { render json: Seat.taken.collect{|s| s.id}.to_json }
    end
  end

end
