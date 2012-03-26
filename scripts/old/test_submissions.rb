#!/usr/bin/ruby -w
# test_submissions.rb
#
# Created by Ron Bowes (SkullSpace Winnipeg)
# January 5, 2011

require 'rubygems'
require 'openpgp' # required for sha-224
require 'mysql'
require "/home/ron/auth.rb"
require "twitter"


# Soft reset:
# update hash set hash_password_id = 0;delete from password;alter table password auto_increment=1;update submission set submission_done = 0;
#
# Hard reset:
# delete from hash; delete from password; delete from submission; delete from breach; alter table hash auto_increment=1; alter table password auto_increment=1; alter table submission auto_increment=1; alter table breach auto_increment = 1;
#
# Create a little bit of test data:
# update submission set submission_done = 0 ORDER BY rand() LIMIT 10000; update hash join password on hash_password_id = password_id join submission on submission_word = password_password set hash_password_id = 0 where submission_done = 0;
#
# Imports:
# ./import_breach.rb breachdb_admin 646fd1417dd417183e715f30807852288561921b35bcc3fd5a300ff5eb067210 'awakenedlands.com' 0000-00-00 '' '' raw-md5 < ~/import/awakenedlands-md5.txt 
# ./import_breach.rb breachdb_admin 646fd1417dd417183e715f30807852288561921b35bcc3fd5a300ff5eb067210 'gawker' 0000-00-00 '' '' crypt < ~/import/gawker-crypt.txt 
# ./import_breach.rb breachdb_admin 646fd1417dd417183e715f30807852288561921b35bcc3fd5a300ff5eb067210 'hellrising' 0000-00-00 '' '' raw-sha256 < ~/import/hellrising-sha256.txt 
# ./import_breach.rb breachdb_admin 646fd1417dd417183e715f30807852288561921b35bcc3fd5a300ff5eb067210 'rootkit.com' 0000-00-00 '' '' raw-md5 < ~/import/rootkit.com-md5.txt 
# ./import_breach.rb breachdb_admin 646fd1417dd417183e715f30807852288561921b35bcc3fd5a300ff5eb067210 'scrollwars' 0000-00-00 '' '' raw-md5 < ~/import/scrollwars-md5.txt 
# ./import_breach.rb breachdb_admin 646fd1417dd417183e715f30807852288561921b35bcc3fd5a300ff5eb067210 'phpbb' 0000-00-00 '' '' raw-md5 < ~/import/phpbb-md5.txt 



SUBMISSION_READ_SIZE = 50000
HASH_GROUP_SIZE      = 200000

def log(text)
	STDERR.puts("[#{Time.now()}] #{text}")
end

