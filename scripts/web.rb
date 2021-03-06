require 'sinatra'

require 'breaches'
require 'crackers'
require 'dictionaries'
require 'dictionarywords'
require 'hashes'
require 'passwords'
require 'passwordcache'
require 'hashtypes'
require 'masks'
require 'pagination'
require 'submissions'
require 'submissionbatches'

@@all_classes = [ Hashes, Passwords, Breaches, HashTypes, Masks, Submissions, Crackers, SubmissionBatches, Dictionaries, DictionaryWords, PasswordCache ]

if(ARGV.count == 0)
  Breachdb.init()
elsif(ARGV.count == 4)
  Breachdb.init(ARGV[0], ARGV[1], ARGV[2], ARGV[3])
else
  puts("Usage: web.rb <host> <username> <password> <db>")
  exit
end

set :port, 2022

# TODO: Change the hash pages here to use hash_cache instead of hash

# This is authentication for the beta version only. The release will be free
# for anybody who wants to use it to use!
use Rack::Auth::Basic, "BreachDB Beta" do |username, password|
  [username, password] == ['breachdb', 'breachdb']
end

TOP_SIZE  = 10

def get_breach_table(breaches, pagination = nil)
  breaches = Breaches.calculate_cracks(breaches)

  breaches.each do |b|
    b['name'] = Breaches.html_get_link(b['breach_id'], b['breach_name'])
  end

  return Breaches.html_table(breaches, [
          { :heading => "Name",                    :field => "name",                     :sortby => 'breach_name' },
          { :heading => "Date",                    :field => "breach_date",              :sortby => 'breach_date' },
          { :heading => "Total hashes cracked",    :field => "c_total_cracks_string",    :sortby => 'c_total_hashes' },
          { :heading => "Distinct hashes cracked", :field => "c_distinct_cracks_string", :sortby => 'c_distinct_hashes' },
        ], nil, pagination)
end

def get_dictionary_table(dictionaries, pagination = nil)

  dictionaries.each do |d|
    d['dictionary_name'] = Dictionaries.html_get_link(d['dictionary_id'], d['dictionary_name'])
  end

  return Dictionaries.html_table(dictionaries, [
          { :heading => "Name",                :field => "dictionary_name",         :sortby => 'dictionary_name' },
          { :heading => "Date",                :field => "dictionary_date",         :sortby => 'dictionary_date' },
          { :heading => "entries",             :field => "c_word_count",            :sortby => 'c_word_count' },
        ], nil, pagination)
end

def get_hash_type_table(hash_types, pagination = nil)
  hash_types = HashTypes.calculate_cracks(hash_types)

  hash_types.each do |ht|
    ht['name'] = HashTypes.html_get_link(ht['hash_type_id'], ht['hash_type_english_name'])
  end

  return HashTypes.html_table(hash_types, [
          { :heading => "Name",                    :field => "name",                    :sortby => 'hash_type_english_name' },
          { :heading => "Total hashes cracked",    :field => "c_total_cracks_string",   :sortby => 'c_total_hashes' },
          { :heading => "Distinct hashes cracked", :field => "c_distinct_cracks_string",:sortby => 'c_distinct_hashes' }
        ], nil, pagination)
end

def get_password_search(default = nil)
  default = default || ''
  return "
    <form method='get' action='/search/password/'>
      <p>Search passwords: <input type='text' name='password' value='#{default}'> <input type='submit' value='Search'></p>
    </form>"
end

def get_hash_search(default = nil)
  default = default || ''
  return "
    <form method='get' action='/search/hash/'>
      <p>Search hashes: <input type='text' name='hash' value='#{default}'> <input type='submit' value='Search'></p>
    </form>"
end

def get_password_cache_table(passwords, pagination = nil)
  passwords.each do |p|
    p['password'] = Passwords.html_get_link(p['password_cache_password_id'], p['password_cache_password_password'])
  end

  return PasswordCache.html_table(passwords, [
          { :heading => "Password", :field => "password",   :sortby => 'password_cache_password_password' },
          { :heading => "Count",    :field => "password_cache_password_count", :sortby => 'password_cache_password_count' },
        ], nil, pagination)
end

def get_dictionary_words_table(dictionary_words, pagination = nil)
  dictionary_words.each do |p|
    p['dictionary_word'] = DictionaryWords.html_get_link(p['dictionary_word_id'], p['dictionary_word_word'])
  end

  return DictionaryWords.html_table(dictionary_words, [
          { :heading => "Word",  :field => "dictionary_word_word",   :sortby => 'dictionary_word_word' },
        ], nil, pagination)
end

