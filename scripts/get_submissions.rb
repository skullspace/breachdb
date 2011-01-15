#!/usr/bin/ruby -w
# get_submissions
#
# Created by Ron Bowes (SkullSpace Winnipeg)
# January 5, 2011

require "mysql"

if(ARGV.length != 3) then
	puts("Usage: #{$0} <dbuser> <dbpass> <include_done>\n")
	exit();
end

my = Mysql::new("localhost", ARGV[0], ARGV[1], "breachdb")

# Get a handle to the submission
if(ARGV[2] == '1') then
	submission = my.query("SELECT *
					FROM `submission`") 
else
	submission = my.query("SELECT *
					FROM `submission`
					WHERE `submission_done`='0'") 
end

i = 0
puts("%s %s %s %s %s" % ['ID'.ljust(8), 'Date'.ljust(16), 'IP'.ljust(16), 'Cracker'.ljust(24), 'Word'])
puts("%s %s %s %s %s" % ['--'.ljust(8), '----'.ljust(16), '--'.ljust(16), '-------'.ljust(24), '----'])
submission.each_hash { |r|
    puts("%s %s %s %s %s" % [r['submission_id'].ljust(8), r['submission_date'].ljust(16), r['submission_ip'].ljust(16), r['submission_cracker_name'].ljust(24), r['submission_word']])
	i = i + 1
}
puts("Exported %d submissions" % i)

