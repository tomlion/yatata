require '../lib/yatata'
require 'yaml'

Blather.logger = Logger.new(STDOUT)
Blather.logger.level = Logger::DEBUG

EventMachine::run do
  @client = XmppClient.connect('admin@shout.dev', 'me')
  p '====~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
  @client.discover_nodes('<iq><payload>*************************************************</payload></iq>')
  p '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
end

