class EasyCustomMenu < ActiveRecord::Base
  belongs_to :easy_user_type, :inverse_of => :easy_custom_menus
  belongs_to :root, class_name: 'EasyCustomMenu', foreign_key: 'root_id', :inverse_of => :submenus

  validates :name, :url, :presence => true
  validates_length_of :url, maximum: 2000

  acts_as_positioned scope: [:easy_user_type_id, :root_id]
  acts_as_easy_translate

  scope :sorted, -> { order(Arel.sql("#{table_name}.position ASC")) }

  has_many :submenus, -> { sorted }, class_name: 'EasyCustomMenu', foreign_key: 'root_id', dependent: :destroy

  accepts_nested_attributes_for :submenus

  def root?
    root_id.nil?
  end

end
