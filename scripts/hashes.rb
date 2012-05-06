require 'rubygems'
require 'mysql'
require 'breachdb'

class Hashes < Breachdb
  def self.table_name()
    return 'hash'
  end
  def self.id_column
    return 'hash_id'
  end

  # Argument = table with key = passwords, value = array of hashes
  def self.update_with_passwords(passwords, cracker_id)
    # First, make sure all the passwords are inserted
    debug("Inserting passwords as required..")

    # Get a list of all hashes
    hashes = []
    passwords.each_value do |h|
      hashes = hashes + h
    end

    # Get the password and hash IDs
    debug("Looking up the passwords' ids...")
    password_ids = Passwords.insert_if_required('password_password', passwords.keys, {'password_date'=>Time.new().strftime("%Y-%m-%d")})
    password_ids = Passwords.get_ids('password_password', passwords.keys(), true)
    debug("Looking up the hashes' ids...")
    hash_ids     = Hashes.get_ids('hash_hash', hashes, true)

    updates = []
    # Loop through the password and its corresponding hashes; get the id of each; insert it
    passwords.each() do |password, hashes|
      hashes.each() do |hash|
        hash_ids[hash].each() do |hash_id|
          updates << "WHEN '#{Mysql.quote(hash_id)}' THEN '#{Mysql.quote(password_ids[password][0])}'"
        end
      end
    end

    debug("Updating the hashes to point at passwords")
    query("UPDATE `hash`
          SET `hash_cracker_id`='#{Mysql::quote(cracker_id)}',
          `hash_password_id` = CASE `hash_id`
            #{updates.join("\n")}
          END
        WHERE `hash_id` IN (#{hash_ids.values().join(',')})")
  end

  def self.cache_update()
    puts("Updating hash.c_password...")
    query("UPDATE `hash` SET `c_password`=''")
    query(" UPDATE `hash` JOIN `password` ON `hash_password_id`=`password_id` SET `c_password`=`password_password` ")

    puts("Updating hash.c_breach_name...")
    query(" UPDATE `hash` JOIN `breach` ON `hash_breach_id`=`breach_id` SET `c_breach_name`=`breach_name` ")

    puts("Updating hash.c_hash_type...")
    query(" UPDATE `hash` JOIN `hash_type` ON `hash_hash_type_id`=`hash_type_id` SET `c_hash_type`=`hash_type_john_name` ")

    puts("Updating hash.c_is_internal...")
    query(" UPDATE `hash` JOIN `hash_type` ON `hash_hash_type_id`=`hash_type_id` SET `c_is_internal`=`hash_type_is_internal` ")

    puts("Updating hash.c_difficulty...")
    query(" UPDATE `hash` JOIN `hash_type` ON `hash_hash_type_id`=`hash_type_id` SET `c_difficulty`=`hash_type_difficulty` ")
  end

  def self.export_files()
    # Add some basic password stuff
    files = []

    files << {
      :filename => "data/hashes.csv.bz2",
      :description => "A list of all hashes",
      :show_header => false,
      :query => {
        :columns => [
          { :name => 'hash_hash' },
        ],
        :groupby => 'hash_hash',
        :orderby => 'hash_hash',
      }
    }

    files << {
      :filename => "data/uncracked_hashes.csv.bz2",
      :description => "A list of all hashes",
      :show_header => false,
      :query => {
        :columns => [
          { :name => 'hash_hash' },
        ],
        :groupby => 'hash_hash',
        :orderby => 'hash_hash',
        :where => "`hash_password_id`='0'"
      }
    }


#    files << {
#      :filename => "data/passwords_with_count.csv.bz2",
#      :description => "A list of all passwords",
#      :show_header => true,
#      :query => {
#        :columns => [
#          { :name => 'password_cache_password_count', :aggregate => 'SUM', :as => 'count' },
#          { :name => 'password_cache_password_password', :as => 'password' },
#        ],
#        :orderby => {
#          :column=>'count',
#          :dir=>'DESC'
#        },
#        :groupby => 'password_cache_password_id',
#      }
#    }
#
#    files << {
#      :filename => "data/passwords_with_hash.csv.bz2",
#      :description => "A list of all passwords with their associated hashes",
#      :show_header => true,
#      :query => {
#        :columns => [
#          { :name => 'password_cache_password_count',    :as => 'count' },
#          { :name => 'password_cache_hash_type_name',    :as => 'hash_type' },
#          { :name => 'password_cache_hash_hash',         :as => 'hash' },
#          { :name => 'password_cache_password_password', :as => 'password' },
#        ],
#        :orderby => {
#          :column=>'hash',
#          :dir=>'ASC'
#        },
#        :groupby => 'password_cache_hash_hash',
#      }
#    }
#
#    files << {
#      :filename => "data/passwords_with_details.csv.bz2",
#      :description => "A list of all passwords with detailed information",
#      :show_header => true,
#      :query => {
#        :columns => [
#          { :name => 'password_cache_password_count',    :as => 'count' },
#          { :name => 'password_cache_password_password', :as => 'password' },
#          { :name => 'password_cache_hash_hash',         :as => 'hash' },
#          { :name => 'password_cache_breach_name',       :as => 'breach' },
#          { :name => 'password_cache_mask_mask',         :as => 'mask' },
#          { :name => 'password_cache_hash_type_name',    :as => 'hash_type' },
#        ],
#        :orderby => {
#          :column=>'password_cache_password_password',
#          :dir=>'ASC'
#        }
#      }
#    }
#
#    # Loop through the breaches and add files for each of them
#    Breaches.query_ex().each do |breach|
#      name_clean = breach['breach_name'].downcase.sub(' ', '_').sub(/[^a-zA-Z0-9_-]/, '')
#
#      # Passwords for the breach
#      files << {
#        :filename => "data/#{name_clean}_passwords.csv.bz2",
#        :description => "Cracked passwords from " + breach['breach_name'],
#        :show_header => false,
#        :query => {
#          :columns => [
#            { :name => 'password_cache_password_password', :as => 'password' },
#          ],
#          :orderby => {
#            :column=>'password_cache_password_password',
#            :dir=>'ASC'
#          },
#          :groupby => "password_cache_password_id",
#          :where => "password_cache_breach_id = '#{breach['breach_id']}'"
#        }
#      }
#
#      # Passwords + counts for the breach
#      files << {
#        :filename => "data/#{name_clean}_passwords_with_count.csv.bz2",
#        :description => "Cracked passwords from " + breach['breach_name'] + " with count",
#        :show_header => true,
#        :query => {
#          :columns => [
#            { :name => 'password_cache_password_count', :aggregate => 'SUM', :as => 'count' },
#            { :name => 'password_cache_password_password', :as => 'password' },
#          ],
#          :orderby => {
#            :column=>'count',
#            :dir=>'DESC'
#          },
#          :groupby => 'password_cache_password_id',
#          :where => "password_cache_breach_id = '#{breach['breach_id']}'"
#        },
#      }
#
#      files << {
#        :filename => "data/#{name_clean}_passwords_with_hash.csv.bz2",
#        :description => "Cracked passwords from " + breach['breach_name'] + " with hash",
#        :show_header => true,
#        :query => {
#          :columns => [
#            { :name => 'password_cache_password_count',    :as => 'count' },
#            { :name => 'password_cache_hash_type_name',    :as => 'hash_type' },
#            { :name => 'password_cache_hash_hash',         :as => 'hash' },
#            { :name => 'password_cache_password_password', :as => 'password' },
#          ],
#          :orderby => {
#            :column=>'hash',
#            :dir=>'ASC'
#          },
#          :groupby => 'password_cache_hash_hash',
#          :where => "password_cache_breach_id = '#{breach['breach_id']}'"
#        }
#      }
#
#      files << {
#        :filename => "data/#{name_clean}_passwords_with_details.csv.bz2",
#        :description => "Cracked passwords from " + breach['breach_name'] + " with details",
#        :show_header => true,
#        :query => {
#          :columns => [
#            { :name => 'password_cache_password_count',    :as => 'count' },
#            { :name => 'password_cache_password_password', :as => 'password' },
#            { :name => 'password_cache_hash_hash',         :as => 'hash' },
#            { :name => 'password_cache_breach_name',       :as => 'breach' },
#            { :name => 'password_cache_mask_mask',         :as => 'mask' },
#            { :name => 'password_cache_hash_type_name',    :as => 'hash_type' },
#          ],
#          :orderby => {
#            :column=>'password_cache_password_password',
#            :dir=>'ASC'
#          },
#          :where => "password_cache_breach_id = '#{breach['breach_id']}'"
#        }
#      }
#    end
#
#    # Loop through the hash types and add files for each of them
#    HashTypes.query_ex({ :where => "`c_total_passwords` != 0" }).each do |hash_type|
#      name_clean = hash_type['hash_type_english_name'].downcase.sub(' ', '_').sub(/[^a-zA-Z0-9_-]/, '')
#
#      # Passwords for the hash_type
#      files << {
#        :filename => "data/#{name_clean}_passwords.csv.bz2",
#        :description => "Cracked passwords of type " + hash_type['hash_type_english_name'],
#        :show_header => false,
#        :query => {
#          :columns => [
#            { :name => 'password_cache_password_password', :as => 'password' },
#          ],
#          :orderby => {
#            :column=>'password_cache_password_password',
#            :dir=>'ASC'
#          },
#          :groupby => "password_cache_password_id",
#          :where => "password_cache_hash_type_id = '#{hash_type['hash_type_id']}'"
#        }
#      }
#
#      # Passwords + counts for the hash_type
#      files << {
#        :filename => "data/#{name_clean}_passwords_with_count.csv.bz2",
#        :description => "Cracked passwords of type " + hash_type['hash_type_english_name'] + " with count",
#        :show_header => true,
#        :query => {
#          :columns => [
#            { :name => 'password_cache_password_count', :aggregate => 'SUM', :as => 'count' },
#            { :name => 'password_cache_password_password', :as => 'password' },
#          ],
#          :orderby => {
#            :column=>'count',
#            :dir=>'DESC'
#          },
#          :groupby => 'password_cache_password_id',
#          :where => "password_cache_hash_type_id = '#{hash_type['hash_type_id']}'"
#        },
#      }
#
#      files << {
#        :filename => "data/#{name_clean}_passwords_with_hash.csv.bz2",
#        :description => "Cracked passwords of type " + hash_type['hash_type_english_name'] + " with hash",
#        :show_header => true,
#        :query => {
#          :columns => [
#            { :name => 'password_cache_password_count',    :as => 'count' },
#            { :name => 'password_cache_hash_type_name',    :as => 'hash_type' },
#            { :name => 'password_cache_hash_hash',         :as => 'hash' },
#            { :name => 'password_cache_password_password', :as => 'password' },
#          ],
#          :orderby => {
#            :column=>'hash',
#            :dir=>'ASC'
#          },
#          :groupby => 'password_cache_hash_hash',
#          :where => "password_cache_hash_type_id = '#{hash_type['hash_type_id']}'"
#        }
#      }
#
#      files << {
#        :filename => "data/#{name_clean}_passwords_with_details.csv.bz2",
#        :description => "Cracked passwords of type " + hash_type['hash_type_english_name'] + " with details",
#        :show_header => true,
#        :query => {
#          :columns => [
#            { :name => 'password_cache_password_count',    :as => 'count' },
#            { :name => 'password_cache_password_password', :as => 'password' },
#            { :name => 'password_cache_hash_hash',         :as => 'hash' },
#            { :name => 'password_cache_breach_name',       :as => 'breach' },
#            { :name => 'password_cache_mask_mask',         :as => 'mask' },
#            { :name => 'password_cache_hash_type_name',    :as => 'hash_type' },
#          ],
#          :orderby => {
#            :column=>'password_cache_password_password',
#            :dir=>'ASC'
#          },
#          :where => "password_cache_hash_type_id = '#{hash_type['hash_type_id']}'"
#        }
#      }
#    end
#
    return files
  end
end

