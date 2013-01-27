require 'sinatra/base'
require 'data_mapper'
require 'date'
require 'dm-validations'
require 'haml'
require "digest/sha1"
require 'sinatra/flash'
require "sinatra-authentication"
require "pry"

class Weight  
  include DataMapper::Resource  
  property :id, Serial  
  property :value, Float, :required => true
  property :date, Date, :required => true, 	:unique => true
  property :user, Integer

  validates_within :value, :set => (0..200)
  validates_within :date, :set => (Date.new(1900,1,1)..Date.today)
end

class DmUser
  property :name, String, :required => true, :unique => true
end

class Siliwe < Sinatra::Base
	register Sinatra::Flash
	DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/siliwe.db")  
	use Rack::Session::Cookie, :secret => 'superdupersecret'
	set :sinatra_authentication_view_path, Pathname(__FILE__).dirname.expand_path + "views/"
	DataMapper.finalize.auto_upgrade!

	def check_permission
		if current_user.id != @weight.user
			flash[:notice] = "You are not authorized to do that."
			redirect '/'
		end
	end

	get '/' do
		if logged_in?
			@weights = Weight.all(:user => current_user.id, :order => [:date.asc])
			@title = "Your weights"
			flash[:notice] = "Hi #{current_user.name}!"
		else
			@weights = Weight.all
			@title = "All weights"
			flash[:notice] = "Hi anonymous, why not log in?"
		end
		haml :home
	end

	post '/' do
		if logged_in?
			@weight = Weight.new
			@weight.value = params[:value]
			@weight.date = params[:date].empty? ? Date.today : Date.parse(params[:date])
			@weight.user = current_user.id
			flash[:notice] = (@weight.save) ? "Weight posted successfully" : "Error: #{@weight.errors.first.first}"
			redirect '/'
		else
			flash[:notice] = "You must login"
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
		haml :delete
	end

	delete '/weights/:id' do  
	  @weight = Weight.get params[:id]  
	  check_permission
	  @weight.destroy  
	  redirect '/'  
	end

	get '/users/?*?' do
		raise Sinatra::NotFound
	end

	register Sinatra::SinatraAuthentication

	run! if app_file == $0
end