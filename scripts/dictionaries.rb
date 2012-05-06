require 'rubygems'
require 'mysql'
require 'breachdb'

class Dictionaries < Breachdb
  def self.table_name()
    return 'dictionary'
  end
  def self.id_column
    return 'dictionary_id'
  end

  def self.cache_update()
    # Not necessary
  end

  def self.export_files()
    return []
  end
end
