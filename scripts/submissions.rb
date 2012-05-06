require 'rubygems'
require 'mysql'
require 'breachdb'

class Submissions < Breachdb
  def self.table_name()
    return 'submission'
  end
  def self.id_column
    return 'submission_id'
  end

  def self.cache_update()
    # No cache in submission table
  end

  def self.export_files()
    return []
  end
end

