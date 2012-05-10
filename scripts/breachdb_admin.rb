#!/usr/bin/ruby

require 'breachdb'
require 'breaches'
require 'hashtypes'
require 'passwords'
require 'masks'
require 'submissions'
require 'hashes'
require 'crackers'
require 'submissionbatches'
require 'dictionaries'
require 'dictionarywords'
require 'passwordcache'

require 'mysql'

# The order no longer matters here
@all_classes = [ Hashes, Passwords, Breaches, HashTypes, Masks, Submissions, Crackers, SubmissionBatches, Dictionaries, DictionaryWords, PasswordCache ]

IMPORT_FORMAT_MULTIPLE_LINES = '1'
IMPORT_FORMAT_UNIQ           = '2'
IMPORT_FORMAT_COMMA          = '3'
IMPORT_FORMAT_COLON          = '4'

SUBMISSION_FORMAT_ALONE      = '1'
SUBMISSION_FORMAT_HASH       = '2'

@should_update_cache = false

def get_with_default(prompt, default, pattern = nil)
  loop do
    print("#{prompt} [#{default}] --> ")
    result = $stdin.gets().chomp
    if(result == '')
      result = default if(result == '')
    end

    if(pattern.nil? || result =~ pattern)
      return result
    end

    puts("Invalid entry: #{result}")
  end
end

# Get a filename and make sure it's valid
def get_file_with_default(prompt, default)
  file = default
  loop do
    # Get the file
    file = get_with_default(prompt, file)

    if(File.exist?(file))
      return file
    end

    puts("Invalid file!")
  end
end

# Column names = an array of tables with :english and :name
def show_list(rows, columns, brief = false)
  info = {}

  # If no rows, just return
  if(rows.count == 0)
    puts("No results.")
    return
  end

  # Make sure we have all the columns set to at least something
  rows.each do |row|
    columns.each do |column|
      if(row[column[:name]].nil?)
        row[column[:name]] = ''
      end
    end
  end

  # Go through the rows and figure out the maximum width for each column
  rows.each do |row|
    columns.each do |column|
      info[column[:name]] = info[column[:name]] || {
        :english => column[:english],
        :max_width => [4, column[:english].length].max
      }
      if(row[column[:name]].length > info[column[:name]][:max_width])
        info[column[:name]][:max_width] = row[column[:name]].length
      end
    end
  end

  # Print the headers
  if(brief)
    columns.each do |column|
      print(column[:english].ljust(info[column[:name]][:max_width]+1))
    end
    puts()
    columns.each do |column|
      print(('-' * column[:english].length).ljust(info[column[:name]][:max_width]+1))
    end
    puts()
  end

  rows.each do |row|
    columns.each do |column|
      if(brief)
        print(row[column[:name]].ljust(info[column[:name]][:max_width]+1))
      else
        puts(column[:english] + ": " + row[column[:name]])
      end
    end
    puts()
  end
end


##
# Prompt the user for a number of different values, and return them in a table.
#
# @param table The class to be modified (eg, Breaches).
# @param id The ID to edit (set to nil to create a field).
# @param data A table of values that we're requesting from the user. Each
#  key in the table corresponds to one of the following:
#  * :name - [required] The name (this is what's displayed to the user)
#  * :column - [required] The column in the database that we're prompting for.
#    The result will be stored under that key in the return value.
#  * :value - The default value
#  * :regex - Set to a regex to validate the value before accepting it
#  * :is_file - If true, only a valid filename will be accepted
#  * :foreign_table - Set to a class (ie, Breaches), and a valid foreign key
#    from that table will be required
#  * :foreign_list - Set to a method (ie, list_breaches), and it will be
#    displayed before requesting the value
#  * :foreign_create - Set to a method for creating a row in another table (ie,
#    edit_breach), and it will be called if the user specifies '0' as the value
#
# @return A table, where the key is the column and the value is what the user
#         entered.
def prompt_values(table, id, data)
  to_import = {}

  # If we're editing a table, load it
  if(!id.nil?)
    results = table.get(id)
    results.each_pair do |column, value|
      data = data.each() do |d|
        if(d[:column] == column)
          d[:value] = value
        end
      end
    end
  end

  # Loop through the possible fields
  data.each() do |d|
    # If there's a list function for this column, use that to get the input
    if(d[:foreign_list])
      d[:value] = d[:foreign_list].call(true, true)
      # If it's a foreign key, and the value was '0', let them enter it
      if(!d[:foreign_create].nil? && d[:value] == '0')
        d[:value] = d[:foreign_create].call
      end
    else
      begin
        valid = true
        d[:value] = get_with_default(table.table_name + "::" + d[:name], d[:value], d[:regex])
        valid = false if(d[:is_file] && !File.exist?(d[:value]))
        valid = false if(d[:foreign_table] && d[:foreign_table].get(d[:value]).nil? && d[:value] != '0')
      end while(!valid)
    end

    # Write it to an associative array
    to_import[d[:column]] = d[:value]
  end

  # Validate that we're doing what the user wants
  puts()
  name_size = 4
  data.each() do |d|
    name_size = [name_size, d[:name].length].max
  end

  return to_import
