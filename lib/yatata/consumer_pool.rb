require File.join(File.dirname(__FILE__), *%w[consumer])

module Yatata
class ConsumerPool
  attr_accessor :consumers

  def self.get(jid, password)
    jid += "@shout.dev" unless jid.include?('@')
    @consumers ||= {}
    @consumers[jid] ||= Consumer.new(jid, password).run
    @consumers[jid]
  end

end
end
