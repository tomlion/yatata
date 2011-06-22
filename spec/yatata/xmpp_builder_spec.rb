require File.expand_path "../../spec_helper", __FILE__

describe XmppBuilder do
  before(:each) do
    @client = XmppClient.new 'n@d/r', 'pass', '127.0.0.1', 12345
    @stream = mock('stream')
    @stream.stub(:send)
    @client.client.post_init @stream, Blather::JID.new('n@d/r')
    @builder = @client.builder
  end

  it 'build discover_nodes stanza' do
    node_name = 'testnodename'
    @builder.build_discover_nodes_message(node_name).should == "<iq type=\"get\" from=\"n@d/r\" to=\"pubsub.localhost\"><query xmlns=\"http://jabber.org/protocol/disco#items\" node=\"testnodename\"/></iq>\n"
  end

end
