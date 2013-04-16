class Customer < ActiveRecord::Base
  attr_accessible :first_name, :last_name, :oauth_expires_at, :oauth_token, :provider, :uid

  # NJS - put an ordering on time_sheets
  has_many :time_sheets, :order => "created_at ASC"
  has_many :time_sheet_entries, :through => :time_sheets, :order => "created_at ASC"
  has_many :payments, :order => 'created_at DESC'
  has_many :hails

  has_many :seat_reservations, :order => "opened_at ASC"

  # NJS - add a scope for open seat_reservations

  # based on http://railscasts.com/episodes/360-facebook-authentication?view=asciicast
  def self.from_omniauth(auth)
    where(auth.slice(:provider, :uid)).first_or_initialize.tap do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.first_name = auth.info.first_name
      user.last_name = auth.info.last_name
      user.oauth_token = auth.credentials.token
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
      user.save!
    end
  end

  def record_stripe_payment(stripe_charge, internal_user = nil)
    # NJS - need to log a lot more info!
    payment = Payment.new
    payment.customer = self
    payment.flavor = Payment::FLAVORS[:cc_payment]
    payment.amount = stripe_charge.amount
    payment.internal_user = internal_user
    payment.save!
  end

  def current_time_sheet
    ctse = current_time_sheet_entry
    if ctse
      ctse.time_sheet
    else
      nil
    end
  end
  
  def checkout_time_sheet
    ctse = checkout_time_sheet_entry
    if ctse
      ctse.time_sheet
    else
      nil
    end
  end

  def current_seat_reservation
    last_seat_reservation = seat_reservations.last
    if last_seat_reservation && last_seat_reservation.is_open?
      last_seat_reservation
    else
      nil
    end
  end

  # charges for the current time sheet if there is one. otherwise zero
  def current_charges
    cts = current_time_sheet
    if cts && cts.is_open?
      cts.calculate_charge rescue (0.0).to_d
    else
      (0.0).to_d
    end
  end

  def current_time_sheet_entry
    last_time_sheet_entry = time_sheet_entries.last#where("start_time IS NOT NULL").last
    if last_time_sheet_entry && last_time_sheet_entry.end_time.blank?
      last_time_sheet_entry
    else
      nil
    end
  end
  alias_method :currently_checked_in?, :current_time_sheet_entry
  
  def checkout_time_sheet_entry
    last_time_sheet_entry = time_sheet_entries.where("start_time IS NOT NULL").last
    if last_time_sheet_entry && last_time_sheet_entry.end_time.blank?
      last_time_sheet_entry
    else
      nil
    end
  end

  def total_paid
    self.payments.where(:flavor => [1, 3, 4]).inject(0){|total, p| total + p.amount}
  end

  # only takes charges for bills that are closed out
  def total_charges
    self.time_sheets.inject(0) do |total, ts| 
      puts ts.id
      if ts.charge.blank?
        total
      else
        total + ts.charge
      end
    end
  end

  def add_remining_minutes(m)
    last_time_sheet_entry = time_sheet_entries.last
    if last_time_sheet_entry
      begin
      last_time_sheet_entry.remining_minits += m 
      rescue
      last_time_sheet_entry.remining_minits = m 
      end
      # last_time_sheet_entry.save
      return last_time_sheet_entry.remining_minits if last_time_sheet_entry
    else
      return m
    end
    
  end

  #Caliculate remining refundable minutes
  def refundable_minits
    self.payments.where(:flavor => 1).map(&:minutes).sum
  end

  #Latest available minutes
  def lat_total_in_account
    time_sheet_entries.last.remining_minits
  end

  def balance
    total_paid - current_charges - total_charges
  end

  def balance_due
    bal = self.balance
    (bal < 0) ? -bal : (0.0).to_d
  end

  def current_seat
    try(:current_time_sheet).try(:current_seat)
  end

  def pending_initiated_hail
    self.hails.type_customer_initiated.pending.first
  end

end
