
require 'git'

module GitWiki
  class GitRepo < Git::Base
    def self.gitwiki_instance
      if GitWiki::Environment[:git_remote_url].nil? || GitWiki::Environment[:git_remote].nil?
        @gitwiki_instance = Git.init(GitWiki::Environment[:repository]) if @gitwiki_instance.nil?
      else
        @gitwiki_instance = Git.clone(GitWiki::Environment[:git_remote_url], :name => GitWiki::Environment[:git_remote], :path => GitWiki::Environment[:repository])
      end
      return @gitwiki_instance
    end
  end
end
