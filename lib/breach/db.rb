module Breach
  DB = Sequel.connect("mysql2://root@localhost/breachdb")
end

require 'lib/breach/models/breach'
require 'lib/breach/models/dictionary'
require 'lib/breach/models/dictionary_word'
require 'lib/breach/models/hash'
require 'lib/breach/models/hash_type'
require 'lib/breach/models/news'
require 'lib/breach/models/password'
require 'lib/breach/models/submission'
