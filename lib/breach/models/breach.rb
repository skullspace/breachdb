module Breach
  class Breach < Sequel::Model(:breach)
    one_to_many :hash, :key => :hash_breach_id, :class => 'Breach::Hash'

    def hash_count
      hash_dataset.count
    end

    def cracked_count
      hash_dataset.filter('hash_password_id > 0').count
    end

    def cracked_percentage
      cracked_count/hash_count.to_f
    end
  end
end
