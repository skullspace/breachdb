echo "drop database breachdb; create database breachdb;" | mysql -u root -p
bzcat breachdb-with-data.sql.bz2 | mysql -u root -p -D breachdb
echo "grant select, update, insert on breachdb.* to 'breachdb'@'localhost';" | mysql -u root -p

