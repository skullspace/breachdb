
module Breach
  class Server < Sinatra::Base
    set :haml, :format => :html5

    set :public, File.dirname(__FILE__) + '/public'
    set :views,  File.dirname(__FILE__) + '/views'

    get "/breaches" do
      response["Cache-Control"] = "max-age=60, public"

      @breaches = Breach.all
      haml :'breaches/index'
    end

    get '/breaches/:id' do
      @breach = Breach[params[:id]]
      haml :'breaches/show'
    end

    get '/submissions' do
      content_type :json
      Submission.limit(10).map(&:values).to_json 
    end

    get  '/submissions/new' do
      haml :'submission/new'
    end

    post '/submissions' do 
      puts params[:submission]
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
      content_type :xml
      Hash.limit(10).map(&:values).to_xml
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
