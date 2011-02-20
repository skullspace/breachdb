module Breach
  class Breach < Sequel::Model(:breach)
    one_to_many :hash, :key => :hash_breach_id, :class => 'Breach::Hash'

    def hash_count
      hash_dataset.sum(:hash_count).to_i
    end

    def cracked_count
      hash_dataset.filter('hash_password_id > 0').sum(:hash_count).to_i
    end

    def cracked_percentage
      return 0 if hash_count == 0
      cracked_count/hash_count.to_f
    end
  end
end
