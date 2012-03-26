require 'rubygems'
require 'mysql'
require 'breachdb'

class Masks < Breachdb
  def self.table_name()
    return 'mask'
  end
  def self.id_column
    return 'mask_id'
  end

  def self.get_mask(password)
    mask = ''
    password.split(//).each do |c|
      if(c =~ /^[a-z]$/)
        mask = mask + '?l'
      elsif(c =~ /^[A-Z]$/)
        mask = mask + '?u'
      elsif(c =~ /^[0-9]$/)
        mask = mask + '?d'
      else
        mask = mask + '?s'
      end
    end

    return mask
  end

  ##
  # Inserts the masks into the database, as necessary.
  ##
  def self.insert_if_required(masks)
    # Get the IDs for the masks that we already have
    mask_ids = Masks.get_ids('mask_mask', masks, false)

    # Figure out which masks are missing and insert them
    missing = []
    masks.each() do |p|
      if(mask_ids[p].nil?)
        missing << p
      end
    end

    if(missing.size() > 0)
      missing.collect!() do |m| "('" + Mysql::quote(m) + "')" end
      query("INSERT INTO `mask`
        (`mask_mask`)
          VALUES
        #{missing.join(',')}
      ")
    end
  end


  def self.cache_update()
    puts("Updating mask.c_password_count...")
    query("UPDATE `mask` SET `c_password_count`='0'")
    query("
      UPDATE `mask` AS `m1`
        JOIN (
          SELECT `password_mask_id`, SUM(`hash_count`) AS `c_hash_count`
            FROM `password` JOIN `hash` ON `password_id`=`hash_password_id`
          GROUP BY `password_mask_id`
        ) AS `sub` ON `m1`.`mask_id` = `sub`.`password_mask_id`
      SET `m1`.`c_password_count` = `sub`.`c_hash_count`
    ")

    puts("Updating mask.c_mask_example...")
    query("UPDATE `mask` SET `c_mask_example`=''")
    query("
      UPDATE `mask` JOIN ( SELECT * FROM `password` ORDER BY `c_hash_count`) AS a ON `password_mask_id`=`mask_id`
          SET `c_mask_example`=`password_password`
    ")
  end
end
