class TimeSheet < ActiveRecord::Base
  class TimeSheetAlreadyOpen < StandardError  
  end

  attr_accessible :start_time, :end_time

  has_many :time_sheet_entries, :order => "created_at ASC"
  has_one :seat_reservation
  belongs_to :customer

  # "running" = not yet closed time sheets
  scope :running, TimeSheet.joins(:time_sheet_entries).where('time_sheet_entries.end_time' => nil)

  def self.check_in(c, iu = nil, seat = nil, seat_reservation = nil)
    if !(c.kind_of? Customer)
      c = Customer.find(c)
    end
    if !iu.blank? && !(iu.kind_of? InternalUser)
      iu = InternalUser.find(iu)
    end
    if !seat.blank? && !(seat.kind_of? Seat)
      seat = Seat.find(seat)      
    end
    if !seat_reservation.blank? && !(seat_reservation.kind_of? SeatReservation)
      seat_reservation = SeatReservation.find(seat)
    end

    ts = TimeSheet.new
    ts.customer = c
    ts.seat_reservation = seat_reservation
    begin
      ts.save!
    rescue ActiveRecord::RecordNotUnique => e
      raise TimeSheet::TimeSheetAlreadyOpen.new(e)
    end

    ts.add_time_sheet_entry(iu, seat)
    ts.save!
    ts
  end

  def check_out(iu = nil)
    if !iu.blank? && !(iu.kind_of? InternalUser)
      iu = InternalUser.find(iu)
    end

    tse = time_sheet_entries.last
    tse.end_time = Time.now
    tse.internal_user_end = iu
    tse.save!

    # XXX JBB: First use payments with remaining value, then calculate minimum
    #          payment if any. Good to pair with NJS on this so no surprises.
    #          Customer should know "how much this visit cost", "how much value
    #          I have remaining in my previous payments", "how much extra I
    #          have to pay today, if any ($-10 policy not only for new folks?)"
    self.charge = calculate_charge
    # XXX Need to select correct locations record once we support > 1 location
    # XXX Need to select the correct seat_rate for the location
    self.rate = Location.first.seat_rates.first.minutes_per_dollar
    self.save!

    # cancel customer's hails as well
    customer.hails.pending.each do |h|
      h.mark_customer_left!(iu)
    end

    self
  end

  # NJS - make sure seat is actually available
  def update_seat(seat, iu = nil)
    if !(seat.kind_of? Seat)
      seat = Seat.find(seat)
    end

    tse = add_time_sheet_entry(iu, seat)
    tse.save!
  end

  def current_seat
    time_sheet_entries.last.seat
  end

  def is_open?
    time_sheet_entries.last ? time_sheet_entries.last.end_time.blank? : false
  end

  # was this time sheet started by an internal user filling a customer's reservation request?
  def filled_by_internal_user?
    seat_reservation && time_sheet_entries.first.internal_user_start
  end

  def start_time
    time_sheet_entries.first.start_time
  end

  def end_time
    time_sheet_entries.last.end_time
  end

  def total_time
    end_time = nil
    if is_open?
      end_time = Time.now
    else
      end_time = time_sheet_entries.last.end_time
    end

    end_time - time_sheet_entries.first.start_time    
  end

  # NJS - should probably be protected
  def calculate_charge
    # XXX Need to select correct locations record once we support > 1 location
    # XXX Need to select the correct seat_rate for the location
    (total_time / 60.0) * Location.first.seat_rates.first.dollars_per_minute
  end

  def add_time_sheet_entry(iu = nil, seat = nil)
    if !iu.blank? && !(iu.kind_of? InternalUser)
      iu = InternalUser.find(iu)
    end
    if !seat.blank? && !(seat.kind_of? Seat)
      seat = Seat.find(seat)
    end

    now = Time.now

    tse = TimeSheetEntry.new
    tse.start_time = now
    tse.internal_user_start = iu
    tse.seat = seat

    TimeSheet.transaction do
      begin
        if time_sheet_entries.size > 0
          # close out previous one first
          prev_tse = time_sheet_entries.last
          prev_tse.end_time = now
          prev_tse.internal_user_end = iu
          prev_tse.save!
        end
        # automatically saves only if the TimeSheet is already stored in the db
        # see "Unsaved objects and associations" at http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html
        time_sheet_entries << tse
      rescue ActiveRecord::RecordNotUnique => e        
        raise TimeSheetEntry::SeatTaken.new(e)      
      end
    end

    # add first seating hail if necessary
    if !tse.seat.blank?
      if time_sheet_entries.size > 1 && time_sheet_entries[-2].seat.blank?
        # was previously roaming
        Hail.create_first_seating(self.customer)
      elsif time_sheet_entries.size == 1 && !filled_by_internal_user?
        # just entered on own and at a seat
        Hail.create_first_seating(self.customer)
      elsif time_sheet_entries.size == 2 && filled_by_internal_user?
        # Had seat reserved and filled by staff. Told us they had arrived
        Hail.create_first_seating(self.customer)
      end
    end

    tse
  end

end