def get_hash_table(hashes, pagination = nil)
  hashes.each do |h|
    h['hash']     = Hashes.html_get_search(h['hash_hash'], h['hash_hash'])
    h['password'] = h['c_password'] == '' ? '&lt;unknown&gt;' : Passwords.html_get_search(h['c_password'], h['c_password'])
    h['count']    = "<a href='/hash/by_hash_id/#{h['hash_id']}'>#{h['hash_count']}</a>"
    h['hash_type']= "<a href='/hash_type/#{h['hash_hash_type_id']}'>#{h['c_hash_type']}</a>"
    h['breach']   = "<a href='/breach/#{h['hash_breach_id']}'>#{h['c_breach_name']}</a>"
  end

  return Hashes.html_table(hashes, [
          { :heading => "Hash",     :field => "hash",     :sortby => 'hash_hash' },
          { :heading => "Breach",   :field => "breach",   :sortby => 'c_breach_name' },
          { :heading => "Type",     :field => "hash_type",:sortby => 'c_hash_type' },
          { :heading => "Password", :field => "password", :sortby => 'c_password' },
          { :heading => "Count",    :field => "count",    :sortby => 'hash_count' },
        ], nil, pagination)
end

def get_mask_table(masks, pagination = nil)
  masks.each do |m|
    m['mask']    = "<a href='/mask/#{m['mask_id']}'>#{m['mask_mask']}</a>"
  end

  return Masks.html_table(masks, [
          { :heading => "Mask",     :field => "mask",             :sortby => 'mask_mask' },
          { :heading => "Count",    :field => "c_password_count", :sortby => 'c_password_count' },
          { :heading => "Example",  :field => "c_mask_example",   :sortby => 'c_mask_example' },
        ], nil, pagination)
end

def get_cracker_table(crackers, pagination = nil)
  crackers.delete_if do |h| h['c_total_hashes'] == '0' end
  crackers.each do |c|
    c['name'] = Crackers.html_get_link(c['cracker_id'], c['cracker_name'])
  end
  return Crackers.html_table(crackers, [
          { :heading => "Cracker",                 :field => "name",             :sortby => 'cracker_name' },
          { :heading => "Total hashes cracked",    :field => "c_total_hashes",   :sortby => 'c_total_hashes' },
          { :heading => "Distinct hashes cracked", :field => "c_distinct_hashes",:sortby => 'c_distinct_hashes' }
        ], nil, pagination)
end

# TODO: Check if the mysql connection is still alive

get '/downloads' do
  str = "<h1>Downloads</h1>
    <p><a href='/'>Home</a></p>"

  str += "<ul>"

  links = []
  @@all_classes.each do |c|
    c.export_files().each do |file|
      links << "<li><a href='#{file[:filename]}'>#{file[:description]}</a></li>"
    end
  end

  str += links.sort.join("\n")

  str += "</ul>"
end

get /^\/(downloads\/[a-z0-9_-]+.[a-z]+.bz2)$/ do |filename|
  send_file filename
end

get '/' do
  # Get a list of breaches
  str = ''
  str += "<p>Please read the <a href='/faq'>faq</a> page before yelling at me!</p>"
  str += "<p>Perhaps you wish to visit the <a href='/downloads'>downloads</a> page</p>"
  str += "<p>Perhaps you want to help out with <a href='/submissions'>cracking hashes</a>, or perhaps you want to <a href='https://github.com/skullspace/breachdb'>help develop</a>?</p>"

  str += "<h1>Top breaches</h1>\n"
  str += get_breach_table(Breaches.get_top('c_total_hashes', TOP_SIZE))
  str += "<p><a href='/breaches'>More breaches...</a> [<a href='/downloads/breaches.csv.bz2'>download</a>]</p>"

  str += "<h1>Top dictionaries</h1>\n"
  str += get_dictionary_table(Dictionaries.get_top('c_word_count', TOP_SIZE))
  str += "<p><a href='/dictionaries'>More dictionaries...</a> [<a href='/downloads/dictionaries.csv.bz2'>download</a>]</p>"
         
  str += "<h1>Top hash types</h1>\n"
  str += get_hash_type_table(HashTypes.get_top('c_total_hashes', TOP_SIZE))
  str += "<p><a href='/hash_types'>More hash types...</a> [<a href='/downloads/hash_types.csv.bz2'>download</a>]</p>"

  str += "<h1>Top passwords</h1>\n"
  str += get_password_search()
  str += get_password_cache_table(PasswordCache.get_top_sum('password_cache_password_count', 'password_cache_password_id', TOP_SIZE))
  str += "<p><a href='/passwords'>More passwords...</a> [<a href='/downloads/passwords.csv.bz2'>Download</a> | <a href='/downloads/passwords_with_count.csv.bz2'>Download w/ count</a> | <a href='/downloads/passwords_with_hash.csv.bz2'>Download w/ hash</a> | <a href='/downloads/passwords_with_details.csv.bz2'>Download w/ details</a>]</p>\n"

  str += "<h1>Top hashes</h1>"
  str += get_hash_search()
  str += get_hash_table(Hashes.get_top('hash_count', TOP_SIZE))
  str += "<p><a href='/hashes'>More hashes...</a> [<a href='/downloads/hashes.csv.bz2'>download</a> | <a href='/downloads/hashes_with_count.csv.bz2'>download w/ counts</a>]</p>"

  str += "<h1>Top uncracked hashes</h1>"
  str += get_hash_table(Hashes.get_top('hash_count', TOP_SIZE, {:where => "`hash_password_id`='0'"}))
  str += "<p><a href='/hashes/uncracked'>More uncracked hashes...</a> [<a href='/downloads/uncracked_hashes.csv.bz2'>download</a> | <a href='/downloads/uncracked_hashes_with_count.csv.bz2'>download w/ counts</a>]</p>"

  str += "<h1>Top masks</h1>"
  str += get_mask_table(Masks.get_top('c_password_count', TOP_SIZE))
  str += "<p><a href='/masks'>More masks...</a> [<a href='/downloads/masks.csv.bz2'>download</a>]</p>"

  str += "<h1>Top crackers</h1>"
  str += get_cracker_table(Crackers.get_top('c_total_hashes', TOP_SIZE))
  str += "<p><a href='/crackers'>More crackers...</a> [<a href='/downloads/crackers.csv.bz2'>download</a>]</p>"

  return str
