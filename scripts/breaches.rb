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
    query("UPDATE `breach` SET `c_total_hashes`='0', `c_distinct_hashes`='0'")
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

    # TODO: This doesn't actually work
#    puts("Updating breach.c_hash_types (different types of hashes used)...")
#    query("UPDATE `breach` SET `c_hash_types`=''")
#    query("
#      UPDATE `breach` AS `b1`
#        JOIN (
#          SELECT `hash_breach_id`, CONCAT(`hash_type_name`) AS `c_hash_types`
#          FROM `hash` JOIN `hash_type` ON `hash_hash_type_id`=`hash_type_id`
#          GROUP BY `hash_breach_id`
#        ) AS `sub` ON `b1`.`breach_id` = `sub`.`hash_breach_id`
#      SET `b1`.`c_hash_types` = `sub`.`c_hash_types`
#    ")
  end
end

