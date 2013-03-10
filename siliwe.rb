require 'sinatra/base'
require 'data_mapper'
require 'date'
require 'dm-validations'
require 'haml'
require "digest/sha1"
require 'sinatra/flash'
require "pry"
require "json"
require 'csv'

require_relative "models"

class Siliwe < Sinatra::Base
	register Sinatra::Flash

	DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/siliwe.db")  
	use Rack::Session::Cookie, :secret => 'superdupersecret'
	DataMapper.finalize.auto_upgrade!

	def check_permission
		if current_user.nil? || (!@weight.nil? and (current_user.id != @weight.user_id))
			flash[:notice] = "You are not authorized to do that."
			redirect '/'
		end
	end

	def logged_in?
    	!!session[:user]
	end

	def current_user
      session[:user] ? User.get(session[:user]) : nil
    end

	get '/signup' do
		haml :signup
	end

	post '/signup' do
		@user = User.create(params[:user])
		if @user.valid? && @user.id
			session[:user] = @user.id
		end
		redirect '/'
	end

	get '/login' do
		haml :login
	end

	post '/login' do
		if user = User.authenticate(params[:email], params[:password])
        	session[:user] = user.id
        	redirect '/'
        else
        	flash[:notice] = "Wrong username or password"
        	redirect '/login'
        end
	end

	get '/logout' do
		session[:user] = nil
		redirect '/'
	end

	get '/' do
		if logged_in?
			@weights = Weight.all(:user_id => current_user.id, :order => [:date.asc])
			@title = "Your weights"
			flash[:notice] = "Hi #{current_user.name}!"
		else
			@weights = Weight.all(:order => [:date.asc])
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
			@weight.user = current_user
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

	get '/graph' do
		@weights = Weight.all(:user_id => current_user.id, :order => [:date.asc])
		total_days = (@weights.last.date - @weights.first.date)
		@array = Array.new(@weights.length) {Array.new(2)}
		for i in 0..@weights.length-1
			weight = @weights[i]
			#@array[i] = [((weight.date-@weights.first.date)/total_days).to_f, weight.value] 
			@array[i] = [weight.date.to_s, weight.value]
		end
		#binding.pry
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
			@weight.user = current_user
			@weight.save!
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

	run! if app_file == $0
end

