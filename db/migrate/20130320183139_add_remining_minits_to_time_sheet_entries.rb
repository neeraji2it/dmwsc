class AddReminingMinitsToTimeSheetEntries < ActiveRecord::Migration
  def change
    add_column :time_sheet_entries, :remining_minits, :decimal
  end
end