end

##
# Reads a file in 
##
def read_file_import(filename, format = nil)
  # Ask the user which format the file is in
  if(format.nil?)
    puts("Which format is the file?")
    puts("1) Multiple lines with the same entry (or unique lines)")
    puts("2) Output from call to 'uniq -c'")
    puts("3) Lines in the format 'count,value'")
    puts("4) Lines in the format 'count:value'")

    format = get_with_default("Selection", '0', /^[1234]$/)
  end

  # Read the file into the appropriate place
  lines = IO.readlines(filename).collect do |line| line.chomp end

  # Create an associative array counts, which will be hash=>count pairs
  counts = {}
  if(format == IMPORT_FORMAT_MULTIPLE_LINES)
    lines.each do |line|
      counts[line] = counts[line].nil? ? 1 : counts[line] + 1
    end
  else
    lines.each do |line|
      results = nil
      if(format == IMPORT_FORMAT_UNIQ)
        results = line.match(/^[ ]*([0-9]+) (.*)$/)
      elsif(format == IMPORT_FORMAT_COMMA)
        results = line.match(/^[ ]*([0-9]+)[ ]*,(.*)$/)
      elsif(format == IMPORT_FORMAT_COLON)
        results = line.match(/^[ ]*([0-9]+)[ ]*:(.*)$/)
      else
        throw :InvalidFormatException
      end

      if(results.nil? || results[1].nil? || results[2].nil?)
        puts("Line is in an invalid format: #{line}")
        throw :InvalidFormatException
      end
      counts[results[2]] = counts[results[2]].nil? ? results[1].to_i : counts[results[2]] + results[1].to_i
    end
  end

  return counts
end

def read_file_submissions(filename)
  # Ask the user which format the file is in
  puts("Which format is the file?")
  puts("1) submission")
  puts("2) hash:submission")

  format = get_with_default("Selection", '0', /^[12]$/)

  # Read the file into the appropriate place
  lines = IO.readlines(filename).collect do |line| line.chomp end

  # Create an associative array counts, which will be hash=>count pairs
  submissions = []
  if(format == SUBMISSION_FORMAT_ALONE)
    lines.each do |line|
      submissions << { :word => line, :hash => '' }
    end
  elsif(format == SUBMISSION_FORMAT_HASH)
    lines.each do |line|
      results = line.match(/^([^:]+):(.*)$/)

      if(results.nil? || results[1].nil? || results[2].nil?)
        puts("Line is in an invalid format: #{line}")
        throw :InvalidFormatException
      end
      submissions << { :word => results[2], :hash => results[1] }
    end
  else
    throw :InvalidFormatException
  end

  return submissions
end

def cache_update()
  @all_classes.each do |c|
    puts("Updating cache for #{c.name}...")
    c.cache_update()
  end

  @all_classes.each do |c|
    puts("Exporting data for #{c.name}...")
    c.export()
  end
  @should_update_cache = false
end

def prompt_for_key(table)
  value = '0'
  loop do
    value = get_with_default(table.table_name + "::id", value, /^[0-9]+$/)
    if(!table.get(value).nil? || value == '0')
      return value
    end
  end
end

def list_breaches(brief = true, prompt = false)
  puts("Breaches:")
  puts("--------")
  show_list(Breaches.query_ex(), [
    { :name=>'breach_id',   :english=> 'ID'},
    { :name=>'breach_name', :english=>'Name'},
    { :name=>'breach_date', :english=>'Date'}], brief)

  # Get the input from the user
  if(prompt)
    return prompt_for_key(Breaches)
  end
end

