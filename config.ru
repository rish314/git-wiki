#!/usr/bin/env rackup
LIB_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
$:.unshift LIB_PATH
require 'git-wiki/application'

GitWiki::Config.new
run GitWiki::Application
