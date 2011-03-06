module Breach
  class Password < Sequel::Model(:password)
    set_primary_key :password_id
  end
end
