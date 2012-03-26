#!/usr/bin/ruby -w
# import_dictionary.rb
#
# Created by Ron Bowes (SkullSpace Winnipeg)
# January 5, 2011

require "mysql"
require "/home/ron/auth.rb"

def get_cracker(my, name)
    result = my.query("SELECT `cracker_id`
                        FROM `cracker`
                        WHERE `cracker_name`= '#{Mysql::quote(name)}'
                    ");
	if(result.num_rows() > 0) then
    	result.each_hash() do |cracker|
        	return cracker['cracker_id']
    	end
	end

	my.query("INSERT INTO `cracker`
		(`cracker_name`)
			VALUES 
		('#{Mysql::quote(name)}')")
	return my.insert_id()
end


if(ARGV.length != 3) then
	puts("Usage: #{$0} <cracker_name|id> <date> <ip> < submissions.txt\n")
	exit();
end

my = Mysql::new("localhost", DB_USERNAME, DB_PASSWORD, "breachdb")

submissions = []
i = 0
total_count = 0
STDIN.read.split("\n").each do |submission|
	i = i + 1

	submissions << submission
end
puts("Importing #{submissions.size()} submissions...")

# Get the cracker
cracker = ARGV[0];
if(ARGV[0] =~ /^[0-9]+$/)
	cracker = ARGV[0]
else
	cracker = get_cracker(my, ARGV[0])
end

puts("Cracker = #{cracker}")
exit


# Get the submissions in 20,000-word batches
i = 1
slice_size = rand(10000) + 20000
submissions.each_slice(slice_size) do |submissions_slice|
	puts("Importing submissions #{i} to #{i+slice_size}...")
	i = i + slice_size

	query = []
	submissions_slice.each() do |submission|
		query << "('#{Mysql::quote(submission)}', '#{Mysql::quote(cracker)}', '#{Mysql::quote(ARGV[1])}', '#{Mysql::quote(ARGV[2])}')"
	end

	my.query("INSERT INTO `submission`
		(`submission_word`, `submission_cracker_id`, `submission_date`, `submission_ip`)
			VALUES #{query.join(',')}")
end

