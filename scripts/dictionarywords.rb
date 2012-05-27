require 'rubygems'
require 'mysql'
require 'breachdb'

class DictionaryWords < Breachdb
  def self.table_name()
    return 'dictionary_word'
  end
  def self.id_column
    return 'dictionary_word_id'
  end

  def self.cache_update()
    # Not necessary
  end

  def self.export_files()
    files = []

    dictionaries = Dictionaries.query_ex

    dictionaries.each do |dictionary|
      name_clean = get_filename(dictionary['dictionary_name'])

      files << {
        :filename => "downloads/#{name_clean}.csv.bz2",
        :description => "Words from dictionary #{dictionary['dictionary_name']}",
        :show_header => false,
        :query => {
          :columns => [
            { :name => 'dictionary_word_word' },
          ],
          :where => "`dictionary_word_dictionary_id`='#{dictionary['dictionary_id']}'",
          :orderby => 'dictionary_word_word',
        }
      }
    end

    return files
  end
end
