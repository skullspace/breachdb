require 'rubygems'
require 'mysql'
require 'breachdb'

require 'crackers'

class Submissions < Breachdb
  def self.table_name()
    return 'submission'
  end
  def self.id_column
    return 'submission_id'
  end

  def self.cache_update()
    # No cache in submission table
  end

  def self.export_files()
    return []
  end

  # submissions is an array of submissions
  # cracker_name is a string representing the submissions
  def self.import_submissions(submissions, cracker_name = nil, ip = nil, batch_id = nil)
    if(batch_id.nil?)
      # Insert or find the cracker by their name
      cracker = Crackers.query_ex({ :where => "`cracker_name`='#{cracker_name}'"})
      if(cracker.size > 0)
        cracker_id = cracker[0]['cracker_id']
      else
        cracker_id = Crackers.insert_rows({'cracker_name' => cracker_name})
      end

      # Insert a new batch, and get the id
      batch_id = SubmissionBatches.insert_rows({
          'submission_batch_cracker_id' => cracker_id,
          'submission_batch_date' => Time.new().strftime('%Y-%m-%d'),
          'submission_batch_ip' => ip,
      })
    end

    submissions.collect! do |s| 
      s.chomp!
    end
  
    # Automatically detect if the passwords are in hash:password format by
    # looking at the first bunch and seeing if they all contain colons
    with_hash = true
    0.upto([submissions.length, 100].min - 1) do |i|
      if(!submissions[i].include?(':'))
        with_hash = false
      end
    end
  
    # Loop through the submissions and add them to arrays
    words = []
    hashes = []
    submissions.each do |submission|
      # IMPORTANT: This value has to be sanitized
      submission = Mysql::quote(submission)
      hash = ''
      if(with_hash)
        # Eliminate blank lines when a colon is expected
        if(submission == '')
          next
        end
  
        hash, word = submission.split(/:/, 2)
      else
        word = submission
      end
  
      words << word
      hashes << hash
    end
  
    # This is the table of values that is inserted into the database
    values = {}
    values['submission_submission_batch_id'] = batch_id
    values['submission_password'] = words
    values['submission_hash'] = hashes
  
    Submissions.insert_rows(values)
  end
end

