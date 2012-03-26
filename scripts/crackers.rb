require 'rubygems'
require 'mysql'
require 'breachdb'

class Crackers < Breachdb
  def self.table_name()
    return 'cracker'
  end
  def self.id_column
    return 'cracker_id'
  end

  def self.add(name)
    query("INSERT INTO `cracker` (`cracker_name`)
      VALUES
        ('#{name}')
      ")

    return @@my.insert_id().to_s
  end

  def self.cache_update()
    puts("Updating cracker.c_total_hashes and cracker.c_distinct_hashes...")
    query("UPDATE `cracker` SET `c_total_hashes`='0', `c_distinct_hashes`='0'")
    query("
      UPDATE `cracker` AS `b1`
        JOIN (
          SELECT `hash_cracker_id`, SUM(`hash_count`) AS `c_total_hashes`, COUNT(*) AS `c_distinct_hashes`
          FROM `hash`
          GROUP BY `hash_cracker_id`
        ) AS `sub` ON `b1`.`cracker_id` = `sub`.`hash_cracker_id`
      SET
        `b1`.`c_total_hashes` = `sub`.`c_total_hashes`,
        `b1`.`c_distinct_hashes` = `sub`.`c_distinct_hashes`
    ")
  end
end
