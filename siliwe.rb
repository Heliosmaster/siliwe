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

  def compute_trend(value,last_weight)
    if last_weight.nil?
      value
    else
      last_trend = last_weight.trend
      (((value-last_trend)/10).round(1)+last_trend).round(1)
    end
  end

  get '/logout' do
    session[:user] = nil
    redirect '/'
  end

  get '/' do
    if logged_in?
      @weights = Weight.all(:user_id => current_user.id, :order => [:date.asc])
      @default_value = @weights.empty? ? 0.0 : @weights.last.value
      @title = "Your weights"
    else
      @weights = []
      @default_value = 0.0
      @title = "All weights"
    end
    haml :home
  end

  post '/' do
    if logged_in?
      @weight = Weight.new
      @weight.value = params[:value]
      @weight.date = params[:date].empty? ? Date.today : Date.parse(params[:date])
      @weight.trend = compute_trend(@weight.value,Weight.all(:user_id => current_user.id, :date.lt => @weight.date, :order => [:date.asc]).last)
      #binding.pry
      @weight.user = current_user
      if @weight.save
        flash[:success] = "Weight posted successfully"
      else
        flash[:error] = "Error: #{@weight.errors.first.first}"
      end
      redirect '/'
    else
      flash[:error] = "You must login"
      redirect '/login'
    end
  end

  get '/weights/:id' do
    @weight = Weight.get params[:id]
    check_permission
    @title = "Measure ##{params[:id]}"
    haml :show_weight
  end


  get '/weights/:id/edit' do 
    @weight = Weight.get params[:id]
    check_permission
    @title = "Edit measure ##{params[:id]}"
    haml :edit_weight
  end

  put '/weights/:id' do
    @weight = Weight.get params[:id]
    check_permission
    @weight.value = params[:value]
    @weight.date = params[:date].empty? ? Date.today : Date.parse(params[:date])
    @weight.save!
    redirect '/'
  end

  get '/weights/:id/delete' do
    @weight = Weight.get params[:id]
    check_permission
    @title = "Deletion of measure ##{params[:id]}"
    haml :delete_weight
  end

  delete '/weights/:id' do
    @weight = Weight.get params[:id]  
    check_permission
    @weight.destroy!
    redirect '/'
  end

  get '/graph' do
    check_permission
    @weights = Weight.all(:user_id => current_user.id, :order => [:date.asc])
    total_days = (@weights.last.date - @weights.first.date)
    @array = Array.new(@weights.length) {Array.new(2)}
    for i in 0..@weights.length-1
      weight = @weights[i]
      @array[i] = [weight.date.to_s, weight.value]
    end
    haml :show_chart
  end

  get '/parse_csv' do
    check_permission
    haml :parse_csv
  end

  post '/parse_csv' do
    check_permission
    csv_text = File.read(params[:file][:tempfile])
    csv = CSV.parse(csv_text, :headers => :first_row, :col_sep => ";")
    csv.each do |row|
      @weight = Weight.new
      @weight.value = row["Weight"]
      @weight.date = row["Date"]
      @weight.trend = row["Trend"]
      @weight.user = current_user
      @weight.save! if @weight.valid?
    end
    redirect '/'
  end

  get '/delete_all_weights' do
    check_permission
    Weight.all(:user_id => current_user.id).destroy!
    redirect '/'
  end

  not_found do
    @title ="Page not found!"
    haml :not_found
  end

  get '/auth/:provider/callback' do
    resp = request.env["omniauth.auth"]
    if user = User.all(:email => resp.info.email).first
      session[:user] = user.id
      flash[:success] = "Successfully logged in"
      redirect '/'
    else
      @user = User.new
      @user.name = resp.info.name
      @user.email = resp.info.email
      if @user.save
        session[:user] = @user.id
        redirect '/'
      else
        flash[:error] = "Error with signup"
        redirect '/'
      end
    end
  end

  get '/auth/failure' do
    flash[:error] ="Authentication with OAuth failed"
    redirect "/"
  end

  run! if app_file == $0
end

