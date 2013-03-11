require 'spec_helper'

describe Customer do

	before(:each) do
		@customer ||= Customer.new(
			:provider => "foo",
			:uid => "foo",
			:first_name => "Foo",
			:last_name => "Bar",
			:oauth_token => "token_token",
			:oauth_expires_at => Time.zone.now.advance(:days => 1))
	end

	it "should consider a valid customer valid" do
		@customer.valid?.should be_true
		@customer.new_record?.should be_true
		c = @customer.save!
	end
end