def go_breach(id = nil)
  puts("Editing breach...")
  puts("--------------")
  values = prompt_values(Breaches, id,
    [
      {:name=>'Name',              :column=>'breach_name',  :value=>''},
      {:name=>'Date (YYYY-MM-DD)', :column=>'breach_date',  :value=>'0000-00-00', :regex=>/\d\d\d\d-\d\d-\d\d/},
      {:name=>'URL',               :column=>'breach_url',   :value=>'http://'},
      {:name=>'Notes',             :column=>'breach_notes', :value=>''},
    ])

  return Breaches.insert_rows(values, id)
end

def edit_breach()
  return go_breach(list_breaches(true, true))
end

def create_breach()
  return go_breach(nil)
end

def list_crackers(brief = true, prompt = false)
  puts()
  puts("Crackers:")
  puts("--------")

  show_list(Crackers.query_ex(), [
    {:name=>'cracker_id',   :english=>'ID'},
    {:name=>'cracker_name', :english=>'Name'},
    {:name=>'c_total_hashes', :english=>'Hashes cracked'}], brief) # TODO: Other fields

  # Get the input from the user
  if(prompt)
    return prompt_for_key(Crackers)
  end
end

def go_cracker(id = nil)
  puts("Editing cracker...")
  puts("---------------")
  values = prompt_values(Crackers, id,
    [
      {:name=>'Name', :column=>'cracker_name',  :value=>''},
    ])

  return Crackers.insert_rows(values, id)
end

def edit_cracker()
  return go_cracker(list_crackers(true, true))
end

def create_cracker()
  return go_cracker(nil)
end

def list_submission_batches(brief = true, prompt = false)
  puts("Submission batches:")
  puts("------------------")

  show_list(SubmissionBatches.query_ex(), [
    {:name=>'submission_batch_done', :english=>'Done?'},
    {:name=>'submission_batch_id',   :english=>'ID'},
    {:name=>'c_cracker_name',        :english=>'Cracker'},
    {:name=>'submission_batch_date', :english=>'Date'},
    {:name=>'submission_batch_ip',   :english=>'IP'},
    {:name=>'c_submission_count',    :english=>'Count'}], brief)

  # Get the input from the user
  if(prompt)
    return prompt_for_key(SubmissionBatches)
  end
end

def go_submission_batch(id = nil)
  puts("Editing submission_batch...")
  puts("-----------------------")

  values = prompt_values(SubmissionBatches, id,
    [
      {:name=>'Cracker',           :column=>'submission_batch_cracker_id',  :value=>'0', :foreign_table=>Crackers, :foreign_list=>method(:list_crackers), :foreign_create=>method(:create_cracker)},
      {:name=>'Date (YYYY-MM-DD)', :column=>'submission_batch_date',        :value=>'0000-00-00', :regex=>/\d\d\d\d-\d\d-\d\d/},
      {:name=>'IP Address',        :column=>'submission_batch_ip',          :value=>'0.0.0.0'},
    ])

  return SubmissionBatches.insert_rows(values, id)
end

def edit_submission_batch()
  return go_submission_batch(list_submission_batches(true, true))
end

def create_submission_batch()
  return go_submission_batch(nil)
end

def process_submissions()
  submission_batch_id = '0'

  loop do
    submission_batch_id = list_submission_batches(true, true)

    # If they picked '0' for all, it's good
    if(submission_batch_id == '0')
      break
    end

    # Check if it's a valid id
    submission_batch = SubmissionBatches.get(submission_batch_id)
    if(!submission_batch.nil?)
      break
    end
  end

  SubmissionBatches.process(submission_batch_id)
  @should_update_cache = true
end

def import_submissions()
  values = prompt_values(Submissions, nil,
    [
      {:name=>'SubmissionBatch', :column=>'submission_submission_batch_id', :value=>'0', :foreign_table=>SubmissionBatches, :foreign_list=>method(:list_submission_batches), :foreign_create=>method(:create_submission_batch)},
      {:name=>'File', :column=>'submission_password', :value=>'',  :is_file=>true}
    ])

  # Read the file into the appropriate place
  submissions = IO.readlines(values['submission_password'])
  Submissions.import_submissions_with_batch_id(submissions, values['submission_submission_batch_id'])
  @should_update_cache = true
end

