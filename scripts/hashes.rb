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
      :filename => "downloads/hashes.csv.bz2",
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
      :filename => "downloads/uncracked_hashes.csv.bz2",
      :description => "A list of all uncracked hashes",
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

    files << {
      :filename => "downloads/hashes_with_password.csv.bz2",
      :description => "A list of all hashes with passwords",
      :show_header => true,
      :query => {
        :columns => [
          { :name => 'hash_hash', :as => "hash" },
          { :name => 'c_password', :as => "password" },
        ],
        :groupby => 'hash_hash',
        :orderby => 'hash_hash',
      }
    }

    files << {
      :filename => "downloads/hashes_with_type.csv.bz2",
      :description => "A list of all hashes with type",
      :show_header => true,
      :query => {
        :columns => [
          { :name => 'hash_hash', :as => "hash" },
          { :name => 'c_hash_type', :as => "hash_type" },
        ],
        :groupby => 'hash_hash',
        :orderby => 'hash_hash',
      }
    }

    files << {
      :filename => "downloads/uncracked_hashes_with_type.csv.bz2",
      :description => "A list of uncracked hashes with types",
      :show_header => true,
      :query => {
        :columns => [
          { :name => 'hash_hash', :as => "hash_hash" },
          { :name => 'c_hash_type', :as => "hash_type" },
        ],
        :groupby => 'hash_hash',
        :orderby => 'hash_hash',
        :where => "`hash_password_id`='0'"
      }
    }

    files << {
      :filename => "downloads/hashes_with_count.csv.bz2",
      :description => "A list of all hashes with count",
      :show_header => true,
      :query => {
        :columns => [
          { :name => 'hash_count', :aggregate => 'SUM', :as => 'count' },
          { :name => 'hash_hash', :as => 'hash' },
          { :name => 'c_password', :as => 'password' },
          { :name => 'c_hash_type', :as => "hash_type" },
        ],
        :orderby => {
          :column=>'count',
          :dir=>'DESC'
        },
        :groupby => 'hash_hash',
      }
    }

    files << {
      :filename => "downloads/uncracked_hashes_with_count.csv.bz2",
      :description => "A list of uncracked hashes with count",
      :show_header => true,
      :query => {
        :columns => [
          { :name => 'hash_count', :aggregate => 'SUM', :as => 'count' },
          { :name => 'hash_hash', :as => 'hash' },
          { :name => 'c_password', :as => 'password' },
          { :name => 'c_hash_type', :as => "hash_type" },
        ],
        :orderby => {
          :column=>'count',
          :dir=>'DESC'
        },
        :groupby => 'hash_hash',
        :where => "`hash_password_id`='0'"
      }
    }

    # Loop through the breaches and add files for each of them
    Breaches.query_ex().each do |breach|
      name_clean = breach['breach_name'].downcase.sub(' ', '_').sub(/[^a-zA-Z0-9_-]/, '')

      # Hashes for the breach
      files << {
        :filename => "downloads/#{name_clean}_hashes.csv.bz2",
        :description => "Hashes from " + breach['breach_name'],
        :show_header => false,
        :query => {
          :columns => [
            { :name => 'hash_hash', :as => 'hash' },
          ],
          :orderby => {
            :column=>'hash_hash',
            :dir=>'ASC'
          },
          :groupby => "hash_hash",
          :where => "hash_breach_id = '#{breach['breach_id']}'"
        }
      }

      # Uncracked hashes for the breach
      files << {
        :filename => "downloads/#{name_clean}_uncracked_hashes.csv.bz2",
        :description => "Uncracked hashes from " + breach['breach_name'],
        :show_header => false,
        :query => {
          :columns => [
            { :name => 'hash_hash', :as => 'hash' },
          ],
          :orderby => {
            :column=>'hash_hash',
            :dir=>'ASC'
          },
          :groupby => "hash_hash",
          :where => "hash_breach_id = '#{breach['breach_id']}' AND `hash_password_id` = '0'"
        }
      }
    end

    # Loop through the hash types and add files for each of them
    HashTypes.query_ex({ :where => "`c_total_passwords` != 0" }).each do |hash_type|
      name_clean = hash_type['hash_type_english_name'].downcase.sub(' ', '_').sub(/[^a-zA-Z0-9_-]/, '')

      # Hashes for the hash type
      files << {
        :filename => "downloads/#{name_clean}_hashes.csv.bz2",
        :description => "Hashes of type " + hash_type['hash_type_english_name'],
        :show_header => false,
        :query => {
          :columns => [
            { :name => 'hash_hash', :as => 'hash' },
          ],
          :orderby => {
            :column=>'hash_hash',
            :dir=>'ASC'
          },
          :groupby => "hash_hash",
          :where => "hash_hash_type_id = '#{hash_type['hash_type_id']}'"
        }
      }

      # Uncracked hashes for the hash_type
      files << {
        :filename => "downloads/#{name_clean}_uncracked_hashes.csv.bz2",
        :description => "Uncracked hashes of type " + hash_type['hash_type_english_name'],
        :show_header => false,
        :query => {
          :columns => [
            { :name => 'hash_hash', :as => 'hash' },
          ],
          :orderby => {
            :column=>'hash_hash',
            :dir=>'ASC'
          },
          :groupby => "hash_hash",
          :where => "hash_hash_type_id = '#{hash_type['hash_type_id']}' AND `hash_password_id` = '0'"
        }
      }
    end

    return files
  end
end

