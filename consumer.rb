require 'blather/client/client'

class Consumer
  attr_accessor :client

  def initialize(jid, password)
    @client = Client.setup jid, password

    @client.register_handler(:ready) do
      puts "Connected ! send messages to #{client.jid.stripped}."
    end

    @client.register_handler :subscription, :request? do |s|
      client.write s.approve!
    end

    @client.register_handler :message, :chat?, :body do |m|
      client.write Blather::Stanza::Message.new(m.from, "You sent: #{m.body}")
    end

  end

end
