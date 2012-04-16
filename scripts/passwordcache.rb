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
              `password_cache_password_count`
            )
            (
              SELECT 
                `password_id`       AS `password_cache_password_id`,
                `password_password` AS `password_cache_password_password`,
                `breach_id`         AS `password_cache_breach_id`,
                `breach_name`       AS `password_cache_breach_name`,
                `mask_id`           AS `password_cache_mask_id`,
                `mask_mask`         AS `password_cache_mask_mask`,
                `hash_type_id`      AS `password_cache_hash_type_id`,
                `hash_type_name`    AS `password_cache_hash_type_name`,
                SUM(`hash_count`)   AS `password_cache_hash_count`
              FROM `password` 
                JOIN `hash`      ON `hash_password_id`=`password_id`
                JOIN `breach`    ON `hash_breach_id`=`breach_id`
                JOIN `mask`      ON `password_mask_id`=`mask_id`
                JOIN `hash_type` ON `hash_hash_type_id`=`hash_type_id`
              GROUP BY `breach_id`, `password_id`
            );
    ")
  end
end

