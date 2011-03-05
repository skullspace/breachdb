module Breach
  class Breach < Sequel::Model(:breach)
    one_to_many :hashes, :key => :hash_breach_id, :class => 'Breach::Hash'

    one_to_many( :cracked_hashes,
                 :key   => :hash_breach_id,
                 :class => 'Breach::Hash') do |hashes|
      hashes.filter { hash_password_id > 0}
    end

    cache_methods do
      # hash_count
      #   - first attempts cache hit
      #   - otherwise calls hash_count!
      #
      # hash_count!
      #   - original method
      #
      def hash_count
        hashes_dataset.sum(:hash_count).to_i
      end

      def cracked_count
        cracked_hashes_dataset.sum(:hash_count).to_i
      end

      def hash_types
        DB["SELECT distinct(hash_type.hash_type_english_name) FROM hash INNER JOIN hash_type ON (hash.hash_hash_type_id = hash_type.hash_type_id) WHERE hash_breach_id = #{self.breach_id}"].map {|r| r[:hash_type_english_name] }.join(",")
      end
    end


    def cracked_percentage
      return 0 if hash_count == 0
      cracked_count/hash_count.to_f
    end
  end
end
