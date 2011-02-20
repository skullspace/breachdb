require 'logger'

module Breach
  DB = Sequel.connect("mysql2://root@localhost/breachdb", :loggers => [Logger.new($stdout)])
end

require 'breach/models/breach'
require 'breach/models/dictionary'
require 'breach/models/dictionary_word'
require 'breach/models/hash'
require 'breach/models/hash_type'
require 'breach/models/news'
require 'breach/models/password'
require 'breach/models/submission'
