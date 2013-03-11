module ApplicationHelper

  def cents_to_currency(cents)
    cents = cents.to_d if (cents.is_a?(String))
    number_to_currency(cents / (100.0).to_d)
  end

  def dollars_to_cents(dollars)
    dollars = dollars.to_s.to_d unless (dollars.is_a?(BigDecimal))
    (dollars * 100).to_i
  end
end
