module EasyContacts
  class FieldsSettings

    attr_reader :model, :column_name, :user

    def initialize(model, column_name, user = nil)
      @model = model
      @column_name = column_name
      @user = user || User.current
    end

    def visible?
      return true if !special_permissions_enabled? || user.admin?
      group_allowed? || user_type_allowed? || user_allowed?
    end

    def special_permissions_enabled?
      allowed_group_ids.to_a.detect(&:present?) || allowed_easy_user_type_ids.to_a.detect(&:present?) || allowed_user_ids.to_a.detect(&:present?)
    end

    def groups
      Group.sorted.where(id: allowed_group_ids)
    end

    def easy_user_types
      EasyUserType.sorted.where(id: allowed_easy_user_type_ids)
    end

    def users
      User.sorted.where(id: allowed_user_ids)
    end

    def field_label
      case column_name
      when 'assigned_to_id'
        EasyContact.human_attribute_name(:account_manager)
      when 'external_assigned_to_id'
        EasyContact.human_attribute_name(:external_account_manager)
      else
        EasyContact.human_attribute_name(column_name)
      end
    end

    private

    def group_allowed?
      allowed_group_ids.present? && (allowed_group_ids.map(&:to_i) & user.group_ids).present?
    end

    def user_type_allowed?
      allowed_easy_user_type_ids.present? && allowed_easy_user_type_ids.map(&:to_i).include?(user.easy_user_type_id)
    end

    def user_allowed?
      allowed_user_ids.present? && allowed_user_ids.map(&:to_i).include?(user.id)
    end

    %w(allowed_group_ids allowed_easy_user_type_ids allowed_user_ids).each do |method|
      define_method method do
        EasySetting.value("#{model.name.underscore}_#{column_name}_#{method}")
      end
    end

  end
end