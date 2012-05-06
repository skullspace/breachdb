require 'rubygems'
require 'mysql'
require 'breachdb'

class PasswordCache < Breachdb
  def self.table_name()
    return 'password_cache'
  end

  def self.id_column
    return 'password_cache_id'
  end

  def self.cache_update()
    puts("Creating password_cache table...")
    query("DELETE FROM `password_cache`")
    query("
            INSERT INTO `password_cache`
            (
              `password_cache_password_id`,
              `password_cache_password_password`,
              `password_cache_breach_id`,
              `password_cache_breach_name`,
              `password_cache_mask_id`,
              `password_cache_mask_mask`,
              `password_cache_hash_type_id`,
              `password_cache_hash_type_name`,
              `password_cache_password_count`,
              `password_cache_hash_hash`
            )
            (
              SELECT 
                `password_id`            AS `password_cache_password_id`,
                `password_password`      AS `password_cache_password_password`,
                `breach_id`              AS `password_cache_breach_id`,
                `breach_name`            AS `password_cache_breach_name`,
                `mask_id`                AS `password_cache_mask_id`,
                `mask_mask`              AS `password_cache_mask_mask`,
                `hash_type_id`           AS `password_cache_hash_type_id`,
                `hash_type_english_name` AS `password_cache_hash_type_name`,
                SUM(`hash_count`)        AS `password_cache_hash_count`,
                `hash_hash`              AS `password_cache_hash_hash`
              FROM `password` 
                LEFT JOIN `hash`      ON `hash_password_id`=`password_id`
                LEFT JOIN `breach`    ON `hash_breach_id`=`breach_id`
                LEFT JOIN `mask`      ON `password_mask_id`=`mask_id`
                LEFT JOIN `hash_type` ON `hash_hash_type_id`=`hash_type_id`
              GROUP BY `breach_id`, `password_id`
            );
    ")
  end

  def self.export_files()
    # Add some basic password stuff
    files = []

    files << {
      :filename => "data/passwords.csv.bz2",
      :description => "A list of all passwords",
      :show_header => false,
      :query => {
        :columns => [
          { :name => 'password_cache_password_password' },
        ],
        :groupby => 'password_cache_password_id',
        :orderby => 'password_cache_password_password',
      }
    }

    files << {
      :filename => "data/passwords_with_count.csv.bz2",
      :description => "A list of all passwords with count",
      :show_header => true,
      :query => {
        :columns => [
          { :name => 'password_cache_password_count', :aggregate => 'SUM', :as => 'count' },
          { :name => 'password_cache_password_password', :as => 'password' },
        ],
        :orderby => {
          :column=>'count',
          :dir=>'DESC'
        },
        :groupby => 'password_cache_password_id',
      }
    }

    files << {
      :filename => "data/passwords_with_hash.csv.bz2",
      :description => "A list of all passwords with their associated hashes",
      :show_header => true,
      :query => {
        :columns => [
          { :name => 'password_cache_password_count',    :as => 'count' },
          { :name => 'password_cache_hash_type_name',    :as => 'hash_type' },
          { :name => 'password_cache_hash_hash',         :as => 'hash' },
          { :name => 'password_cache_password_password', :as => 'password' },
        ],
        :orderby => {
          :column=>'hash',
          :dir=>'ASC'
        },
        :groupby => 'password_cache_hash_hash',
      }
    }

    files << {
      :filename => "data/passwords_with_details.csv.bz2",
      :description => "A list of all passwords with detailed information",
      :show_header => true,
      :query => {
        :columns => [
          { :name => 'password_cache_password_count',    :as => 'count' },
          { :name => 'password_cache_password_password', :as => 'password' },
          { :name => 'password_cache_hash_hash',         :as => 'hash' },
          { :name => 'password_cache_breach_name',       :as => 'breach' },
          { :name => 'password_cache_mask_mask',         :as => 'mask' },
          { :name => 'password_cache_hash_type_name',    :as => 'hash_type' },
        ],
        :orderby => {
          :column=>'password_cache_password_password',
          :dir=>'ASC'
        }
      }
    }

    # Loop through the breaches and add files for each of them
    Breaches.query_ex().each do |breach|
      name_clean = breach['breach_name'].downcase.sub(' ', '_').sub(/[^a-zA-Z0-9_-]/, '')

      # Passwords for the breach
      files << {
        :filename => "data/#{name_clean}_passwords.csv.bz2",
        :description => "Cracked passwords from " + breach['breach_name'],
        :show_header => false,
        :query => {
          :columns => [
            { :name => 'password_cache_password_password', :as => 'password' },
          ],
          :orderby => {
            :column=>'password_cache_password_password',
            :dir=>'ASC'
          },
          :groupby => "password_cache_password_id",
          :where => "password_cache_breach_id = '#{breach['breach_id']}'"
        }
      }

      # Passwords + counts for the breach
      files << {
        :filename => "data/#{name_clean}_passwords_with_count.csv.bz2",
        :description => "Cracked passwords from " + breach['breach_name'] + " with count",
        :show_header => true,
        :query => {
          :columns => [
            { :name => 'password_cache_password_count', :aggregate => 'SUM', :as => 'count' },
            { :name => 'password_cache_password_password', :as => 'password' },
          ],
          :orderby => {
            :column=>'count',
            :dir=>'DESC'
          },
          :groupby => 'password_cache_password_id',
          :where => "password_cache_breach_id = '#{breach['breach_id']}'"
        },
      }

      files << {
        :filename => "data/#{name_clean}_passwords_with_hash.csv.bz2",
        :description => "Cracked passwords from " + breach['breach_name'] + " with hash",
        :show_header => true,
        :query => {
          :columns => [
            { :name => 'password_cache_password_count',    :as => 'count' },
            { :name => 'password_cache_hash_type_name',    :as => 'hash_type' },
            { :name => 'password_cache_hash_hash',         :as => 'hash' },
            { :name => 'password_cache_password_password', :as => 'password' },
          ],
          :orderby => {
            :column=>'hash',
            :dir=>'ASC'
          },
          :groupby => 'password_cache_hash_hash',
          :where => "password_cache_breach_id = '#{breach['breach_id']}'"
        }
      }

      files << {
        :filename => "data/#{name_clean}_passwords_with_details.csv.bz2",
        :description => "Cracked passwords from " + breach['breach_name'] + " with details",
        :show_header => true,
        :query => {
          :columns => [
            { :name => 'password_cache_password_count',    :as => 'count' },
            { :name => 'password_cache_password_password', :as => 'password' },
            { :name => 'password_cache_hash_hash',         :as => 'hash' },
            { :name => 'password_cache_breach_name',       :as => 'breach' },
            { :name => 'password_cache_mask_mask',         :as => 'mask' },
            { :name => 'password_cache_hash_type_name',    :as => 'hash_type' },
          ],
          :orderby => {
            :column=>'password_cache_password_password',
            :dir=>'ASC'
          },
          :where => "password_cache_breach_id = '#{breach['breach_id']}'"
        }
      }
    end

    # Loop through the hash types and add files for each of them
    HashTypes.query_ex({ :where => "`c_total_passwords` != 0" }).each do |hash_type|
      name_clean = hash_type['hash_type_english_name'].downcase.sub(' ', '_').sub(/[^a-zA-Z0-9_-]/, '')

      # Passwords for the hash_type
      files << {
        :filename => "data/#{name_clean}_passwords.csv.bz2",
        :description => "Cracked passwords of type " + hash_type['hash_type_english_name'],
        :show_header => false,
        :query => {
          :columns => [
            { :name => 'password_cache_password_password', :as => 'password' },
          ],
          :orderby => {
            :column=>'password_cache_password_password',
            :dir=>'ASC'
          },
          :groupby => "password_cache_password_id",
          :where => "password_cache_hash_type_id = '#{hash_type['hash_type_id']}'"
        }
      }

      # Passwords + counts for the hash_type
      files << {
        :filename => "data/#{name_clean}_passwords_with_count.csv.bz2",
        :description => "Cracked passwords of type " + hash_type['hash_type_english_name'] + " with count",
        :show_header => true,
        :query => {
          :columns => [
            { :name => 'password_cache_password_count', :aggregate => 'SUM', :as => 'count' },
            { :name => 'password_cache_password_password', :as => 'password' },
          ],
          :orderby => {
            :column=>'count',
            :dir=>'DESC'
          },
          :groupby => 'password_cache_password_id',
          :where => "password_cache_hash_type_id = '#{hash_type['hash_type_id']}'"
        },
      }

      files << {
        :filename => "data/#{name_clean}_passwords_with_hash.csv.bz2",
        :description => "Cracked passwords of type " + hash_type['hash_type_english_name'] + " with hash",
        :show_header => true,
        :query => {
          :columns => [
            { :name => 'password_cache_password_count',    :as => 'count' },
            { :name => 'password_cache_hash_type_name',    :as => 'hash_type' },
            { :name => 'password_cache_hash_hash',         :as => 'hash' },
            { :name => 'password_cache_password_password', :as => 'password' },
          ],
          :orderby => {
            :column=>'hash',
            :dir=>'ASC'
          },
          :groupby => 'password_cache_hash_hash',
          :where => "password_cache_hash_type_id = '#{hash_type['hash_type_id']}'"
        }
      }

      files << {
        :filename => "data/#{name_clean}_passwords_with_details.csv.bz2",
        :description => "Cracked passwords of type " + hash_type['hash_type_english_name'] + " with details",
        :show_header => true,
        :query => {
          :columns => [
            { :name => 'password_cache_password_count',    :as => 'count' },
            { :name => 'password_cache_password_password', :as => 'password' },
            { :name => 'password_cache_hash_hash',         :as => 'hash' },
            { :name => 'password_cache_breach_name',       :as => 'breach' },
            { :name => 'password_cache_mask_mask',         :as => 'mask' },
            { :name => 'password_cache_hash_type_name',    :as => 'hash_type' },
          ],
          :orderby => {
            :column=>'password_cache_password_password',
            :dir=>'ASC'
          },
          :where => "password_cache_hash_type_id = '#{hash_type['hash_type_id']}'"
        }
      }
    end

    return files
  end
end

