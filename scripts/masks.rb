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

  def self.cache_update()
    puts("Generating password masks...")
    Passwords.each_chunk(CHUNK_SIZE, true, {:where => "`password_mask_id`='0'"}) do |passwords|
      # Create a list of password_id->mask mappings
      masks = {}
      passwords.each do |p|
        # Generate the mask for this password
        mask = get_mask(p['password_password'])

        # Make each element in the masks hash an array containing all applicable passwords
        if(masks[mask].nil?)
          masks[mask] = [ p['password_id'] ]
        else
          masks[mask] << p['password_id']
        end
      end

      # Ensure all the masks are in the database
      if(masks.keys.size > 0) then
        mask_ids = insert_if_required('mask_mask', masks.keys)

      # Loop through the masks to point the password ids at the proper place
      updates = []
      masks.each() do |mask, password_ids|
        mask_id = mask_ids[mask]

          # Loop through the passwords that should point to this mask
          password_ids.each do |password_id|
            updates << "WHEN '#{Mysql.quote(password_id)}' THEN '#{Mysql.quote(mask_id[0])}'"
          end
        end

        update_query = "UPDATE `password`
              SET `password_mask_id` = CASE `password_id`
                #{updates.join("\n")}
              END
            WHERE `password_id` IN (#{masks.values.flatten.join(',')})"
        query(update_query)
      end
    end

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
      UPDATE `mask` JOIN ( SELECT * FROM `password` ORDER BY `password_password`) AS a ON `password_mask_id`=`mask_id`
          SET `c_mask_example`=`password_password`
    ")
  end

  def self.export_files()
    files = []

    files << {
      :filename => "downloads/masks.csv.bz2",
      :description => "Masks",
      :show_header => true,
      :query => {
        :columns => [
          { :name => 'mask_mask',        :as => 'mask' },
          { :name => 'c_password_count', :as => 'count' },
          { :name => 'c_mask_example',   :as => 'example' },
        ],
        :orderby => {
          :column=>'count',
          :dir=>'DESC'
        },

      }
    }
  end
end
