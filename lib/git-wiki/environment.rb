require 'rubygems'
require 'bundler/setup'

require 'git'
require 'bluecloth'
require 'rubypants'

require 'git-wiki/page'

GIT_REPO = ENV['HOME'] + '/wiki'
HOMEPAGE = 'home'

unless File.exists?(GIT_REPO) && File.directory?(GIT_REPO)
  puts "Initializing repository in #{GIT_REPO}..."
  Git.init(GIT_REPO)
end

$repo = Git.open(GIT_REPO)

