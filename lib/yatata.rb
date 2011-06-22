%w[
  yatata/client
  yatata/client_pool
  xmpp_helper/xmpp_helper
  xmpp_helper/xmpp_builder
  xmpp_helper/xmpp_client
].each{|r| require File.join(File.dirname(__FILE__), r) }

module Yatata
  autoload :Client, 'yatata/client'
  autoload :ClientPool, 'yatata/client_pool'
end
