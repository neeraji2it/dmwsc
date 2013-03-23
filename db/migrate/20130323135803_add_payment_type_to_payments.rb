class AddPaymentTypeToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :payment_type, :string,:default => 1
  end
end
