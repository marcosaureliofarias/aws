class EasyChecklist < ActiveRecord::Base
  include Redmine::I18n
  include Redmine::SafeAttributes

  belongs_to :entity, :polymorphic => true
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  has_and_belongs_to_many :projects, :join_table => 'projects_easy_checklists',
                                     :class_name => 'Project',
                                     :foreign_key => 'easy_checklist_id',
                                     :association_foreign_key => 'project_id'
  has_many :easy_checklist_items, :dependent => :destroy, :inverse_of => :easy_checklist

  attr_accessor :prepare_items

  validates_length_of :name, :maximum => 255, :allow_blank => true
  validates :author, :presence => true

  safe_attributes :name, :entity_type, :entity_id,
                  :easy_checklist_items_attributes, :project_ids, :is_default_for_new_projects
  accepts_nested_attributes_for :easy_checklist_items, :allow_destroy => true, :reject_if => proc{|attributes| attributes[:subject].blank? }

  serialize :settings, Hash

  after_initialize :ensure_author
  after_initialize :prepare_default_items, :if => Proc.new{ self.prepare_items }
  after_save :create_journal
  after_destroy :create_journal

  scope :visible, lambda {
    if User.current.admin?
      self.all
    else
      visible_project_ids = Project.allowed_to(:manage_easy_checklist_templates).pluck(:id)
      eager_load(:projects).where("#{Project.table_name}.id in (?) OR #{EasyChecklist.table_name}.author_id = ?", visible_project_ids.to_a, User.current.id)
    end
  }

  def is_template?
    false
  end

  def can_delete?(user=nil)
    user ||= User.current
    return entity && user.allowed_to?(:delete_easy_checklists, entity.project)
  end

  def can_edit?(user=nil)
    user ||= User.current
    return true if self.author == user || user.admin? || (entity && user.allowed_to?(:edit_easy_checklist_items, entity.project))
    return false
  end

  def is_history_changes_enabled?
    is_setting_enabled?('easy_checklist_enable_history_changes')
  end

  def is_change_done_ratio_enabled?
    is_setting_enabled?('easy_checklist_enable_change_done_ratio')
  end

  def is_setting_enabled?(setting_name)
    return false if !self.entity
    project = self.entity.project

    # use project setting if set, if not use global setting
    enable_change_done_ratio = (project && EasySetting.value('easy_checklist_use_project_settings', project)) ? EasySetting.value(setting_name, project) : EasySetting.value(setting_name)

    return enable_change_done_ratio
  end

  def display_mode
    self.settings ||= {}
    self.settings['display_mode'] || '1'
  end

  def css_classes
    "cols-#{display_mode}"
  end

  private

  def ensure_author
    self.author = User.current if self.author.nil?
  end

  def prepare_default_items
    return true if easy_checklist_items.present?

    3.times { self.easy_checklist_items.build }
  end

  def create_journal
    return true if !is_history_changes_enabled?

    if entity
      if saved_change_to_id?
        # journal for easy checklist created
        journal = entity.init_journal(User.current)
        journal.details << JournalDetail.new(:property => 'easy_checklist', :value => self.name)
      elsif destroyed?
        # journal for easy checklist deleted
        journal = entity.init_journal(User.current)
        journal.details << JournalDetail.new(:property => 'easy_checklist', :old_value => self.name)
      elsif saved_change_to_name?
        # journal for easy checklist changed
        journal = entity.init_journal(User.current)
        journal.details << JournalDetail.new(:property => 'easy_checklist', :prop_key => self.name, :value => self.name, :old_value => self.name_before_last_save)
      end
      journal.save if journal
    end
    true
  end
end
