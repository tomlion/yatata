require File.expand_path "../../spec_helper", __FILE__

describe Yatata::ClientPool do
  Yatata::ClientPool.const_set(:DEFAULT_TIMEOUT, 0.1)

  def counter
    @counter ||= mock('counter')
  end

  before :each do
    @counter = nil
    stream = mock('stream')
    stream.stub(:stop)
    stream.stub(:close_connection_after_writing){ counter.disconnect }
    Yatata::Client.any_instance.stub(:stream).and_return(stream)
    Yatata::Client.any_instance.stub(:run_once) do
      counter.connect
    end
  end    
  after :each do
    #Yatata::Client.any_instance.unstub(:run_once) 
    #Yatata::Client.any_instance.unstub(:stream) 
  end

  it 'can get a client' do
    counter.should_receive(:connect).once
    counter.should_receive(:disconnect).once
    EM.run do
      EM.add_timer(0.2){ EM.stop }
      @client = Yatata::ClientPool.fetch 'n@d/r', 'pass', '127.0.0.1', 12345
    end
  end

  it 'can fetch a client from pool' do
    counter.should_receive(:connect).once
    counter.should_receive(:disconnect).once
    EM.run do
      EM.add_timer(0.2){ EM.stop }
      Yatata::ClientPool.fetch 'n@d/r', 'pass', '127.0.0.1', 12345
      EM.add_timer(0.05) do
        Yatata::ClientPool.fetch 'n@d/r', 'pass', '127.0.0.1', 12345
      end
    end
  end

  it 'create a new client if old client is timeout or disconnect ' do
    counter.should_receive(:connect).twice
    counter.should_receive(:disconnect).twice
    EM.run do
      EM.add_timer(0.5){ EM.stop }
      Yatata::ClientPool.fetch 'n@d/r', 'pass', '127.0.0.1', 12345
      EM.add_timer(0.2) do
        Yatata::ClientPool.fetch 'n@d/r', 'pass', '127.0.0.1', 12345
      end
    end
  end

end  

