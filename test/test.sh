#!/bin/sh

# Set up the testing variables
TEST_HOST='localhost'
TEST_USERNAME='breachdb_test'
TEST_PASSWORD='breachdb_test'
TEST_DB='breachdb_test'
CMD="ruby -C ../scripts ../scripts/breachdb_admin.rb $TEST_HOST $TEST_USERNAME $TEST_PASSWORD $TEST_DB"
OUTFILE="actual_output.txt"
EXPECTED="expected_output.txt"

# Create the database structure
cat ../db/breachdb.sql | mysql -h $TEST_HOST -u $TEST_USERNAME --password=$TEST_PASSWORD -D $TEST_DB

# Populate the hashes table
echo -ne "19\n../db/hash_types.csv\n0\n" | $CMD

# Import the test breaches
echo -ne "14\n13\n\nJail Lords\n\n\n\n../test/jailords-md5.txt\n1\n0\n" | $CMD
echo -ne "14\n63\n\nHell Rising\n\n\n\n../test/hellrising-sha256.txt\n1\n0\n" | $CMD
echo -ne "14\n13\n\nOmploader\n\n\n\n../test/omploader-md5.txt\n1\n0\n" | $CMD
echo -ne "14\n-1\n\nPlaintext test\n\n\n\n../test/unhashed-plaintext.txt\n1\n0\n" | $CMD

# Import the submissions
echo -ne "11\n\n\ncracker 1\n\n\n../test/passwords-1.txt\n1\n0\n" | $CMD
echo -ne "11\n\n\ncracker 2\n\n\n../test/passwords-2.txt\n2\n0\n" | $CMD
echo -ne "11\n\n\ncracker 3\n\n\n../test/passwords-3.txt\n1\n0\n" | $CMD

# Update the caches
echo -ne "1\n0\n" | $CMD

# Process the hashes
echo -ne "13\n\n0\n" | $CMD

# Create a dictionary and populate it
echo -ne "21\nTest Dictionary 1\n\n\n23\n1\n../test/dictionary-1.txt\n3\n0\n" | $CMD
echo -ne "21\nTest Dictionary 2\n\n\n23\n2\n../test/dictionary-2.txt\n3\n0\n" | $CMD
echo -ne "21\nTest Dictionary 3\n\n\n23\n3\n../test/dictionary-3.txt\n3\n0\n" | $CMD

# Update the caches
echo -ne "1\n0\n" | $CMD

# Output the database
echo '' > $OUTFILE
echo "SELECT breach_name, breach_date, breach_url, breach_notes, c_total_hashes, c_distinct_hashes, c_total_passwords, c_distinct_passwords FROM breach ORDER BY breach_name" | mysql -h $TEST_HOST -u $TEST_USERNAME --password=$TEST_PASSWORD -D $TEST_DB  | sort >> $OUTFILE
echo "SELECT cracker_name, c_total_hashes, c_distinct_hashes FROM cracker ORDER BY cracker_name" | mysql -h $TEST_HOST -u $TEST_USERNAME --password=$TEST_PASSWORD -D $TEST_DB  | sort >> $OUTFILE
echo "SELECT dictionary_name, dictionary_notes, dictionary_date, c_word_count, c_distinct_word_count FROM dictionary ORDER BY dictionary_name" | mysql -h $TEST_HOST -u $TEST_USERNAME --password=$TEST_PASSWORD -D $TEST_DB  | sort >> $OUTFILE
echo "SELECT dictionary_word_word, dictionary_word_count FROM dictionary_word ORDER BY dictionary_word_word, dictionary_word_count" | mysql -h $TEST_HOST -u $TEST_USERNAME --password=$TEST_PASSWORD -D $TEST_DB  | sort >> $OUTFILE
echo "SELECT hash_hash, hash_count, c_password, c_hash_type, c_breach_name, c_is_internal, c_difficulty FROM hash ORDER BY hash_hash, c_breach_name" | mysql -h $TEST_HOST -u $TEST_USERNAME --password=$TEST_PASSWORD -D $TEST_DB  | sort >> $OUTFILE
echo "SELECT hash_type_john_name, hash_type_english_name, hash_type_difficulty, hash_type_john_test_speed, hash_type_is_salted, hash_type_is_internal, hash_type_pattern, hash_type_hash_example, hash_type_hash_example_plaintext, hash_type_notes, c_total_hashes, c_distinct_hashes, c_total_passwords, c_distinct_passwords FROM hash_type ORDER BY hash_type_john_name" | mysql -h $TEST_HOST -u $TEST_USERNAME --password=$TEST_PASSWORD -D $TEST_DB  | sort >> $OUTFILE
echo "SELECT mask_mask, c_password_count, c_mask_example FROM mask ORDER BY mask_mask" | mysql -h $TEST_HOST -u $TEST_USERNAME --password=$TEST_PASSWORD -D $TEST_DB  | sort >> $OUTFILE
echo "SELECT news_name, news_title, news_date, news_story FROM news ORDER BY news_name" | mysql -h $TEST_HOST -u $TEST_USERNAME --password=$TEST_PASSWORD -D $TEST_DB  | sort >> $OUTFILE
echo "SELECT password_password, password_date FROM password ORDER BY password_password" | mysql -h $TEST_HOST -u $TEST_USERNAME --password=$TEST_PASSWORD -D $TEST_DB  | sort >> $OUTFILE
echo "SELECT password_cache_password_password, password_cache_breach_name, password_cache_mask_mask, password_cache_hash_type_name, password_cache_password_count, password_cache_hash_hash FROM password_cache ORDER BY password_cache_password_password" | mysql -h $TEST_HOST -u $TEST_USERNAME --password=$TEST_PASSWORD -D $TEST_DB  | sort >> $OUTFILE
echo "SELECT submission_hash, submission_hash FROM submission ORDER BY submission_hash" | mysql -h $TEST_HOST -u $TEST_USERNAME --password=$TEST_PASSWORD -D $TEST_DB  | sort >> $OUTFILE
echo "SELECT submission_batch_date, submission_batch_ip, submission_batch_done, c_submission_count, c_cracker_name FROM submission_batch ORDER BY submission_batch_date" | mysql -h $TEST_HOST -u $TEST_USERNAME --password=$TEST_PASSWORD -D $TEST_DB  | sort >> $OUTFILE

sed -i 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/####-##-##/g' $EXPECTED
sed -i 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/##:##:##/g' $EXPECTED
sed -i 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/####-##-##/g' $OUTFILE
sed -i 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/##:##:##/g' $OUTFILE

echo -n "Expected: "
md5sum $EXPECTED
echo -n "We got:   "
md5sum $OUTFILE

