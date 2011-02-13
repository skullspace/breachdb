require 'rubygems'
require 'bundler'

Bundler.require

require 'active_support/all'
require 'active_support/inflector'

$:.unshift File.expand_path(__FILE__+'/../','lib')

require 'breach/db'
require 'breach/server'
require 'rack/cache'

use Rack::Cache,
  :verbose     => true,
  :metastore   => 'file:/tmp/cache/rack/meta',
  :entitystore => 'file:/tmp/cache/rack/body'

run Breach::Server
