<?php
	# queries.php
	# Written by Ron Bowes (SkullSpace Winnipeg)
	# Created January 9, 2011
	require_once("config.php");

	function queries_init()
	{
		$conDB = mysql_pconnect(DBHOST, DBUSERNAME, DBPASSWORD);
		mysql_select_db(DBNAME, $conDB);
		return $conDB;
	}

	function get_hash_types($conDB)
	{
		$result = mysql_query("
			SELECT `hash_type_name` AS `name`,
					`hash_type_is_salted` AS `is_salted`,
					COUNT(`hash_id`) AS `count`
				FROM `hash_type`
					LEFT JOIN
						`hash` ON `hash_type_id`=`hash_hash_type_id`");

		$result = array();
		while($row = mysql_fetch_assoc($result))
			array_push($result, $row)

		return $result;
	}
?>
