require File.expand_path "../../spec_helper", __FILE__
require 'yaml'
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

  before(:each) do
    @client = XmppClient.new 'admin@localhost', 'me', '127.0.0.1', 12345
  end

  it 'build discover_nodes stanza' do
    state = nil

    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><session xmlns='urn:ietf:params:xml:ns:xmpp-session' /></stream:features>"

      when :started
        state = :check_stanza
        doc = parse_stanza val
        #doc.find('/iq[@type="set" and @to="d"]/sess_ns:session', :sess_ns => Blather::Stream::Session::SESSION_NS).should_not be_empty
        server.send_data "<iq from='d' type='result' id='#{doc.find_first('iq')['id']}' />"
        server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
      
      when :check_stanza
        state = :completed
        p val
        doc = parse_stanza val

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

      @client.client.run
      @client.discover_nodes('nooooooooooooooooooooooooooooooooooooooooooode')
    }
  end

end  

