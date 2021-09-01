class EasyKnowledgeCategory < ActiveRecord::Base
  include Redmine::SafeAttributes
  include EasyKnowledge::EasyKnowledgeCategoryNestedSet

  has_and_belongs_to_many :easy_knowledge_stories, :join_table => 'easy_knowledge_story_categories', :foreign_key => 'category_id', :association_foreign_key => 'story_id'
  alias_method :stories, :easy_knowledge_stories

  belongs_to :entity, :polymorphic => true
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :user, :foreign_key => 'entity_id', :foreign_type => 'Principal'
  belongs_to :project, :foreign_key => 'entity_id', :foreign_type => 'Project'

  acts_as_customizable
  acts_as_searchable :columns => ["#{self.table_name}.name", "#{self.table_name}.description"],
    :project_key => "#{self.table_name}.entity_type='Project' AND #{self.table_name}.entity_id"
  acts_as_event :title => :name,
    :url => Proc.new {|o|
    controller = case o.entity_type
    when 'Project'
      'easy_knowledge_projects'
    when 'Principal'
      'easy_knowledge_users'
    else
      'easy_knowledge_globals'
    end
    {:controller => controller, :action => 'show', :id => o.id}},
    :datetime => :updated_on,
    :type => 'easy_knowledge_categories'

  before_save :check_entity_type
  before_validation :set_default_values

  validates :name, :presence => true

  scope :global, lambda { where(:entity_type => nil, :entity_id => nil).order(:lft) }
  scope :category_by_user, lambda { |*args| user_id = args.first; (user_id ? where(:entity_type => 'Principal', :entity_id => user_id) : where(:entity_type => 'Principal')).order(:lft) }
  scope :category_by_project, lambda { |*args| project_id = args.first; project_id ? where(:entity_type => 'Project', :entity_id => project_id).order(:lft) : where(:entity_type => 'Project').order(:lft) }
  scope :visible, lambda {|*args| where(self.visible_condition(args.shift || User.current, *args))}

  safe_attributes 'name', 'entity_type', 'entity_id', 'description', 'parent_id'

  html_fragment :description, :scrub => :strip

  def self.visible_condition(user, options={})
    return '1=1' if user.admin?
    return '1=0' unless user.allowed_to_globally?(:view_easy_knowledge)

    visible_categories(user, options)
  end

  def self.visible_categories(user, options={})
    visible_project_ids = Project.visible.where("#{Project.allowed_to_condition(user, :read_project_stories)} OR #{Project.allowed_to_condition(user, :manage_project_categories)}").distinct.pluck(:id)
    categories_table = EasyKnowledgeCategory.arel_table
    categories_entity_type = categories_table[:entity_type]
    categories_entity_id = categories_table[:entity_id]

    conditions = categories_entity_type.eq('Principal').and(categories_entity_id.eq(user.id))
    conditions = conditions.or(categories_entity_type.eq('Project').and(categories_entity_id.in(visible_project_ids))) if visible_project_ids.any?
    conditions = conditions.or(categories_entity_type.eq(nil)) if user.allowed_to_globally?(:read_global_stories) || user.allowed_to_globally?(:manage_global_categories)
    conditions
  end

  def to_s
    name
  end

  def stories_editable?(user=nil)
    user ||= User.current
    if entity_type == 'Project'
      user.allowed_to?(:edit_all_project_stories, project)
    elsif entity_type.nil?
      user.allowed_to_globally?(:edit_all_global_stories)
    end
  end

  def stories_deletable?(user=nil)
    stories_editable?(user)
  end

  def stories_visible?(user=nil)
    user ||= User.current
    if entity_type == 'Project'
      user.allowed_to?(:read_project_stories, project)
    elsif entity_type.nil?
      user.allowed_to_globally?(:read_global_stories)
    end
  end

  def set_default_values
    self.author ||= User.current
  end

  def self.available_custom_fields
    EasyKnowledgeCategoryCustomField.sorted
  end

  def available_custom_fields
    self.class.available_custom_fields
  end

  def editable?(user=nil)
    user ||= User.current
    case entity_type
      when 'Project'
        user.allowed_to?(:manage_project_categories, Project.find_by(id: entity_id))
      when 'Principal'
        author == user && user.allowed_to_globally?(:manage_own_personal_categories)
      else
        user.allowed_to_globally?(:manage_global_categories)
    end
  end

  def allowed_parents
    return @allowed_parents if @allowed_parents
    case entity_type
    when 'Project'
      @allowed_parents = EasyKnowledgeCategory.category_by_project(entity_id)
    when 'Principal'
      @allowed_parents = EasyKnowledgeCategory.category_by_user(entity_id)
    else
      @allowed_parents = EasyKnowledgeCategory.global
    end
    @allowed_parents = @allowed_parents - self_and_descendants

    #    if User.current.allowed_to?(:add_project, nil, :global => true) || (!new_record? && parent.nil?)
    @allowed_parents << nil
    #    end
    unless parent.nil? || @allowed_parents.empty? || @allowed_parents.include?(parent)
      @allowed_parents << parent
    end
    @allowed_parents
  end

  def copy_from(arg)
    category = arg.is_a?(EasyKnowledgeCategory) ? arg : EasyKnowledgeCategory.find(arg)
    self.attributes = category.attributes.dup.except('id', 'parent_id', 'lft', 'rgt', 'created_on', 'updated_on')
    self
  end

  def css_classes(lvl=nil)
    css = ''
    if lvl && lvl > 0
      css << ' idnt'
      css << " idnt-#{lvl}"
    end

    css
  end

  private

  def check_entity_type
    write_attribute(:entity_type, nil) if read_attribute(:entity_type).blank?
    write_attribute(:entity_id, nil) if read_attribute(:entity_type).blank?
  end

end
