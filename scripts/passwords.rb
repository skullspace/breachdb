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

  ##
  # Inserts the passwords into the database, as necessary.
  ##
  def self.insert_if_required(passwords)
    # Get the IDs for the passwords that we already have
    password_ids = Passwords.get_ids('password_password', passwords, false)

    # Figure out which passwords are missing and insert them
    missing = []
    passwords.each() do |p|
      if(password_ids[p].nil?)
        missing << p
      end
    end

    if(missing.size() > 0)
      missing.collect!() do |m| "('" + Mysql::quote(m) + "', NOW())" end
      query("INSERT INTO `password`
        (`password_password`, `password_date`)
          VALUES
        #{missing.join(',')}
      ")
    end
  end

  def self.cache_update()
    # Do nothing
  end
end

