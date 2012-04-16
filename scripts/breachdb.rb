require 'rubygems'
require 'db'

class Breachdb < Db
  ##
  # Take the result from a query to a table with cache columns
  # (c_total_hashes, c_total_passwords, c_distinct_hashes,
  # c_distinct_passwords), and create new fields:
  # * c_total_percentage
  # * c_distinct_percentage
  # * c_total_string
  # * c_distinct_string
  #
  # @param result The result table to update (will be modified)
  #
  # @return result
  ##
  def self.calculate_cracks(result)
    result.each do |r|
      total_hashes       = r['c_total_hashes']
      total_passwords    = r['c_total_passwords']
      total_percentage   = total_hashes.to_i == 0 ? 0 : total_passwords.to_f / total_hashes.to_f
      distinct_hashes    = r['c_distinct_hashes']
      distinct_passwords = r['c_distinct_passwords']
      distinct_percentage= distinct_hashes.to_i == 0 ? 0 : distinct_passwords.to_f / distinct_hashes.to_f

      r['c_total_percentage']    = total_percentage
      r['c_distinct_percentage'] = distinct_percentage
      r['c_total_cracks_string'] = "#{total_passwords} / #{total_hashes} (#{(total_percentage * 10000).round / 100.0}%)"
      r['c_distinct_cracks_string'] = "#{distinct_passwords} / #{distinct_hashes} (#{(distinct_percentage * 10000).round / 100.0}%)"
    end

    return result
  end
end

