%w[
  yatata/client
  yatata/consumer
  yatata/consumer_pool
].each{|r| require File.join(File.dirname(__FILE__), r) }

module Yatata
  autoload :Client, 'yatata/client'
  autoload :Consumer, 'yatata/consumer'
  autoload :ConsumerPool, 'yatata/consumer_pool'
end
