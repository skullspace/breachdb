-- MySQL dump 10.13  Distrib 5.1.62, for pc-linux-gnu (x86_64)
--
-- Host: localhost    Database: breachdb
-- ------------------------------------------------------
-- Server version	5.1.62-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `breach`
--

DROP TABLE IF EXISTS `breach`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `breach` (
  `breach_id` int(11) NOT NULL AUTO_INCREMENT,
  `breach_name` varchar(64) NOT NULL DEFAULT '',
  `breach_date` date NOT NULL DEFAULT '1900-01-01',
  `breach_url` varchar(256) DEFAULT NULL,
  `breach_notes` text NOT NULL,
  `c_total_hashes` int(11) NOT NULL DEFAULT '0',
  `c_distinct_hashes` int(11) NOT NULL DEFAULT '0',
  `c_total_passwords` int(11) NOT NULL DEFAULT '0',
  `c_distinct_passwords` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`breach_id`)
) ENGINE=MyISAM AUTO_INCREMENT=80 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cache`
--

DROP TABLE IF EXISTS `cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cache` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `updated_time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cracker`
--

DROP TABLE IF EXISTS `cracker`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cracker` (
  `cracker_id` int(11) NOT NULL AUTO_INCREMENT,
  `cracker_name` varchar(64) NOT NULL DEFAULT '',
  `c_total_hashes` int(11) NOT NULL DEFAULT '0',
  `c_distinct_hashes` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`cracker_id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `dictionary`
--

DROP TABLE IF EXISTS `dictionary`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dictionary` (
  `dictionary_id` int(11) NOT NULL AUTO_INCREMENT,
  `dictionary_name` varchar(64) NOT NULL DEFAULT '',
  `dictionary_notes` text NOT NULL,
  `dictionary_date` date NOT NULL DEFAULT '1900-01-01',
  `c_word_count` int(11) NOT NULL DEFAULT '0',
  `c_distinct_word_count` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`dictionary_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `dictionary_word`
--

DROP TABLE IF EXISTS `dictionary_word`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dictionary_word` (
  `dictionary_word_id` int(11) NOT NULL AUTO_INCREMENT,
  `dictionary_word_dictionary_id` int(11) NOT NULL DEFAULT '0',
  `dictionary_word_word` varbinary(64) NOT NULL DEFAULT '',
  `dictionary_word_count` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`dictionary_word_id`),
  KEY `dictionary_word_dictionary_id` (`dictionary_word_dictionary_id`),
  KEY `dictionary_word_index` (`dictionary_word_word`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hash`
--

DROP TABLE IF EXISTS `hash`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hash` (
  `hash_id` int(11) NOT NULL AUTO_INCREMENT,
  `hash_breach_id` int(11) NOT NULL DEFAULT '0',
  `hash_hash_type_id` int(11) NOT NULL DEFAULT '0',
  `hash_password_id` int(11) NOT NULL DEFAULT '0',
  `hash_cracker_id` int(11) NOT NULL DEFAULT '0',
  `hash_hash` varbinary(256) NOT NULL DEFAULT '',
  `hash_count` int(11) NOT NULL DEFAULT '0',
  `c_password` varbinary(64) NOT NULL DEFAULT '',
  `c_hash_type` varchar(64) NOT NULL DEFAULT '',
  `c_breach_name` varchar(64) NOT NULL DEFAULT '',
  `c_is_internal` tinyint(1) NOT NULL DEFAULT '0',
  `c_difficulty` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`hash_id`),
  KEY `hash_hash_type_id` (`hash_hash_type_id`),
  KEY `hash_password_id` (`hash_password_id`),
  KEY `hash_hash` (`hash_hash`),
  KEY `hash_password_id_index` (`hash_password_id`),
  KEY `hash_count` (`hash_count`),
  KEY `hash_breach_id` (`hash_breach_id`)
) ENGINE=MyISAM AUTO_INCREMENT=12111092 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hash_type`
--

DROP TABLE IF EXISTS `hash_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hash_type` (
  `hash_type_id` int(11) NOT NULL AUTO_INCREMENT,
  `hash_type_john_name` varchar(64) NOT NULL DEFAULT '',
  `hash_type_english_name` varchar(64) NOT NULL DEFAULT '',
  `hash_type_difficulty` int(11) NOT NULL DEFAULT '0',
  `hash_type_john_test_speed` int(11) NOT NULL DEFAULT '0',
  `hash_type_is_salted` tinyint(1) NOT NULL DEFAULT '0',
  `hash_type_is_internal` tinyint(1) NOT NULL DEFAULT '0',
  `hash_type_pattern` varchar(256) NOT NULL DEFAULT '^.*$',
  `hash_type_hash_example` varchar(256) NOT NULL DEFAULT '',
  `hash_type_hash_example_plaintext` varchar(64) NOT NULL DEFAULT '',
  `hash_type_notes` text NOT NULL,
  `c_total_hashes` int(11) NOT NULL DEFAULT '0',
  `c_distinct_hashes` int(11) NOT NULL DEFAULT '0',
  `c_total_passwords` int(11) NOT NULL DEFAULT '0',
  `c_distinct_passwords` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`hash_type_id`)
) ENGINE=MyISAM AUTO_INCREMENT=69 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mask`
--

DROP TABLE IF EXISTS `mask`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mask` (
  `mask_id` int(11) NOT NULL AUTO_INCREMENT,
  `mask_mask` varchar(512) NOT NULL DEFAULT '',
  `c_password_count` int(11) NOT NULL DEFAULT '0',
  `c_mask_example` varchar(512) NOT NULL DEFAULT '',
  PRIMARY KEY (`mask_id`)
) ENGINE=MyISAM AUTO_INCREMENT=4720 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `news`
--

DROP TABLE IF EXISTS `news`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `news` (
  `news_id` int(11) NOT NULL AUTO_INCREMENT,
  `news_name` varchar(64) NOT NULL DEFAULT '',
  `news_title` varchar(256) NOT NULL DEFAULT '',
  `news_date` date NOT NULL DEFAULT '1900-01-01',
  `news_story` text NOT NULL,
  PRIMARY KEY (`news_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `password`
--

DROP TABLE IF EXISTS `password`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `password` (
  `password_id` int(11) NOT NULL AUTO_INCREMENT,
  `password_mask_id` int(11) NOT NULL DEFAULT '0',
  `password_password` varbinary(256) NOT NULL DEFAULT '',
  `password_date` date NOT NULL DEFAULT '1900-01-01',
  PRIMARY KEY (`password_id`),
  UNIQUE KEY `password_password_2` (`password_password`),
  KEY `password_password` (`password_password`),
  KEY `password_password_index` (`password_password`)
) ENGINE=MyISAM AUTO_INCREMENT=492324 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `password_cache`
--

DROP TABLE IF EXISTS `password_cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `password_cache` (
  `password_cache_id` int(11) NOT NULL AUTO_INCREMENT,
  `password_cache_password_id` int(11) NOT NULL DEFAULT '0',
  `password_cache_password_password` varbinary(64) NOT NULL DEFAULT '',
  `password_cache_breach_id` int(11) NOT NULL DEFAULT '0',
  `password_cache_breach_name` varchar(64) NOT NULL DEFAULT '',
  `password_cache_mask_id` int(11) NOT NULL DEFAULT '0',
  `password_cache_mask_mask` varchar(256) NOT NULL DEFAULT '',
  `password_cache_hash_type_id` int(11) NOT NULL DEFAULT '0',
  `password_cache_hash_type_name` varchar(64) NOT NULL DEFAULT '',
  `password_cache_password_count` int(11) NOT NULL DEFAULT '0',
  `password_cache_hash_hash` varbinary(256) NOT NULL DEFAULT '',
  PRIMARY KEY (`password_cache_id`),
  KEY `password_cache_password_id` (`password_cache_password_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `submission`
--

DROP TABLE IF EXISTS `submission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `submission` (
  `submission_id` int(11) NOT NULL AUTO_INCREMENT,
  `submission_submission_batch_id` int(11) NOT NULL DEFAULT '0',
  `submission_hash` varchar(256) NOT NULL DEFAULT '',
  `submission_password` varchar(256) NOT NULL DEFAULT '',
  PRIMARY KEY (`submission_id`),
  KEY `submission_submission_batch_id` (`submission_submission_batch_id`)
) ENGINE=MyISAM AUTO_INCREMENT=1001 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `submission_batch`
--

DROP TABLE IF EXISTS `submission_batch`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `submission_batch` (
  `submission_batch_id` int(11) NOT NULL AUTO_INCREMENT,
  `submission_batch_cracker_id` int(11) NOT NULL DEFAULT '0',
  `submission_batch_date` date NOT NULL DEFAULT '0000-00-00',
  `submission_batch_ip` varchar(16) NOT NULL DEFAULT '',
  `submission_batch_done` tinyint(1) NOT NULL DEFAULT '0',
  `c_submission_count` int(11) NOT NULL DEFAULT '0',
  `c_cracker_name` varchar(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`submission_batch_id`),
  KEY `submission_batch_cracker_id` (`submission_batch_cracker_id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2012-10-08  2:13:28