end

get '/breaches' do
  pagination = Pagination.new('/breaches', params, Breaches.get_count, 'c_total_hashes', 'DESC')

  str = ''
  str += "<h1>Breaches</h1>\n"
  str += "<p><a href='/'>Home</a></p>\n"
  str += "<p><a href='/downloads/breaches.csv.bz2'>Download</a></p>\n"
  str += pagination.get_html()
  str += get_breach_table(Breaches.query_ex({ :pagination => pagination }))
  str += pagination.get_html()

  return str
end

get '/dictionaries' do
  pagination = Pagination.new('/dictionaries', params, Dictionaries.get_count, 'c_word_count', 'DESC')

  str = ''
  str += "<h1>Dictionaries</h1>\n"
  str += "<p><a href='/'>Home</a></p>\n"
  str += "<p><a href='/downloads/dictionaries.csv.bz2'>Download</a></p>\n"
  str += pagination.get_html()
  str += get_dictionary_table(Dictionaries.query_ex({ :pagination => pagination }))
  str += pagination.get_html()

  return str
end

get '/hash_types' do
  pagination = Pagination.new('/hash_types', params, HashTypes.get_count, 'c_total_hashes', 'DESC')

  str = ''
  str += "<h1>Hash Types</h1>\n"
  str += "<p><a href='/'>Home</a></p>\n"
  str += "<p><a href='/downloads/hash_types.csv.bz2'>Download</a></p>\n"
  str += pagination.get_html()
  str += get_hash_type_table(HashTypes.query_ex({:pagination => pagination}), pagination)
  str += pagination.get_html()

  return str
end

get '/passwords' do
  count = PasswordCache.get_aggregate_count('password_cache_password_count', 'password_cache_password_id', 'SUM')
  pagination = Pagination.new('/passwords', params, count, 'password_cache_password_count', 'DESC')
  table = PasswordCache.get_aggregate('password_cache_password_count', 'password_cache_password_id', 'SUM', {:pagination => pagination})
  

  str = ''
  str += "<h1>Passwords</h1>\n"
  str += "<p><a href='/downloads/passwords.csv.bz2'>Download</a> | <a href='/downloads/passwords_with_count.csv.bz2'>Download w/ count</a> | <a href='/downloads/passwords_with_hash.csv.bz2'>Download w/ hash</a> | <a href='/downloads/passwords_with_details.csv.bz2'>Download w/ details</a> </p>\n"
  str += "<p><a href='/'>Home</a></p>\n"
  str += pagination.get_html()
  str += get_password_cache_table(table, pagination)
  str += pagination.get_html()

  return str
end

get '/hashes' do
  pagination = Pagination.new('/hashes', params, Hashes.get_count, 'hash_count', 'DESC')

  str = ''
  str += "<h1>Hashes</h1>\n"
  str += "<p><a href='/'>Home</a></p>\n"
  str += "<p><a href='/downloads/hashes.csv.bz2'>Download</a> | <a href='/downloads/hashes_with_count.csv.bz2'>Download w/ count</a> </p>\n"
  str += pagination.get_html()
  str += get_hash_table(Hashes.query_ex({:pagination => pagination}), pagination)
  str += pagination.get_html()

  return str
end

get '/hashes/uncracked' do
  query = {:where => "`hash_password_id`='0'"}
  query[:pagination] = Pagination.new('/hashes', params, Hashes.get_count(query), 'hash_count', 'DESC')

  str = ''
  str += "<h1>Uncracked hashes</h1>\n"
  str += "<p><a href='/'>Home</a></p>\n"
  str += "<p><a href='/downloads/uncracked_hashes.csv.bz2'>Download</a> | <a href='/downloads/uncracked_hashes_with_count.csv.bz2'>Download w/ count</a> </p>\n"
  str += query[:pagination].get_html()
  str += get_hash_table(Hashes.query_ex(query), query[:pagination])
  str += query[:pagination].get_html()

  return str
end

get '/masks' do
  pagination = Pagination.new('/masks', params, Masks.get_count, 'c_password_count', 'DESC')

  str = ''
  str += "<h1>Masks</h1>\n"
  str += "<p><a href='/'>Home</a></p>\n"
  str += "<p><a href='/downloads/masks.csv.bz2'>Download</a></p>\n"
  str += pagination.get_html()
  str += get_mask_table(Masks.query_ex({:pagination => pagination}), pagination)
  str += pagination.get_html()

  return str
