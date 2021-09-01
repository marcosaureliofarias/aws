require 'easy_extensions/spec_helper'

describe EasyContactsToolbarController, :logged => :admin do
  let!(:person) { FactoryGirl.create(:personal_easy_contact_type, is_default: true) }
  let!(:easy_contacts) { FactoryGirl.create_list(:easy_contact, 3) }
  let!(:my_easy_contact) { FactoryGirl.create(:easy_contact, :firstname => 'John', :lastname => 'Smith') }
  let!(:my_easy_contact2) { FactoryGirl.create(:easy_contact, :firstname => 'Jonathan Peter', :lastname => 'Max') }

  context 'search' do
    it 'firstname' do
      get :search, :params => {:easy_query_q => 'John'}
      expect(assigns(:easy_contacts)).not_to be_nil
      expect(assigns(:easy_contacts).count).to eq 1
    end

    it 'lastname' do
      get :search, :params => {:easy_query_q => 'Smith'}
      expect(assigns(:easy_contacts)).not_to be_nil
      expect(assigns(:easy_contacts).count).to eq 1
    end

    it 'fullname' do
      get :search, :params => {:easy_query_q => 'John Smith'}
      expect(assigns(:easy_contacts)).not_to be_nil
      expect(assigns(:easy_contacts).count).to eq 1
    end

    it 'reverse fullname' do
      get :search, :params => {:easy_query_q => 'Smith John'}
      expect(assigns(:easy_contacts)).not_to be_nil
      expect(assigns(:easy_contacts).count).to eq 1
    end

    xit '3 names' do
      get :search, :params => {:easy_query_q => 'Peter Max'}
      expect(assigns(:easy_contacts)).not_to be_nil
      expect(assigns(:easy_contacts).count).to eq 1
    end

    it 'all' do
      get :search, :params => {:easy_query_q => ''}
      expect(assigns(:easy_contacts)).not_to be_nil
      expect(assigns(:easy_contacts).count).to eq 5
    end

    it 'nothing' do
      get :search, :params => {:easy_query_q => '***'}
      expect(assigns(:easy_contacts)).not_to be_nil
      expect(assigns(:easy_contacts).count).to eq 0
    end
  end
end
