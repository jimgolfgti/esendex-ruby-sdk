require 'nokogiri'

module Esendex
  class Account
    DEFAULT_DATE_OFFSET = 90
    
    attr_accessor :reference
    
    def initialize(account_reference = Esendex.account_reference)
      @reference = account_reference
    end
    
    def api_connection
      @api_connection ||= ApiConnection.new
    end

    def messages_remaining
      response = api_connection.get "/v1.0/accounts"
      doc = Nokogiri::XML(response.body)
      node = doc.at_xpath("//api:account[api:reference='#{@reference}']/api:messagesremaining", 'api' => Esendex::API_NAMESPACE)
      raise AccountReferenceError.new() if node.nil?
      node.content.to_i
    end

    def send_message(args={})
      raise ArgumentError.new(":to required") unless args[:to]
      raise ArgumentError.new(":body required") unless args[:body]

      send_messages([Message.new(args[:to], args[:body], args[:from])])
    end
    
    def send_messages(messages)
      batch_submission = MessageBatchSubmission.new(@reference, messages)
      response = api_connection.post "/v1.0/messagedispatcher", batch_submission.to_s
      DispatcherResult.from_xml response.body
    end

    def sent_messages(args={})
      args[:account_reference] = reference
      args[:start] = args[:finish] - DEFAULT_DATE_OFFSET if args.key?(:finish) and not args.key?(:start)
      args[:finish] = args[:start] + DEFAULT_DATE_OFFSET if args.key?(:start) and not args.key?(:finish)

      SentMessageClient
        .new(api_connection)
        .get_messages(args)
    end
  end
end
