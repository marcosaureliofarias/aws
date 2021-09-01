require 'easy_extensions/spec_helper'

describe EasyEntityActivity, logged: :admin do

  let!(:users) { FactoryBot.create_list(:user, 2) }
  let!(:easy_contact) { FactoryBot.create(:easy_contact) }
  let!(:category) { EasyEntityActivityCategory.create(name: 'cat') }
  let!(:entity_activity) { EasyEntityActivity.create(entity_type: 'EasyContact', entity_id: easy_contact.id, category: category) }

  it 'decorated autocompletes' do
    decorated = entity_activity.to_decorate
    expect(decorated.user_attendees.map{|x| x[:id]}).to include(User.current.id)
    expect(decorated.easy_contact_attendees.map{|x| x[:id]}).to include(easy_contact.id)
    expect(decorated.categories.map{|x| x[1]}).to include(category.id)
  end

end
