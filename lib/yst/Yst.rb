require 'tilt'

Tilt.register Tilt::ErubisTemplate, 'rxml'
yst = Tilt.new File.join(File.dirname(__FILE__), 'template/message.rxml')
p yst.render Object.new, from: 'b@shout.dev', to: 'admin@shout.dev'
