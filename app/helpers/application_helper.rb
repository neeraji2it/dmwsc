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
end
