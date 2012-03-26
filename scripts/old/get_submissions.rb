#!/usr/bin/ruby -w
# get_submissions
#
# Created by Ron Bowes (SkullSpace Winnipeg)
# January 5, 2011

require "mysql"
require "/home/ron/auth.rb"

if(ARGV.length != 1 && ARGV.length != 2) then
	puts("Usage: #{$0} <include_done> [max_rows=10000]\n")
	exit();
end

my = Mysql::new('localhost', DB_USERNAME, DB_PASSWORD, 'breachdb')

max_rows = ARGV.length == 2 ? ARGV[1] : '10000';

# Get a handle to the submission
if(ARGV[0] == '1') then
	submission = my.query("SELECT *
					FROM `submission` LEFT JOIN `cracker` ON `submission_cracker_id`=`cracker_id`
					LIMIT #{Mysql::quote(max_rows)}") 
else
	submission = my.query("SELECT *
					FROM `submission` LEFT JOIN `cracker` ON `submission_cracker_id`=`cracker_id`
					WHERE `submission_done`='0'
					LIMIT #{Mysql::quote(max_rows)}") 
end

i = 0
puts("%s %s %s %s %s" % ['ID'.ljust(8), 'Date'.ljust(16), 'IP'.ljust(16), 'Cracker'.ljust(24), 'Word'])
puts("%s %s %s %s %s" % ['--'.ljust(8), '----'.ljust(16), '--'.ljust(16), '-------'.ljust(24), '----'])
submission.each_hash { |r|
	r['cracker_name'] = r['cracker_name'] ? r['cracker_name'] : ''
    puts("%s %s %s %s %s" % [r['submission_id'].ljust(8), r['submission_date'].ljust(16), r['submission_ip'].ljust(16), r['cracker_name'].ljust(24), r['submission_word']])
	i = i + 1
}
puts("Exported %d submissions (use second argument to change)" % i)

