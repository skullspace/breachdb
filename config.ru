require 'rubygems'
require 'bundler'

Bundler.require

require 'active_support/all'
require 'active_support/inflector'

$:.unshift File.expand_path(__FILE__+'/../','lib')

require 'breach/db'
require 'breach/server'

run Breach::Server
