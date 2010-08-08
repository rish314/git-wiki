def require_gem_with_feedback(gem)
  begin
    require gem
  rescue LoadError
    puts "You need to 'sudo gem install #{gem}' before we can proceed"
  end
end


class Time
  def for_time_ago_in_words
    "#{(self.to_i * 1000)}"
  end
end
