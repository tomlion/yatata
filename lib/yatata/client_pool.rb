module Yatata
class ClientPool
  DEFAULT_TIMEOUT = 100

  def self.fetch(jid, password, host = nil, port = nil)
    @@clients ||= {}
    client = @@clients[jid.to_s]

    unless client
      @@clients[jid.to_s] = client = Client.setup(jid, password, host, port)
      client.register_handler :disconnected do
        @@clients.delete(client.jid.to_s)
        @@client_timers.delete(client.jid.to_s) if @@client_timers
      end
    end

    if EM.reactor_running?
      client.run
      refresh_client_timeout(client)
    end
    client
  end

  def self.refresh_client_timeout(client)
    @@client_timers ||= {}
    timer = @@client_timers[client.jid.to_s]
    timer.cancel if timer

    timer = EventMachine::Timer.new(DEFAULT_TIMEOUT) do
      cli = @@clients.delete(client.jid.to_s)
      cli.close if cli
      @@client_timers.delete(client.jid.to_s)
    end
    @@client_timers[client.jid.to_s] = timer
  end

end
end
