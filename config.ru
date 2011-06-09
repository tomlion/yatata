require 'eventmachine'
require 'redis'
require 'blather'
require 'sinatra/base'
require "sinatra/reloader"
require 'active_support/json'
require 'active_support/ordered_hash'
require './yat_controller'

run YatController
