class CreateHails < ActiveRecord::Migration
  def up
    create_table :hails do |t|
      t.integer :customer_id, :null => false
      t.integer :internal_user_id, :null => true
      t.integer :hail_type, :null => false
      t.integer :state, :null => false
      
      t.timestamps
    end

    # partial indexes currently only supported in Edge Rails
    # add_index(:seat_reservations, [:seat_id], :unique => true, :where => 'closed_at IS NULL', :name => 'foo')    
    # do it manually instead   
    sql = "CREATE UNIQUE INDEX hails_customer_type_pending " +
      "ON hails (customer_id, hail_type) " +
      "WHERE state = 1;"
    execute sql
    
  end

  def down
    drop_table :hails
  end
end
