require 'blather/client/client'

module Yatata
class Client < Blather::Client
  attr_accessor :state
  
  def initialize
    super
    @waiting_stanzas = []
  end
  
  def queue(stanza)
    @waiting_stanzas << stanza
  end
  
  def queue_with_handler(stanza, &handler)
    @waiting_stanzas << [stanza, handler]
  end
  
  def consume_queue
    while stanza = @waiting_stanzas.pop do
      stanza.is_a?(Array) ? write_with_handler(stanza[0], &stanza[1]) : write(stanza)
    end
  end
  
  def run
    connect
  end
  
  [:initializing, :ready].each do |state|
    define_method("#{state}?") { @state == state }
  end
  
  def deliver(stanza)
    ready? ? write(stanza) : queue(stanza)
  end
  
  def deliver_with_handler(stanza, &handler)
    ready? ? write_with_handler(stanza, &handler) : queue_with_handler(stanza, &handler)
  end
  
  def post_init(stream, jid = nil)  # @private
    super(stream, jid)
    consume_queue
  end
  
end # Client
end # Module
