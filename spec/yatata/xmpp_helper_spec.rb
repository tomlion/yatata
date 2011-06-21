require File.expand_path "../../spec_helper", __FILE__

describe XmppHelper do
  
  describe XmppBuilder do
    before(:each) do
      @client = Yatata::Client.new
      @client.setup('me@me.com', 'me')
      @stream = mock('stream')
      @client.post_init @stream, Blather::JID.new('me.com')
    end

    it 'build discover_nodes stanza' do
      node_name = 'testnodename'
      XmppBuilder.new(@client).discover_nodes(node_name).should == "<iq type=\"get\" from=\"me.com\" to=\"pubsub.localhost\"><query xmlns=\"http://jabber.org/protocol/disco#items\" node=\"testnodename\"/></iq>\n"
    end

    
  end

  #describe XmppClient do
    #it 'deliver stanza' do
      #XmppClient.connect('me@me.com', 'pass').deliver(XmppBuilder.build_discover_nodes)
      #MockServer.should_receiver(:receive_data).with do |*params|
        #p params
      #end
    #end
  #end

  #it 'writes to the stream' do
    #stanza = Blather::Stanza::Iq.new
    #stream = mock()
    #stream.expects(:send).with stanza
    #@client.setup('me@me.com', 'me')
    #@client.post_init stream, Blather::JID.new('me.com')
    #@client.write stanza
  #end
end  
