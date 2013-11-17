require 'cgi'
require 'nokogiri'

module Esendex
  class SentMessageClient
    END_POINT = "/v1.0/messageheaders"
    DEFAULT_COUNT = 30

    attr_accessor :api_connection

    def initialize(api_connection = ApiConnection.new)
      @api_connection = api_connection
    end

    def get_messages(criteria={})
      criteria[:count] = DEFAULT_COUNT unless criteria.key?(:count)
      criteria[:start_index] = (criteria[:page] - 1) * criteria[:count] if criteria.key?(:page) and criteria[:page] > 0
      
      request_uri = generate_uri criteria
      response = api_connection.get request_uri

      root = Nokogiri::XML.parse(response.body).root()
      start_index = root['startindex'].to_i
      total_messages = root['totalcount'].to_i

      return SentMessagesResult.new(0, 0, []) if total_messages == 0

      messages = root.css('messageheader').map do |header|
        parse_header header
      end

      page_size = criteria[:count]
      page, pages = calculate_paging start_index, total_messages, page_size

      previous_page_criteria = criteria.clone.merge(count: page_size, start_index: start_index - page_size)
      previous_page_func = page == 1 ? nil : lambda { get_messages(previous_page_criteria) }

      next_page_criteria = criteria.clone.merge(count: page_size, start_index: start_index + page_size)
      next_page_func = page == pages ? nil : lambda { get_messages(next_page_criteria) }
      
      SentMessagesResult.new page, total_messages, messages, previous_page_func, next_page_func
    end

    def calculate_paging(index, total, page_size)
      pages = (total.to_f / page_size).ceil
      return 1, pages if index == 0
      return ((index + 1).to_f / page_size).ceil, pages
    end

    def get_message(message_id)
      response = api_connection.get "#{END_POINT}/#{message_id}"
      parse_header Nokogiri::XML.parse(response.body).root()
    end

    def parse_header(header)
      SentMessage.new({ 
        id: header['id'],
        account: header.at('reference').text,
        status: header.at('status').text,
        status_at: parse_date(header.at('laststatusat')),
        submitted_by: header.at('username').text,
        submitted_at: parse_date(header.at('submittedat')),
        sent_at: parse_date(header.at('sentat')),
        delivered_at: parse_date(header.at('deliveredat')),
        from: header.at('from phonenumber').text,
        to: format_contact(header.at('to')),
        type: header.at('type').text,
        sms_parts: header.at('parts').text.to_i,
        summary: header.at('summary').text
      }, lambda { 
        response = api_connection.get(header.at('body')['uri'])
        Nokogiri::XML.parse(response.body).at('bodytext').text
      })
    end

    def parse_date(node)
      return nil if node.nil?
      DateTime.iso8601(node.text)
    end

    def format_contact(contact_node)
      number = contact_node.at('phonenumber').text
      if contact_node.at('displayname').nil? then 
        number
      else 
        "#{contact_node.at('displayname').text} <#{number}>"
      end
    end

    def generate_uri(criteria)
      uri = URI.parse("#{END_POINT}?")
      separator = ''
      %w(account_reference start finish start_index count).each do |key|
        next unless criteria.key?(key.to_sym)
        uri.query += "#{separator}#{key.delete('_')}=#{CGI.escape(criteria[key.to_sym].to_s)}"
        separator = '&'
      end
      uri.to_s
    end

    private :calculate_paging, :parse_header, :parse_date, :format_contact, :generate_uri
  end
end
