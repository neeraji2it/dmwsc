class SeatRate < ActiveRecord::Base

  belongs_to :location

  # NOTE: A location's seat_rates records should cover payments any positive
  #       dollar amount.  Each step is marked by min_dollars.

  def dollars_per_minute
    dollars / minutes
  end

  def minutes_per_dollar
    minutes / dollars
  end
end
