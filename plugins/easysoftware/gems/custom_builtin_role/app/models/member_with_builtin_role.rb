class MemberWithBuiltinRole < Member

  def initialize(principal: nil, project: nil, role: nil)
    super principal: principal, project: project
    @role = role
    readonly!
  end

  def roles
    [@role]
  end

end