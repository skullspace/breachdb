#!/bin/sh

# Set up the testing variables
TEST_HOST='localhost'
TEST_USERNAME='breachdb_test'
TEST_PASSWORD='breachdb_test'
TEST_DB='breachdb_test'

# Create the database structure
cat ../db/breachdb.sql | mysql -h $TEST_HOST -u $TEST_USERNAME --password=$TEST_PASSWORD -D $TEST_DB

# Populate the hashes table
echo -ne "19\n../db/hash_types.csv\n0\n" | ruby -C ../scripts ../scripts/breachdb_admin.rb localhost breachdb_test breachdb_test breachdb_test


