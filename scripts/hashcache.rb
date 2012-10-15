require 'rubygems'
require 'mysql'
require 'breachdb'

class HashCache < Breachdb
  def self.table_name()
    return 'hash_cache'
  end

  def self.id_column
    return 'hash_cache_id'
  end

  def self.cache_update()
    puts("Creating hash_cache table...")
    query("DELETE FROM `hash_cache`")
    query("
            INSERT INTO `hash_cache`
            (
              `hash_cache_hash_hash`,
              `hash_cache_password_id`,
              `hash_cache_password_password`,
              `hash_cache_hash_type_id`,
              `hash_cache_hash_type_name`,
              `hash_cache_hash_count`
            )
            (
              SELECT 
                `hash_hash`              AS `hash_cache_hash_hash`,
                `password_id`            AS `hash_cache_password_id`,
                `password_password`      AS `hash_cache_password_password`,
                `hash_type_id`           AS `hash_cache_hash_type_id`,
                `hash_type_english_name` AS `hash_cache_hash_type_name`,
                SUM(`hash_count`)        AS `hash_cache_hash_count`

              FROM `hash` 
                LEFT JOIN `password`  ON `hash_password_id`=`password_id`
                LEFT JOIN `hash_type` ON `hash_hash_type_id`=`hash_type_id`

              WHERE `hash_type_id` > 0
              GROUP BY `hash_hash`
            );
    ")
  end

  def self.export_files()
    files = []

    files << {
      :filename => "downloads/hashes.csv.bz2",
      :description => "Hashes",
      :show_header => false,
      :query => {
        :columns => [
          { :name => 'hash_cache_hash_hash' },
        ],
      }
    }

    files << {
      :filename => "downloads/uncracked_hashes.csv.bz2",
      :description => "Uncracked hashes",
      :show_header => false,
      :query => {
        :columns => [
          { :name => 'hash_cache_hash_hash' },
        ],
        :where => "`hash_cache_password_id`='0'"
      }
    }

    files << {
      :filename => "downloads/hashes_with_password.csv.bz2",
      :description => "Hashes with passwords",
      :show_header => true,
      :query => {
        :columns => [
          { :name => 'hash_cache_hash_hash',         :as => "hash" },
          { :name => 'hash_cache_password_password', :as => "password" },
        ],
        :where   => '`hash_cache_password_id` != 0'
      }
    }

    files << {
      :filename => "downloads/hashes_with_type.csv.bz2",
      :description => "Hashes with type",
      :show_header => true,
      :query => {
        :columns => [
          { :name => 'hash_cache_hash_hash',      :as => "hash" },
          { :name => 'hash_cache_hash_type_name', :as => "hash_type" },
        ],
      }
    }

    files << {
      :filename => "downloads/uncracked_hashes_with_type.csv.bz2",
      :description => "Uncracked hashes with types",
      :show_header => true,
      :query => {
        :columns => [
          { :name => 'hash_cache_hash_hash',      :as => "hash" },
          { :name => 'hash_cache_hash_type_name', :as => "hash_type" },
        ],
        :where => "`hash_cache_password_id`='0'"
      }
    }

    files << {
      :filename => "downloads/hashes_with_count.csv.bz2",
      :description => "Hashes with count",
      :show_header => true,
      :query => {
        :columns => [
          { :name => 'hash_cache_hash_count',        :as => 'count'     },
          { :name => 'hash_cache_hash_hash',         :as => 'hash'      },
          { :name => 'hash_cache_password_password', :as => 'password'  },
          { :name => 'hash_cache_hash_type_name',    :as => "hash_type" },
        ],
        :orderby => {
          :column => 'count',
          :dir    => 'DESC'
        },
      }
    }

    files << {
      :filename => "downloads/uncracked_hashes_with_count.csv.bz2",
      :description => "Uncracked hashes with count",
      :show_header => true,
      :query => {
        :columns => [
          { :name => 'hash_cache_hash_count',        :as => 'count'     },
          { :name => 'hash_cache_hash_hash',         :as => 'hash'      },
          { :name => 'hash_cache_password_password', :as => 'password'  },
          { :name => 'hash_cache_hash_type_name',    :as => "hash_type" },
        ],
        :orderby => {
          :column=>'count',
          :dir=>'DESC'
        },
        :where => "`hash_cache_password_id`='0'"
      }
    }

    # Loop through the hash types and add files for each of them
    HashTypes.query_ex({ :where => "`c_total_passwords` != 0" }).each do |hash_type|
      name_clean = get_filename(hash_type['hash_type_english_name'])

      # Hashes for the hash type
      files << {
        :filename => "downloads/#{name_clean}_hashes.csv.bz2",
        :description => "Hashes of type " + hash_type['hash_type_english_name'],
        :show_header => false,
        :query => {
          :columns => [
            { :name => 'hash_cache_hash_hash', :as => 'hash' },
          ],
          :where => "hash_cache_hash_type_id = '#{hash_type['hash_type_id']}'"
        }
      }

      # Uncracked hashes for the hash_type
      files << {
        :filename => "downloads/#{name_clean}_uncracked_hashes.csv.bz2",
        :description => "Uncracked hashes of type " + hash_type['hash_type_english_name'],
        :show_header => false,
        :query => {
          :columns => [
            { :name => 'hash_cache_hash_hash', :as => 'hash' },
          ],
          :where => "hash_cache_hash_type_id = '#{hash_type['hash_type_id']}' AND `hash_cache_password_id` = 0"
        }
      }
    end

    return files
  end
end

