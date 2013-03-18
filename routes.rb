class Siliwe < Sinatra::Base
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
      @weight.user = current_user
      @weight.trend = @weight.compute_trend
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
    check_permission
    @weight = Weight.get params[:id]
    @title = "Edit measure ##{params[:id]}"
    haml :edit_weight
  end

  put '/weights/:id' do
    check_permission
    Weight.update_values(params)
    redirect '/'
  end

  get '/weights/:id/delete' do
    check_permission
    @weight = Weight.get params[:id]
    @title = "Deletion of measure ##{params[:id]}"
    haml :delete_weight
  end

  delete '/weights/:id' do
    check_permission
    Weight.get(params[:id]).destroy
    redirect '/'
  end

  get '/graph' do
    check_permission
    @weights = Weight.all(:user_id => current_user.id, :order => [:date.asc])
    total_days = (@weights.last.date - @weights.first.date)
    @array = Array.new(@weights.length) {Array.new(3)}
    for i in 0..@weights.length-1
      weight = @weights[i]
      @array[i] = [weight.date.to_s, weight.value, weight.trend]
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
    csv.each {|row| Weight.create_from_csv(row,current_user) }
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
end