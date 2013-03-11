require 'spec_helper'

describe ApplicationHelper do

  it "should convert cents to currency string" do
    cents_to_currency(100).should eql("$1.00")
    cents_to_currency("100").should eql("$1.00")
    cents_to_currency("100.02").should eql("$1.00")
    cents_to_currency(100.0).should eql("$1.00")
    cents_to_currency((100.0).to_d).should eql("$1.00")
  end

  it "should convert dollars to (Integer) cents" do
    dollars_to_cents(1).should eql(100)
    dollars_to_cents("1").should eql(100)
    dollars_to_cents(1.0).should eql(100)
    dollars_to_cents((1.0).to_d).should eql(100)
  end
end

