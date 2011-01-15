module Breach
  class Server < Sinatra::Base
    get "/breaches" do
      content_type :json
      Breach.limit(10).map(&:values).to_json 
    end

    get '/submissions' do
      content_type :json
      Submission.limit(10).map(&:values).to_json 
    end

    get '/dictionaries' do 
      content_type :json
      Dictionary.limit(10).map(&:values).to_json 
    end

    get '/dictionary_words' do
      content_type :json
      DictionaryWord.limit(10).map(&:values).to_json 
    end

    get '/hashes' do
      content_type :json
      Hash.limit(10).map(&:values).to_json 
    end

    get '/hash_types' do
      content_type :json
      HashType.limit(10).map(&:values).to_json 
    end
    get '/news' do
      content_type :json
      News.limit(10).map(&:values).to_json 
    end

    get '/passwords' do
      content_type :json
      Password.limit(10).map(&:values).to_json 
    end

    get '/submissions' do
      content_type :json
      Submission.limit(10).map(&:values).to_json 
    end
  end
end
