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

  def self.cache_update()
    puts("Generating password masks...")
    each_chunk(CHUNK_SIZE, true, {:where => "`password_mask_id`='0'"}) do |passwords|
      # Create a list of password_id->mask mappings
      masks = {}
      passwords.each do |p|
        masks[p['password_id']] = Masks.get_mask(p['password_password'])
      end

      # Ensure all the masks are in the database
      Masks.insert_if_required(masks.values)

      # Get the IDs
      mask_ids = Masks.get_ids('mask_mask', masks.values, true)

      # Update passwords to point at the proper masks
      updates = []
      masks.each() do |password_id, mask|
        mask_id = mask_ids[mask]
        updates << "WHEN '#{Mysql.quote(password_id)}' THEN '#{Mysql.quote(mask_id[0])}'"
      end

      query("UPDATE `password`
            SET `password_mask_id` = CASE `password_id`
              #{updates.join("\n")}
            END
          WHERE `password_id` IN (#{masks.keys.join(',')})")

    end
  end
end

