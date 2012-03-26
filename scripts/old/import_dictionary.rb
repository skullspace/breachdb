#!/usr/bin/ruby -w
# import_dictionary.rb
#
# Created by Ron Bowes (SkullSpace Winnipeg)
# January 5, 2011

require "mysql"

if(ARGV.length != 6) then
	puts("Usage: #{$0} <dbuser> <dbpass> <name> <date> <notes> <format> < words.txt\n")
	puts("Possible values of format:")
	puts("1: Each line is a single word. The 'count' is set based on how many")
	puts("   times a word appears in the input")
	puts("2: Each line is in the format count:word. If word appears multiple")
	puts("   times, the counts are summed")
	puts("3: Each line is a single word, and it should be unique; if the same")
	puts("   word is seen more than once, an error is printed")
	puts("4: Each line has the format count in front, padded to 8 characters")
	puts("   with spaces, followed by the password. This is the default output")
	puts("   of uniq -c")
	puts("")
	exit();
end

my = Mysql::new("localhost", ARGV[0], ARGV[1], "breachdb")
my.query("INSERT INTO `dictionary`
	(`dictionary_name`, `dictionary_date`, `dictionary_notes`)
		VALUES 
	(
		'#{Mysql::quote(ARGV[2])}', 
		'#{Mysql::quote(ARGV[3])}', 
		'#{Mysql::quote(ARGV[4])}'
	)")
id = my.insert_id()

puts("Created a new dictionary with the id #{id}")

words = {}
i = 0
total_count = 0
STDIN.read.split("\n").each do |word|
	i = i + 1

	count = 1
	if(ARGV[5] == '2') then
		line = word
		count, word = line.split(/:/, 2)
		if(!word) then
			puts("ERROR: The following line isn't in the proper count:word format:")
			puts(line)
			exit(1)
		end
	elsif(ARGV[5] == '4') then
		line = word
		parsed = line.match(/^(........)(.*)$/)
		count  = parsed[1].to_i
		word   = parsed[2]
	end

	total_count = total_count + count.to_i
	if(words[word]) then
		if(ARGV[5] == '3') then
			puts("ERROR: The word #{word} appears multiple times! Aborting...")
			exit(1)
		end
		words[word] = words[word] + count.to_i
	else
		words[word] = count.to_i
	end
end
puts("Importing #{i} lines with a total of #{words.keys().size()} distinct words and a count of #{total_count}...")

# Get the words in 20,000-word batches
i = 1
slice_size = rand(10000) + 20000
words.keys().each_slice(slice_size) do |words_slice|
	puts("Importing words #{i} to #{i+slice_size}...")
	i = i + slice_size

	query = []
	words_slice.each() do |word|
		query << "('#{id}', '#{Mysql::quote(word)}', '#{words[word]}')"
	end

	my.query("INSERT INTO `dictionary_word`
		(`dictionary_word_dictionary_id`, `dictionary_word_word`, `dictionary_word_count`)
			VALUES #{query.join(',')}")
end

