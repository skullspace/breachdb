module Breach
  class Server < Sinatra::Base
    get "/" do
      "Hello, World!"
    end
  end
end
