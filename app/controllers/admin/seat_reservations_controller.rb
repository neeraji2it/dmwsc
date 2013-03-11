class Admin::SeatReservationsController < ApplicationController
  protect_from_forgery
  layout 'admin'

  # NJS - make sure user is logged in as an internal_user

  def index
    @open_reservations = SeatReservation.find_all_by_closed_at(nil)
  end

  def update
    sr = SeatReservation.find(params[:id])
    # NJS - make sure sr isn't already closed

    begin
      # NJS - validate that it's a valid closing reason
      sr.close_reservation(params[:closing_reason_id], InternalUser.find(1))

      msg = nil
      case params[:closing_reason_id].to_i
      when SeatReservation::CLOSING_REASONS[:FILLED]
        msg = "Your reservation has been filled"
      when SeatReservation::CLOSING_REASONS[:SEAT_UNAVAILABLE]
        msg = "Unfortunately your reservation could not be filled as the seat is unavailable"
      when SeatReservation::CLOSING_REASONS[:CANCELED]
        msg = "Your seat reservation request has been canceled"
      when SeatReservation::CLOSING_REASONS[:ALREADY_CHECKED_IN]
        msg = "Looks like you're already checked in. Your seat reservation request has been canceled"
      else
        msg = "There has been an error filling your reservation request"
      end
      PUBNUB.publish({
                       # NJS - make this channel more secure. Don't just use the customer id
                       :channel => "customer_messages_#{sr.customer.id}",
                       :message => msg,
                       :callback => lambda { |message| puts(message) }
                     })

    rescue TimeSheetEntry::SeatTaken => e
      flash[:error] = "Seat is already taken! Cannot fill"
    rescue TimeSheet::TimeSheetAlreadyOpen => e
      flash[:error] = "Customer is already check in. Cannot fill"
    end

    # NJS - what to return back? just a success msg?
    respond_to do |format|
      format.html { 
        if flash[:error].blank?
          flash[:notice] = "reservation updated"
        end
        redirect_to :action => :index
      }
    end
  end

  def blast_db    
    Payment.find(:all).each {|x| x.destroy}
    SeatReservation.find(:all).each {|x| x.destroy}
    TimeSheetEntry.find(:all).each {|x| x.destroy}
    TimeSheet.find(:all).each {|x| x.destroy}
    Hail.find(:all).each {|x| x.destroy}

    flash[:notice] = "payments, seat reservation, time_sheet, and time_sheet_entry data blasted <br />".html_safe
    flash[:notice] += "Payment count = #{Payment.find(:all).count} <br />".html_safe
    flash[:notice] += "Seat Reservations count = #{SeatReservation.find(:all).count} <br />".html_safe
    flash[:notice] += "Time Sheet Entries count = #{TimeSheetEntry.find(:all).count} <br />".html_safe
    flash[:notice] += "Time Sheet count = #{TimeSheet.find(:all).count} <br />".html_safe
    flash[:notice] += "Hail count = #{Hail.find(:all).count} <br />".html_safe

    redirect_to :action => :index
  end

end
