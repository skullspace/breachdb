#!/bin/sh

# Set up the testing variables
TEST_HOST='localhost'
TEST_USERNAME='breachdb_test'
TEST_PASSWORD='breachdb_test'
TEST_DB='breachdb_test'
CMD="ruby -C ../scripts ../scripts/breachdb_admin.rb $TEST_HOST $TEST_USERNAME $TEST_PASSWORD $TEST_DB"

# Create the database structure
cat ../db/breachdb.sql | mysql -h $TEST_HOST -u $TEST_USERNAME --password=$TEST_PASSWORD -D $TEST_DB

# Populate the hashes table
echo -ne "19\n../db/hash_types.csv\n0\n" | $CMD

# Import the test breaches
echo -ne "14\n20\n\nJail Lords\n\n\n\n../test/jailords-md5.txt\n1\n0\n" | $CMD
echo -ne "14\n63\n\nHell Rising\n\n\n\n../test/hellrising-sha256.txt\n1\n0\n" | $CMD
echo -ne "14\n13\n\nOmploader\n\n\n\n../test/omploader-md5.txt\n1\n0\n" | $CMD

# Import the submissions
echo -ne "11\n\n\ncracker 1\n\n\n../test/passwords-1.txt\n1\n0\n" | $CMD
echo -ne "11\n\n\ncracker 2\n\n\n../test/passwords-2.txt\n1\n0\n" | $CMD
echo -ne "11\n\n\ncracker 3\n\n\n../test/passwords-3.txt\n1\n0\n" | $CMD

# Update the caches (TODO: This shouldn't be necessary)
echo -ne "1\n0\n" | $CMD
echo -ne "1\n0\n" | $CMD
echo -ne "1\n0\n" | $CMD

# Process the hashes
echo -ne "13\n\n0\n" | $CMD

# Update the caches (TODO: Probably don't need multiple calls)
echo -ne "1\n0\n" | $CMD
echo -ne "1\n0\n" | $CMD
echo -ne "1\n0\n" | $CMD

