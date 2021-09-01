=begin
FactoryBot.define do

  factory :member_role do
    role
    member
  end

  factory :member do
    project
    user
    roles { [] }

    after :build do |member, evaluator|
      if evaluator.roles.empty?
        member.member_roles << FactoryBot.build(:member_role, member: member)
      else
        evaluator.roles.each do |role|
          member.member_roles << FactoryBot.build(:member_role, member: member, role: role)
        end
      end
    end
  end

end
=end
