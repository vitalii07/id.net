module RSpec::EventMessageInstrument

  def push_event_to_client event
    EventMessageMatcher.new event
  end

  class EventMessageMatcher
    def initialize event
      @event = event
    end

    def supports_block_expectations?
      true
    end

    def matches? block
      subscription = ActiveSupport::Notifications.subscribe @event do |name, start, finish, id, payload|
        @name = name
        @payload = payload
      end

      block.call
      ActiveSupport::Notifications.unsubscribe(subscription)

      check_name? && check_with?
    end

    def with params
      @with_chained = true
      @params = params
      self
    end

    def failure_message
      errors = []
      errors << "event name was called #{@event}"
      errors << "with payload was called #{@payload.blank? ? "nil" : @payload} but should be #{@params}"
      errors.join("\n")
    end

    private

    def check_with?
      return true unless @with_chained
      stringify_values(@params) == stringify_values(@payload)
    end

    def check_name?
      @event == @name
    end

    def stringify_values params={}
      (params || {}).inject({}) do |hash, value|
        hash[value[0].to_sym] = value[1].to_s
        hash
      end
    end
  end
end

module RSpec::Matchers
  include RSpec::EventMessageInstrument
end
