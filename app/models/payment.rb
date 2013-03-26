class Payment < ActiveRecord::Base
  extend ActiveModel::Callbacks

  define_model_callbacks :create, :only => :before
  before_create :action_before_create

  attr_accessible :amount, :minutes, :flavor, :customer_id, :internal_user_id,
                  :location_id, :description, :staff_details, :payment_type

  belongs_to :customer
  belongs_to :location
  belongs_to :internal_user

  PAY_TYPE ={
    :CASH => 1,
    :FREE => 2,
    :STRIPE => 3,
    :CREADIT_CARD => 4
  }

  FLAVORS = {
    :cc_payment => 1,
    :cc_refund => 2,
    :discount => 3,
    :discount_reduced => 4 }
  FLAVOR_IDS = FLAVORS.invert

  include Flavors

  TENDER = {
    :cc_payment => true,
    :cc_refund => true,
    :discount => false,
    :discount_reduced => false }

  validates_presence_of :customer_id
  validates_presence_of :internal_user_id
  validates_presence_of :location_id
  validate :flavor_specific_checks

  def is_tender?
    TENDER[self.flavor_sym]
  end

  def amount_in_cents()
    (self.amount * 100).to_i
  end

  def minutes_at_location_rate(location)
    self.amount * location.minutes_for_dollars(self.amount)
  end

  def to_s
    # NOTE: minutes are not scaled to current location; could be if preferred
    return "unrecorded payment" if (self.new_record?)
    h = minutes / 60
    m = minutes % 60
    time_s = "#{h} hours"
    time_s << ", #{m} minutes" if (m > 0)
    bucks_s = ActionController::Base.helpers.number_to_currency(amount)
    case self.flavor_sym
    when :cc_payment
      s = "#{time_s} purchased for #{bucks_s}"
    when :cc_refund
      s = "#{time_s} returned for #{bucks_s} refund"
    when :discount
      s = "#{time_s} free"
      s << " for #{description}" if (description.present)
    when :discount_reduced
      s = "#{time_s} free time"
      s << " for #{description}" if (description.present)
      s << " returned"
    end
    s
  end

  def adjusted_remaining_minutes(timesheet_location)
    remaining_minutes *
                purchase_location_timesheet_location_ratio(timesheet_location)
  end

  def adjusted_remaining_amount(timesheet_location)
    remaining_amount *
                purchase_location_timesheet_location_ratio(timesheet_location)
  end

private

  def flavor_specific_checks
    fs = self.flavor_sym
    errors.add(:flavor, "unknown flavor #{flavor.inspect}") if (fs.nil?)
    case fs
    when :cc_payment, :discount
      if (self.amount < (0.0).to_d)
        msg = "for #{fs.to_s.titleize} must be positive, got $#{amount.to_s}"
        errors.add(:amount, msg)
      end
      if (self.remaining_amount && self.remaining_amount < (0.0).to_d)
        msg = "for #{fs.to_s.titleize} must be positive, " <<
              "got $#{remaining_amount.to_s}"
        errors.add(:remaining_amount, msg)
      end
    when :cc_refund, :discount_reduced
      # if (self.amount > (0.0).to_d)
      #   msg = "for #{fs.to_s.titleize} must be negative, got $#{amount.to_s}"
      #   errors.add(:amount, msg)
      # end
    end
  end

  def action_before_create
    case self.flavor_sym
    when :cc_payment, :discount
      self.remaining_amount = self.amount
    end
    self.minutes = minutes_at_location_rate(self.location)
  end

  # Ratio used for adjustments for price changes and for spending at different
  # locations; principles are:
  # - Workshop cafe doesn't do bait-and-switch. We give customers the best
  #   value when prices change between the time they purchase minutes and the
  #   time they use minutes, i.e.:
  #   - on price decreases, they get the larger number of minutes the remaining
  #     value of their payment would purchase today.
  #   - on price increases, they get the larger number of minutes we told them
  #     they were purchasing at the time they made their payment.
  # - Payments made at one location can be used at a different location.
  def purchase_location_timesheet_location_ratio(timesheet_location)
    # XXX need divide-by-zero protection
    purchase_rate = minutes / amount
    current_rate_at_purchase_location = location.seat_rate_for_dollars(amount)
    best_rate_at_purchase_location = max([purchase_rate,
                                          current_rate_at_purchase_location])
    current_rate_at_timesheet_location =
                              timesheet_location.seat_rate_for_dollars(amount)
    best_rate_at_purchase_location / current_rate_at_timesheet_location
  end

end
