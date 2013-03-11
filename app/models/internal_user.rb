class InternalUser < ActiveRecord::Base
  attr_accessible :first_name, :last_name

  has_many :time_sheet_entry_starts, :class_name => "TimeSheetEntry", :foreign_key => "internal_user_start_id"
  has_many :time_sheet_entry_ends, :class_name => "TimeSheetEntry", :foreign_key => "internal_user_end_id"

  has_many :seat_reservations_opened, :as => :opened_by, :class_name => "SeatReservation"
  has_many :seat_reservations_closed, :as => :closed_by, :class_name => "SeatReservation"

  has_many :hails
  has_many :payments, :order => 'created_at DESC'
end