end

get '/crackers' do
  pagination = Pagination.new('/crackers', params, Crackers.get_count, 'c_total_hashes', 'DESC')

  str = ''
  str += "<h1>Crackers</h1>\n"
  str += "<p><a href='/'>Home</a></p>\n"
  str += "<p><a href='/downloads/crackers.csv.bz2'>Download</a></p>\n"
  str += pagination.get_html()
  str += get_cracker_table(Crackers.query_ex({:pagination => pagination}), pagination)
  str += pagination.get_html()

  return str
end

get /^\/breach\/([\d]+)$/ do |breach_id|
  breach = Breaches.get(breach_id)
  if(breach.nil?)
    return 'Breach not found'
  end

  clean_name = Db.get_filename(breach['breach_name'])

  str = ""
  str += "<h1>Breach: #{breach['breach_name']}</h1>\n"
  str += "<h2>Details</h2>\n"
  str += "<table>\n"
  str += "<tr><th>Date of breach</th><td>#{breach['breach_date']}</td></tr>\n"
  str += "<tr><th>URL</th><td>#{breach['breach_url']}</td></tr>\n"

  str += "<tr><th>Download passwords</th><td>"
  str += " <a href='/downloads/#{clean_name}_passwords.csv.bz2'>list</a> | "
  str += " <a href='/downloads/#{clean_name}_passwords_with_count.csv.bz2'>w/ count</a> | "
  str += " <a href='/downloads/#{clean_name}_passwords_with_hash.csv.bz2'>w/ hash</a> | "
  str += " <a href='/downloads/#{clean_name}_passwords_with_details.csv.bz2'>w/ details</a>"
  str += "</td></tr>\n"

  str += "<tr><th>Download hashes</th><td>"
  str += " <a href='/downloads/#{clean_name}_hashes.csv.bz2'>all</a> | "
  str += " <a href='/downloads/#{clean_name}_uncracked_hashes.csv.bz2'>uncracked</a> "
  str += "</td></tr>\n"

  str += "<tr><th>Notes</th><td>#{breach['breach_notes']}</td></tr>\n"
  str += "</table>\n"
  str += "<a href='/breaches'>Back to breach list</a>\n"

  str += "<h2>Top hashes</h2>\n"
  str += get_hash_table(Hashes.get_top('hash_count', TOP_SIZE, {:where => "`hash_breach_id`='#{breach['breach_id']}'"}))
  str += "<p><a href='/breach/#{breach['breach_id']}/hashes'>More hashes...</a></p>"

  str += "<h2>Top uncracked hashes</h2>\n"
  str += get_hash_table(Hashes.get_top('hash_count', TOP_SIZE, {:where => "`hash_breach_id`='#{breach['breach_id']}' AND `hash_password_id`='0'"}))

  str += "<p><a href='/breach/#{breach['breach_id']}/hashes/uncracked'>More uncracked hashes...</a></p>"

  str += "<h2>Top passwords</h2>\n"
  str += get_password_cache_table(PasswordCache.get_top_sum('password_cache_password_count', 'password_cache_password_id', TOP_SIZE, { :where => "`password_cache_breach_id`='#{Mysql::quote(breach_id)}'"}))
  str += "<p><a href='/breach/#{breach['breach_id']}/passwords'>More passwords...</a></p>"
  
  return str
end

get /^\/dictionary\/([\d]+)$/ do |dictionary_id|
  dictionary = Dictionaries.get(dictionary_id)
  if(dictionary.nil?)
    return 'Dictionary not found'
  end

  clean_name = Db.get_filename(dictionary['dictionary_name'])

  str = ""
  str += "<h1>Dictionary: #{dictionary['dictionary_name']}</h1>\n"
  str += "<h2>Details</h2>\n"
  str += "<table>\n"
  str += "<tr><th>Creation date</th><td>#{dictionary['dictionary_date']}</td></tr>\n"
  str += "<tr><th>Notes</th><td>#{dictionary['dictionary_notes']}</td></tr>\n"
  str += "<tr><th>Download</th><td><a href='/downloads/#{clean_name}_words.csv.bz2'>Download</a></td></tr>\n"
  str += "</table>\n"

  str += "<a href='/dictionaries'>Back to dictionary list</a>\n"

  query = { :where => "`dictionary_word_dictionary_id`='#{dictionary['dictionary_id']}'" }

  query[:pagination] = Pagination.new("/dictionary/#{dictionary['dictionary_id']}", params, DictionaryWords.get_count(query), 'dictionary_word_word', 'ASC')

  str += "<h2>Words</h2>\n"

  str += "<p><a href='/'>Home</a></p>\n"
  str += query[:pagination].get_html()
  str += get_dictionary_words_table(DictionaryWords.query_ex(query), query[:pagination])
  str += query[:pagination].get_html()
  return str


  return str
end

