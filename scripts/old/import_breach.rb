#!/usr/bin/ruby -w
# import_breach.rb
#
# Created by Ron Bowes (SkullSpace Winnipeg)
# January 5, 2011

require "mysql"
require "twitter"
require "/home/ron/auth.rb"

def get_hash_type_name(my, id)
	result = my.query("
		SELECT `hash_type_english_name`
			FROM `hash_type`
			WHERE `hash_type_id`='#{Mysql.quote(id)}'
			LIMIT 1
		")

	if(result.num_rows() == 0) then
		STDERR.puts("Invalid hash type: #{id}")
		exit();
	end

	result.each_hash() do |row|
		return row['hash_type_english_name']
	end
end


def get_breach_name(my, breach_id)
	result = my.query("
		SELECT `breach_name`
			FROM `breach`
			WHERE `breach_id`='#{Mysql.quote(breach_id)}'
			LIMIT 1
		")

	result.each_hash() do |row|
		return row['breach_name']
	end
end

if(ARGV.length == 2) then
	breach_id, hash_type = ARGV[0], ARGV[1]
	name = nil
elsif(ARGV.length == 5) then
	breach_id = '0'
	name, date, url, notes, hash_type = ARGV[0], ARGV[1], ARGV[2], ARGV[3], ARGV[4]
elsif(ARGV.length == 6) then
	breach_id, name, date, url, notes, hash_type = ARGV[0], ARGV[1], ARGV[2], ARGV[3], ARGV[4], ARGV[5]
else
    puts("Usage: #{$0} [breach_id] [<name> <date> <url> <notes>] <hash_type> < passwords.txt\n\n")
    puts("Each line in passwords should be a single hashed password.")
    exit();
end

my = Mysql::new('localhost', DB_USERNAME, DB_PASSWORD, 'breachdb')

# If the user gave a hash_type name instead of id, look it up
if(hash_type != '0') then
	if(hash_type.match(/^[0-9]+$/)) then
		hash_type_id = hash_type
	else
		type_result = my.query("
				SELECT `hash_type_id`
				FROM `hash_type`
				WHERE
					`hash_type_john_name`='#{Mysql.quote(hash_type)}' 
						OR 
					`hash_type_english_name`='#{Mysql.quote(hash_type)}'
				LIMIT 0, 1")
		if(type_result.num_rows() == 0) then
			puts("Valid hash types (you can pass in the id or either name):")
			system("./get_hash_types.rb")
			exit(1)
		else
			hash_type_id = type_result.fetch_hash()['hash_type_id']
		end
	end
	
	hash_type_name = get_hash_type_name(my, hash_type_id)
	puts("Inserting hashes with hash_type_id = #{hash_type_id} (#{hash_type_name})")
end
	
# Check if we're changing the name (and therefore the other fields) of the breach
is_new_breach = true;
if(breach_id != '0') then
	is_new_breach = false;
end

if(name != nil) then
	if(breach_id != '0') then
		my.query("UPDATE `breach`
			SET
				`breach_name`='#{Mysql::quote(name)}',
				`breach_date`='#{Mysql::quote(date)}',
				`breach_url`='#{Mysql::quote(url)}',
				`breach_notes`='#{Mysql::quote(notes)}'
			WHERE
				`breach_id`='#{Mysql::quote(breach_id)}'")
	
		puts("Updated breach with the id #{breach_id}")
	else
		my.query("INSERT INTO `breach`
			(`breach_name`, `breach_date`, `breach_url`, `breach_notes`)
				VALUES 
			(
				'#{Mysql::quote(name)}', 
				'#{Mysql::quote(date)}', 
				'#{Mysql::quote(url)}',
				'#{Mysql::quote(notes)}'
			)")
		breach_id = my.insert_id()
	
		puts("Created a new breach with the id #{breach_id}")
	end
else
	puts("Breach already exists, skipping to hash import...")
end

if(hash_type == '0')
	exit()
end

i = 0
hashes = {}
puts("Reading hashes from stdin...")
display_interval = rand(10000) + 15000
STDIN.read.split("\n").each do |hash|
	i = i + 1
	if((i % display_interval) == 0)
		puts("Read #{i} hashes...")
	end

	if(hashes[hash]) then
		hashes[hash] = hashes[hash] + 1
	else
		hashes[hash] = 1
	end
end

puts("Read #{i} hashes (#{hashes.keys.size()} distinct) from stdin!")

# Save these for statistical information
hashes_imported = i
hashes_imported_distinct = hashes.keys.size()


# Split up the INSERT into large chunks
group_interval = rand(10000) + 20000
i = 1
hashes.keys().each_slice(group_interval) do |hash_group|
	puts("Importing hashes #{i} to #{[i + group_interval, hashes.keys.size()].min()}...")
	i = i + group_interval

	insert = []
	hash_group.each() do |hash|
		count = hashes[hash]
		insert << "('#{Mysql::quote(breach_id.to_s)}', '#{Mysql::quote(hash)}', '#{Mysql::quote(hash_type_id)}', '#{Mysql::quote(count.to_s)}')"
	end
	my.query("INSERT INTO `hash`
		(`hash_breach_id`, `hash_hash`, `hash_hash_type_id`, `hash_count`)
			VALUES #{insert.join(',')}")
end

# Get the breach name (in case we don't have it)
breach_name = get_breach_name(my, breach_id.to_s)
hash_type_name = get_hash_type_name(my, hash_type_id)

if(is_new_breach) then
	output = "Imported new breach: #{breach_name} (#{hashes_imported} hashes; #{hashes_imported_distinct} distinct hashes; type: #{hash_type_name})"
else
	output = "Updated breach: #{breach_name} (added #{hashes_imported} hashes; #{hashes_imported_distinct} distinct hashes; type: #{hash_type_name})"
end

puts(output)

# Certain methods require authentication. To get your Twitter OAuth credentials,
# register an app at http://dev.twitter.com/apps
Twitter.configure do |config|
  config.consumer_key = CONSUMER_KEY
  config.consumer_secret = CONSUMER_SECRET
  config.oauth_token = OAUTH_TOKEN
  config.oauth_token_secret = OAUTH_TOKEN_SECRET
end

twitter = Twitter::Client.new
twitter.update(output)


