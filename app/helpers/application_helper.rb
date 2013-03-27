module ApplicationHelper

  def cents_to_currency(cents)
    cents = cents.to_d if (cents.is_a?(String))
    number_to_currency(cents / (100.0).to_d)
  end

  def dollars_to_cents(dollars)
    dollars = dollars.to_s.to_d unless (dollars.is_a?(BigDecimal))
    (dollars * 100).to_i
  end

  def timesheet_duration(total_seconds)
	minutes = (total_seconds / 60) % 60
	hours = total_seconds / (60 * 60)
	return "#{hours.to_i}h #{minutes.to_i}m"
  end

  def timesheet_used(total_seconds)
	hours = total_seconds / (60 * 60)
	return "#{hours.round(2)} hrs "
  end

  def cal_time_with_minutes(total_seconds)
    hours = total_seconds.to_f / 60
    return "#{hours.round(2)} hrs"
  end

  def payment_type(type)
    case type
    when '1'
      return "Cash"
    when '2'
      return "Free"
    when '3'
      return "Stripe"
    when '4'
      return "Credit Card"
    end
  end

  def payment_status(payment, a_minits)
    if payment.amount == 0 && payment.payment_type.to_i == Payment::PAY_TYPE[:FREE]
      return "Cannot refund (free)"
    elsif payment.flavor == Payment::FLAVORS[:cc_refund]
      return "Cannot refund (already refunded)"
    elsif a_minits > 0
      return "Unused"
    elsif (a_minits + payment.minutes) > 0
      return "#{((-a_minits.to_f)/60).round(2)} hr used"
    else
      return "Already used"
    end
  end

  def get_id_for_payment_list(payment, a_minits)
    if payment.amount == 0 && payment.payment_type.to_i == Payment::PAY_TYPE[:FREE]
      return "#{payment.id}_free"
    elsif payment.flavor == Payment::FLAVORS[:cc_refund]
      return "#{payment.id}_refunded"
    elsif a_minits > 0
      return "#{payment.id}_#{payment.minutes}"
    elsif (a_minits + payment.minutes) > 0
      return "#{payment.id}_#{a_minits + payment.minutes}"
    else
      return "#{payment.id}_used"
    end
  end

  def find_refund_amount(tot_amount, tot_time, reming_time)
    req_amount = ((reming_time.to_f / tot_time.to_f) * tot_amount.to_i).round(2)
  end

end
