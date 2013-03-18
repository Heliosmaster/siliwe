require 'sinatra/base'
require 'data_mapper'
require 'date'
require 'dm-validations'
require 'haml'
require 'sinatra/flash'
require "pry"
require "json"
require 'csv'
require 'omniauth'
require 'omniauth-google-oauth2'
require 'yaml'

require_relative "models"
require_relative "routes"

class Siliwe < Sinatra::Base
  use Rack::MethodOverride
  register Sinatra::Flash

  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/siliwe.db")  
  use Rack::Session::Cookie, :secret => 'superdupersecret'
  DataMapper.finalize.auto_upgrade!

  config_file = YAML.load_file("config.yml");

  use OmniAuth::Builder do
    provider :google_oauth2, config_file["client_id"], config_file["client_secret"],
    {
      :scope => "userinfo.email,userinfo.profile",
      :approval_prompt => "auto"
    }
  end

  OmniAuth.config.on_failure do |env|
    [302, {'Location' => '/auth/failure', 'Content-Type'=> 'text/html'}, []]
  end

  def check_permission
    if current_user.nil? || (!@weight.nil? and (current_user.id != @weight.user_id))
      flash[:error] = "You are not authorized to do that."
      redirect '/'
    end
  end

  def logged_in?
    !!session[:user]
  end

  def current_user
    session[:user] ? User.get(session[:user]) : nil
  end

  run! if app_file == $0
end

