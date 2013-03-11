class CreateCustomers < ActiveRecord::Migration
  def change
    create_table :customers do |t|
      t.string :provider
      t.string :uid
      t.string :first_name
      t.string :last_name
      t.string :oauth_token
      t.datetime :oauth_expires_at

      t.timestamps
    end

    add_index(:customers, [:provider, :uid], :unique => true)    
  end
end
