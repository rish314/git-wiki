require 'git'

unless File.exists?(GitWiki::Config[:repository]) && File.directory?(GitWiki::Config[:repository])
  puts "Initializing repository in #{GitWiki::Config[:repository]}..."
  Git.init(GitWiki::Config[:repository])
end

$repo = Git.open(GitWiki::Config[:repository])