get /^\/breach\/([\d]+)\/hashes$/ do |breach_id|
  breach = Breaches.get(breach_id)
  if(breach.nil?)
    return 'Breach not found'
  end

  query = { :where => "`hash_breach_id`='#{breach['breach_id']}'" }

  query[:pagination] = Pagination.new("/breach/#{breach['breach_id']}/hashes", params, Hashes.get_count(query), 'hash_count', 'DESC')

  str = ""
  str += "<h2>Hashes for #{breach['breach_name']}</h2>\n"

  str += "<p><a href='/'>Home</a></p>\n"
  str += "<p><a href='/breach/#{breach['breach_id']}'>Back to #{breach['breach_name']}</a></p>\n"
  str += "<p><a href='/downloads/#{Db.get_filename(breach['breach_name'])}_hashes.csv.bz2'>Download</a></p>"
  str += query[:pagination].get_html()
  str += get_hash_table(Hashes.query_ex(query), query[:pagination])
  str += query[:pagination].get_html()
  return str
end

get /^\/breach\/([\d]+)\/hashes\/uncracked$/ do |breach_id|
  breach = Breaches.get(breach_id)
  if(breach.nil?)
    return 'Breach not found'
  end

  query = { :where => "`hash_breach_id`='#{breach['breach_id']}' AND `hash_password_id`='0'" }
  query[:pagination] = Pagination.new("/breach/#{breach['breach_id']}/hashes/uncracked", params, Hashes.get_count(query), 'hash_count', 'DESC')

  str = ""
  str += "<h2>Hashes for #{breach['breach_name']}</h2>\n"

  str += "<p><a href='/'>Home</a></p>\n"
  str += "<p><a href='/breach/#{breach['breach_id']}'>Back to #{breach['breach_name']}</a></p>\n"
  str += "<p><a href='/downloads/#{Db.get_filename(breach['breach_name'])}_uncracked_hashes.csv.bz2'>Download</a></p>"
  str += query[:pagination].get_html()
  str += get_hash_table(Hashes.query_ex(query))
  str += query[:pagination].get_html()
  return str
end

get /^\/breach\/([\d]+)\/passwords$/ do |breach_id|
  breach = Breaches.get(breach_id)
  if(breach.nil?)
    return 'Breach not found'
  end

  query = { :where => "`password_cache_breach_id`='#{breach['breach_id']}'" }
  query[:pagination] = Pagination.new("/breach/#{breach['breach_id']}/passwords", params, PasswordCache.get_count(query), 'password_cache_password_count', 'DESC')

  str = ""
  str += "<h2>Passwords for #{breach['breach_name']}</h2>\n"

  str += "<p><a href='/'>Home</a></p>\n"
  str += "<p><a href='/breach/#{breach['breach_id']}'>Back to #{breach['breach_name']}</a></p>\n"

  clean_name = Db.get_filename(breach['breach_name'])
  str += "<p><a href='/downloads/#{clean_name}_passwords.csv.bz2'>Download list</a></p>"
  str += "<p><a href='/downloads/#{clean_name}_passwords_with_count.csv.bz2'>Download list w/ count</a></p>"
  str += "<p><a href='/downloads/#{clean_name}_passwords_with_hash.csv.bz2'>Download list w/ hash</a></p>"
  str += "<p><a href='/downloads/#{clean_name}_passwords_with_details.csv.bz2'>Download list w/ details</a></p>"

  str += query[:pagination].get_html()
  str += get_password_cache_table(PasswordCache.query_ex(query), query[:pagination])
  str += query[:pagination].get_html()
  return str
end

get /^\/hash_type\/([\d]+)$/ do |hash_type_id|
  hash_type = HashTypes.get(hash_type_id)
  if(hash_type.nil?)
    return 'Hash type not found'
  end

  str = ""
  str += "<h1>Hash type: #{hash_type['hash_type_english_name']}</h1>\n"
  str += "<h2>Details</h2>\n"
  str += "<table>\n"
  str += "<tr><th>Pattern</th><td>#{hash_type['hash_type_pattern']}</td></tr>\n"
  str += "<tr><th>Example</th><td>#{hash_type['hash_type_example']}</td></tr>\n"
  str += "<tr><th>(plaintext)</th><td>#{hash_type['hash_type_example_plaintext']}</td></tr>\n"
  str += "<tr><th>Notes</th><td>#{hash_type['hash_type_notes']}</td></tr>\n"
  str += "<tr><th>Total hashes</th><td>#{hash_type['c_total_hashes']}</td></tr>\n"
  str += "<tr><th>Distinct hashes</th><td>#{hash_type['c_distinct_hashes']}</td></tr>\n"
  str += "<tr><th>Total cracked passwords</th><td>#{hash_type['c_total_passwords']}</td></tr>\n"
  str += "<tr><th>Distinct cracked passwords</th><td>#{hash_type['c_distinct_passwords']}</td></tr>\n"

  clean_name = Db.get_filename(hash_type['hash_type_english_name'])
  str += "<tr><th>Download passwords</th><td>"
  str += " <a href='/downloads/#{clean_name}_passwords.csv.bz2'>list</a> | "
  str += " <a href='/downloads/#{clean_name}_passwords_with_count.csv.bz2'>w/ count</a> | "
  str += " <a href='/downloads/#{clean_name}_passwords_with_hash.csv.bz2'>w/ hash</a> | "
  str += " <a href='/downloads/#{clean_name}_passwords_with_details.csv.bz2'>w/ details</a>"
  str += "</td></tr>\n"

  str += "<tr><th>Download hashes</th><td>"
  str += " <a href='/downloads/#{clean_name}_hashes.csv.bz2'>all</a> | "
  str += " <a href='/downloads/#{clean_name}_uncracked_hashes.csv.bz2'>uncracked</a> "
  str += "</td></tr>\n"

  str += "</table>\n"
  str += "<a href='/hashes'>Back to hash list</a>\n"

  str += "<h2>Top hashes</h2>\n"
  str += get_hash_table(Hashes.get_top('hash_count', TOP_SIZE, {:where => "`hash_hash_type_id`='#{hash_type['hash_type_id']}'"}))
  str += "<p><a href='/hash_type/#{hash_type['hash_type_id']}/hashes'>More hashes...</a></p>"

  str += "<h2>Top uncracked hashes</h2>\n"
  str += get_hash_table(Hashes.get_top('hash_count', TOP_SIZE, {:where => "`hash_password_id`='0' AND `hash_hash_type_id`='#{hash_type['hash_type_id']}'"}))
  str += "<p><a href='/hash_type/#{hash_type['hash_type_id']}/hashes/uncracked'>More uncracked hashes...</a></p>"

  str += "<h2>Top passwords</h2>\n"
  str += get_password_cache_table(PasswordCache.get_top_sum('password_cache_password_count', 'password_cache_password_id', TOP_SIZE, {:where => "`password_cache_hash_type_id`='#{hash_type['hash_type_id']}'"}))
  str += "<p><a href='/hash_type/#{hash_type['hash_type_id']}/passwords'>More passwords...</a></p>"
  
  return str
