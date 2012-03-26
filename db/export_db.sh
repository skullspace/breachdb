echo "Exporting the structure..."
mysqldump -u root -p --no-data breachdb | bzip2 - > breachdb.sql.bz2
echo "Exporting the data..."
mysqldump -u root -p breachdb | bzip2 - > breachdb-with-data.sql.bz2 

