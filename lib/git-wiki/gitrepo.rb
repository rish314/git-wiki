
require 'git'

module GitWiki
  class GitRepo < Git::Base
    def self.gitwiki_instance
      if @gitwiki_instance.nil?
        if !GitWiki::Environment[:git_remote_url].nil? && !GitWiki::Environment[:git_remote].nil? && !File.directory?(GitWiki::Environment[:repository])
          @gitwiki_instance = Git.clone(GitWiki::Environment[:git_remote_url], GitWiki::Environment[:repository])
        else
          @gitwiki_instance = Git.init(GitWiki::Environment[:repository])
        else
      end
      return @gitwiki_instance
    end
  end
end