end

get /^\/hash_type\/([\d]+)\/hashes$/ do |hash_type_id|
  hash_type = HashTypes.get(hash_type_id)
  if(hash_type.nil?)
    return 'Hash type not found'
  end

  query = { :where => "`hash_hash_type_id`='#{hash_type['hash_type_id']}'" }

  query[:pagination] = Pagination.new("/hash_type/#{hash_type['hash_type_id']}/hashes", params, Hashes.get_count(query), 'hash_count', 'DESC')

  str = ""
  str += "<h2>Hashes for #{hash_type['hash_type_english_name']}</h2>\n"

  str += "<p><a href='/'>Home</a></p>\n"
  str += "<p><a href='/hash_type/#{hash_type['hash_type_id']}'>Back to #{hash_type['hash_type_english_name']}</a></p>\n"
  str += "<p><a href='/downloads/#{Db.get_filename(hash_type['hash_type_english_name'])}_hashes.csv.bz2'>Download</a></p>"
  str += query[:pagination].get_html()
  str += get_hash_table(Hashes.query_ex(query), query[:pagination])
  str += query[:pagination].get_html()
  return str
end

get /^\/hash_type\/([\d]+)\/hashes\/uncracked$/ do |hash_type_id|
  hash_type = HashTypes.get(hash_type_id)
  if(hash_type.nil?)
    return 'Hash type not found'
  end

  query = { :where => "`hash_hash_type_id`='#{hash_type['hash_type_id']}' AND `hash_password_id`='0'" }

  query[:pagination] = Pagination.new("/hash_type/#{hash_type['hash_type_id']}/hashes", params, Hashes.get_count(query), 'hash_count', 'DESC')

  str = ""
  str += "<h2>Uncracked hashes for #{hash_type['hash_type_english_name']}</h2>\n"

  str += "<p><a href='/'>Home</a></p>\n"
  str += "<p><a href='/hash_type/#{hash_type['hash_type_id']}'>Back to #{hash_type['hash_type_english_name']}</a></p>\n"
  str += "<p><a href='/downloads/#{Db.get_filename(hash_type['hash_type_english_name'])}_uncracked_hashes.csv.bz2'>Download</a></p>"
  str += query[:pagination].get_html()
  str += get_hash_table(Hashes.query_ex(query), query[:pagination])
  str += query[:pagination].get_html()
  return str
end

get /^\/hash_type\/([\d]+)\/passwords$/ do |hash_type_id|
  hash_type = HashTypes.get(hash_type_id)
  if(hash_type.nil?)
    return 'Hash type not found'
  end

  query = { :columns => [
              {:name => '*'},
              {:name => 'password_cache_password_count', :aggregate => 'sum', :as => 'password_count' }
            ],
            :where => "`password_cache_hash_type_id`='#{hash_type['hash_type_id']}'",
            :groupby => "password_cache_password_id"
  }

  query[:pagination] = Pagination.new("/hash_type/#{hash_type['hash_type_id']}/passwords", params, PasswordCache.get_count(query), 'password_cache_password_count', 'DESC')

  str = ""
  str += "<h2>Passwords for #{hash_type['hash_type_english_name']}</h2>\n"

  str += "<p><a href='/'>Home</a></p>\n"
  str += "<p><a href='/hash_type/#{hash_type['hash_type_id']}'>Back to #{hash_type['hash_type_english_name']}</a></p>\n"

  clean_name = Db.get_filename(hash_type['hash_type_english_name'])
  str += "<p><a href='/downloads/#{clean_name}_passwords.csv.bz2'>Download list</a></p>"
  str += "<p><a href='/downloads/#{clean_name}_passwords_with_count.csv.bz2'>Download list w/ count</a></p>"
  str += "<p><a href='/downloads/#{clean_name}_passwords_with_hash.csv.bz2'>Download list w/ hash</a></p>"
  str += "<p><a href='/downloads/#{clean_name}_passwords_with_details.csv.bz2'>Download list w/ details</a></p>"

  str += query[:pagination].get_html()
  str += get_password_cache_table(PasswordCache.query_ex(query), query[:pagination])
  str += query[:pagination].get_html()
  return str
