echo "Exporting the structure..."
mysqldump -u root -p --no-data breachdb_test | sed 's/AUTO_INCREMENT=[0-9]*//' > breachdb.sql
#echo "Exporting the data..."
#mysqldump -u root -p breachdb | bzip2 - > breachdb-with-data.sql.bz2 

