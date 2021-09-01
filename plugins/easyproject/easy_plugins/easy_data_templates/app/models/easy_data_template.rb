class EasyDataTemplate < ActiveRecord::Base
  include Redmine::SafeAttributes

  self.table_name = 'easy_data_templates'

  belongs_to :user, :class_name => 'User', :foreign_key => 'user_id'
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  has_many :assignments, :class_name => "EasyDataTemplateAssignment", :foreign_key => 'easy_data_template_id', :dependent => :destroy

  acts_as_attachable

  validates :template_type, :presence => true
  validates :format_type, :presence => true
  validates :type, :presence => true, :if => Proc.new { |data_template| data_template.format_type != 'xml' }
  validates :name, :length => 1..255

  after_initialize :set_default_values

  serialize :settings

  attr_reader :is_public

  safe_attributes 'name', 'format_type', 'template_type', 'is_public'

  def set_default_values
    self.author_id ||= User.current.id
    self.settings ||= self.default_settings
    @is_public = (self.user_id.nil? ? "1" : "0")
  end

  def is_public=(value)
    @is_public=value
    self.user_id = (value.to_i == 0 ? User.current.id : nil)
  end

  def attachments_visible?(user=User.current)
    user.admin?
  end

  def attachments_deletable?(user=User.current)
    user.admin?
  end

  # workaround link_to_attachments - vyzaduje metodu project
  def project
    nil
  end

  def all_allowed_columns
    Hash.new
  end

  def allowed_columns_to_export
    Array.new
  end

  def allowed_columns_to_import
    Array.new
  end

  def default_columns_to_export
    Array.new
  end

  def default_columns_to_import
    Array.new
  end

  def default_settings
    {}
  end

  def find_entities(limit = nil)
    raise NotImplementedError, 'The find_entities is not implemented.'
  end

  def build_entity_from_csv_row(row_values)
    raise NotImplementedError, 'The build_entity_from_csv_row is not implemented.'
  end

  #  def allowed_attributes
  #    EasyDataTemplate.allowed_attributes[self.template_type][self.type] unless self.type.blank?
  #  end
  #
  #  def allowed_custom_field_attributes
  #    EasyDataTemplate.allowed_custom_field_attributes[self.type] unless self.type.blank?
  #  end
  #
  #  def self.allowed_custom_field_attributes
  #    @@allowed_custom_field_attributes ||= {
  #      'Project' => ProjectCustomField.all.collect{|x| [x.name, x.id.to_s]},
  #      'Issue' => IssueCustomField.all.collect{|x| [x.name, x.id.to_s]},
  #      'TimeEntry' => TimeEntryCustomField.all.collect{|x| [x.name, x.id.to_s]},
  #      'User' => UserCustomField.all.collect{|x| [x.name, x.id.to_s]}
  #      }
  #    @@allowed_custom_field_attributes
  #  end
  #
  #  def self.allowed_attributes
  #    @@allowed_attributes ||= {
  #      'import' => {
  #        'Project' => ['description','is_public','name','parent_id','parent_name','trackers_ids','trackers_names','enabled_modules'],
  #        'Issue' => ['assigned_to_id','assigned_to_login','assigned_to_mail','assigned_to_firstname','assigned_to_lastname','author_id','author_login','author_mail','author_firstname','author_lastname','description','due_date','estimated_hours','priority_id','priority_name','project_id','project_name','start_date','subject','tracker_id','tracker_name'],
  #        'TimeEntry' => ['project_id','issue_id','user_id','hours','comments','activity_id','spent_on','easy_range_from', 'easy_range_to'],
  #        'User' => ['admin','firstname','language','lastname','login','mail','password','send_mail']
  #      },
  #      'export' => {
  #        'Project' => ['description','id','is_public','name','parent_id','parent_name','trackers_ids','trackers_names','enabled_modules'],
  #        'Issue' => ['assigned_to_id','assigned_to_login','assigned_to_mail','assigned_to_firstname','assigned_to_lastname','author_id','author_login','author_mail','author_firstname','author_lastname','description','due_date','estimated_hours','id','priority_id','priority_name','project_id','project_name','start_date','subject','tracker_id','tracker_name'],
  #        'TimeEntry' => ['project_id','issue_id','user_id','hours','comments','activity_id','spent_on','easy_range_from', 'easy_range_to'],
  #        'User' => ['admin','firstname','language','id','lastname','login','mail']
  #        }
  #    }
  #    @@allowed_attributes
  #  end

end
