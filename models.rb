class Weight  
  include DataMapper::Resource  
  property :id, Serial  
  property :value, Float, :required => true
  property :date, Date, :required => true
  property :trend, Float

  validates_within :value, :set => (0..200)
  validates_within :date, :set => (Date.new(1900,1,1)..Date.today)
  validates_uniqueness_of :date, :scope => :user

  belongs_to :user

  def prev
    Weight.all(:user_id => self.user.id, :date.lt => self.date, :order => [:date.asc]).last
  end

  def next
    Weight.all(:user_id => self.user.id, :date.gt => self.date, :order => [:date.asc]).first
  end

  def compute_trend
    prev_weight = self.prev
    if prev_weight.nil?
      self.value
    else
      last_trend = prev_weight.trend
      (((self.value-last_trend)/10).round(1)+last_trend).round(1)
    end
  end

  def self.update_values(params)
    weight = self.get(params[:id])
    date = params[:date].empty? ? weight.date : Date.parse(params[:date])
    weight.update(:value => params[:value], :date => date)
  end

  def self.create_from_csv(row,user)
   @weight = self.new
   @weight.value = row["Weight"]
   @weight.date = row["Date"]
   @weight.trend = row["Trend"].to_f.round(1)
   @weight.user = user
   @weight.save
 end

  def self.create_from_params(params,user)
    date = params[:date].empty? ? Date.today : Date.parse(params[:date])
    @weight = self.new
    @weight.value = params[:value]
    @weight.date = date
    @weight.user = user
    @weight.trend = @weight.compute_trend
    @weight.save
  end

end

class User
  include DataMapper::Resource  
  property :name, String, :required => true, :unique => true
  property :id, Serial
  property :email, String, :length => (5..40), :unique => true, :format => :email_address
  property :created_at, Time

  has n, :weights

end