
require 'git'

module GitWiki
  class GitRepo < Git::Base
    def self.gitwiki_instance
      @gitwiki_instance = Git.init(GitWiki::Environment[:repository]) if @gitwiki_instance.nil?
      return @gitwiki_instance
    end
  end
end