def list_submissions(brief = true)
  submission_batch_id = list_submission_batches(true, true)

  puts("Submissions:")
  puts("------------------")

  if(submission_batch_id == '0')
    where = nil
  else
    where = "`submission_submission_batch_id`='#{Mysql::quote(submission_batch_id)}'"
  end
  show_list(Submissions.query_ex({:where => where}), [
    {:name=>'submission_hash',     :english=>'Hash'},
    {:name=>'submission_password', :english=>'Password'}, ], brief)
end

def import_hashes()
  values = prompt_values(Hashes, nil,
    [
      {:name=>'Hash type', :column=>'hash_hash_type_id', :value=>'0', :foreign_table=>HashTypes, :foreign_list=>method(:list_hash_types)},
      {:name=>'Breach', :column=>'hash_breach_id', :value=>'0', :foreign_table=>Breaches, :foreign_list=>method(:list_breaches), :foreign_create=>method(:create_breach)},
      {:name=>'File', :column=>'hash_hash',   :value=>'', :is_file=>true}
    ])

  counts = read_file_import(values['hash_hash'])

  values['hash_hash']  = []
  values['hash_count'] = []

  counts.each_pair() do |hash, count|
    values['hash_hash'] << hash
    values['hash_count'] << count.to_s
  end

  Hashes.insert_rows(values)
  @should_update_cache = true
end

def list_hashes(brief = true)
  hash_breach_id = list_breaches(true, true)

  puts("Hashes:")
  puts("------")

  if(hash_breach_id == '0')
    where = nil
  else
    where = "`hash_breach_id`='#{Mysql::quote(hash_breach_id)}'"
  end
  show_list(Hashes.query_ex({:where => where}), [
    {:name=>'c_hash_type',  :english=>'Type'},
    {:name=>'hash_hash',    :english=>'Hash'},
    {:name=>'c_password',   :english=>'Password'},
  ], brief)
end

def list_hash_types(brief = true, prompt = false)
  puts("Hash types:")
  puts("----------")

  show_list(HashTypes.query_ex(), [
    {:name=>'hash_type_id',   :english=>'ID'},
    {:name=>'hash_type_john_name', :english=>'John name'},
    {:name=>'hash_type_english_name', :english=>'English name'}], brief)

  # Get the input from the user
  if(prompt)
    return prompt_for_key(HashTypes)
  end
end

def go_hash_type(id = nil)
  puts("Editing hash type...")
  puts("-----------------")
  values = prompt_values(HashTypes, id,
    [
      {:name=>'John name',                 :column=>'hash_type_john_name',              :value=>''},
      {:name=>'English name',              :column=>'hash_type_english_name',           :value=>''},
      {:name=>'Difficulty (0 - 10)',       :column=>'hash_type_difficulty',             :value=>'', :regex=>/^[0-9]$/},
      {:name=>'John test speed (numeric)', :column=>'hash_type_john_test_speed',        :value=>''},
      {:name=>'Is salted?',                :column=>'hash_type_is_salted',              :value=>'', :regex=>/^[0-1]$/},
      {:name=>'Is internal?',              :column=>'hash_type_is_internal',            :value=>'', :regex=>/^[0-1]$/},
      {:name=>'Pattern',                   :column=>'hash_type_pattern',                :value=>''},
      {:name=>'Example hash',              :column=>'hash_type_hash_example',           :value=>''},
      {:name=>'Example plaintext',         :column=>'hash_type_hash_example_plaintext', :value=>''},
      {:name=>'Notes',                     :column=>'hash_type_notes',                  :value=>''},
    ])

  return HashTypes.insert_rows(values, id)
end

def edit_hash_type()
  return go_hash_type(list_hash_types(true, true))
end

def import_hash_type()
  puts("Import hash types...")
  puts("-----------------")
  values = prompt_values(HashTypes, nil,
    [
      {:name=>'File', :column=>'hash_type_file', :value=>'', :is_file=>true}
    ])

  HashTypes.import_csv(values['hash_type_file'])
end

def create_hash_type()
  return go_hash_type(nil)
end

def list_dictionaries(brief = true, prompt = false)
  puts("Dictionaries:")
  puts("------------")

  show_list(Dictionaries.query_ex(), [
    {:name=>'dictionary_id',   :english=>'ID'},
    {:name=>'dictionary_name', :english=>'Name'},
    {:name=>'dictionary_date', :english=>'Date'},
    {:name=>'dictionary_notes',:english=>'Notes'}], brief)

  # Get the input from the user
  if(prompt)
    return prompt_for_key(Dictionaries)
  end
end

