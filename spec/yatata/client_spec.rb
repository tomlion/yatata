require File.expand_path "../../spec_helper", __FILE__

describe Yatata::Client do
  before do
    @client = Yatata::Client.new
    @client.setup('me@me.com', 'me')
    @stream = mock('stream')
    @client.post_init @stream, Blather::JID.new('me.com')
  end

  it 'should queue stanzas when not ready' do
    stanza = '<stream></stream>'
    @client.state = :initializing
    @client.should_receive(:queue).with(stanza).once
    @client.deliver stanza
  end

  it 'should send stanzas when stream ready' do
    stanza = '<iq type="get" id="blather0003"/>'
    @client.should_receive(:write).with(stanza).once
    @client.deliver stanza
  end
  
end  