end

get /^\/password\/([\d]+)$/ do |password_id|
  password = Passwords.get(password_id)
  if(password.nil?)
    return 'Password not found'
  end

  str = ""
  str += "<h1>Password: #{password['password_password']}</h1>\n"
  str += "<h2>Details</h2>\n"
  str += "<table>\n"
  str += "<tr><th>Date cracked</th><td>#{password['password_date']}</td></tr>\n"
  str += "</table>\n"
  str += "<a href='/passwords'>Back to password list</a>\n"

  
  str += "<h2>Hash representations</h2>\n"
  str += get_hash_table(Hashes.query_ex({:where => "`hash_password_id`='#{password_id}'"}))

  return str
end

get /^\/mask\/([\d]+)$/ do |mask_id|
  mask = Masks.get(mask_id)

  if(mask.nil?)
    return 'Mask not found'
  end

  query = { :columns => [
              {:name => '*'},
              {:name => 'password_cache_password_count', :aggregate => 'sum', :as => 'password_cache_password_count' }
            ],
            :where => "`password_cache_mask_id`='#{mask['mask_id']}'",
            :groupby => "password_cache_password_id"
  }

  query[:pagination] = Pagination.new("/mask/#{mask['mask_id']}/passwords", params, PasswordCache.get_count(query), 'password_cache_password_count', 'DESC')

  str = ""
  str += "<h2>Passwords for #{mask['mask_mask']}</h2>\n"

  str += "<p><a href='/'>Home</a></p>\n"
  str += "<p><a href='/mask/#{mask['mask_id']}'>Back to #{mask['mask_mask']}</a></p>\n"
  str += query[:pagination].get_html()
  str += get_password_cache_table(PasswordCache.query_ex(query), query[:pagination])
  str += query[:pagination].get_html()
  return str
end

get /^\/cracker\/([\d]+)$/ do |cracker_id|
  cracker = Crackers.get(cracker_id)

  query = { :where => "`hash_cracker_id`='#{cracker_id}'" }
  query[:pagination] = Pagination.new("/cracker/#{cracker_id}", params, Hashes.get_count(query), 'hash_count', 'DESC')

  str = ''
  str += "<h1>Cracker: #{cracker['cracker_name']}</h1>\n"
  str += "<p><a href='/'>Home</a></p>\n"
  str += "<p><a href='/crackers'>Crackers</a></p>\n"
  str += query[:pagination].get_html()
  str += get_hash_table(Hashes.query_ex(query), query[:pagination])
  str += query[:pagination].get_html()

  return str
end

get /^\/search\/hash\/$/ do
  # IMPORTANT: sanitize the hash, since it can be anything
  hash = params['hash']

  str = ''
  if(!hash.nil?)
    hash_sql  = Mysql::quote(hash)
    hash_html = hash.gsub("&", "&amp;").gsub("'", "&apos;").gsub('"', "&quot;").gsub("<", "&lt;").gsub(">", "&gt;")
    hash = ''

    query = { :where => "`hash_hash` LIKE '%#{hash_sql}%'" }

    query[:pagination] = Pagination.new("/search/hash/?hash=#{hash_html}", params, Hashes.get_count(query), 'hash_count', 'DESC')

    str = ''
    str += "<h1>Hashes containing '#{hash_html}':</h1>\n"
    str += "<p><a href='/'>Home</a></p>\n"
    str += query[:pagination].get_html()
    str += get_hash_table(Hashes.query_ex(query), query[:pagination])
    str += query[:pagination].get_html()
    str += get_hash_search(hash_html)
  else
    str += get_hash_search()
  end

  return str
end

get /^\/search\/password\/$/ do
  password = params['password']

  str = ''
  if(!password.nil?)
    # IMPORTANT: sanitize the password, since it can be anything
    password_sql  = Mysql::quote(password)
    password_html = password.gsub("&", "&amp;").gsub("'", "&apos;").gsub('"', "&quot;").gsub("<", "&lt;").gsub(">", "&gt;")
    password = ''

    query = { :where => "`password_cache_password_password` LIKE '%#{password_sql}%'" }

    query[:pagination] = Pagination.new("/search/password/?password=#{password_html}", params, PasswordCache.get_count(query), 'password_cache_password_password', 'ASC')

    str += "<h1>Passwords containing '#{password_html}':</h1>\n"
    str += "<p><a href='/'>Home</a></p>\n"
    str += query[:pagination].get_html()
    str += get_password_cache_table(PasswordCache.query_ex(query), query[:pagination])
    str += query[:pagination].get_html()
    str += get_password_search(password_html)
  else
    str += get_password_search()
  end

  return str
