require_relative '../spec_helper'

describe 'EasyCrmCaseQuery', logged: :admin do

  let(:cf) { FactoryGirl.create(:easy_contact_custom_field, name: 'test1', field_format: 'string', is_primary: true, show_empty: true) }

  let(:main_easy_contact_1) { contact = FactoryGirl.build(:easy_contact)
    cf.contact_types << contact.easy_contact_type
    contact.custom_field_values = { cf.id.to_s => 'test1' }
    contact.save
    contact
  }


  let(:related_easy_contact_1) { contact = FactoryGirl.build(:easy_contact)
    cf.contact_types << contact.easy_contact_type
    contact.custom_field_values = { cf.id.to_s => 'test2' }
    contact.save
    contact
  }


  let!(:easy_crm_case_with_main_contact) { FactoryGirl.create(:easy_crm_case, main_easy_contact: main_easy_contact_1) }

  let!(:easy_crm_case_with_related_contact) { FactoryGirl.create(:easy_crm_case, easy_contacts: [related_easy_contact_1]) }

  let!(:easy_crm_case_with_both_contacts) { FactoryGirl.create(:easy_crm_case, easy_contacts: [related_easy_contact_1, main_easy_contact_1], main_easy_contact: main_easy_contact_1) }
  let!(:easy_crm_case_with_both_contacts2) { FactoryGirl.create(:easy_crm_case, easy_contacts: [related_easy_contact_1, main_easy_contact_1], main_easy_contact: related_easy_contact_1) }

  it 'contacts filters correction data' do
    expect(easy_crm_case_with_main_contact.easy_contact_ids).not_to include(easy_crm_case_with_main_contact.main_easy_contact_id)
    expect(easy_crm_case_with_related_contact.easy_contact_ids).not_to include(easy_crm_case_with_related_contact.main_easy_contact_id)
    expect(easy_crm_case_with_both_contacts.easy_contact_ids).to include(easy_crm_case_with_both_contacts.main_easy_contact_id)

    expect(main_easy_contact_1.custom_field_value(cf.id.to_s)).to eq('test1')

    query = EasyCrmCaseQuery.new
    query.add_filter("easy_contacts_cf_#{cf.id}", '=', 'test2')
    query.add_filter("main_easy_contact_cf_#{cf.id}", '=', 'test1')
    query.sort_criteria = [["main_easy_contacts.#{cf.id}", 'asc']]
    expect(query.entities.count).to eq(1)
    expect(query.entities.first).to eq(easy_crm_case_with_both_contacts)
  end

  it 'contacts filters correction data with reverse filters order' do
    query = EasyCrmCaseQuery.new
    query.add_filter("main_easy_contact_cf_#{cf.id}", '=', 'test1')
    query.add_filter("easy_contacts_cf_#{cf.id}", '=', 'test2')
    query.sort_criteria = [["main_easy_contacts.#{cf.id}", 'asc']]
    expect(query.entities.count).to eq(1)
    expect(query.entities.first).to eq(easy_crm_case_with_both_contacts)
  end

  it 'filtering crm by contacts id' do
    query = EasyCrmCaseQuery.new
    query.add_filter("main_easy_contact_id", '=', "#{main_easy_contact_1.id}")
    query.add_filter("easy_contacts.id", '=', "#{related_easy_contact_1.id}")
    expect(query.entities.count).to eq(1)
    expect(query.entities.first).to eq(easy_crm_case_with_both_contacts)
  end
end
