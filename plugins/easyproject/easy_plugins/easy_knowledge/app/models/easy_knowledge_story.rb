class EasyKnowledgeStory < ActiveRecord::Base
  include Redmine::SafeAttributes

  has_and_belongs_to_many :easy_knowledge_categories, :join_table => 'easy_knowledge_story_categories', :foreign_key => 'story_id', :association_foreign_key => 'category_id'
  alias_method :categories, :easy_knowledge_categories

  has_many :easy_knowledge_story_categories, :foreign_key => 'story_id'
  has_many :versions, class_name: 'EasyKnowledgeStoryVersion', dependent: :destroy

  has_and_belongs_to_many :references_by, :class_name => 'EasyKnowledgeStory', :join_table => 'easy_knowledge_story_references', :foreign_key => 'referenced_by', :association_foreign_key => 'referenced_to'
  has_and_belongs_to_many :references_to, :class_name => 'EasyKnowledgeStory', :join_table => 'easy_knowledge_story_references', :foreign_key => 'referenced_to', :association_foreign_key => 'referenced_by'

  has_many :easy_knowledge_assigned_stories, :foreign_key => 'story_id', :dependent => :destroy
  alias_method :assigned_entities_relationship, :easy_knowledge_assigned_stories

  # Cannot have a has_many :through association 'EasyKnowledgeStory#entities' on the polymorphic object 'Entity#entity'
  # has_many :entities, :through => :easy_knowledge_assigned_stories, :as => :entity
  has_many :users, lambda { where( easy_knowledge_assigned_stories: { entity_type: 'Principal' } ) }, :through => :easy_knowledge_assigned_stories, :as => :entity
  has_many :issues, lambda { where( easy_knowledge_assigned_stories: { entity_type: 'Issue' } ) },    :through => :easy_knowledge_assigned_stories, :as => :entity
  has_many :projects, lambda { where( easy_knowledge_assigned_stories: { entity_type: 'Project' } ) },:through => :easy_knowledge_assigned_stories, :as => :entity

  has_many :easy_favorites, :as => :entity
  has_many :favorited_by, lambda { distinct }, :through => :easy_favorites, :source => :user, :dependent => :destroy

  belongs_to :entity, :polymorphic => true
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'

  belongs_to :project, :foreign_key => 'entity_id', :foreign_type => 'Project'
  belongs_to :issue, :foreign_key => 'entity_id', :foreign_type => 'Issue'
  belongs_to :journal, :foreign_key => 'entity_id', :foreign_type => 'Journal'

  acts_as_taggable_on :tags, :plugin_name => :easy_knowledge
  acts_as_customizable
  acts_as_attachable
  acts_as_user_readable
  acts_as_searchable :columns => ["#{self.table_name}.name", "#{self.table_name}.description", "#{ActsAsTaggableOn::Tag.table_name}.name"]
  acts_as_event :title => :name,
    :url => Proc.new {|o| {:controller => 'easy_knowledge_stories', :action => 'show', :id => o.id}},
    :datetime => :updated_on,
    :type => 'easy_knowledge_stories'

  attr_reader :current_journal
  delegate :notes, :notes=, to: :current_journal, allow_nil: true
  acts_as_easy_journalized

  scope :visible, lambda {|*args| self.visible_condition(args.shift || User.current, *args)}
  scope :like, lambda {|keyword| where(self.arel_table[:name].lower.matches("%#{keyword.downcase}%").or(self.arel_table[:description].lower.matches("%#{keyword.downcase}%"))) }

  include EasyExtensions::EasyInlineFragmentStripper
  html_fragment :description, :scrub => :strip
  strip_inline_images :description

  safe_attributes 'custom_field_values', 'custom_fields', 'name', 'author_id', 'entity_type', 'entity_id', 'easy_knowledge_category_ids', 'references_by_ids', 'tag_list', 'description'

  before_save :set_new_version
  after_save :create_version, :if => Proc.new { |p| !p.description_changed? }
  after_save :references_mirror
  after_create :set_issue_assignment, :if => Proc.new{|kb| kb.entity.is_a?(Journal) || kb.entity.is_a?(Issue)}
  before_validation :set_default_values

  after_create_commit :send_notification_added, if: -> { Setting.notified_events.include?('easy_knowledge_story_added') }
  after_update_commit :send_notification_updated, if: -> { Setting.notified_events.include?('easy_knowledge_story_updated') }

  validates :name, :author, :presence => true

  def initialize(*args)
    super
    if new_record?
      self.version = 1
    end
  end

  def self.search_scope(user, projects, options={})
    scope = self.includes(:tags).visible(user)

    if projects.present?
      cat_tbl = EasyKnowledgeCategory.arel_table
      ass_tbl = EasyKnowledgeAssignedStory.arel_table
      proj_ids = Array(projects).map(&:id)
      scope = scope.includes(:easy_knowledge_assigned_stories, :easy_knowledge_categories).
        where((cat_tbl[:entity_type].eq('Project').and(cat_tbl[:entity_id].in(proj_ids))).or(ass_tbl[:entity_type].eq('Project').and(ass_tbl[:entity_id].in(proj_ids))))
    end
    scope
  end

  def self.additional_search_scope_by_tags(query_string, not_in_story_ids = [])
    delimiters = [' ']

    tags = ActsAsTaggableOn::Tag.arel_table
    stories = EasyKnowledgeStory.arel_table

    tags_array = query_string.split(Regexp.union(delimiters))
    statements = tags_array.map { |tag| tags[:name].matches("%#{tag}%") }.reduce(:or)
    EasyKnowledgeStory
                      .select(Arel.sql(Arel.star).count, stories[Arel.star])
                      .joins(:tags)
                      .where(statements.and(EasyKnowledgeStory.not_in_scope(:id, not_in_story_ids)).to_sql)
                      .group(stories[:id])
                      .having(Arel.sql(Arel.star).count.gteq(1))
                      .order(Arel.sql(Arel.star).count.desc)
                      #.having(Arel.sql(Arel.star).count.eq(tags_array.count)) # if all matched tags
  end

  def self.match_scope(attribute, token)
    arel_table[attribute].matches(token)
  end

  def self.not_in_scope(attribute, array = [])
    arel_table[attribute].not_in(array)
  end

  def self.visible_condition(user, options={})
    return where('1=1') if User.current.admin?

    return where('1=0') unless user.allowed_to_globally?(:view_easy_knowledge)

    if user.allowed_to_globally?(:read_global_stories)
      visible_stories(user)
    else
      visible_stories(user, only_project_stories: true)
    end
  end

  def self.visible_stories(user, options={})
    assigned_stories_table = EasyKnowledgeAssignedStory.arel_table
    categories_table = EasyKnowledgeCategory.arel_table
    assigned_stories_entity_type = assigned_stories_table[:entity_type]
    categories_entity_type = categories_table[:entity_type]

    visible_project_ids = Project.visible.where(Project.allowed_to_condition(user, :read_project_stories)).pluck(:id)

    if !options[:only_project_stories]
      visible_global_stories_condition = "(easy_knowledge_story_categories.story_id IS NOT NULL AND easy_knowledge_categories.entity_type IS NULL)"
    end

    assigned_stories_condition = assigned_stories_entity_type.eq('Principal').and(assigned_stories_table[:entity_id].eq(user.id))

    visible_project_stories_condition = categories_entity_type.eq('Project').and(categories_table[:entity_id].in(visible_project_ids))
    .or(assigned_stories_entity_type.eq('Project').and(assigned_stories_table[:entity_id].in(visible_project_ids)))

    conditions = visible_project_stories_condition.or(assigned_stories_condition)
    conditions = conditions.to_sql + ' OR ' + visible_global_stories_condition if !options[:only_project_stories]

    eager_load([:easy_knowledge_assigned_stories, :easy_knowledge_categories]).where(conditions)
  end

  def self.available_custom_fields
    EasyKnowledgeStoryCustomField.sorted
  end

  def self.css_icon
    'icon icon-bulb'
  end

  def assigned_entities(entity_type = nil)
    case entity_type
    when 'Issue'
      self.issues
    when 'User', 'Principal'
      self.users
    when 'Project'
      self.projects
    else
      self.entities
    end
  end

  def assigned_to_user(required_redaing)
    assigneds = if required_redaing
      t = EasyKnowledgeAssignedStory.arel_table
      self.easy_knowledge_assigned_stories.where(t[:required_reading_date].not_eq(nil)).where(:entity_type => 'Principal').all
    else
      self.easy_knowledge_assigned_stories.where(:required_reading_date => nil, :entity_type => 'Principal').all
    end

    assigneds.collect{|assign| {:user_id => assign.entity_id, :required_reading => assign.required_reading_date,:read => assign.read_date}}
  end

  def set_default_values
    self.author ||= User.current
  end

  def available_custom_fields
    self.class.available_custom_fields
  end

  def add_storyview!
    self.update_column(:storyviews, self.storyviews + 1)
  end

  def get_description
    case entity_type
    when 'Issue'
      entity.description
    when 'Journal'
      entity.notes
    else
      # read_attribute(:description)
      description
    end
  end

  # attachments dance
  def project
    nil
  end

  def attachments_visible?(user=User.current)
    visible?(user)
  end

  def attachments_deletable?(user=User.current)
    user.admin? || self.author == user
  end

  def readers
    User.joins("INNER JOIN #{EasyUserReadEntity.table_name} ON #{User.table_name}.id = #{EasyUserReadEntity.table_name}.user_id").where("#{EasyUserReadEntity.table_name}.entity_type = 'EasyKnowledgeStory' AND #{EasyUserReadEntity.table_name}.entity_id = #{id}").sorted
  end

  def notified_updated_users
    User.active.sorted.where(id: user_ids | user_read_records.map(&:user_id)).to_a
  end

  def notified_users
    notified = []
    categories = []
    notified << self.author
    categories = self.easy_knowledge_categories.preload(:entity).to_a
    if categories.blank?
      notified.concat(self.entity.project.notified_users) if self.entity && self.entity.project
    else
      categories.each do |category|
        case category.entity_type
        when 'Principal'
          notified << category.user
        when 'Project'
          notified.concat(category.project.notified_users) if category.project
        else
          #notified.concat(User.active.non_system_flag.easy_type_internal.to_a)
        end
      end
    end

    notified = notified.uniq.compact.select {|u| u.active? && u.notify_about?(self) && self.visible?(u)}
    notified
  end

  def recipients
    notified_users
  end

  def favorite!(user=User.current)
    unless self.is_favorite?(user)
      user.easy_knowledge_assigned_stories.create(:story_id => self.id) unless user.assigned_knowledge_story?(self)
      self.favorited_by << user
      @is_favorite[user.id] = true
    end
    return self
  end

  def unfavorite!(user=User.current)
    if self.is_favorite?(user)
      self.favorited_by.where(:id => user.id).exists?
      self.favorited_by.delete(user)
      @is_favorite[user.id] = false
    end
    return self
  end

  def is_favorite?(user=User.current)
    @is_favorite ||= Hash.new
    return @is_favorite[user.id] unless @is_favorite[user.id].nil?
    @is_favorite[user.id] = self.favorited_by.where(:id => user.id).exists?
  end

  def categories_count
    self.categories.count
  end

  def editable?(user = nil)
    user ||= User.current

    if user.allowed_to_globally?(:edit_all_global_stories) || (user.allowed_to_globally?(:edit_own_global_stories) && author?(user))
      return true if categories_empty_or_principle? && projects.empty?
      return true if categories.exists?(entity_type: nil) # nil means its a global category
    end

    categories.where(entity_type: 'Project').each do |c|
      return true if ((author?(user) && user.allowed_to?(:edit_own_project_stories, c.project)) || user.allowed_to?(:edit_all_project_stories, c.project))
    end

    projects.each do |project|
      return true if ((author?(user) && user.allowed_to?(:edit_own_project_stories, project)) || user.allowed_to?(:edit_all_project_stories, project))
    end
    false
  end

  def visible?(user = nil)
    user ||= User.current
    return true if user.admin?
    return false unless user.allowed_to_globally?(:view_easy_knowledge)
    self.categories.each {|c| return true if c.stories_visible?(user)}
    self.projects.each {|p| return true if p && user.allowed_to?(:read_project_stories, p)}
    return true if users.include? user
    return true if categories_empty_or_principle? && projects.empty? && user.allowed_to_globally?(:read_global_stories)
  end

  def categories_empty_or_principle?
    return true if categories.empty?
    categories.each {|c| return false if c.entity_type != 'Principal'}
    true
  end

  def author?(user = nil)
    user ||= User.current
    self.author_id == user.id
  end

  def to_s
    self.name
  end

  # Reverts the record to a previous version
  def revert_to!(version)
    if version.easy_knowledge_story_id == id
      update_columns(version.attributes.except('id', 'author_id').slice(*EasyKnowledgeStory.column_names)) && reload
    end
  end

  def set_new_version
    self.version = next_version
  end

  def current_version
    versions.detect{ |v| v.version == version }
  end

  private

  def next_version
    return 1 if new_record?
    (versions.maximum('version') || 0) + 1
  end

  def send_notification_added
    EasyKnowledgeMailer.deliver_easy_knowledge_story_added(self)
  end

  def send_notification_updated
    EasyKnowledgeMailer.deliver_recommended_story_updated(self)
  end

  def create_version
    version = EasyKnowledgeStoryVersion.new(attributes.except("id").slice(*EasyKnowledgeStoryVersion.column_names))
    version.author = User.current
    versions << version
  end

  def references_mirror
    references_to.delete_all
    references_by.each{|r| r.references_by << self}
    references_to.reload
  end

  def set_issue_assignment
    i = self.journal.issue if self.entity.is_a?(Journal)
    i ||= self.issue if self.entity.is_a?(Issue)

    i.easy_knowledge_stories |= [self]
    i.project.easy_knowledge_stories |= [self]
  end

end
