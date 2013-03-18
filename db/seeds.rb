# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)
Admin.destroy_all
Admin.create(:email => 'admin@admin.com', :password => 'admin',:role => Admin::ROLES[:ADMIN])
Admin.create(:email => 'staf@staf.com', :password => 'staf',:role => Admin::ROLES[:STAF])
Seat.destroy_all
(1..110).each do |s|
Seat.create(:name => "Seat_number_#{s}")
end