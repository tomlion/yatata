require 'eventmachine'
require 'redis'
require 'blather'
require 'sinatra/base'
require './evented_redis'

class YatController < Sinatra::Base
  require "sinatra/reloader"
  attr_accessor :pub, :jid

  #use Rack::Auth::Basic, "Restricted Area" do |username, password|
    #@jid = username
  #end
 
  def initialize(app=nil)
    super()
    init_pub_pipe
    yield self if block_given?
  end
  
  get('/:verb/:params')  do
    @pub.publish('xmpp', 'wohahahahah!!!')
  end

  def init_pub_pipe
    @pub = EventedRedis.connect
  end

end

EventMachine.run {
  @sub = EventedRedis.connect
  @sub.subscribe 'xmpp' do |data|
    p data
  end
  Rack::Handler::Thin.run YatController, :Port => 8081
}

