class MigrateExistingAmount < ActiveRecord::Migration
  def up
  	Customer.all.each do |customer|
  		total_minits = customer.payments.where(:flovor => [1, 3]).inject(0){|total, p| total + p.minutes}
  		used_minutes = customer.time_sheet_entries.each do |time_sheet_entry| 
            begin
             time_sheet_entry.remining_minits = total_minits = total_minits - ((time_sheet_entry.end_time - time_sheet_entry.start_time)/60)
            rescue
              time_sheet_entry.remining_minits = total_minits
            end
  			time_sheet_entry.save
  		end
  		
  	end
  end

  def down
  end
end
