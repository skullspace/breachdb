require 'rubygems'
require 'mysql'
require 'breachdb'

class Breaches < Breachdb
  def self.table_name()
    return 'breach'
  end

  def self.id_column
    return 'breach_id'
  end

  def self.cache_update()
    puts("Updating breach.c_total_hashes and breach.c_distinct_hashes...")
    query("UPDATE `breach` SET `c_total_hashes`='0', `c_distinct_hashes`='0', `c_total_passwords`='0', `c_distinct_passwords`='0'")
    query("
      UPDATE `breach` AS `b1`
        JOIN (
          SELECT `hash_breach_id`, SUM(`hash_count`) AS `c_total_hashes`, COUNT(*) AS `c_distinct_hashes`
          FROM `hash`
          GROUP BY `hash_breach_id`
        ) AS `sub` ON `b1`.`breach_id` = `sub`.`hash_breach_id`
      SET
        `b1`.`c_total_hashes` = `sub`.`c_total_hashes`,
        `b1`.`c_distinct_hashes` = `sub`.`c_distinct_hashes`
    ")

    puts("Updating breach.c_total_passwords and breach.c_distinct_passwords...")
    query("
      UPDATE `breach` AS `b1`
        JOIN (
          SELECT `hash_breach_id`, SUM(`hash_count`) AS `c_total_passwords`, COUNT(*) AS `c_distinct_passwords`
          FROM `hash` JOIN `password` ON `hash_password_id`=`password_id`
          WHERE `hash_password_id` != 0
          GROUP BY `hash_breach_id`
        ) AS `sub` ON `b1`.`breach_id` = `sub`.`hash_breach_id`
      SET
        `b1`.`c_total_passwords` = `sub`.`c_total_passwords`,
        `b1`.`c_distinct_passwords` = `sub`.`c_distinct_passwords`
    ")
  end

  def self.export_files()
    files = []

    files << {
      :filename => "downloads/breaches.csv.bz2",
      :description => "Breaches",
      :show_header => true,
      :query => {
        :columns => [
          { :name => 'breach_name',       :as => 'name' },
          { :name => 'breach_date',       :as => 'date' },
          { :name => 'breach_url',        :as => 'url' },
          { :name => 'c_total_hashes',    :as => 'total_hashes' },
          { :name => 'c_distinct_hashes', :as => 'distinct_hashes' },
          { :name => 'c_total_passwords', :as => 'cracked_passwords' },
          { :name => 'c_distinct_hashes', :as => 'distinct_cracked_passwords' },
        ],
        :orderby => 'breach_name',
      }
    }
  end
end

