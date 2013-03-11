class CreateInternalUsers < ActiveRecord::Migration
  def change
    create_table :internal_users do |t|
      t.string :first_name
      t.string :last_name

      t.timestamps
    end
  end
end
