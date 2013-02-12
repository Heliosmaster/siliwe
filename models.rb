class Weight  
  include DataMapper::Resource  
  property :id, Serial  
  property :value, Float, :required => true
  property :date, Date, :required => true
  #property :user, Integer, :required => true

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
  property :hashed_password, String
  property :salt, String
  property :created_at, Time

  has n, :weights

  attr_accessor :password, :password_confirmation

  validates_presence_of :password_confirmation, :unless => Proc.new { |t| t.hashed_password }
  validates_presence_of :password, :unless => Proc.new { |t| t.hashed_password }
  validates_confirmation_of :password


  def password=(pass)
    @password = pass
    self.salt = random_string(10) if !self.salt
    self.hashed_password = User.encrypt(@password, self.salt)
  end

  def random_string(len)
    #generate a random password consisting of strings and digits
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end

  def self.encrypt(pass, salt)
    Digest::SHA1.hexdigest(pass+salt)
  end

  def self.authenticate(email, pass)
    current_user = all(:email => email).first
    return nil if current_user.nil?
    return current_user if User.encrypt(pass, current_user.salt) == current_user.hashed_password
    nil
  end

end