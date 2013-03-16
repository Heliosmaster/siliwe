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
end

class User
  include DataMapper::Resource  
  property :name, String, :required => true, :unique => true
  property :id, Serial
  property :email, String, :length => (5..40), :unique => true, :format => :email_address
  property :created_at, Time

  has n, :weights
end