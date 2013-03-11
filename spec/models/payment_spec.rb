require 'spec_helper'

describe Payment do

  before(:each) do
    customer = Customer.first
    internal_user = InternalUser.first
    location = Location.first
    @payment ||= Payment.new(:amount => (5.00).to_d)
    @payment.flavor = Payment::FLAVORS[:cc_payment]
    @payment.customer_id = customer.id
    @payment.location_id = location.id
    @payment.internal_user_id = internal_user.id
  end

  it "should consider a valid payment valid" do
    @payment.valid?.should be_true
    p = @payment.save!
  end

  it "should find a missing customer_id" do
    @payment.customer_id = nil
    lambda {@payment.save!}.should raise_exception(ActiveRecord::RecordInvalid,
                          /Customer can't be blank/)
  end

  it "should find a missing internal_user_id" do
    @payment.internal_user_id = nil
    lambda {@payment.save!}.should raise_exception(ActiveRecord::RecordInvalid,
                          /Internal user can't be blank/)
  end

  it "should find a bogus flavor" do
    @payment.flavor = 42
    @payment.flavor_sym.should be_nil
    lambda {@payment.save!}.should raise_exception(ActiveRecord::RecordInvalid,
                          /unknown flavor/)
  end

  it "should find a negative amount for a flavor that needs to be positive" do
    @payment.flavor = :cc_payment
    @payment.amount = (-7.95).to_d
    lambda {@payment.save!}.should raise_exception(ActiveRecord::RecordInvalid,
                          /Amount for Cc Payment must be positive, got \$-7.95/)
  end

  it "should find a positive amount for a flavor that needs to be negative" do
    @payment.flavor = :cc_refund
    @payment.amount = (7.95).to_d
    lambda {@payment.save!}.should raise_exception(ActiveRecord::RecordInvalid,
                          /Amount for Cc Refund must be negative, got \$7.95/)
  end

  it "should correctly determine tender property of each flavor" do
    @payment.flavor_sym.should eql(:cc_payment)
    @payment.is_tender?.should be_true
    @payment.flavor = Payment::FLAVORS[:cc_refund]
    @payment.flavor_sym.should eql(:cc_refund)
    @payment.is_tender?.should be_true
    @payment.flavor = :cc_refund
    @payment.flavor_sym.should eql(:cc_refund)
    @payment.is_tender?.should be_true
    @payment.flavor = :discount
    @payment.flavor_sym.should eql(:discount)
    @payment.is_tender?.should be_false
    @payment.flavor = :discount_reduced
    @payment.flavor_sym.should eql(:discount_reduced)
    @payment.is_tender?.should be_false
  end

  it "should determine the payment amount in cents" do
    @payment.amount_in_cents.should eql(500)
	end

  it "should return a string describing the payment" do
    @payment.save!
    @payment.to_s.should_eql("2 hours, 30 minutes purchased for $5.00")
	end
end
