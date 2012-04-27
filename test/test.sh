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
echo -ne "3\nFreeHack\n\n\n\n0\n" | $CMD # Create the breach
echo -ne "14\n20\n1\n../test/freehack-md5_gen6.txt\n1\n0\n" | $CMD # Import the hashes

echo -ne "3\nHell Rising\n\n\n\n0\n" | $CMD # Create the breach
echo -ne "14\n63\n2\n../test/hellrising-sha256.txt\n1\n0\n" | $CMD # Import the hashes

echo -ne "3\nOmploader\n\n\n\n0\n" | $CMD # Create the breach
echo -ne "14\n13\n3\n../test/omploader-md5.txt\n1\n0\n" | $CMD # Import the hashes

# Import the submissions
#echo -ne 
