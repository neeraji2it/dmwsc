class Charge < ActiveRecord::Base
  attr_accessible :amount

  belongs_to :customer
end
