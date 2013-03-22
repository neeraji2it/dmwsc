class AddPosStatustoPayments < ActiveRecord::Migration
  def change
    add_column :payments, :pos_status, :string
    add_column :payments, :staff_details, :string
  end
end
