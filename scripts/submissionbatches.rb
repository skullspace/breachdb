require 'rubygems'
require 'mysql'
require 'openpgp'

require 'breachdb'
require 'submissions'

require '/home/ron/auth.rb'

class SubmissionBatches < Breachdb
  JOHN_PATH = '/home/ron/tools/john-1.7.6/run/'

  def self.table_name()
    return 'submission_batch'
  end
  def self.id_column
    return 'submission_batch_id'
  end

  # Take an array of words and try them against the list of hashes (each of
  # which is a database row). The results argument is an array where the
  # results are stored.
  def self.process_hashes_john(words, hashes, results)
    potfile = '%s/breachdb.pot' % JOHN_PATH
    debug("Creating temporary files to store the hashes...")

    # Create and populate files that john can load
    files = {}
    hash_types = {}
    hashes.each() do |hash|
      # Create a file for this hash type if it doesn't already exist
      if(!files[hash['hash_type_name']]) then
        files[hash['hash_type_name']] = File.new("%s/%s.tmp" % [JOHN_PATH, hash['hash_type_name']], 'w')
      end

      # Add the hash to the file
      files[hash['hash_type_name']] << ("%s\n" % hash['hash'])
    end

    # Close our temporary john files so we can actually work on them
    files.each_value() do |file|
      file.close()
    end

    # Now, start up an instance of john for each of the hash types that are present
    debug("Starting up #{files.size} john the ripper instances (#{files.keys.join(', ')}).....")
    files.each do |hash_type, file|
      pid = fork()
      if(!pid) then
        exec("%s/john --pot=%s --wordlist=%s/submissions.tmp --format=%s --session=%s %s > /dev/null 2>&1" % [JOHN_PATH, potfile, JOHN_PATH, hash_type, hash_type, file.path])
        # Uncomment this for noisy
        #exec("%s/john --pot=%s --wordlist=%s/submissions.tmp --format=%s --session=%s %s" % [JOHN_PATH, potfile, JOHN_PATH, hash_type, hash_type, file.path])
        exit()
      end
    end

    # Wait for john to finish
    Process.waitall()

    # Loop through the john.pot file and extract all the passwords
    pot = File.new(potfile, 'r')
    i = 0
    pot.read.split("\n").each do |line|
      hash, password = line.split(/:/, 2)
      i = i + 1
      if(results[password]) then
        results[password] << hash
      else
        results[password] = [hash]
      end
    end

    # Close and delete the potfile
    pot.close()
    File.delete(potfile)
  end

  # This is a simple loop that assumes all passwords are in plaintext.
  # I wrote this to help simplify the logic of cracking hashes without
  # treating plaintext hashes special all over the place.
  def self.process_hashes_plaintext(hashes, results)
    hashes.each() do |hash|
      hash = hash['hash']
      if(results[hash].nil?)
        results[hash] = [hash]
      else
        results[hash] << hash
      end
    end
  end

  # Take an array of words and try them against the list of hashes (each of
  # which is a database row). The results argument is an array where the
  # results are stored.
  def self.process_hashes_internal(words, hashes, results)
    submission_hashes = {}

    # Hash the words in every known way
    debug("Hashing #{hashes.size()} submissions...")
    words.each() do |word|
      # SHA-2 hashes
      submission_hashes[OpenPGP::Digest::SHA224.digest(word).unpack("H*").shift.downcase]   = word
      submission_hashes[OpenPGP::Digest::SHA256.digest(word).unpack("H*").shift.downcase]   = word
      submission_hashes[OpenPGP::Digest::SHA384.digest(word).unpack("H*").shift.downcase]   = word
      submission_hashes[OpenPGP::Digest::SHA512.digest(word).unpack("H*").shift.downcase]   = word

      # Truncated MD5
      submission_hashes[OpenPGP::Digest::MD5.digest(word).unpack("H*").shift.downcase]      = word
      submission_hashes[OpenPGP::Digest::MD5.digest(word).unpack('H*').shift.downcase[0,8]] = word

      # LinkedIn (sha1, where first 6 characters may be '0')
      sha1 = OpenPGP::Digest::SHA1.digest(word).unpack('H*').shift.downcase
      submission_hashes[sha1]     = word
      l_sha1 = '000000' + sha1[6, sha1.length]
      submission_hashes[l_sha1]   = word
    end

    # Now loop through the hashes and see if we have any
    debug("Looking up #{hashes.size} internal hashes")
    hashes.each() do |hash|
      hash = hash['hash']
      password = submission_hashes[hash]
      if(!password.nil?) then
        if(results[password]) then
          results[password] << hash
        else
          results[password] = [hash]
        end
      end
    end
  end

  def self.process_hashes(words, limit_hashes, results)
    debug("Collecting the list of submission words")

    # Create a file containing the plaintext passwords that we're testing
    debug("Creating temp file containing the plaintext submissions...")
    file = File.new("%s/submissions.tmp" % JOHN_PATH, 'w')
    file.puts(words)
    file.close()

    debug("Auto-cracking plaintext hashes (what a time saver!)")
    Hashes.each_chunk(500000, true, {
      :columns => { :name => 'hash_hash', :as => 'hash' },
      :where   => "`hash_hash_type_id` = -1 AND `hash_password_id`='0'",
    }) do |hashes|
      process_hashes_plaintext(hashes, results)
      debug("[plaintext] Done the chunk of hashes! So far, we have #{results.keys.size} valid passwords representing #{results.values.flatten.size} hashes")
    end

    # Either limit it to easier hashes, or to known hashes
    if(limit_hashes.nil?) then
      limit = "`hash_cache_hash_type_difficulty` < 8"
    else
      limit_hashes = limit_hashes.collect do |hash| "'#{Mysql::quote(hash)}'" end
      limit = "`hash_cache_hash_hash` IN (" + limit_hashes.join(',') + ")"
    end

    debug("Cracking passwords with john...")
    HashCache.each_chunk(100000, true, {
      :columns => [
        { :name => 'hash_cache_hash_hash',      :as => 'hash' },
        { :name => 'hash_cache_hash_type_name', :as => 'hash_type_name'}
      ] ,
      :where => "#{limit} AND `hash_cache_hash_type_is_internal`='0' AND `hash_cache_password_id`='0'",
    }) do |hashes|
      process_hashes_john(words, hashes, results)
      debug("[john] Done the chunk of hashes! So far, we have #{results.keys.size} valid passwords representing #{results.values.flatten.size} hashes")
    end

    debug("Cracking hashes that john doesn't handle...")
    HashCache.each_chunk(100000, true, {
      :columns => [ { :name => 'hash_cache_hash_hash', :as => 'hash' } ],
      :where => "#{limit} AND `hash_cache_hash_type_is_internal`='1' AND `hash_cache_password_id`='0'",
    }) do |hashes|
      process_hashes_internal(words, hashes, results)
      debug("[internal] Done the chunk of hashes! So far, we have #{results.keys.size} valid passwords representing #{results.values.flatten.size} hashes")
    end
  end

  def self.mark_as_complete(submission_batch_id)
    if(submission_batch_id == '0')
      query("UPDATE `submission_batch`
              SET `submission_batch_done`='1'")
    else
      query("UPDATE `submission_batch`
              SET `submission_batch_done`='1'
              WHERE `submission_batch_id`='#{Mysql::quote(submission_batch_id)}'")
    end
  end

  def self.process(submission_batch_id)
    # If they want all the batches, get the list and process each of them using this function
    if(submission_batch_id.to_i == 0)
      submission_batches = SubmissionBatches.query_ex({:where => "`submission_batch_done`='0'"})
      submission_batches.each do |submission_batch|
        process(submission_batch['submission_batch_id'])
      end
      return
    end

    debug("Processing submissions for batch " + submission_batch_id)
    submission_batch = SubmissionBatches.get(submission_batch_id)
    where = "`submission_submission_batch_id`='#{Mysql::quote(submission_batch_id)}'"
    results = {}

    # First, process the submissions that don't have associated hashes
    Submissions.each_chunk(CHUNK_SIZE, true, { :where => where + " AND `submission_hash`=''"}) do |submission|
      submissions = {}
      submission.each() do |row|
        submissions[row['submission_password']] = 1
      end
      process_hashes(submissions.keys, nil, results)
    end

    # Process submissions that have an associated hash
    Submissions.each_chunk(CHUNK_SIZE, true, { :where => where + " AND `submission_hash`!=''"}) do |submission|
      # Get a list of the submitted hashes
      known_hashes = []
      submissions = {}

      # Loop through the submissions and create a password -> hash table
      submission.each() do |row|
        hash = row['submission_hash']
        password = row['submission_password']
        if(submissions[password].nil?)
          submissions[password] = [hash]
        else
          submissions[password] << hash
        end
      end

      # Call process_hashes for each password
      submissions.each_pair do |password, hashes|
        process_hashes(password, hashes, results)
      end
    end

    if(results.size > 0)
      debug("Successfully cracked #{results.size()} passwords! Updating the hashes table to point at the results...")

      # Break the results into more manageable chunks
      # NOTE: This is a smaller size than CHUNK_SIZE because each password can
      # represent 10 (or more) hashes, so we want the chunks to be 1/10 of the
      # size. 
      results.keys.each_slice(1000) do |passwords|
        this_group = {}
        passwords.each() do |password|
          this_group[password] = results[password]
        end
        Hashes.update_with_passwords(this_group, submission_batch['submission_batch_cracker_id'])
      end
    else
      puts(">> No hashes were cracked!")
    end

    mark_as_complete(submission_batch_id)
  end

  def self.cache_update()
    puts("Updating submission_batch.c_submission_count...")
    query("UPDATE `submission_batch` SET `c_submission_count`='0'")
    query("
      UPDATE `submission_batch` AS `s1`
        JOIN (
          SELECT `submission_submission_batch_id`, COUNT(`submission_submission_batch_id`) AS `c_submission_count`
            FROM `submission`
          GROUP BY `submission_submission_batch_id`
        ) AS `sub` ON `s1`.`submission_batch_id` = `sub`.`submission_submission_batch_id`
      SET `s1`.`c_submission_count` = `sub`.`c_submission_count`
    ")

    puts("Updating submission_batch.c_cracker_name...")
    query("UPDATE `submission_batch` SET `c_cracker_name`=''")
    query("UPDATE `submission_batch` JOIN `cracker` ON `submission_batch_cracker_id`=`cracker_id` SET `c_cracker_name`=`cracker_name` ")
 
  end

  def self.export_files()
    return []
  end
end

