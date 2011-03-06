module Breach
  class Breach < Sequel::Model(:breach)
    set_primary_key :breach_id

    one_to_many :hashes, :key => :hash_breach_id, :class => 'Breach::Hash'

    many_to_many :hash_types,
      :join_table => :hash,
        :right_key => :hash_hash_type_id,
        :left_key  => :hash_breach_id

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

      def uniq_hash_type_names
        hash_types_dataset.distinct.select_map(:hash_type_english_name)
      end
    end

    def cracked_percentage
      return 0 if hash_count == 0
      cracked_count/hash_count.to_f
    end
  end
end
