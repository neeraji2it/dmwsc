class MobileAppUiObserver < ActiveRecord::Observer
  observe :hail, :seat_reservation, :time_sheet_entry, :time_sheet

  # works on creates and updates which is what we want
  def after_commit(model)
    # get the customer
    customer = model.customer

    # do a UI update push for this customer
    PUBNUB.publish({
                     # NJS - use more secure channel name
                     :channel => "customer_ui_update_available_#{customer.id}",
                     # the actual message is ignored
                     :message => "UI update available",
                     :callback => lambda { |message| puts(message) }
                   })
  end

end
