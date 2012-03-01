#!/usr/bin/env rackup
LIB_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
$:.unshift LIB_PATH
require 'git-wiki/config'
GitWiki::Config.from_file(File.join(File.dirname(__FILE__), 'config.rb'))

require 'git-wiki/application'
run GitWiki::Application
