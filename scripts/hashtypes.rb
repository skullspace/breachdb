require 'rubygems'
require 'mysql'
require 'breachdb'

class HashTypes < Breachdb
  def self.table_name()
    return 'hash_type'
  end
  def self.id_column
    return 'hash_type_id'
  end

  def self.cache_update()
    puts("Updating hash_type.c_total_hashes and hash_type.c_distinct_hashes...")
    query("UPDATE `hash_type` SET `c_total_hashes`='0', `c_distinct_hashes`='0'")
    query("
      UPDATE `hash_type` AS `b1`
        JOIN (
          SELECT `hash_hash_type_id`, SUM(`hash_count`) AS `c_total_hashes`, COUNT(*) AS `c_distinct_hashes`
          FROM `hash`
          GROUP BY `hash_hash_type_id`
        ) AS `sub` ON `b1`.`hash_type_id` = `sub`.`hash_hash_type_id`
      SET
        `b1`.`c_total_hashes` = `sub`.`c_total_hashes`,
        `b1`.`c_distinct_hashes` = `sub`.`c_distinct_hashes`
    ")

    # TODO: I'm not positive that c_distinct_passwords is right...
    puts("Updating hash_type.c_total_passwords and hash_type.c_distinct_passwords...")
    query("UPDATE `hash_type` SET `c_total_passwords`='0', `c_distinct_passwords`='0'")
    query("
      UPDATE `hash_type` AS `b1`
        JOIN (
          SELECT `hash_hash_type_id`, SUM(`hash_count`) AS `c_total_passwords`, COUNT(*) as `c_distinct_passwords`
          FROM `hash`
          WHERE `hash_password_id`!='0'
          GROUP BY `hash_hash_type_id`
        ) AS `sub` ON `b1`.`hash_type_id` = `sub`.`hash_hash_type_id`
      SET
        `b1`.`c_total_passwords` = `sub`.`c_total_passwords`,
        `b1`.`c_distinct_passwords` = `sub`.`c_distinct_passwords`
    ")
  end
end

