class SeatReservation < ActiveRecord::Base
  belongs_to :seat
  belongs_to :time_sheet
  belongs_to :customer

  belongs_to :internal_user_make, :class_name => "InternalUser", :foreign_key => "internal_user_start_id"
  belongs_to :internal_user_close, :class_name => "InternalUser", :foreign_key => "internal_user_end_id"

  CLOSING_REASONS = {
    :FILLED => 1,
    :SEAT_UNAVAILABLE => 2,
    :CANCELED => 3,
    :ALREADY_CHECKED_IN => 4
  }

  # NJS - add a scope for open reservations

  # NJS - add a check here to insure can only have one seat reservation at a time
  def self.reserve_seat(c, s, iu = nil)
    if !(c.kind_of? Customer)
      c = Customer.find(c)
    end
    if !(s.kind_of? Seat)
      s = Seat.find(s)
    end
    if !iu.blank? && !(iu.kind_of? InternalUser)
      iu = InternalUser.find(iu)
    end

    rs = SeatReservation.new
    rs.customer = c
    rs.seat = s
    rs.internal_user_make = iu
    rs.opened_at = Time.now

    rs.save!
    rs
  end

  def close_reservation(closing_reason_id, iu = nil)
    if !(closing_reason_id.kind_of? Integer)
      closing_reason_id = closing_reason_id.to_i
    end
    if !iu.blank? && !(iu.kind_of? InternalUser)
      iu = InternalUser.find(iu)
    end

    ts = nil
    # create a new TimeSheet if reservation is being filled
    if closing_reason_id == CLOSING_REASONS[:FILLED]
      ts = TimeSheet.check_in(customer, iu, seat, self)
      save!
    end

    # NJS - insure closing_reason_id is one of the values
    self.closed_reason = closing_reason_id
    self.internal_user_close = iu
    self.closed_at = Time.now
    save!

    ts
  end

  def is_open?
    closed_at.blank?
  end

end