def go_dictionary(id = nil)
  puts("Editing dictionary...")
  puts("-----------------")
  values = prompt_values(Dictionaries, id,
    [
      {:name=>'Name',              :column=>'dictionary_name',      :value=>''},
      {:name=>'Breach',            :column=>'dictionary_breach_id', :value=>'0', :foreign_table=>Breaches, :foreign_list=>method(:list_breaches)},
      {:name=>'Date (YYYY-MM-DD)', :column=>'dictionary_date',      :value=>'0000-00-00', :regex=>/\d\d\d\d-\d\d-\d\d/},
      {:name=>'Notes',             :column=>'dictionary_notes',     :value=>''},
    ])

  return Dictionaries.insert_rows(values, id)
end

def edit_dictionary()
  return go_dictionary(list_dictionaries(true, true))
end

def create_dictionary()
  return go_dictionary(nil)
end

def import_dictionary_words()
  values = prompt_values(Dictionaries, nil,
    [
      {:name=>'Dictionary', :column=>'dictionary_word_dictionary_id', :value=>'0', :foreign_table=>Dictionaries, :foreign_list=>method(:list_dictionaries)},
      {:name=>'File',       :column=>'dictionary_word_word',          :value=>'', :is_file=>true}
    ])

  counts = read_file_import(values['dictionary_word_word'])

  values['dictionary_word_word']  = []
  values['dictionary_word_count'] = []

  counts.each_pair() do |word, count|
    values['dictionary_word_word'] << word
    values['dictionary_word_count'] << count.to_s
  end

  DictionaryWords.insert_rows(values)
  @should_update_cache = true
end

def menu()
  menu = [
    {:name=>'Quit',                    :function=>nil},

    {:name=>(@should_update_cache ? '*** CACHE UPDATE ***' : 'Cache::update *'), :function=>method(:cache_update)},

    {:name=>'Breach::list',            :function=>method(:list_breaches)},
    {:name=>'Breach::create',          :function=>method(:create_breach)},
    {:name=>'Breach::edit',            :function=>method(:edit_breach)},

    {:name=>'Crackers::list',          :function=>method(:list_crackers)},
    {:name=>'Crackers::create',        :function=>method(:create_cracker)},
    {:name=>'Crackers::edit',          :function=>method(:edit_cracker)},

    {:name=>'SubmissionBatch::list',   :function=>method(:list_submission_batches)},
    {:name=>'SubmissionBatch::create', :function=>method(:create_submission_batch)},
    {:name=>'SubmissionBatch::edit',   :function=>method(:edit_submission_batch)},

    {:name=>'Submissions::import *',   :function=>method(:import_submissions)},
    {:name=>'Submissions::view *',     :function=>method(:list_submissions)},
    {:name=>'Submissions::process *',  :function=>method(:process_submissions)},

    {:name=>'Hashes::import *',        :function=>method(:import_hashes)},
    {:name=>'Hashes::view *',          :function=>method(:list_hashes)},

    {:name=>'HashType::list',          :function=>method(:list_hash_types)},
    {:name=>'HashType::create',        :function=>method(:create_hash_type)},
    {:name=>'HashType::edit',          :function=>method(:edit_hash_type)},
    {:name=>'HashType::import',        :function=>method(:import_hash_type)},

    {:name=>'Dictionary::list',        :function=>method(:list_dictionaries)},
    {:name=>'Dictionary::create',      :function=>method(:create_dictionary)},
    {:name=>'Dictionary::edit',        :function=>method(:edit_dictionary)},

    {:name=>'DictionaryWords::import', :function=>method(:import_dictionary_words)},
#    {:name=>'DictionaryWords::view',  :function=>method(:view_submissions)}, TODO
  ]

  puts()
  puts()
  menu.each_with_index do |value, num|
    puts("%4d %s" % [num, value[:name]])
  end
  puts()

  choice = get_with_default("Your choice", @should_update_cache ? '1' : '0', /^[0-9]+/)
  if(!choice || choice == '0')
    puts("Bye!")
    exit
  end

  choice = menu[choice.to_i]
  if(!choice.nil?)
    choice[:function].call
  end
end

if(ARGV.count == 0)
  Breachdb.initialize()
elsif(ARGV.count == 4)
  Breachdb.initialize(ARGV[0], ARGV[1], ARGV[2], ARGV[3])
else
  puts("Usage: web.rb <host> <username> <password> <db>")
  exit
end

loop do
  menu()
end

