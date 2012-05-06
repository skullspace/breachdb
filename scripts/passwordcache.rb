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
                `password_id`            AS `password_cache_password_id`,
                `password_password`      AS `password_cache_password_password`,
                `breach_id`              AS `password_cache_breach_id`,
                `breach_name`            AS `password_cache_breach_name`,
                `mask_id`                AS `password_cache_mask_id`,
                `mask_mask`              AS `password_cache_mask_mask`,
                `hash_type_id`           AS `password_cache_hash_type_id`,
                `hash_type_english_name` AS `password_cache_hash_type_name`,
                SUM(`hash_count`)        AS `password_cache_hash_count`
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
    return [
      {
        :filename => "data/passwords.txt.bz2",
        :description => "A list of all passwords",
        :show_header => false,
        :query => 
          {
            :columns => [
              { :name => 'password_cache_password_password' },
            ],
            :groupby => 'password_cache_password_id',
            :orderby => 'password_cache_password_password',
          }
      },
      {
        :filename => "data/passwords_with_count.txt.bz2",
        :description => "A list of all passwords",
        :show_header => true,
        :query => 
          {
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
      },
#      {
#        :filename => "data/passwords_with_hash.txt.bz2",
#        :description => "A list of all passwords with their associated hashes",
#        :query => 
#          {
#            :columns => [
#              { :name => 'password_cache_hash_hash', :as => 'hash' },
#              { :name => 'password_cache_password_password', :as => 'password' },
#            ],
#            :orderby => {
#              :column=>'hash',
#              :dir=>'DESC'
#            },
#            :groupby => 'password_cache_hash_hash',
#          }
#      },
#      {
#        :filename => "data/passwords_with_details.txt.bz2",
#        :description => "[TODO] A list of all passwords",
#        :query => 
#          {
#            :columns => [
#              { :name => 'password_cache_password_count', :aggregate => 'SUM', :as => 'count' },
#              { :name => 'password_cache_password_password', :as => 'password' },
#            ],
#            :orderby => {
#              :column=>'count',
#              :dir=>'DESC'
#            },
#            :groupby => 'password_cache_password_id',
#          }
#      },
    ]
  end
end

