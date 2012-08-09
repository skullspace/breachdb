#!/bin/sh

# Set up the testing variables
TEST_HOST='localhost'
TEST_USERNAME='breachdb_test'
TEST_PASSWORD='breachdb_test'
TEST_DB='breachdb_test'
CMD="ruby -C ../scripts ../scripts/breachdb_admin.rb $TEST_HOST $TEST_USERNAME $TEST_PASSWORD $TEST_DB"
OUTFILE="test_output.txt"
KNOWNGOOD="breachdb_test.sql"

# CURRENTLY BROKEN
exit

# Create the database structure
cat ../db/breachdb.sql | mysql -h $TEST_HOST -u $TEST_USERNAME --password=$TEST_PASSWORD -D $TEST_DB

# Populate the hashes table
echo -ne "19\n../db/hash_types.csv\n0\n" | $CMD

# Import the test breaches
echo -ne "14\n13\n\nJail Lords\n\n\n\n../test/jailords-md5.txt\n1\n0\n" | $CMD
#echo -ne "14\n63\n\nHell Rising\n\n\n\n../test/hellrising-sha256.txt\n1\n0\n" | $CMD
#echo -ne "14\n13\n\nOmploader\n\n\n\n../test/omploader-md5.txt\n1\n0\n" | $CMD
#echo -ne "14\n-1\n\nPlaintext test\n\n\n\n../test/unhashed-plaintext.txt\n1\n0\n" | $CMD

# Import the submissions
echo -ne "11\n\n\ncracker 1\n\n\n../test/passwords-1.txt\n1\n0\n" | $CMD
#echo -ne "11\n\n\ncracker 2\n\n\n../test/passwords-2.txt\n2\n0\n" | $CMD
#echo -ne "11\n\n\ncracker 3\n\n\n../test/passwords-3.txt\n1\n0\n" | $CMD

# Process the hashes
echo -ne "13\n\n0\n" | $CMD

# Create a dictionary and populate it
#echo -ne "21\nTest Dictionary 1\n\n\n23\n1\n../test/dictionary-1.txt\n3\n0\n" | $CMD
#echo -ne "21\nTest Dictionary 2\n\n\n23\n2\n../test/dictionary-2.txt\n3\n0\n" | $CMD
#echo -ne "21\nTest Dictionary 3\n\n\n23\n3\n../test/dictionary-3.txt\n3\n0\n" | $CMD

# Update the caches
#echo -ne "1\n0\n" | $CMD

# Output the database
echo '' > $OUTFILE
for i in breach cache cracker dictionary dictionary_word hash hash_type mask news password password_cache submission submission_batch; do
  echo "$i:" >> $OUTFILE
  echo "SELECT * FROM $i" | mysql -h $TEST_HOST -u $TEST_USERNAME --password=$TEST_PASSWORD -D $TEST_DB >> $OUTFILE
  echo "" >> $OUTFILE
done

echo -n "Expected: "
md5sum $KNOWNGOOD
echo -n "We got:   "
md5sum $OUTFILE

