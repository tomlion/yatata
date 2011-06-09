require 'eventmachine'
require 'em-synchrony'
require 'em-hiredis'
require 'active_support/json'
require File.join(File.dirname(__FILE__), *%w[lib yatata])

EventMachine.run do
  redis = EM::Hiredis.connect
  redis.subscribe 'stanza'
  redis.on(:message) do |channel, message|
    hash = ActiveSupport::JSON.decode(message)
    credentials = hash['credentials']
    Yatata::ConsumerPool.get(*credentials).consume(hash)
  end
end
