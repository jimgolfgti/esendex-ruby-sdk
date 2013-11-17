require 'nestful'

module Esendex
  class ApiConnection

    def initialize
      options = {
        :auth_type => :basic, 
        :user => Esendex.username, 
        :password => Esendex.password,
        :headers => {
          'User-Agent' => Esendex.user_agent
        },
        :format => ApplicationXmlFormat.new
      }
      @connection = Nestful::Endpoint.new(Esendex.api_host, options)
    end

    def get(url)
      @connection[url].get
    rescue => e
      raise Esendex::ApiErrorFactory.new.get_api_error(e)
    end

    def post(url, body)
      @connection[url].post nil, :body => body
    rescue => e
      raise Esendex::ApiErrorFactory.new.get_api_error(e)
    end
  end

  class ApplicationXmlFormat < Nestful::Formats::Format
    def mime_type
      "application/xml"
    end
  end
end
