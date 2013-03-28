class AddPayPlanToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :pay_plan, :string
  end
end