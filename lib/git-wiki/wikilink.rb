
module GitWiki
  class WikiLink
    # Pre-formatted code blocks are used for writing about programming or markup
    # source code. Rather than forming normal paragraphs, the lines of a code
    # block are interpreted literally. Markdown wraps a code block in both <pre>
    # and <code> tags.
    #
    # To produce a code block in Markdown, simply indent every line of the block
    # by at least 4 spaces or 1 tab.
    MARKDOWN_PRE = /^\ {4}|\t/
  
    # Match [[Page]] or even [[a page]] just like in wikipedia and gollum
    GIT_WIKI_SIMPLE_LINK = /\[\[([\w\s\+\-\_\/]+)\]\]/
  
    # Match [[Texas|Lone Star state]] just like wikipedia and unlike gollum
    # (gollum reverses the order of things)
    GIT_WIKI_COMPLEX_LINK = /\[\[([\w\s\+\-\_\/]+)\|([\w\s]+)\]\]/
  
    # Replace things that are obviously meant to be a url:
    #   http(s) or ftp or file then a colon and then some number of slashes,
    #   numbers, chars, question marks, dots (very important)...
    # It is far from perfect; it is good enough for now.
    GIT_WIKI_OBVIOUS_URI = /(https?|ftps?|file)\:[\/\\\w\d\/\-\+\?\!\&\=\.\_\@\%\&\*\~\#]+/
 
    def initialize(str)
      @str = str
    end

    def wiki_linked
      with_links = ""
      @str.each_line do |line|
        # skip the lines that contain <pre> text (code)
        unless line =~ MARKDOWN_PRE
          # self.gsub!(/(?!<nowiki>)(?>\b((?:[A-Z]\w+){2,}))(?!<\/nowiki>)/) { |m| "<a href=\"/#{m}\">#{m}</a>" }
          # self.gsub!(/<\/?nowiki>/,'')
          line.gsub!(GIT_WIKI_SIMPLE_LINK) do
            link = $1
            '[%s](/page/show/%s)' % [link, as_wiki_link(link)]
          end
          line.gsub!(GIT_WIKI_COMPLEX_LINK) do
            link, text = $1, $2
            '[%s](/page/show/%s)' % [text, as_wiki_link(link)]
          end
        end
        with_links << line
      end
      with_links
    end
  
    def as_wiki_link(link)
      link.gsub(/\+/, ' plus ').gsub(/\*/, ' times ').gsub(/\s/, '_')
    end
  end
end

