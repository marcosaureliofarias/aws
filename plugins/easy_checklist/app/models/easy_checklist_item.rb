class EasyChecklistItem < ActiveRecord::Base
  include Redmine::I18n
  include Redmine::SafeAttributes

  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :changed_by, :class_name => 'User', :foreign_key => 'changed_by_id'
  belongs_to :easy_checklist

  validates_length_of :subject, :maximum => 255
  validates :author_id, :subject, :easy_checklist, :presence => true

  safe_attributes :author, :subject, :new_position

  attr_accessor :new_position

  before_save :set_last_done_change
  before_save :set_changed_by
  before_save :ensure_new_position

  after_initialize :ensure_author

  after_save :create_journal
  after_create :change_done_ratio
  after_update :change_done_ratio, if: proc { |item| item.saved_change_to_done? }

  after_destroy :create_journal
  after_destroy :change_done_ratio_after_destroy

  acts_as_positioned :scope => :easy_checklist_id

  def can_change?(user=nil)
    user ||= User.current
    self.can_enable? || self.can_disable?
  end

  def can_enable?(user=nil)
    user ||= User.current
    !done && user.allowed_to?(:enable_easy_checklist_items, easy_checklist.entity.project)
  end

  def can_disable?(user=nil)
    user ||= User.current
    done && user.allowed_to?(:disable_easy_checklist_items, easy_checklist.entity.project)
  end

  private

  def ensure_author
    self.author = User.current if self.author_id.nil?
  end

  def ensure_new_position
    return if self.new_position.blank?
    new_new_position = self.new_position
    self.new_position = nil
    self.position = new_new_position.to_i
  end

  def create_journal
    return true if !easy_checklist.is_history_changes_enabled?

    if easy_checklist && easy_checklist.entity
      if self.done?
        state = l(:text_easy_checklist_item_state_checked)
        old_state = l(:text_easy_checklist_item_state_unchecked)
      else
        state = l(:text_easy_checklist_item_state_unchecked)
        old_state = l(:text_easy_checklist_item_state_checked)
      end
      if saved_change_to_created_at?
        journal = easy_checklist.entity.init_journal(User.current)
        journal.details << JournalDetail.new(:property => 'easy_checklist_item', :value => self.subject)
      elsif saved_change_to_done?
        journal = easy_checklist.entity.init_journal(User.current)
        journal.details << JournalDetail.new(:property => 'easy_checklist_item', :prop_key => self.subject, :value => state, :old_value => old_state)
      elsif saved_change_to_subject?
        journal = easy_checklist.entity.init_journal(User.current)
        journal.details << JournalDetail.new(:property => 'easy_checklist_item', :prop_key => self.subject, :value => self.subject, :old_value => self.subject_before_last_save)
      elsif destroyed?
        journal = easy_checklist.entity.init_journal(User.current)
        journal.details << JournalDetail.new(:property => 'easy_checklist_item', :old_value => self.subject)
      end
      journal.save if journal
    end
    true
  end

  def change_done_ratio_after_destroy
    change_done_ratio(self)
  end

  def change_done_ratio(deleted_item = nil)
    if easy_checklist.is_change_done_ratio_enabled?
      entity = easy_checklist.entity
      entity.init_journal(User.current)

      easy_checklist_items_done = entity.all_easy_checklist_items
      entity.all_easy_checklist_items.delete(deleted_item) if deleted_item

      easy_checklist_items_done.map! {|ecli| ecli.id == self.id ? self.done : ecli.done?}

      done_total_count = easy_checklist_items_done.count(true).to_f
      all_items_count = easy_checklist_items_done.count

      if all_items_count != 0
        ratio = (done_total_count / all_items_count) * 100
      else
        ratio = 0
      end

      entity.update_easy_checklist_done_ratio(ratio) if entity.respond_to?(:update_easy_checklist_done_ratio)
    end
  end

  def set_changed_by
    self.changed_by = User.current
  end

  def set_last_done_change
    if done_changed?
      self.last_done_change = Time.now.utc
    end
  end
end
