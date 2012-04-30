require 'rubygems'
require 'mysql'
require 'breachdb'

class Passwords < Breachdb
  def self.table_name()
    return 'password'
  end
  def self.id_column
    return 'password_id'
  end

  def self.cache_update()
    # Do nothing
  end
end

