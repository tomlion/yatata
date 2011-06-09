require 'sinatra/base'
require 'sinatra/reloader'
require 'redis'
require 'active_support/json'
require 'active_support/ordered_hash'

class YatController < Sinatra::Base
  attr_accessor :pub, :jid

  #use Rack::Auth::Basic, "Restricted Area" do |username, password|
    #p self, username, password
    #@jid = username
  #end
 
  def initialize(app=nil)
    super()
    init_pub_pipe
    yield self if block_given?
  end


  #curl http://b:password@localhost:3000/msg/msg?stanza=%3Cmessage%20from%3D%27b%40shout.dev%27%20to%3D%27admin%40shout.dev%27%20type%3D%27chat%27%3E%3Cbody%3EThy%20lips%20are%20warm.%3C%2Fbody%3E%3C%2Fmessage%3E
  get('/:verb/*') do
    verb = params.delete('verb')
    auth = Rack::Auth::Basic::Request.new(request.env)
    #clazz = params.delete('splat')
    hash = {'stanza' => params[:stanza], 'credentials' => auth.credentials}
    @pub.publish 'stanza', ActiveSupport::JSON.encode(hash)
  end

  def init_pub_pipe
    @pub = Redis.connect
  end

end
