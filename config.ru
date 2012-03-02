#!/usr/bin/env rackup
LIB_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
$:.unshift LIB_PATH
require 'git-wiki/environment'
GitWiki::Environment.from_file(File.join(File.dirname(__FILE__), 'environment.rb'))

require 'git-wiki/application'
run GitWiki::Application
