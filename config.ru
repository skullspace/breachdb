require 'rubygems'
require 'bundler'

Bundler.require

require 'active_support/inflector'
require 'lib/breach/db'

require 'lib/breach/server'

run Breach::Server
