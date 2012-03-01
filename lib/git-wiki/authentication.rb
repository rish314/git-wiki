
module GitWiki
  class Authentication
  class << self
    attr_accessor :password
  end

  def self.authenticated?(username, password)
    load_passwords if self.password.nil?
    if self.password[username] == password
      true
    else
      false
    end
  end

  def self.load_passwords
    self.password = Hash.new
    self.password["admin"] = "admin"
  end
  end
end