end

get '/submissions' do
  return "
<h1>Submissions</h1>

<p>Thanks for offering to help crack passwords! Any help goes a long way towards password research!</p>

<p>The first thing you should do is visit the <a href='/hashes/uncracked'>uncracked hashes</a> page, or pick a <a href='/breaches'>breach</a> or <a href='/hash_types'>hash type</a> you're interested in.</p>

<p>Then run the hashes through <a href='http://www.openwall.com/john/'>John the Ripper</a>, <a href='http://hashcat.net/oclhashcat-plus/'>Hashcat</a>, or whatever tool you like.</p>

<p>Finally, copy/paste your passwords into the field below, one password per line. The hashes aren't necessary unless you're cracking a particularly slow protocol - such as bcrypt or phpass - in which case I'd ask that you start each line with the hash, followed by a colon.</p>

<p>Note: results won't show up right away, they're cached and processed in batches.</p>

<form action='/submissions/submit' method='post'>
  <p><textarea name='passwords' rows='10' cols='60'></textarea></p>
  <p>Your name, if you want credit: <input type='text' name='cracker' value='anonymous'></p>
  <p><input type='submit' value='Submit'></p>
</form>

<form action='/submissions/test' method='post' enctype='multipart/form-data'>
  <p>File: <input type='file' name='file'></p>
  <p>Note: Format can be .txt or .bz2.</p>
  <p>One password per line, optionally with the hash and a colon before the password (eg, '1a2b3c:password')
  <p>Your name, if you want credit: <input type='text' name='cracker' value='anonymous'></p>
  <p><input type='submit' value='Submit'></p>
</form>
"
end

post '/submissions/test' do
  file = params['file'][:tempfile]
  if(params['file'][:filename] =~ /\.bz2$/)
    file = Bzip2::Reader.new(params['file'][:tempfile])
  end
    
  submissions = file.readlines
  Submissions.import_submissions(submissions, params['cracker'], @env['REMOTE_ADDR'])

  return "<p>Your #{submissions.count} submissions have been saved and will be rolled into the active set at our next batch update. Thanks for your help!</p>
          <p><a href='/'>Home</a></p>"
end

post '/submissions/submit' do
  submissions  = params['passwords'].split(/\r\n|\n|\r/)

  Submissions.import_submissions(submissions, params['cracker'], @env['REMOTE_ADDR'])

  return "<p>Your #{submissions.count} submissions have been saved and will be rolled into the active set at our next batch update. Thanks for your help!</p>
          <p><a href='/'>Home</a></p>"
end

get '/faq' do
return "<h1>FAQ</h1>
<p>What, exactly, are you doing?</p>
<p>I collect statistical data on <em>public</em> password breaches.</p>

<p>Are you hurting people?</p>
<p>No, my goal is to raise awareness, particularly for people storing passwords, and help prevent this from happening again. All data on my site was, at one time or another, posted publicly, and we can therefore be certain that the bad guys have not only the passwords, but the email addresses, usernames, and any other leaked information as well. Please see this blog post for more information.</p>

<p>Can I send you a breach privately?</p>
<p>Only if it's a publicly known breach that's already been posted offline. If you compromised a site yourself and want to send me the details, you've come to the wrong place.</p>

<p>Are you releasing private data?</p>
<p>No. I only release information that's already out there and that the \"bad guys\" already have.</p>

<p>Are you releasing personal data?</p>
<p>No. I only release aggregate password data, nothing else.</p>

<p>My site's listed here!</p>
<p>That sucks, but remember that somebody, somewhere, has the rest of your data, too. It's your responsibility to make sure this doesn't happen again! </p>

<p>How can I prevent this type of thing from happening to me?</p>
<p>There are plenty of ways!</p>
<ul>
  <li>Implement good security and coding standards on your sites</li>
  <li>Use a 3rd party password system (Facebook, Google, OpenID, Yahoo, etc)</li>
  <li>Hash passwords with a slow algorithm - bcrypt, phpass-md5, etc</li>
</ul>

<p>Can you send me the (usernames/email addresses/etc) from a site?</p>
<p>No. I don't share (or keep) identifying information - that is, information that can harm people.</p>

<p>Who are you?</p>
<p>I am Ron Bowes. I run SkullSecurity.org. You can find more information about me there.</p>

<p>Is this site affiliated with.....</p>
<p>No (unless you were going to say SkullSecurity.org, my blog). This site is not affiliated with any company or organization.</p>

<p>How can I help?</p>
<p>If you have hardware and a familiarity with john, download uncracked hashes in any format, find any plaintexts you can, and submit them to me.  If not, then spread the word about the importance of password security!</p>

<p>Why don't you let me create an account when I submit cracks?</p>
<p>I refuse to store any private data in this database. 100% of the breachdb site and database are available as snapshots to anybody who wants them - any less would be an invitation to steal them from me anyways. :)</p>"

end
