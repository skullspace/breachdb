#!/usr/bin/ruby -w
# import_dictionary.rb
#
# Created by Ron Bowes (SkullSpace Winnipeg)
# January 5, 2011

require "mysql"

if(ARGV.length != 2) then
	puts("Usage: #{$0} <dbuser> <dbpass>\n\n");
	exit();
end

# TODO: Sanity check the arguments

my = Mysql::new("localhost", ARGV[0], ARGV[1], "breachdb")

# Make sure the words are unique
result = my.query("SELECT * FROM `hash_type` ORDER BY `hash_type_id` ASC")

puts("%s %s %s %s %s %s %s" % ['ID'.ljust(5), 'John Name'.ljust(12), 'Name'.ljust(40), 'Dif.'.ljust(4), 'Avg c/s'.ljust(12), 'Internal?'.ljust(10), 'Salted?'])
puts("%s %s %s %s %s %s %s" % ['--'.ljust(5), '---------'.ljust(12), '----'.ljust(40), '----'.ljust(4), '-------'.ljust(12), '---------'.ljust(10), '-------'])
result.each_hash { |r|
	puts("%s %s %s %s %s %s %s" % [r['hash_type_id'].ljust(5), r['hash_type_john_name'].ljust(12), r['hash_type_english_name'].ljust(40), r['hash_type_difficulty'].ljust(4), r['hash_type_john_test_speed'].ljust(12), (r['hash_type_is_internal'] != '0' ? 'TRUE' : 'FALSE').ljust(10), r['hash_type_is_salted'] != '0' ? 'TRUE' : 'FALSE'])
}

