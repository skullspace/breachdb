module Breach
  class News < Sequel::Model(:news)
    set_primary_key :news_id
  end
end
