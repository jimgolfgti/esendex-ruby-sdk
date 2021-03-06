module Esendex
  class SentMessage
    @load_body_func
    @cached_body

    def initialize(properties, load_body_func)
      properties.each do |key, value|
        define_singleton_method key, lambda { value }
      end
      @load_body_func = load_body_func
    end

    def body
      @cached_body ||= resolve_body()
    end

    def to_s
      "#{id} to: #{to} @ #{submitted_at}"
    end

    def resolve_body()
      if summary.length < 50
        summary
      else
        @load_body_func.call
      end
    end

    private :resolve_body
  end
end
