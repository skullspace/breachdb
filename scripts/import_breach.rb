#!/usr/bin/ruby -w
# import_breach.rb
#
# Created by Ron Bowes (SkullSpace Winnipeg)
# January 5, 2011

require "mysql"

if(ARGV.length == 4) then
	breach_id, hash_type = ARGV[2], ARGV[3]
	name = nil
elsif(ARGV.length == 7) then
	breach_id = '0'
	name, date, url, notes, hash_type = ARGV[2], ARGV[3], ARGV[4], ARGV[5], ARGV[6]
elsif(ARGV.length == 8) then
	breach_id, name, date, url, notes, hash_type = ARGV[2], ARGV[3], ARGV[4], ARGV[5], ARGV[6], ARGV[7]
else
    puts("Usage: #{$0} <dbuser> <dbpass> [breach_id] [<name> <date> <url> <notes>] <hash_type> < passwords.txt\n\n")
    puts("Each line in passwords should be a single hashes password.")
    exit();
end

my = Mysql::new("localhost", ARGV[0], ARGV[1], "breachdb")

# If the user gave a hash_type name instead of id, look it up
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
		system("./get_hash_types.rb #{ARGV[0]} #{ARGV[1]}")
		exit(1)
	else
		hash_type_id = type_result.fetch_hash()['hash_type_id']
	end
end
puts("Inserting hashes with hash_type_id = #{hash_type_id}")

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
sleep(1)


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

