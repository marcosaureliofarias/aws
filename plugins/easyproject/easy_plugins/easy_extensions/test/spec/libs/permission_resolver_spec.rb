require 'easy_extensions/spec_helper'

module ResolverTest
  class MyModel
    mattr_accessor :visible, default: false
  end

  class MyResolver < PermissionResolver
    register_for 'ResolverTest::MyModel'

    def resolve_visibility(key)
      case key
      when :via_case
        ResolverTest::MyModel.visible
      end
    end

    def via_method_visible
      ResolverTest::MyModel.visible
    end

    map_visibility(:via_mapper) do
      ResolverTest::MyModel.visible
    end

  end
end

RSpec.describe PermissionResolver do

  it 'test visibility' do
    resolver = PermissionResolver.resolver_for(ResolverTest::MyModel.new)

    expect(resolver.visible?(:via_case)).to be_falsey
    expect(resolver.visible?(:via_method)).to be_falsey
    expect(resolver.visible?(:via_mapper)).to be_falsey
    expect(resolver.visible?(:undefined)).to be_truthy

    ResolverTest::MyModel.visible = true

    expect(resolver.visible?(:via_case)).to be_truthy
    expect(resolver.visible?(:via_method)).to be_truthy
    expect(resolver.visible?(:via_mapper)).to be_truthy
    expect(resolver.visible?(:undefined)).to be_truthy
  end

end
