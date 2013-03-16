class Admin < ActiveRecord::Base
  attr_accessible :email, :first_name, :integer, :last_name, :password_hash, :password_salt, :role, :password

ROLES = {:ADMIN => 1, :STAF => 2}

validates :email, :role, :presence => true

  def password=(pw)
    @password = pw # used by confirmation validator
    salt = [Array.new(6){rand(256).chr}.join].pack("m").chomp # 2^48 combos
    self.password_salt, self.password_hash = salt, Digest::MD5.hexdigest(pw + salt)
  end

  def password_is?(pw)
    Digest::MD5.hexdigest(pw + password_salt) == password_hash
  end

end
