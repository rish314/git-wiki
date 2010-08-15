def require_gem_with_feedback(gem)
  begin
    require gem
  rescue LoadError
    puts "You need to 'sudo gem install #{gem}' before we can proceed"
  end
end



class String

  # matches [Page] or [[Page]] or even [[a page]]
  SIMPLE_WIKI_LINK = /\[{1,2}([\w\s\+\-\_]+)\]{1,2}/
  # matches [a description of Page|Page] or [[blah blah|Page]]
  COMPLEX_WIKI_LINK = /\[{1,2}([\w\s]+)\|([\w\s]+)\]{1,2}/

  def wiki_linked
#     self.gsub!(/(?!<nowiki>)(?>\b((?:[A-Z]\w+){2,}))(?!<\/nowiki>)/) { |m| "<a href=\"/#{m}\">#{m}</a>" }
#     self.gsub!(/<\/?nowiki>/,'')
    self.gsub!(SIMPLE_WIKI_LINK) do
      s = $1
      '<a href="/%s">%s</a>' % [s.as_wiki_link, s]
    end
    self.gsub!(COMPLEX_WIKI_LINK) do
      text, link = $1, $2
      '<a href="/%s">%s</a>' % [link.as_wiki_link, text]
    end
    self
  end

  def as_wiki_link
    self.gsub(/\+/, ' plus ').gsub(/\*/, ' times ').gsub(/\s/, '_')
  end
end


class Time
  def for_time_ago_in_words
    "#{(self.to_i * 1000)}"
  end
end
