class TimeSheetEntry < ActiveRecord::Base
  class SeatTaken < StandardError  
  end

  attr_accessible :start_time, :end_time

  belongs_to :time_sheet
  belongs_to :internal_user_start, :class_name => "InternalUser", :foreign_key => "internal_user_start_id"
  belongs_to :internal_user_end, :class_name => "InternalUser", :foreign_key => "internal_user_end_id"
  belongs_to :seat

  scope :running, where(:end_time => nil)

  def customer
    time_sheet.customer
  end

  def open?
    end_time.blank?
  end

  def closed?
    !end_time.blank?
  end

end
