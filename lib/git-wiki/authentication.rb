
module GitWiki
  class Authentication
    class << self
      attr_accessor :password
    end
 
    #
    # shelling out to openssl is idiotic, but i can't find a rubygem to do MD5 crypt
    #
    # the ruby String.crypt() function on MacOSX does not support MD5 crypt, only DES crypt
    #
    def self.authenticated?(username, password)
      load_passwords if @htpasswd.nil?
      return false if @htpasswd[username].nil?
      type, salt = @htpasswd[username].split('$')[1..2]
      case type
      when "apr1"
        crypted = `echo #{password} | openssl passwd -apr1 -stdin -salt #{salt}`.chomp
      when "1"
        crypted = `echo #{password} | openssl passwd -1 -stdin -salt #{salt}`.chomp
      else
        raise "unknown password hash for #{username}"
      end
      puts "#{crypted} supplied, #{@htpasswd[username]} in htpasswd"
      if @htpasswd[username] == crypted
        true
      else
        false
      end
    end
  
    def self.load_passwords
      @htpasswd = IO.read(GitWiki::Environment[:htpasswd_file]).each_line.each_with_object({}) do |line, hash|
        user, crypt = line.chomp.split(/:/)
        hash[user] = crypt
      end
    end
  end
end

