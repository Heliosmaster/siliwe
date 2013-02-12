require 'spec_helper'

describe Siliwe do
	include Sinatra::Helpers

	before do
		new_user = User.new
		new_user.email = "pippo@minni.com"
		new_user.name  = "pippo"
		new_user.password = "123"
		new_user.password_confirmation = "123"
		new_user.save!

		new_user2 = User.new
		new_user2.email = "ciccio@papera.com"
		new_user2.name = "ciccio"
		new_user2.password = "123"
		new_user2.password_confirmation = "123"
		new_user2.save!
	end

	def log_in
		get '/login'
		fill_in "email", :with => "pippo@minni.com"
		fill_in "password", :with => "123"
		click_button "Log in"
		follow_redirect!
	end

	def log_in2
		get '/login'
		fill_in "email", :with => "ciccio@papera.com"
		fill_in "password", :with => "123"
		click_button "Log in"
		follow_redirect!
	end


	def post_weight(default_weight=80.5, default_date=Date.today.to_s)
		get '/'
		fill_in "value", :with => "#{default_weight}"
		fill_in "date", :with => "#{default_date}"
		click_button "Post new weight"
		follow_redirect!
	end

	describe 'homepage' do

		it "should respond to GET" do
			get '/'
			last_response.should be_ok
		end
	end

	describe 'authentication' do
		
		it 'should signup succesfully' do
			get '/signup'
			fill_in "user[email]", :with => "pippo2@minni.com"
			fill_in "user[name]", :with => "pippo2"
			fill_in "user[password]", :with => "123"
			fill_in "user[password_confirmation]", :with => "123"
			click_button "Sign up"
			follow_redirect!
			response.body.should contain (/logged in as/)
		end

		it "should login succesfully" do
			log_in
			response.body.should contain (/logged in as/)
		end

		it "should not allow posting while not logged in" do
			post_weight
			last_response.body.should contain(/You must login/)
		end
	
		it "should allow posting when logged in" do
			log_in
			post_weight
			last_response.body.should contain(/Weight posted successfully/)
		end

		it "should not allow to see weights that belong to another user" do
			log_in
			post_weight
			get '/logout'
			log_in2
			get '/weights/1'
			follow_redirect!
			last_response.body.should contain(/You are not authorized to do that./)
		end

		it "should not allow to edit weights that belong to another user" do
			log_in
			post_weight
			get '/logout'
			log_in2
			get '/weights/1/edit'
			follow_redirect!
			last_response.body.should contain(/You are not authorized to do that./)
		end

		it "should not allow to delete weights that belong to another user" do
			log_in
			post_weight
			get '/logout'
			log_in2
			get '/weights/1/delete'
			follow_redirect!
			last_response.body.should contain(/You are not authorized to do that./)
		end
	end

	describe "measurements" do
		it "should succeed in posting a new weight" do
			log_in
			post_weight(100.5)
			get '/'
			Weight.all(:user_id => 1).first.value.should eq 100.5
		end

		it "should display all proper weights of a user" do
			log_in
			post_weight(101)
			post_weight(102,Date.today.prev_day.to_s)
			get '/'
			last_response.body.should contain(/101/)		
			last_response.body.should contain(/102/)		
		end
		
		it "should be displayed somewhere in their proper page" do
			log_in
			post_weight(121)
			@weight = Weight.first
			get "/weights/#{@weight.id}"
			last_response.body.should contain "#{@weight.value}"
		end

		it "should not post a value greater than 200" do
			w = Weight.new
			w.value = 201
			w.user_id = 1
			w.date = Date.today
			w.valid?.should be_false
		end

		it "should allow values smaller than 200" do
			w = Weight.new
			w.value = 199
			w.date = Date.today
			w.user_id = 1
			w.valid?.should be_true
		end
		it "should not allow measurements with future dates" do
			w = Weight.new
			w.value = 123
			w.user_id = 1
			w.date = Date.today.next_day
			w.valid?.should be_false
		end

		it "should not allow the same date within the same user" do
			w = Weight.new
			w.value = 123
			w.user_id = 1
			w.date = Date.today
			w.save!

			w2 = Weight.new
			w2.value = 123
			w2.user_id = 1
			w2.date = Date.today
			w2.valid?.should be_false
		end

		it "should allow same date with different users" do
			w = Weight.new
			w.value = 123
			w.user_id = 1
			w.date = Date.today
			w.save!

			w2 = Weight.new
			w2.value = 123
			w2.user_id = 2
			w2.date = Date.today
			w2.valid?.should be_true
		end

	end
end