require File.join(File.dirname(__FILE__), '..', 'siliwe.rb')

require 'sinatra'
require 'rack/test'
require 'webrat'

# setup test environment
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

def app
	Siliwe
end

Webrat.configure do |config|
  config.mode = :rack
end

RSpec.configure do |config|
  config.before(:each) { DataMapper.auto_migrate! }
  config.include Rack::Test::Methods
  config.include Webrat::Methods
  config.include Webrat::Matchers  
end