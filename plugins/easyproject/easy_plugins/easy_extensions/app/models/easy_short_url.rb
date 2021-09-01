class EasyShortUrl < ActiveRecord::Base
  include Redmine::SafeAttributes

  has_many :accesses, :class_name => "EasyShortUrlAccess", :foreign_key => "easy_short_url_id", :dependent => :destroy
  belongs_to :entity, :polymorphic => true

  validates :source_url, presence: true
  validates :allow_external, :inclusion => { :in => [true, false] }

  safe_attributes 'source_url', 'valid_to', 'allow_external'

  before_save :generate_shortcut

  def self.generate_random_string(length)
    allowed_charsets = %w{ 2 3 4 6 7 9 A C D E F G H J K M N P Q R T V W X Y Z}
    (0...length).map { allowed_charsets.to_a[SecureRandom.random_number(allowed_charsets.size)] }.join
  end

  def self.generate_shortcut
    generate_random_string(7)
  end

  def still_valid?
    return true if valid_to.nil?
    Time.now <= valid_to
  end

  def add_access(user, ip)
    # Same user already access to entity
    prev = self.accesses.find_by(user_id: user.id, ip: ip)

    if prev
      prev.count += 1
      prev.save
    else
      self.accesses << EasyShortUrlAccess.new(user_id: user.id, ip: ip)
    end
  end

  private

  def generate_shortcut
    self.shortcut = EasyShortUrl.generate_shortcut
  end

end
