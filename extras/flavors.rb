module Flavors

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def normalize_flavor_id(try_sym)
      flavs = self.const_get(:FLAVORS)
      case try_sym
      when Symbol
        return flavs[try_sym]
      when Integer
        flav_ids = self.const_get(:FLAVOR_IDS)
        return flavs[flav_ids[try_sym]]
      end
      nil
    end
  end

  def flavor=(flavor_arg)
    f = self.class::normalize_flavor_id(flavor_arg) || flavor_arg
    write_attribute(:flavor, f)
  end

  def flavor_sym
    self.class::FLAVOR_IDS[self.flavor]
  end

  def flavor_s
    flavor_sym.to_s
  end
end
