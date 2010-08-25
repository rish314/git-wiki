def require_gem_with_feedback(gem)
  begin
    require gem
  rescue LoadError
    puts "You need to 'gem install #{gem}' before we can proceed"
  end
end



class String

  # matches [[Page]] or even [[a page]] just like in wikipedia and gollum
  SIMPLE_WIKI_LINK = /\[\[([\w\s\+\-\_]+)\]\]/
  # matches [[Texas|Lone Star state]] just like wikipedia and unlike gollum (gollum reverses the order of things)
  COMPLEX_WIKI_LINK = /\[\[([\w\s]+)\|([\w\s]+)\]\]/
  def wiki_linked
    replace_uri!
#     self.gsub!(/(?!<nowiki>)(?>\b((?:[A-Z]\w+){2,}))(?!<\/nowiki>)/) { |m| "<a href=\"/#{m}\">#{m}</a>" }
#     self.gsub!(/<\/?nowiki>/,'')
    self.gsub!(SIMPLE_WIKI_LINK) do
      s = $1
      '<a href="/%s">%s</a>' % [s.as_wiki_link, s]
    end
    self.gsub!(COMPLEX_WIKI_LINK) do
      link, text = $1, $2
      '<a href="/%s">%s</a>' % [link.as_wiki_link, text]
    end
    self
  end

  def as_wiki_link
    self.gsub(/\+/, ' plus ').gsub(/\*/, ' times ').gsub(/\s/, '_')
  end

  def replace_uri!
    self.gsub!(URI.regexp) do
      s = $&
      puts s.inspect
      '<a href="/%s">%s</a>' % [s, s]
    end
    self
  end
end


class Time
  def for_time_ago_in_words
    "#{(self.to_i * 1000)}"
  end
end
