module Yatata
class Consumer
  attr_accessor :client

  def initialize(jid, password)
    @client = Client.setup jid, password
  end
  
  def run
    @client.connect
    self
  end

  def consume(hash)
    p "consume #{hash}, #{@client.ready?}"
    @client.deliver hash['stanza']
  end

end
end
