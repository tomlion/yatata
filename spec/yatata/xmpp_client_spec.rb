require File.expand_path "../../spec_helper", __FILE__
#Blather.logger = Logger.new(STDOUT)
#Blather.logger.level = Logger::DEBUG

describe XmppClient do
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
    stream = mock('stream')
    stream.stub(:stop)
    stream.stub(:close_connection_after_writing)
    Yatata::Client.any_instance.stub(:stream).and_return(stream)
  end    
  after :each do
    #Yatata::Client.any_instance.unstub(:stream)
  end

  it 'send discover_nodes stanza' do
    state = nil
    mocked_server do |val, server|
      case state
      when nil
        #p "nil: #{val}"
        state = :completed
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"

      #when :bind
        #p "bind: #{val}"
        #state = :session
        #doc = parse_stanza val
        #p "response: <iq id='#{doc.find_first('iq')['id']}' type='result'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'><jid>n@d/r</jid></bind></iq>"
        #server.send_data "<iq id='#{doc.find_first('iq')['id']}' type='result'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'><jid>n@d/r</jid></bind></iq>"
        #server.send_data "<stream:features><session xmlns='urn:ietf:params:xml:ns:xmpp-session' /></stream:features>"

      #when :session
        #p "session: #{val}"
        #state = :roster
        #next if val =~ /xmpp-bind/
        #doc = parse_stanza val
        ##doc.find('/iq[@type="set" and @to="d"]/sess_ns:session', :sess_ns => Blather::Stream::Session::SESSION_NS).should_not be_empty
        #server.send_data "<iq from='d' type='result' id='#{doc.find_first('iq')['id']}'><session xmlns='urn:ietf:params:xml:ns:xmpp-session'/></iq>"

      #when :roster
        #p "roster: #{val}"
        #state = :check_stanza
        #doc = parse_stanza val
        #server.send_data "<iq from='d' id='#{doc.find_first('iq')['id']}' type='result'><query xmlns='jabber:iq:roster'></query></iq>"

      #when :check_stanza
        #p "check_stanza: #{val}"
        #state = :completed
        #doc = parse_stanza val

      when :completed
        EM.stop
        true

      else
        EM.stop
        false

      end
    end

    EventMachine::run {
      EM.add_timer(0.5) { EM.stop if EM.reactor_running? }
      EventMachine::start_server '127.0.0.1', 12345, ServerMock

      @client = XmppClient.connect 'n@d/r', 'pass', '127.0.0.1', 12345
      @client.client.state = :ready
      @client.client.should_receive(:write).once.with do |stnz|
        stnz.should =~ /oooooooooooooooooooooo/
      end
      @client.discover_nodes('nooooooooooooooooooooooooooooooooooooooooooode')
    }
  end

  it 'queue stanzas when stream not ready' do
    state = nil

    mocked_server do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"

      when :started
        state = :completed
        doc = parse_stanza val
        server.send_data "<iq from='d' type='result' id='#{doc.find_first('iq')['id']}' />"
      
      when :completed
        EM.stop
        true

      else
        EM.stop
        false

      end
    end

    EventMachine::run {
      EM.add_timer(0.5) { EM.stop if EM.reactor_running? }
      EventMachine::start_server '127.0.0.1', 12345, ServerMock

      @client = XmppClient.connect 'n@d/r', 'pass', '127.0.0.1', 12345
      @client.client.should_receive(:queue).once.with do |stnz|
        stnz.should =~ /oooooooooooooooooooooo/
      end
      @client.discover_nodes('nooooooooooooooooooooooooooooooooooooooooooode')
    }
  end
end  

