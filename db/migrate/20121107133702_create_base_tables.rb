# NJS - add indexes

class CreateBaseTables < ActiveRecord::Migration
  def up
    create_table :seats do |t|
      t.string :name, :null => false

      t.timestamps
    end

    create_table :payments do |t|
      t.integer :customer_id, :null => false
      t.integer :flavor, :null => false
      t.decimal :amount, :precision => 8, :scale => 2, :null => false
      t.integer :minutes
      t.integer :location_id
      t.decimal :remaining_amount, :precision => 8, :scale => 2
      t.integer :internal_user_id
      t.string :description, :default => '', :null => false

      t.timestamps
    end

    create_table :locations do |t|
      t.string :name, :null => false

      t.timestamps
    end

    create_table :seat_rates do |t|
      t.integer :location_id, :null => false
      t.decimal :minutes, :null => false
      t.decimal :dollars, :null => false
      t.decimal :min_dollars, :null => false
    end

    create_table :time_sheets do |t|
      t.integer :customer_id, :null => false
      t.integer :charge, :null => true
      t.float :rate, :null => true

      t.timestamps
    end

    # partial indexes currently only supported in Edge Rails
    # add_index(:seat_reservations, [:seat_id], :unique => true, :where => 'closed_at IS NULL', :name => 'foo')    
    # do it manually instead   
    sql = "CREATE UNIQUE INDEX open_time_sheet_customer_id_uniq " +
      "ON time_sheets (customer_id) " +
      "WHERE charge IS NULL;"
    execute sql

    create_table :time_sheet_entries do |t|
      t.integer  :time_sheet_id, :null => false
      t.integer  :seat_id,     :null => true # customer is "roaming" if null
      t.integer  :internal_user_start_id
      t.integer  :internal_user_end_id
      t.datetime :start_time,  :null => false
      t.datetime :end_time

      t.timestamps
    end

    # partial indexes currently only supported in Edge Rails
    # add_index(:seat_reservations, [:seat_id], :unique => true, :where => 'closed_at IS NULL', :name => 'foo')    
    # do it manually instead   
    sql = "CREATE UNIQUE INDEX time_sheet_entries_seat_id_uniq " +
      "ON time_sheet_entries (seat_id) " +
      "WHERE end_time IS NULL;"
    execute sql

    create_table :seat_reservations do |t|
      t.integer :customer_id, :null => false
      t.integer :seat_id, :null => false

      t.integer :internal_user_make_id
      t.integer :internal_user_close_id

      t.integer :closed_reason
      t.integer :time_sheet_id, :null => true

      t.datetime :opened_at, :null => false
      t.datetime :closed_at, :null => true
      
      t.timestamps      
    end

    # Populate first location
    loc = Location.new
    loc.name = "180 Montgomery"
    loc.save!

    # Populate seat rates for first location
    seat_rate = SeatRate.new
    seat_rate.minutes = (60.0).to_d
    seat_rate.dollars = (2.0).to_d
    seat_rate.min_dollars = (0.0).to_d
    seat_rate.location = loc
    seat_rate.save!

    seat_rate = SeatRate.new
    seat_rate.minutes = (180.0).to_d
    seat_rate.dollars = (10.0).to_d
    seat_rate.min_dollars = (10.0).to_d
    seat_rate.location = loc
    seat_rate.save!

    seat_rate = SeatRate.new
    seat_rate.minutes = (600.0).to_d
    seat_rate.dollars = (20.0).to_d
    seat_rate.min_dollars = (20.0).to_d
    seat_rate.location = loc
    seat_rate.save!

    seat_rate = SeatRate.new
    seat_rate.minutes = (2400.0).to_d
    seat_rate.dollars = (70.0).to_d
    seat_rate.min_dollars = (70.0).to_d
    seat_rate.location = loc
    seat_rate.save!

    # NJS - remove these dummy seats for production
    ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"].each do |table|
      ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K"].each do |seat|
        s = Seat.new
        s.name = "Table #{table} Chair #{seat}"
        s.save!
      end
    end

    # NJS - remove these dummer internal users for production
    iu = InternalUser.new
    iu.first_name = "Victor"
    iu.last_name = "Fries"
    iu.save!

    iu = InternalUser.new
    iu.first_name = "Jervis"
    iu.last_name = "Tetch"
    iu.save!    
  end

  def down
    drop_table :seats
    drop_table :payments
    drop_table :locations
    drop_table :seat_reservation
    drop_table :time_sheet_entries
    drop_table :time_sheets
  end
end
