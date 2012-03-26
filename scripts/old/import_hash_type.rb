#!/usr/bin/ruby -w
# create_hash_type.rb
#
# Created by Ron Bowes (SkullSpace Winnipeg)
# January 5, 2011

require "mysql"

if(ARGV.length != 2) then
	puts("Usage: #{$0} <dbuser> <dbpass> < hash_types.txt\n\n");
	puts("Where hash_types.txt is a pipe-separated file in the following format:\n");
	puts("<id>|<difficulty>|<c/s>|<john_name>|<english_name>|<is_salted>|<is_internal>|<example_hash>|<example_plaintext>|<notes>")
	exit();
end

my = Mysql::new("localhost", ARGV[0], ARGV[1], "breachdb")

STDIN.read().split("\n").each do |line|
	id, difficulty, speed, john_name, english_name, is_salted, is_internal, pattern, example_hash, example_plaintext, notes = line.split(/\|/, 11)

	result = my.query("SELECT * FROM `hash_type` WHERE `hash_type_id`='#{Mysql::quote(id)}'")
	if(result.num_rows() > 0) then
		my.query("UPDATE `hash_type` SET
			`hash_type_john_name`='#{Mysql::quote(john_name)}',
			`hash_type_english_name`='#{Mysql::quote(english_name)}',
			`hash_type_difficulty`='#{Mysql::quote(difficulty)}',
			`hash_type_john_test_speed`='#{Mysql::quote(speed)}',
			`hash_type_is_salted`='#{Mysql::quote(is_salted)}',
			`hash_type_is_internal`='#{Mysql::quote(is_internal)}',
			`hash_type_pattern`='#{Mysql::quote(pattern)}',
			`hash_type_hash_example`='#{Mysql::quote(example_hash)}',
			`hash_type_hash_example_plaintext`='#{Mysql::quote(example_plaintext)}',
			`hash_type_notes`='#{Mysql::quote(notes)}'
		WHERE
			`hash_type_id`='#{Mysql::quote(id)}'")

		puts("Successfully updated hash type #{john_name} with id = #{id}")
	else
		my.query("INSERT INTO `hash_type`
			(`hash_type_id`, `hash_type_john_name`, `hash_type_english_name`, `hash_type_difficulty`, `hash_type_john_test_speed`,
			`hash_type_is_salted`, `hash_type_is_internal`, `hash_type_hash_example`, `hash_type_hash_example_plaintext`, `hash_type_notes`)
		VALUES 
	(
		'#{Mysql::quote(id)}',
		'#{Mysql::quote(john_name)}',
		'#{Mysql::quote(english_name)}',
		'#{Mysql::quote(difficulty)}',
		'#{Mysql::quote(speed)}',
		'#{Mysql::quote(is_salted)}',
		'#{Mysql::quote(is_internal)}',
		'#{Mysql::quote(example_hash)}',
		'#{Mysql::quote(example_plaintext)}',
		'#{Mysql::quote(notes)}'
	)")
		id = my.insert_id()

		puts("Successfully added hash type #{john_name} with id = #{id}")
	end
end

