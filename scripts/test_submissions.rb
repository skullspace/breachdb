#!/usr/bin/ruby -w
# test_submissions.rb
#
# Created by Ron Bowes (SkullSpace Winnipeg)
# January 5, 2011

require 'rubygems'
require 'openpgp' # required for sha-224
require 'mysql'


if(ARGV.length != 3) then
	STDERR.puts("Usage: #{$0} <dbuser> <dbpass> <path to john/run>\n")
	exit();
end

my = Mysql::new("localhost", ARGV[0], ARGV[1], "breachdb")

# Remove john.pot
STDERR.puts("Removing john.pot")
begin File.delete("%s/john.pot" % ARGV[2]) rescue Exception end

# Get the list of submissions and write it to a temp file
STDERR.puts("Loading submissions into a temp file...");
submission_file = File.new("%s/submissions.tmp" % ARGV[2], 'w')
submission = my.query("SELECT `submission_word`, `submission_cracker_name`, MIN(`submission_date`) AS `submission_date`
					FROM `submission`
					WHERE `submission_done`='0'
					GROUP BY `submission_word` ") 
submissions = {}
submission.each_hash() do |submission|
	submissions[submission['submission_word']] = submission
	submission_file << ("%s\n" % submission['submission_word'])
end
submission_file.close()
STDERR.puts("Loaded %d submissions" % submissions.size)
sleep(1);

# We're going to divide this into groups
start = 0
count = 400000

while(true) do
	# Get a list of all uncracked hashes along with their types
	STDERR.puts("Loading uncracked hashes #{start} to #{start + count}...")
	hashes = my.query("SELECT `hash_type_john_name` AS `name`, `hash_hash` AS `hash`, `hash_type_is_internal` AS `is_internal`
						FROM `hash`
							JOIN `hash_type` ON `hash_type_id`=`hash_hash_type_id`
						WHERE `hash_password_id` = '0'
						LIMIT #{start}, #{count}")
	start = start + count

	if(hashes.num_rows() == 0) then
		STDERR.puts("Done!");
		exit(0);
	end

	# Devide the hashes into john_hashes and internal_hashes
	STDERR.puts("Loaded #{hashes.num_rows()} hashes, saving them into memory...")
	john_hashes = []
	internal_hashes = []
	hashes.each_hash() do |hash|
		if(hash['is_internal'] == '0') then
			john_hashes << hash
		else
			internal_hashes << hash
		end
	end

	STDERR.puts("Loaded %d hashes for john, and %d hashes that john can't handle" % [john_hashes.size, internal_hashes.size])
	sleep(1);

	# Create temporary files for each john hash
	hash_types = []
	files = {}
	STDERR.puts("Building temporary files file john the ripper to crack");
	john_hashes.each() do |hash|
		if(hash['is_internal'] == '0') then
			# Check if we already have the hash
			if(not(files[hash['name']])) then
				STDERR.puts("Creating temp file for %s" % hash['name'])
				files[hash['name']] = File.new("%s/%s.tmp" % [ARGV[2], hash['name']], 'w')
			end
	
			files[hash['name']] << ("%s\n" % hash['hash'])
		end
	end
	# Close our temporary john files
	files.each_value() do |file|
		file.close()
	end
	STDERR.puts("Created %d temp files" % files.size)
	sleep(1)
	
	# Now, start up an instance of john for each of its hash types that are present
	STDERR.puts("Starting up %d john the ripper instances (%s)" % [files.size, files.keys.join(', ')])
	files.each do |hash_type, file|
		STDERR.puts("Starting john for hash_type: %s" % hash_type)
		pid = fork()
		if(!pid) then
			exec("%s/john --wordlist=%s/submissions.tmp --format=%s --session=%s %s > /dev/null 2>&1" % [ARGV[2], ARGV[2], hash_type, hash_type, file.path])
			exit()
		end
	end
	
	# Wait for john to finish
	Process.waitall()
	
	# Delete the files we were using
	files.each_value() do |file|
		File.delete(file.path)
	end
	
	STDERR.puts("john the ripper finished!\n")
	sleep(1)
	
	# Loop through the john.pot file and extract all the passwords
	passwords = {}
	pot = File.new("%s/john.pot" % ARGV[2], 'r')
	i = 0;
	pot.read.split("\n").each do |line|
		hash, password = line.split(/:/, 2)
		i = i + 1
		if(passwords[password]) then
			passwords[password] << hash
		else
			passwords[password] = [hash]
		end
	end
	STDERR.puts("Loaded %d different passwords john.pot" % i)
	sleep(1)
	
	# Now go through the hashtypes that john can't handle
	submission_hashes = {}
	STDERR.puts("Hashing %d submissions that john can't handle..." % submissions.size())
	submissions.values().each() do |submission|
		submission_hashes[OpenPGP::Digest::SHA224.digest(submission['submission_word']).unpack("H*").shift.downcase] = submission['submission_word']
		submission_hashes[OpenPGP::Digest::SHA256.digest(submission['submission_word']).unpack("H*").shift.downcase] = submission['submission_word']
		submission_hashes[OpenPGP::Digest::SHA384.digest(submission['submission_word']).unpack("H*").shift.downcase] = submission['submission_word']
		submission_hashes[OpenPGP::Digest::SHA512.digest(submission['submission_word']).unpack("H*").shift.downcase] = submission['submission_word']
	end
	
	# Now loop through the hashes and see if we have any
	STDERR.puts("Looking up %d hashes that john can't handle" % internal_hashes.size())
	i = 0
	internal_hashes.each() do |hash|
		if(submission_hashes[hash['hash']]) then
			i = i + 1
			password = submission_hashes[hash['hash']]
			if(passwords[password]) then
				passwords[password] << hash['hash']
			else
				passwords[password] = [hash['hash']]
			end
		end
	end
	STDERR.puts("Successfully found %d unique passwords internally" % i)
	sleep(1)

	# Make a list of all the passwords we've found in sql format to see which ones are in the table already
	password_list = []
	hash_list = []
	passwords.each() do |password, hashes|
		password_list << ("'%s'" % Mysql.quote(password))
		hashes.each() do |hash|
			hash_list = hash_list << ("'%s'" % Mysql.quote(hash))
		end
	end

	STDERR.puts("Looking up %d passwords..." % password_list.size())
	passwords_result = my.query("SELECT `password_password`
									FROM `password`
									WHERE `password_password` IN (#{password_list.join(',')})");
	passwords_to_insert = passwords.keys()
	STDERR.puts("We have %d passwords to insert of which %d are already in the database" % [passwords_to_insert.size(), passwords_result.num_rows()])
	passwords_result.each_hash() do |password|
		passwords_to_insert.delete(password['password_password'])
	end

	# Now insert the passwords if there are any (don't bother keeping track of IDs, we're going to
	# sort that out later)
	if(passwords_to_insert.size() > 0) then
		values = []
		passwords_to_insert.each() do |password|
			values << "('#{Mysql.quote(password)}', '#{Mysql.quote(submissions[password]['submission_cracker_name'])}', '#{Mysql.quote(submissions[password]['submission_date'])}')"
		end
		STDERR.puts("Inserting %d new passwords into the password list" % values.size())
		my.query("INSERT INTO `password` 
					(`password_password`, `password_cracker`, `password_date`)
				VALUES #{values.join(',')}")
	else
		STDERR.puts("All passwords are already in the database, carrying on")
	end

	# Get the ID for all the passwords we need to look up
	password_get_ids = []
	passwords.keys().each() do |password|
		password_get_ids << "'#{Mysql.quote(password)}'"
	end
	STDERR.puts("Looking up %d passwords" % password_get_ids.size())
	password_id_result = my.query("SELECT `password_id`, `password_password`
								FROM `password`
								WHERE `password_password` IN (#{password_get_ids.join(',')})")
	passwords_by_id = {}
	password_id_result.each_hash() do |result|
		passwords_by_id[result['password_id']] = passwords[result['password_password']]
	end
	STDERR.puts("Finished looking up passwords!")
	sleep(1)

	# Convert the hashes to ids
	STDERR.puts("Looking up %d hashes" % [hash_list.size()])
	hash_ids = {}
	hashes_result = my.query("SELECT `hash_id`, `hash_hash`
								FROM `hash`
								WHERE `hash_hash` IN (#{hash_list.join(',')})");

	STDERR.puts("Found %d matching hashes" % hashes_result.num_rows())
	hashes_result.each_hash() do |result|
		hash_ids[result['hash_hash']] = result['hash_id']
	end
	STDERR.puts("Finished looking up hashes!")
	sleep(1)

	# Now it's time to update all of the hashes to point at their password
	STDERR.puts("Updating hashes to point at their respective passwords...")
	updates = []
	passwords_by_id.each() do |password_id, hashes| 
		hashes.each() do |hash|
			updates << "WHEN '#{Mysql.quote(hash_ids[hash])}' THEN '#{Mysql.quote(password_id)}'\n"
		end
	end
	my.query("UPDATE `hash`
				SET `hash_password_id` = CASE `hash_id`
					#{updates.join(' ')}
				END
			WHERE `hash_id` IN (#{hash_ids.values().join(',')})")
	STDERR.puts("Done updating hashes!")
	sleep(1)
end

STDERR.puts("Deleting temporary submissions file")
File.delete(submission_file.path)

# TODO: Mark submissions as completed

STDERR.puts("Done!")
