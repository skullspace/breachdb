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

  def self.import_csv(filename)
    lines = {}
      lines['hash_type_id']                     = []
      lines['hash_type_difficulty']             = []
      lines['hash_type_john_test_speed']        = []
      lines['hash_type_name']                   = []
      lines['hash_type_is_salted']              = []
      lines['hash_type_is_internal']            = []
      lines['hash_type_pattern']                = []
      lines['hash_type_hash_example']           = []
      lines['hash_type_hash_example_plaintext'] = []
      lines['hash_type_notes']                  = []

    IO.readlines(filename).each do |line|
      line.chomp!
      id, difficulty, john_test_speed, dummy, name, is_salted, is_internal, pattern, hash_example, hash_example_plaintext, notes = line.split(/\|/)

puts(id)
      lines['hash_type_id']                     << (id.nil?                     ? '' : id)
      lines['hash_type_difficulty']             << (difficulty.nil?             ? '' : difficulty)
      lines['hash_type_john_test_speed']        << (john_test_speed.nil?        ? '' : john_test_speed)
      lines['hash_type_name']                   << (name.nil?                   ? '' : name)
      lines['hash_type_is_salted']              << (is_salted.nil?              ? '' : is_salted)
      lines['hash_type_is_internal']            << (is_internal.nil?            ? '' : is_internal)
      lines['hash_type_pattern']                << (pattern.nil?                ? '' : pattern)
      lines['hash_type_hash_example']           << (hash_example.nil?           ? '' : hash_example)
      lines['hash_type_hash_example_plaintext'] << (hash_example_plaintext.nil? ? '' : hash_example_plaintext)
      lines['hash_type_notes']                  << (notes.nil?                  ? '' : notes)
    end

puts(lines.inspect)

    query("DELETE FROM `#{table_name}`")
    insert_rows(lines)
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

