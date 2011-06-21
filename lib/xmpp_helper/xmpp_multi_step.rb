  class XmppMultiStep
    attr_accessor :steps
    attr_reader :client, :last_reply

    def initialize(client)
      @client = client
      @steps = []
    end

    def step(&block)
      @steps << block
    end

    def run!
      current_stage = 0
      client.connection.add_handler("iq") do |iq|
        @last_reply = iq.to_s
        if @steps[current_stage]
          @steps[current_stage].call
          current_stage += 1
        else
          StropheRuby::EventLoop.stop(client.ctx)
        end
      end
    end

    def method_missing(name, *args, &block)
      step(&block)
    end
  end


