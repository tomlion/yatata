require File.expand_path "../../spec_helper", __FILE__

describe XmppHelper do
  class Account; end
  class Group; end
  class User; def xmpp_jid; 'n@d/r'; end; def xmpp_node; 'n2'; end; end

  def XmppHelper.queue(*strings); end
  def XmppHelper.connect(jid, password)
    client = XmppClient.connect(jid, password, '127.0.0.1', 12345)
    yield client
  end

  class MockServer; end
  module ServerMock
    def receive_data(data)
      @server ||= MockServer.new
      @server.receive_data data, self
    end
  end

  def mocked_server(times = nil, &block)
    MockServer.any_instance.should_receive(:receive_data).send(*(times ? [:exactly, times] : [:at_least, 1])).times.with &block
  end

  before :each do
    @update = mock('update')
    @update.stub(:sender).and_return(User.new)
    @update.stub(:group_message?).and_return(true)
    @update.stub(:receiver).and_return(User.new)
    @update.stub(:to_xmpp_payload).and_return(Blather::Stanza::PubSub::Items.new)
  end

  it "build a stanza then queue it" do
    XmppHelper.should_receive(:queue).once
    XmppHelper.deliver_update(@update)
  end

  it "build a stanza then send it" do
    state = nil
    mocked_server do |val, server|
      case state
      when nil
        state = :completed
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
      when :completed
        EM.stop
        true
      end
    end

    Yatata::Client.any_instance.should_receive(:deliver) do |stnz|
      stnz.should =~ /ooooooooooooo/
    end
    EM.run do
      EM.add_timer(0.5) { EM.stop if EM.reactor_running? }
      EventMachine::start_server '127.0.0.1', 12345, ServerMock

      XmppHelper.discover_nodes('n@d/r', 'pass', 'nooooooooooooooooooode')
    end
  end

end  
