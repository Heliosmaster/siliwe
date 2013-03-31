class Siliwe < Sinatra::Base
  get '/' do
    if logged_in?
      @weights = Weight.all(:user_id => current_user.id, :order => [:date.asc])
      @default_value = @weights.empty? ? 0.0 : @weights.last.value
      @title = "Your weights"
    else
      @weights = []
      @default_value = 0.0
      @title = "Welcome!"
    end
    haml :home
  end

  post '/' do
    if logged_in?
      if Weight.create_from_params(params,current_user)
        flash[:success] = "Weight posted successfully"
      else
        flash[:error] = "Error: #{@weight.errors.first.first}"
      end
      redirect '/'
    else
      flash[:error] = "You must login"
      redirect '/'
    end
  end

  ['/weights/*', '/graph', '/parse_csv', '/user'].each do |path|
    before path do
      check_permission
    end
  end

  get '/weights/wipe' do
    Weight.all(:user_id => current_user.id).destroy!
    redirect '/'
  end

  before '/weights/:id*' do
    @weight = Weight.get params[:id]
  end

  get '/weights/:id' do
    @title = "Measure ##{params[:id]}"
    haml :show_weight
  end


  get '/weights/:id/edit' do
    @title = "Edit measure ##{params[:id]}"
    haml :edit_weight
  end

  put '/weights/:id' do
    @weight.update_values(params)
    redirect '/'
  end

  get '/weights/:id/delete' do
    @title = "Deletion of measure ##{params[:id]}"
    haml :delete_weight
  end

  delete '/weights/:id' do
    Weight.get(params[:id]).destroy
    redirect '/'
  end

  get '/graph' do
    @weights = Weight.all(:user_id => current_user.id, :order => [:date.asc])
    total_days = (@weights.last.date - @weights.first.date)
    @array = Array.new(@weights.length) {Array.new(3)}
    for i in 0..@weights.length-1
      weight = @weights[i]
      @array[i] = [weight.date.strftime("%Q").to_i, weight.value, weight.trend]
    end
    haml :show_chart
  end

  get '/parse_csv' do
    haml :parse_csv
  end

  post '/parse_csv' do
    csv_text = File.read(params[:file][:tempfile])
    csv = CSV.parse(csv_text, :headers => :first_row, :col_sep => ";")
    csv.each {|row| Weight.create_from_csv(row,current_user) }
    redirect '/'
  end

  not_found do
    @title ="Page not found!"
    haml :not_found
  end

  get '/profile' do
    haml :profile
  end

  put '/profile' do
    current_user.update(:lbs => !!params[:lbs])
    redirect '/profile'
  end

  get '/logout' do
    session[:user] = nil
    redirect '/'
  end

  get '/auth/:provider/callback' do
    resp = request.env["omniauth.auth"]
    if user = User.all(:email => resp.info.email).first
      session[:user] = user.id
      flash[:success] = "Successfully logged in"
      redirect '/'
    else
      @user = User.create(:name => resp.info.name, :email => resp.info.email)
      if @user.saved?
        session[:user] = @user.id
        flash[:success] = "Account successfully created"
      else
        flash[:error] = "Error with signup"
      end
      redirect '/'
    end
  end

  get '/auth/failure' do
    flash[:error] ="Authentication with OAuth failed"
    redirect "/"
  end
end