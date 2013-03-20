# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130320183139) do

  create_table "admins", :force => true do |t|
    t.string   "email"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "password_hash"
    t.string   "password_salt"
    t.integer  "role"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "customers", :force => true do |t|
    t.string   "provider"
    t.string   "uid"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "oauth_token"
    t.datetime "oauth_expires_at"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "customers", ["provider", "uid"], :name => "index_customers_on_provider_and_uid", :unique => true

  create_table "hails", :force => true do |t|
    t.integer  "customer_id",      :null => false
    t.integer  "internal_user_id"
    t.integer  "hail_type",        :null => false
    t.integer  "state",            :null => false
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "internal_users", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "locations", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "payments", :force => true do |t|
    t.integer  "customer_id",                                                    :null => false
    t.integer  "flavor",                                                         :null => false
    t.decimal  "amount",           :precision => 8, :scale => 2,                 :null => false
    t.integer  "minutes"
    t.integer  "location_id"
    t.decimal  "remaining_amount", :precision => 8, :scale => 2
    t.integer  "internal_user_id"
    t.string   "description",                                    :default => "", :null => false
    t.datetime "created_at",                                                     :null => false
    t.datetime "updated_at",                                                     :null => false
  end

  create_table "seat_rates", :force => true do |t|
    t.integer "location_id",                                :null => false
    t.decimal "minutes",     :precision => 10, :scale => 0, :null => false
    t.decimal "dollars",     :precision => 10, :scale => 0, :null => false
    t.decimal "min_dollars", :precision => 10, :scale => 0, :null => false
  end

  create_table "seat_reservations", :force => true do |t|
    t.integer  "customer_id",            :null => false
    t.integer  "seat_id",                :null => false
    t.integer  "internal_user_make_id"
    t.integer  "internal_user_close_id"
    t.integer  "closed_reason"
    t.integer  "time_sheet_id"
    t.datetime "opened_at",              :null => false
    t.datetime "closed_at"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  create_table "seats", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "time_sheet_entries", :force => true do |t|
    t.integer  "time_sheet_id",                                         :null => false
    t.integer  "seat_id"
    t.integer  "internal_user_start_id"
    t.integer  "internal_user_end_id"
    t.datetime "start_time",                                            :null => false
    t.datetime "end_time"
    t.datetime "created_at",                                            :null => false
    t.datetime "updated_at",                                            :null => false
    t.decimal  "remining_minits",        :precision => 10, :scale => 0
  end

  create_table "time_sheets", :force => true do |t|
    t.integer  "customer_id", :null => false
    t.integer  "charge"
    t.float    "rate"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

end