def submissions_remove_duplicates(my)
	log("> Checking for duplicate submissions...")

	done_result = my.query("SELECT `submission_id`
				FROM `submission`
				WHERE `submission_done`='0' 
					AND `submission_word` IN
				(
					SELECT `submission_word`
					FROM `submission`
					WHERE `submission_done`='1'
				)
			");

	if(done_result && done_result.num_rows() > 0) then
		done_list = [];
		done_result.each_hash() do |result|
			done_list << "'#{Mysql.quote(result['submission_id'])}'"
		end
		log(">>> Found #{done_list.count} submissions that have already been completed! Removing...");

		my.query("UPDATE `submission`
					SET `submission_done`='1'
					WHERE `submission_id` IN
						(#{done_list.join(',')})
				");
	end

end

def get_submission_count(my)
	# Get the list of submissions and write it to a temp file
	log("> Getting submission count...");

	submission = my.query("SELECT COUNT(DISTINCT `submission_word`) AS `count`
						FROM `submission`
						WHERE `submission_done`='0'
					");
	submission.each_hash() do |submission|
		return submission['count'].to_i
	end
end

# @return submissions A table with the index of the submission word and a value of a submission row
# @return submission_words An array of submission words
def get_submissions(my, john_path)
	# Get the list of submissions and write it to a temp file
	log("> Loading submissions...");

	submission = my.query("SELECT `t1`.*
						FROM `submission` AS `t1`
							LEFT JOIN `submission` AS `t2` ON (`t1`.`submission_word` = `t2`.`submission_word` AND `t2`.submission_date < t1.submission_date)
						WHERE t1.`submission_done`='0'
							AND `t2`.`submission_id` IS NULL LIMIT #{SUBMISSION_READ_SIZE}
					")

	submissions = {}
	submission_words = []
	if(submission.num_rows() == 0) then
		log("> No further submissionus!")
		return nil
	end

	submission_ids = []
	submission.each_hash() do |submission|
		submissions[submission['submission_word']] = submission
		submission_words << submission['submission_word']
	end
	log("> Loaded %d submissions" % submissions.size)

	return [submissions, submission_words]
end

def get_breach_id(my, breach_name_or_id)
	breach_id_sql = '1=1';
	if(breach_name_or_id) then
		if(breach_name_or_id.match(/^[0-9]+$/)) then
			breach_id = breach_name_or_id
		else
    		breach_result = my.query("
            		SELECT `breach_id`
            		FROM `breach`
            		WHERE
                		`breach_name`='#{Mysql.quote(breach_name_or_id)}' 
            		LIMIT 0, 1")
    		if(breach_result.num_rows() == 0) then
        		log("> Breach #{breach_id} not found!")
        		exit(1)
    		else
        		breach_id = breach_result.fetch_hash()['breach_id']
    		end
		end
		breach_id_sql = "`hash_breach_id`='#{Mysql.quote(breach_id)}'"
	end
	return breach_id_sql
end

def get_john_hash_ids(my, filter)
	# This excludes bcrypt hashes automatically
	hash_result = my.query("SELECT `hash_id` 
						FROM `hash`
							JOIN `hash_type` ON `hash_type_id`=`hash_hash_type_id`
						WHERE `hash_type_is_internal`='0'
							AND `hash_password_id`='0'
							AND `hash_type_difficulty`<9
							AND #{filter}
						ORDER BY rand()")

	if(hash_result.num_rows() == 0) then
		log(">> No john hashes!");
		return []
	end

	john_hash_ids = []
	hash_result.each_hash() do |hash|
		john_hash_ids << hash['hash_id']
	end

	log(">> Loaded %d uncracked hashes for john" % [john_hash_ids.size()])

	return john_hash_ids
end

def get_internal_hash_ids(my, filter)
	hash_result = my.query("SELECT `hash_id` 
						FROM `hash`
							JOIN `hash_type` ON `hash_type_id`=`hash_hash_type_id`
						WHERE `hash_type_is_internal`!='0'
							AND `hash_password_id`='0'
							AND #{filter}
						ORDER BY rand()")

	if(hash_result.num_rows() == 0) then
		log(">> No internal hashes!");
		return []
	end

	internal_hash_ids = []
	hash_result.each_hash() do |hash|
		internal_hash_ids << hash['hash_id']
	end

	log(">> Loaded %d uncracked hashes for internal" % [internal_hash_ids.size()])

	return internal_hash_ids
end

def get_hashes_from_ids(my, hash_ids)
	hash_ids_sql = []
	hashes = []
	hash_ids.each() do |hash_id|
		hash_ids_sql << "'#{Mysql.quote(hash_id)}'"
	end

	log(">> Looking up %d hashes....." % hash_ids.size())
	result = my.query("SELECT *
					FROM `hash`
						JOIN `hash_type` ON `hash_hash_type_id`=`hash_type_id`
					WHERE `hash_id` IN
						(#{hash_ids_sql.join(',')})")

	result.each_hash() do |row|
		hashes << row
	end
	log(">>> Found %d hashes!" % hashes.size())
	return hashes
end

def crack_john_hashes(my, hash_ids, submission_words, john_path)
	hashes = get_hashes_from_ids(my, hash_ids)

	# Create the submission file
	submission_file = File.new("%s/submissions.tmp" % john_path, 'w')
	submission_words.each() do |submission_word|
		submission_file << ("%s\n" % submission_word)
	end
	submission_file.close()

	passwords = {}
	if(hashes.size() > 0) then
		potfile = '%s/breachdb.pot' % john_path

		# Create temporary files for each john hash
		log(">> Building temporary files file john the ripper to crack");

		files = {}
		counts = {}
		hashes.each() do |hash|
			# Create a file for this hash type if it doesn't already exist
			if(not(files[hash['hash_type_john_name']])) then
				files[hash['hash_type_john_name']] = File.new("%s/%s.tmp" % [john_path, hash['hash_type_john_name']], 'w')
			end

			if(not(counts[hash['hash_type_john_name']])) then
				counts[hash['hash_type_john_name']] = 0
			end
			counts[hash['hash_type_john_name']] += 1

			# Add the hash to the file
			files[hash['hash_type_john_name']] << ("%s\n" % hash['hash_hash'])
		end

		# Close our temporary john files so we can actually work on them
		files.each_value() do |file|
			file.close()
		end
		
		# Now, start up an instance of john for each of the hash types that are present
		log(">> Starting up %d john the ripper instances (%s)....." % [files.size, files.keys.join(', ')])
		counts.each() do |hash_type, count|
			log(">>> %s: %d hashes" % [hash_type, count])
		end

		files.each do |hash_type, file|
			pid = fork()
			if(!pid) then
				#exec("%s/john --pot=%s --wordlist=%s/submissions.tmp --format=%s --session=%s %s" % [john_path, potfile, john_path, hash_type, hash_type, file.path])
				exec("%s/john --pot=%s --wordlist=%s/submissions.tmp --format=%s --session=%s %s > /dev/null 2>&1" % [john_path, potfile, john_path, hash_type, hash_type, file.path])
				exit()
			end
		end
			
		# Wait for john to finish
		Process.waitall()
	
		log(">>> john the ripper finished!\n")
		
		# Loop through the john.pot file and extract all the passwords
		pot = File.new(potfile, 'r')
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

		# Close and delete the potfile
		pot.close()
		File.delete(potfile)

		log(">> Loaded %d different passwords from %s" % [i, potfile])
	else
		log(">> No john-crackable hashes were in this batch")
	end

	return passwords
end

def crack_internal_hashes(my, hash_ids, submission_words)
	hashes = get_hashes_from_ids(my, hash_ids)
	
	passwords = {}
	if(hashes.size() > 0) then
		submission_hashes = {}
		log(">> Hashing %d submissions that john can't handle..." % hashes.size())
		submission_words.each() do |word|
			submission_hashes[OpenPGP::Digest::SHA224.digest(word).unpack("H*").shift.downcase]       = word
			submission_hashes[OpenPGP::Digest::SHA256.digest(word).unpack("H*").shift.downcase]       = word
			submission_hashes[OpenPGP::Digest::SHA384.digest(word).unpack("H*").shift.downcase]       = word
			submission_hashes[OpenPGP::Digest::SHA512.digest(word).unpack("H*").shift.downcase]       = word
			submission_hashes[OpenPGP::Digest::MD5.digest(word).unpack("H*").shift.downcase]          = word
			submission_hashes[OpenPGP::Digest::MD5.digest('123456').unpack('H*').shift.downcase[0,8]] = word
		end
	
		# Now loop through the hashes and see if we have any
		log(">> Looking up %d hashes that john can't handle" % hashes.size())
		i = 0
		hashes.each() do |hash|
			if(submission_hashes[hash['hash_hash']]) then
				i = i + 1
				password = submission_hashes[hash['hash_hash']]
				if(passwords[password]) then
					passwords[password] << hash['hash_hash']
				else
					passwords[password] = [hash['hash_hash']]
				end
			end
		end
		log(">> Successfully found %d unique passwords internally" % i)
	else
		log(">> No internal hashes were in this batch")
	end

	return passwords
end

def save_cracks(my, cracks, submissions, filter)
	if(cracks.keys().size() == 0) then
		return
	end

	# Get lists of our cracked passwords and hashes in a MySQL-safe format
	password_list = []
	hash_list = []
	cracks.each do |password, hashes|
		password_list = password_list << "'#{Mysql.quote(password)}'"
		hashes.each() do |hash|
			hash_list << ("'%s'" % Mysql.quote(hash))
		end
	end

	# This will tell us which passwords are already in the database
	log(">> Determining which passwords to insert and which to update...")
	passwords_result = my.query("SELECT `password_password`
									FROM `password`
									WHERE `password_password` IN (#{password_list.join(',')})");
	passwords_to_insert = cracks.keys()
	passwords_result.each_hash() do |password|
		passwords_to_insert.delete(password['password_password'])
	end
	log("> We have %d cracks: %d to insert and %d to update" % [cracks.size, passwords_to_insert.size, cracks.size - passwords_to_insert.size])

	# Now we insert the new passwords (we're going to update the id values later)
	if(passwords_to_insert.size() > 0) then
		new_passwords = []
		passwords_to_insert.each() do |password|
			# Find the matching submission. This becomes difficult with a hashtype with a maximum length, because they can
			# be shorter than expected. 
			submission = submissions[password]
			if(!submission) then
				key = submissions.keys().detect() do |value|
					value[0, password.length] == password
				end
				submission = submissions[key]
			end

			new_passwords << "('#{Mysql.quote(password)}', '#{Mysql.quote(submission['submission_cracker_id'])}', '#{Mysql.quote(submission['submission_date'])}')"
		end
		my.query("INSERT INTO `password`
					(`password_password`, `password_cracker_id`, `password_date`)
				VALUES #{new_passwords.join(',')}")

		log(">> Inserted #{new_passwords.size()} passwords!")
	end

	# Now, we want the IDs of all passwords in our cracks list
	password_query = []
	cracks.keys().each() do |password|
		password_query << "'#{Mysql.quote(password)}'"
	end
	log(">> Looking up %d passwords....." % password_query.size())
	password_id_result = my.query("SELECT `password_id`, `password_password`
								FROM `password`
								WHERE `password_password` IN (#{password_query.join(',')})")
	# Put them into a table - the index is the password and the value is the id
	passwords_by_word = {}
	password_id_result.each_hash() do |row|
		passwords_by_word[row['password_password']] = row['password_id']
	end
	log(">>> Found %d passwords!" % password_id_result.num_rows())

	# Do the same thing with hashes - look them up then put them in a table
	log(">> Looking up %d hashes....." % hash_list.size())
	hash_id_result = my.query("SELECT `hash_id`, `hash_hash`
								FROM `hash`
								WHERE `hash_hash` IN (#{hash_list.join(',')})")
	# Put them into a table - the index is the hash and the value is the id
	hashes_by_hash = {}
	hash_id_result.each_hash() do |row|
		hashes_by_hash[row['hash_hash']] = row['hash_id']
	end
	log(">>> Found %d hashes!" % hash_id_result.num_rows())

	# Get the update part of the 'case' statement
	updates = []
	cracks.each() do |password, hashes|
		password_id = passwords_by_word[password]
		if(!password_id) then
			log("ERROR: Couldn't look up password #{password}")
		else
			hashes.each() do |hash|
				if(!hashes_by_hash[hash]) then
					STDERR.puts("ERROR: Couldn't find hash_id for hash: #{hash}")
				end

				updates << "WHEN '#{Mysql.quote(hashes_by_hash[hash])}' THEN '#{Mysql.quote(password_id)}'\n"
			end
		end
	end
	
	# Now update the hashes to point at their respective passwords
	log(">> Updating %d hashes to point to their respective passwords..." % updates.size)
	my.query("UPDATE `hash`
				SET `hash_password_id` = CASE `hash_id`
					#{updates.join(' ')}
				END
			WHERE `hash_id` IN (#{hashes_by_hash.values().join(',')})
				AND #{filter}")
	log(">>> Update complete!")
end

def mark_submissions_done(my, submission_words)
	log("> Marking submissions as complete...");
	words_sql = []

	submission_words.each() do |word|
		words_sql << "'#{Mysql.quote(word)}'"
	end

	my.query("UPDATE `submission`
		SET `submission_done`='1'
		WHERE `submission_word` IN
			(#{words_sql.join(',')})")
end

def get_stats(my, hashes)
	if(hashes.count() == 0) then
		return nil;
	end

	log("> Gather statistical information...")
	query = []
	hashes.each do |hash|
		query << "'#{Mysql.quote(hash)}'"
	end

	result = my.query("SELECT `password_password`, sum(`hash_count`) AS `hash_count`
				FROM `hash`
					JOIN `password` ON `hash_password_id` = `password_id`
				WHERE `hash_hash` IN ( #{query.join(',')} )
				GROUP BY `hash_password_id`
				ORDER BY `hash_count` DESC
				LIMIT 1
			")
	result.each_hash() do |row|
		popular_password = row['password_password']
		popular_password_count = row['hash_count']
	end

	result = my.query("SELECT `breach_name`, COUNT(`hash_breach_id`) AS `breach_count`
				FROM `hash`
					JOIN `breach` ON `hash_breach_id`=`breach_id`
				WHERE `hash_hash` IN ( #{query.join(',')} )
				GROUP BY `hash_breach_id`
				ORDER BY `breach_count` DESC
				LIMIT 1
			")
	result.each_hash() do |row|
		popular_breach = row['breach_name']
		popular_breach_count = row['breach_count']
	end

	return [popular_password, popular_password_count, popular_breach, popular_breach_count]
end

if(ARGV.length != 1 and ARGV.length != 2) then
	log("Usage: #{$0} <path to john/run> [breach_id]\n")
	log("breach_id is the name (or id) of the breach - used if we only");
	log("want to test submissions against a single breach. If it's set,");
	log("submission_done will still be updated.");
	exit();
end

# Certain methods require authentication. To get your Twitter OAuth credentials,
# register an app at http://dev.twitter.com/apps
Twitter.configure do |config|
  config.consumer_key = CONSUMER_KEY
  config.consumer_secret = CONSUMER_SECRET
  config.oauth_token = OAUTH_TOKEN
  config.oauth_token_secret = OAUTH_TOKEN_SECRET
end

my = Mysql::new('localhost', DB_USERNAME, DB_PASSWORD, 'breachdb')

breach_id_sql = get_breach_id(my, ARGV[1])

submissions_remove_duplicates(my)
submission_count = get_submission_count(my);

passwords_for_count = {}
hashes_for_count = {}
submission_num = 0

loop do
	submissions_all, submission_words_all = get_submissions(my, ARGV[0])
	if(submissions_all.nil?) then
		break;
	end
	if(submissions_all.size() == 0) then
		log("Done!");
	end

	submission_words_all.each_slice(SUBMISSION_READ_SIZE) do |submission_words|
		hash_num = 0
		john_hash_ids_all = get_john_hash_ids(my, breach_id_sql)
		john_hash_ids_all.each_slice(HASH_GROUP_SIZE) do |john_hash_ids|
			log("PROCESSING: submissions %d -> %d of %s: john hash %d -> %d of %d" % [
					submission_num,
					[submission_num + SUBMISSION_READ_SIZE, submission_count].min,
					submission_count,
					hash_num,
					[hash_num + HASH_GROUP_SIZE, john_hash_ids_all.size()].min,
					john_hash_ids_all.size()
				])
			hash_num += HASH_GROUP_SIZE
	
			john_cracks = crack_john_hashes(my, john_hash_ids, submission_words, ARGV[0])
			save_cracks(my, john_cracks, submissions_all, breach_id_sql)

			# This loop is purely for collecting statistical data
			john_cracks.each do |password, hashes|
				passwords_for_count[password] = (passwords_for_count[password] ? passwords_for_count[password] + 1 : 1);
				hashes.each() do |hash|
					hashes_for_count[hash] = (hashes_for_count[hash] ? hashes_for_count[hash] + 1 : 1);
				end
			end
		end
	
		hash_num = 0
		internal_hash_ids_all = get_internal_hash_ids(my, breach_id_sql)
		internal_hash_ids_all.each_slice(HASH_GROUP_SIZE) do |internal_hash_ids|
			log("PROCESSING: submissions %d -> %d of %s: internal hash %d -> %d of %d" % [
					submission_num,
					[submission_num + SUBMISSION_READ_SIZE, submission_count].min,
					submission_count,
					hash_num,
					[hash_num + HASH_GROUP_SIZE, internal_hash_ids_all.size()].min,
					internal_hash_ids_all.size()
				])
			hash_num += HASH_GROUP_SIZE
	
			internal_cracks = crack_internal_hashes(my, internal_hash_ids, submission_words)
			save_cracks(my, internal_cracks, submissions_all, breach_id_sql)

			# This loop is purely for collecting statistical data
			internal_cracks.each do |password, hashes|
				passwords_for_count[password] = (passwords_for_count[password] ? passwords_for_count[password] + 1 : 1);
				hashes.each() do |hash|
					hashes_for_count[hash] = (hashes_for_count[hash] ? hashes_for_count[hash] + 1 : 1);
				end
			end
		end
	
		mark_submissions_done(my, submission_words)
	end
	submission_num += SUBMISSION_READ_SIZE;
end

if(hashes_for_count.keys().size() > 0 && passwords_for_count.keys().size() > 0) then
	# Initialize your Twitter client
	twitter = Twitter::Client.new

	password, password_count, breach, breach_count = get_stats(my, hashes_for_count.keys());
	status = "Integrated %d submissions: cracked %d new passwords - mostly from %s - top was '%s' w/ %d hashes)" % [submission_count, hashes_for_count.keys().size(), passwords_for_count.keys().size(), breach, password, password_count]
	log(status)
	twitter.update(status)
end

