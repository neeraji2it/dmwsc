class Location < ActiveRecord::Base

  attr_accessible :name
  has_many :payments
  has_many :seat_rates, :order => 'min_dollars ASC'

  # XXX JBB: Constants are placeholders for locations table open/close times.
  #          Useful for the batch job to close out time_sheets for any
  #          customers who left the building with out checking out.
  #          May eventually use this to build an info page; likely need
  #          different values for different days of the week.
  OPEN_HOUR = 6
  OPEN_MINUTES = 0
  CLOSE_HOUR = 21
  CLOSE_MINUTES = 0

  def seat_rate_for_dollars(payment_dollars)
    sr = seat_rates.where("dollars >= ?", payment_dollars).first
    sr
  end

  def minutes_for_dollars(payment_dollars)
    sr = seat_rate_for_dollars(payment_dollars)
    rate = sr.minutes_per_dollar
     payment_dollars * rate
  end

  def dollars_for_minutes(payment_dollars, target_minutes)
    sr = seat_rate_for_dollars(payment_dollars)
    rate = sr.dollars_per_minute
    target_minutes * rate
  end

end
