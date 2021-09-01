require 'easy_extensions/spec_helper'

RSpec.describe ActiveRecord::Serialization do
  # just to make sure that #to_xml exports some data - ensures presence of 'activemodel-serializers-xml' gem
  describe '#to_xml' do
    let(:users) { [User.current, User.current] }
    it 'outputs xml with User attributes as xml nodes' do
      lastname_node = "<lastname>#{users.first.lastname}</lastname>"
      type_node     = "<type>#{users.first.type}</type>"
      expect(users.to_xml(only: [:lastname, :type])).to include(lastname_node, type_node)
    end
  end
end
