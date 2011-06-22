def test_with_block
  p block_given?
  yield
end



#require '../lib/yatata'
#require 'yaml'

#Blather.logger = Logger.new(STDOUT)
#Blather.logger.level = Logger::DEBUG

#EventMachine::run do
  #@client = XmppClient.connect('a@shout.dev/r', 'password')
  #@client.discover_nodes('<iq><payload>*************************************************</payload></iq>')
#end

