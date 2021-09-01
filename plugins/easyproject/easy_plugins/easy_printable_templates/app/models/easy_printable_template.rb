class EasyPrintableTemplate < ActiveRecord::Base
  include Redmine::SafeAttributes

  PAGES_ORIENTATION_PORTRAIT = 'portrait'
  PAGES_ORIENTATION_LANDSCAPE = 'landscape'

  belongs_to :project
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  has_many :easy_printable_template_pages, :dependent => :destroy

  scope :visible, lambda {|*args|
    options = args.extract_options!
    user = args.shift || User.current
    where(EasyPrintableTemplate.visible_condition(user, options))
  }

  acts_as_attachable

  validates :name, :author, :presence => true

  after_initialize :set_default_values, :if => Proc.new { |template| template.new_record? }

  accepts_nested_attributes_for :easy_printable_template_pages, :allow_destroy => true

  safe_attributes 'name', 'pages_orientation', 'pages_size', 'private',
    'category', 'easy_printable_template_pages_attributes', 'description', if: ->(t, user) { t.editable? }

  safe_attributes 'author_id', if: ->(t, user) { user.allowed_to_globally?(:manage_easy_printable_templates) }

  def self.create_from_view!(attrs, options = {})
    plugin_name = options[:plugin_name] || 'easy_extensions'
    internal_name = options[:internal_name]
    template_name = options[:template_name] || plugin_name
    template_path = options[:template_path] || File.join(Rails.root, EasyExtensions::RELATIVE_EASYPROJECT_EASY_PLUGINS_PATH, plugin_name, 'app', 'views', 'easy_printable_templates', "#{internal_name || template_name}.html")

    return nil unless File.exists?(template_path)

    if internal_name
      template = EasyPrintableTemplate.find_or_initialize_by(:internal_name => internal_name)
    else
      template = EasyPrintableTemplate.find_or_initialize_by(:name => attrs[:name] || template_name)
    end

    template.attributes = attrs

    template.easy_printable_template_pages.clear if !template.new_record?
    template.easy_printable_template_pages.build(:page_text => File.read(template_path))
    template.set_default_values
    template.save!
    template
  end

  def self.visible_condition(user, options={})
    condition = ''
    user.allowed_to_globally?(:view_easy_printable_templates, options) do |role, user|
      if role.easy_printable_templates_visibility == 'all'
      elsif (role.easy_printable_templates_visibility == 'own') && user.logged?
        condition = "#{table_name}.author_id = #{user.id}"
      else
        condition = '1=0'
      end
    end
    condition
  end

  def dup_with_pages
    clone = self.dup
    self.easy_printable_template_pages.each do |page|
      clone.easy_printable_template_pages << page.dup
    end
    clone.author = User.current
    clone.internal_name = nil
    clone
  end

  def self.translate_pages_orientation(orientation)
    l(orientation, :scope => [:easy_printable_template, :pages_orientation])
  end

  def self.find_internal_name(internal_name)
    EasyPrintableTemplate.where(:internal_name => internal_name).first
  end

  def translate_pages_orientation
    self.class.translate_pages_orientation(self.pages_orientation)
  end

  def visible?(user = nil)
    user ||= User.current
    user.allowed_to_globally?(:view_easy_printable_templates) do |role, u|
      if role.easy_printable_templates_visibility == 'all'
        true
      elsif (role.easy_printable_templates_visibility == 'own') && user.logged?
        self.author_id == u.id
      else
        false
      end
    end
  end

  def editable?(user = nil)
    user ||= User.current
    self.internal_name.blank? && (user.allowed_to_globally?(:manage_easy_printable_templates) || (user.allowed_to_globally?(:manage_own_easy_printable_templates) && self.author_id == user.id))
  end

  def deletable?(user = nil)
    editable?(user)
  end

  def category_caption
    EasyPrintableTemplate.category_caption(category)
  end

  def self.category_caption(category)
    l(category, :scope => [:easy_printable_templates_categories], :default => category.humanize)
  end

  def set_default_values
    self.pages_orientation ||= EasyPrintableTemplate::PAGES_ORIENTATION_PORTRAIT
    self.pages_size ||= 'a4'
    self.author ||= User.current
  end

  def attachments_visible?(user=User.current)
    user.allowed_to_globally?(self.class.attachable_options[:view_permission])
  end

  def attachments_editable?(user=User.current)
    user.allowed_to_globally?(self.class.attachable_options[:edit_permission])
  end

  def attachments_deletable?(user=User.current)
    user.allowed_to_globally?(self.class.attachable_options[:delete_permission])
  end

  def docx_template
    attachments.detect{|a| a.filename.to_s.ends_with?('.docx')}
  end

end
