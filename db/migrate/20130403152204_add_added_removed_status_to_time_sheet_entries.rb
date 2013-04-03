class AddAddedRemovedStatusToTimeSheetEntries < ActiveRecord::Migration
  def up
    add_column :time_sheet_entries, :added_removed_status, :string
    add_column :time_sheet_entries, :transaction_status, :string
    add_column :time_sheet_entries, :purchase_method, :string
    add_column :time_sheet_entries, :refunded_method, :string
    add_column :time_sheet_entries, :staff_intials, :string
    add_column :time_sheet_entries, :comments, :string
    add_column :time_sheet_entries, :pos_conformation, :string
    change_column :time_sheet_entries, :start_time, :datetime,  :null => true
  end

  def down
  	remove_column :time_sheet_entries, :added_removed_status
    remove_column :time_sheet_entries, :transaction_status
    remove_column :time_sheet_entries, :purchase_method
    remove_column :time_sheet_entries, :refunded_method
    remove_column :time_sheet_entries, :staff_intials
    remove_column :time_sheet_entries, :comments
    remove_column :time_sheet_entries, :pos_conformation
    change_column :time_sheet_entries, :start_time, :datetime,  :null => false
  end

end
