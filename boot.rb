require 'rubygems'
require 'bundler'

Bundler.require

require 'active_support/all'
require 'active_support/inflector'

$:.unshift File.expand_path(__FILE__+'/../','lib')

class Object
  include Gibbler::String
end

require 'breach/cache'
require 'breach/db'
require 'breach/server'
require 'rack/cache'
