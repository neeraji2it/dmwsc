class TimeSheetEntry < ActiveRecord::Base
  class SeatTaken < StandardError  
  end

  attr_accessible :start_time, :end_time, :added_removed_status, :transaction_status, :refunded_method,
                  :staff_intials, :comments, :pos_conformation, :time_sheet_id, :remining_minits,
                  :purchase_method, :comments

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

  def cal_remining_minits
    last_remining_minits = self.time_sheet.time_sheet_entries.where('end_time IS NOT NULL').last.remining_minits rescue nil
    if last_remining_minits.nil?
        last_payment = self.customer.payments.last
        available_minuts = last_payment.nil? ? 0 : last_payment.minutes
        self.remining_minits = available_minuts - (self.time_sheet.total_time / 60)
    else
        begin
        self.remining_minits =  last_remining_minits - (((self.end_time - self.start_time) / 60) % 60)
      rescue
        self.remining_minits =  last_remining_minits
      end
    end
  end

end
