class Hail < ActiveRecord::Base
  belongs_to :customer
  belongs_to :internal_user
  
  HAIL_STATES = {
    :PENDING => 1,
    :DONE => 2,
    :CUSTOMER_CANCELED => 3,
    :CUSTOMER_LEFT => 4 # does not differentiate between self checkout or staff checkout
  }

  HAIL_TYPES = {
    :CUSTOMER_INITIATED => 1,
    :FIRST_SEATING => 2
  }

  scope :pending, where(:state => HAIL_STATES[:PENDING])
  scope :done, where(:state => HAIL_STATES[:DONE])
  scope :customer_canceled, where(:state => HAIL_STATES[:CUSTOMER_CANCELED])
  scope :customer_left, where(:state => HAIL_STATES[:CUSTOMER_LEFT])

  scope :type_customer_initiated, where(:hail_type => HAIL_TYPES[:CUSTOMER_INITIATED])
  scope :type_first_seat, where(:hail_type => HAIL_TYPES[:FIRST_SEATING])

  def self.create_customer_initiated(c)
    if !(c.kind_of? Customer)
      c = Customer.find(c)
    end

    Hail.find_or_create_by_customer_id_and_hail_type_and_state(c.id,
                                                               HAIL_TYPES[:CUSTOMER_INITIATED],
                                                               HAIL_STATES[:PENDING])
  end

  def self.create_first_seating(c)
    if !(c.kind_of? Customer)
      c = Customer.find(c)
    end

    Hail.find_or_create_by_customer_id_and_hail_type_and_state(c.id,
                                                               HAIL_TYPES[:FIRST_SEATING],
                                                               HAIL_STATES[:PENDING])
  end

  def mark_done!(iu)
    if !iu.blank? && !(iu.kind_of? InternalUser)
      iu = InternalUser.find(iu)
    end

    return if state != HAIL_STATES[:PENDING]

    self.state = HAIL_STATES[:DONE]
    self.internal_user = iu
    self.save!
  end

  def mark_customer_canceled!
    return if state != HAIL_STATES[:PENDING]

    self.state = HAIL_STATES[:CUSTOMER_CANCELED]
    self.save!
  end

  def mark_customer_left!(iu = nil)
    if !iu.blank? && !(iu.kind_of? InternalUser)
      iu = InternalUser.find(iu)
    end

    return if state != HAIL_STATES[:PENDING]

    self.state = HAIL_STATES[:CUSTOMER_LEFT]
    self.internal_user = iu
    self.save!
  end

end
