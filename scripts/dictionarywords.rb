require 'rubygems'
require 'mysql'
require 'breachdb'

class DictionaryWords < Breachdb
  def self.table_name()
    return 'dictionary_word'
  end
  def self.id_column
    return 'dictionary_word_id'
  end

  def self.cache_update()
    # Not necessary
  end

  def self.export_files()
    return []
  end
end
