require 'rubygems'
require 'mysql'
require 'breachdb'

class Dictionaries < Breachdb
  def self.table_name()
    return 'dictionary'
  end
  def self.id_column
    return 'dictionary_id'
  end

  def self.cache_update()
    puts("Updating dictionary.c_word_count...")
    query("UPDATE `dictionary` SET `c_word_count`='0'")
    query("
      UPDATE `dictionary` AS `b1`
        JOIN (
          SELECT `dictionary_word_dictionary_id`, SUM(`dictionary_word_count`) AS `c_word_count`
          FROM `dictionary_word`
          GROUP BY `dictionary_word_dictionary_id`
        ) AS `sub` ON `b1`.`dictionary_id` = `sub`.`dictionary_word_dictionary_id`
      SET
        `b1`.`c_word_count` = `sub`.`c_word_count`
    ")
    
  end

  def self.export_files()
    return []
  end
end
