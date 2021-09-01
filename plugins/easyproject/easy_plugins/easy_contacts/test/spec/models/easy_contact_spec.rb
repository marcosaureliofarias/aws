require 'easy_extensions/spec_helper'

describe EasyContact, :logged => :admin do

  let!(:easy_contact_type) {
    easy_contact_type = FactoryGirl.create(:easy_contact_type)
    easy_contact_type.custom_fields << FactoryGirl.create(:easy_contact_custom_field, internal_name: 'easy_contacts_street')
    easy_contact_type.custom_fields << FactoryGirl.create(:easy_contact_custom_field, internal_name: 'easy_contacts_city')
    easy_contact_type.custom_fields << FactoryGirl.create(:easy_contact_custom_field, field_format: :email, internal_name: 'easy_contacts_email')
    easy_contact_type
  }

  let(:easy_contact1) { FactoryGirl.create(:easy_contact, :personal, :with_random_address, {:easy_contact_type => easy_contact_type}) }
  let(:easy_contact2) { FactoryGirl.create(:easy_contact, :personal, :with_random_address, {:easy_contact_type => easy_contact_type}) }
  let(:easy_contact3) { FactoryGirl.create(:easy_contact, :personal, :with_random_address, {:easy_contact_type => easy_contact_type}) }

  it 'like' do
    expect(EasyContact.like(easy_contact1.firstname)).to eq([easy_contact1])
  end

  it 'assignment' do
    easy_contact1.cf_email_value = 'x@x.com'
    easy_contact1.save
    issue = FactoryBot.create(:issue, easy_email_to: 'x@x.com')
    issue.reload
    expect(issue.easy_contacts).to eq([easy_contact1])
    issue = FactoryBot.create(:issue, easy_email_to: 'z@z.com')
    issue.reload
    expect(issue.easy_contacts).to be_empty
  end

  it 'visible without permissions', logged: true do
    easy_contact1
    expect(EasyContact.visible.to_a).to eq([])
    t = User.current.easy_user_type
    t.easy_contact_types = [easy_contact_type]
    t.save
    expect(EasyContact.visible.to_a).to eq([])
  end

  it 'merges easy contacts correctly into easy contact1' do
    json = IO.read(File.join(EasyExtensions::EASY_EXTENSIONS_DIR + '/test/fixtures/files', 'geocode.json'))
    stub_request(:get, /.*maps.googleapis.com\/maps\/api\/geocode\/json.*/).
         with(:headers => {'Accept' => '*/*', 'User-Agent' => 'Ruby'}).
         to_return(:status => 200, :body => json, :headers => {'Content-Type' => 'application/json; charset=UTF-8'})

    easy_contact1; easy_contact2; easy_contact3

    EasyContact.easy_merge_easy_contacts([easy_contact2, easy_contact3], easy_contact1)

    ec1 = EasyContact.find(easy_contact1.id) # FORCE reload
    expect(
      ec1.cf_street_value
    ).to eq ([easy_contact1.cf_street_value, easy_contact2.cf_street_value, easy_contact3.cf_street_value].join(','))
    expect(
      ec1.cf_city_value
    ).to eq ([easy_contact1.cf_city_value, easy_contact2.cf_city_value, easy_contact3.cf_city_value].join(','))
  end

  context 'fields permissions', :logged => true do

    let!(:user) { FactoryGirl.create(:user)}

    it 'should be visible' do
      with_easy_settings('easy_contact_author_id_allowed_user_ids' => [User.current.id.to_s]) do
        expect(EasyContact.author_id_field_visible?).to be true
      end
    end

    it 'should be invisible' do
      with_easy_settings('easy_contact_author_id_allowed_user_ids' => [user.id.to_s]) do
        expect(EasyContact.author_id_field_visible?).to be false
      end
    end
  end

  context 'geocode' do
    it 'on create and address change' do
      expect {
         easy_contact1
      }.to have_enqueued_job(GetContactGeocodeJob)
      easy_contact1.reload

      easy_contact1.cf_city_value = 'Oslo'
      expect {
         easy_contact1.save
      }.to have_enqueued_job(GetContactGeocodeJob)
    end

    it 'on regular save' do
      easy_contact1.reload
      expect {
        easy_contact1.save
      }.not_to have_enqueued_job(GetContactGeocodeJob)
    end
  end

end