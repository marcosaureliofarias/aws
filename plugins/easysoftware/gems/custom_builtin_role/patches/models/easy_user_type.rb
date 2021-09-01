Rys::Patcher.add('EasyUserType') do
  apply_if_plugins :easy_extensions

  included do
    belongs_to :builtin_role, class_name: 'Role', foreign_key: 'builtin_role_id'

    safe_attributes 'builtin_role_id'
  end

end
