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

  def self.top_passwords(limit = 10)
    return result_to_list(query("
      SELECT `password_cache`.*, SUM(`password_cache_password_count`) AS `password_cache_password_count`
      FROM `password_cache`
      GROUP BY `password_cache_password_id`
      ORDER BY `password_cache_password_count` DESC
      LIMIT #{limit}
    "))
  end

  def self.top_passwords_by_breach(breach_id, limit = 10)
    return result_to_list(query("
      SELECT `password_cache`.*
      FROM `password_cache`
      WHERE `password_cache_breach_id`='#{Mysql::quote(breach_id)}'
      ORDER BY `password_cache_password_count` DESC
      LIMIT #{limit}
    "))
  end

#  def self.list_with_hash(where = nil, orderby = nil, orderby_dir = nil, page_size = nil, page = nil)
#    where = '1=1' if(where.nil?)
#    page = 1 if(page.nil? || page < 1)
#    page_size = 10 if(page_size.nil? || page_size == 0)
# 
#    if(orderby.nil?)
#      orderby = ''
#    elsif(orderby.is_a? String)
#      orderby = "ORDER BY `#{Mysql::quote(orderby)}` #{Mysql::quote(orderby_dir)}"
#    elsif(orderby.is_a? Array)
#      new_orderby = []
#      0.upto(orderby.count - 1) do |i|
#        new_orderby << "`#{Mysql::quote(orderby[i])}` #{Mysql::quote(orderby_dir[i])}"
#      end
#      orderby = "ORDER BY #{new_orderby.join(", ")}"
#    end
# 
#    # Set up the pagination code
#    limit = ''
#    if(!page_size.nil?)
#      page = page.to_i || 0
#      page_size = page_size.to_i
# 
#      limit = "LIMIT #{(page-1) * page_size}, #{page_size}"
#    end
# 
#    # Get the results
#    return result_to_list(query("
#      SELECT *, SUM(`hash_count`) AS `hash_count`
#      FROM `password` JOIN `hash` ON `password_id`=`hash_password_id`
#      #{where.nil? ? "" : "WHERE #{where}"}
#      GROUP BY `hash_password_id`
#      #{orderby}
#      #{limit}
#    "))
#  end

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
              `password_cache_password_count`
            )
            (
              SELECT 
                `password_id`       AS `password_cache_password_id`,
                `password_password` AS `password_cache_password_password`,
                `breach_id`         AS `password_cache_breach_id`,
                `breach_name`       AS `password_cache_breach_name`,
                SUM(`hash_count`)   AS `password_cache_hash_count`
              FROM `password` 
                JOIN `hash` ON `hash_password_id`=`password_id`
                JOIN `breach` ON `hash_breach_id`=`breach_id`
              GROUP BY `breach_id`, `password_id`
            );
    ")
  end
end

