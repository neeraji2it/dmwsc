class Seat < ActiveRecord::Base
  attr_accessible :name

  has_many :time_sheet_entries
  has_many :seat_reservations

  scope :taken, Seat.joins(:time_sheet_entries).where('time_sheet_entries.end_time' => nil)

  def is_available?
    TimeSheetEntry.open.find_by_seat_id(id)
  end

end
