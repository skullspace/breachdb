require 'rubygems'
require 'mysql'
require 'breachdb'

class Passwords < Breachdb
  def self.table_name()
    return 'password'
  end
  def self.id_column
    return 'password_id'
  end

  ##
  # Inserts the passwords into the database, as necessary.
  ##
  def self.insert_if_required(passwords)
    # Get the IDs for the passwords that we already have
    password_ids = Passwords.get_ids('password_password', passwords, false)

    # Figure out which passwords are missing and insert them
    missing = []
    passwords.each() do |p|
      if(password_ids[p].nil?)
        missing << p
      end
    end

    if(missing.size() > 0)
      missing.collect!() do |m| "('" + Mysql::quote(m) + "', NOW())" end
      query("INSERT INTO `password`
        (`password_password`, `password_date`)
          VALUES
        #{missing.join(',')}
      ")
    end
  end

#  def self.top_passwords_by_breach(breach_id, limit = 10)
#    return result_to_list(query("
#      SELECT `password`.*
#      FROM `password` JOIN `hash` ON `password_id`=`hash_id`
#      ORDER BY `c_hash_count` DESC
#      LIMIT #{limit}
#    "))
#  end
# 
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
# 
#  def self.get_count_with_hash(where = nil)
#    result = result_to_list(query("
#      SELECT COUNT(*) AS `count`
#      FROM `password` JOIN `hash` ON `password_id`=`hash_password_id`
#      #{where.nil? ? '' : "WHERE #{where}"}
#    "))
#    return result.pop['count'].to_i
#  end
# 
# 
  def self.cache_update()
    # I don't think we need anything here
  end
#    puts("Updating password.c_hash_count...")
#    query("UPDATE `password` SET `c_hash_count`='0'")
#    query("
#      UPDATE `password` AS `p1`
#        JOIN (
#          SELECT `hash_password_id`, SUM(`hash_count`) AS `c_hash_count`
#          FROM `hash`
#          GROUP BY `hash_password_id`
#        ) AS `sub` ON `p1`.`password_id` = `sub`.`hash_password_id`
#      SET `p1`.`c_hash_count` = `sub`.`c_hash_count`
#    ")
# 
#    puts("Generating password masks...")
#    each_chunk(nil, CHUNK_SIZE, "`password_mask_id`='0'") do |passwords|
#      # Create a list of password_id->mask mappings
#      masks = {}
#      passwords.each do |p|
#        masks[p['password_id']] = Masks.get_mask(p['password_password'])
#      end
# 
#      # Ensure all the masks are in the database
#      Masks.insert_if_required(masks.values)
# 
#      # Get the IDs
#      mask_ids = Masks.get_ids('mask_mask', masks.values, true)
# 
#      # Update passwords to point at the proper masks
#      updates = []
#      masks.each() do |password_id, mask|
#        mask_id = mask_ids[mask]
#        updates << "WHEN '#{Mysql.quote(password_id)}' THEN '#{Mysql.quote(mask_id[0])}'"
#      end
# 
#      query("UPDATE `password`
#            SET `password_mask_id` = CASE `password_id`
#              #{updates.join("\n")}
#            END
#          WHERE `password_id` IN (#{masks.keys.join(',')})")
# 
#    end
# 
#    puts("Creating password_cache table...")
#    query("DELETE FROM `password_cache`")
#    query("
#            INSERT INTO `password_cache`
#            (
#              `password_cache_password_id`,
#              `password_cache_password_password`,
#              `password_cache_breach_id`,
#              `password_cache_breach_name`,
#              `password_cache_password_count`
#            )
#            (
#              SELECT 
#                `password_id`       AS `password_cache_password_id`,
#                `password_password` AS `password_cache_password_password`,
#                `breach_id`         AS `password_cache_breach_id`,
#                `breach_name`       AS `password_cache_breach_name`,
#                SUM(`hash_count`)   AS `password_cache_hash_count`
#              FROM `password` 
#                JOIN `hash` ON `hash_password_id`=`password_id`
#                JOIN `breach` ON `hash_breach_id`=`breach_id`
#              GROUP BY `breach_id`, `password_id`
#            );
#    ")
#  end
end

