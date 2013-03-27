class MigrateExistingAmount < ActiveRecord::Migration
  def up
  	Customer.all.each do |customer|
  		total_minits = customer.payments.inject(0){|total, p| total + p.minutes}
      p 11111111
      p total_minits
  		used_minutes = customer.time_sheet_entries.each do |time_sheet_entry| 
             time_sheet_entry.remining_minits = total_minits = total_minits - ((time_sheet_entry.end_time - time_sheet_entry.start_time)/60)
  			time_sheet_entry.save
  		end
  		
  	end
  end

  def down
  end
end
