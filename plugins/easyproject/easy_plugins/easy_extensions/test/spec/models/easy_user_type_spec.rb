require 'easy_extensions/spec_helper'

RSpec.describe EasyUserType, :type => :model, :logged => :admin do

  let(:easy_user_type) { FactoryGirl.create(:test_easy_user_type) }

  it 'checks if current easy_user_type exists' do
    expect(User.current.easy_user_type).to_not be nil
  end

  it 'changes default easy_user_type' do
    easy_user_type.is_default = true
    easy_user_type.save
    expect(easy_user_type.is_default).to be true
    easy_user_type.is_default = false
    easy_user_type.save
    expect(easy_user_type.is_default).to be true # can't change the default type to false
    expect(EasyUserType.where(:is_default => true).count).to eq(1)
  end

  it 'destroys default easy_user_type' do
    easy_user_type.is_default = true
    easy_user_type.save
    expect { easy_user_type.destroy }.not_to change(EasyUserType, :count)
  end

  it 'destroys easy_user_type' do
    easy_user_type
    expect { easy_user_type.destroy }.to change(EasyUserType, :count).by(-1)
  end

  it 'assignes easy_user_type to the user' do
    expect {
      User.current.easy_user_type = easy_user_type
      User.current.save
      User.current.reload
    }.to change(User.current, :easy_user_type_id)
  end

  it 'checks associations', :logged => true do
    User.current.admin          = false
    User.current.easy_user_type = easy_user_type
    User.current.save
    easy_user_type.reload
    expect(easy_user_type.users).to include User.current
    easy_user_type.internal = true
    easy_user_type.save
    expect(User.current).to be_internal_client
    expect(User.current).not_to be_external_client
    easy_user_type.internal = false
    easy_user_type.save
    expect(User.current).not_to be_internal_client
    expect(User.current).to be_external_client
  end

  it 'admin should always be an internal client', :logged => :admin do
    User.current.easy_user_type = easy_user_type
    User.current.save
    easy_user_type.internal = false
    easy_user_type.save
    expect(User.current).to be_internal_client
  end

  it 'destroys easy_user_type and checks changed associations' do
    old_easy_user_type        = User.current.easy_user_type
    easy_user_type.is_default = true
    easy_user_type.save
    easy_user_type.reload
    expect(User.current.easy_user_type).not_to eq(easy_user_type)
    old_easy_user_type.reload
    old_easy_user_type.destroy
    easy_user_type.reload
    User.current.reload
    expect(User.current.easy_user_type).not_to eq(old_easy_user_type)
    expect(User.current.easy_user_type).to eq(easy_user_type)
  end

  it 'custom menu url lesser or equal to 2000 characters should be saved' do
    easy_user_type.easy_custom_menus << EasyCustomMenu.new(name: 'test', url: '0' * 2000)
    easy_user_type.save
    easy_user_type.reload
    expect(easy_user_type.easy_custom_menus.first.url).to eq('0' * 2000)
  end

  it 'custom menu url over 2000 characters should not be valid' do
    easy_user_type.easy_custom_menus << EasyCustomMenu.new(name: 'test', url: '0' * 2001)
    expect(easy_user_type.easy_custom_menus.first.valid?).to eq(false)
  end

  context 'cache' do
    let(:easy_user_type2) { FactoryGirl.create(:test_easy_user_type) }
    let(:user1) { FactoryGirl.create(:user, :easy_user_type => easy_user_type) }
    let(:user2) { FactoryGirl.create(:user, :easy_user_type => easy_user_type2) }

    def reload_users
      user1.reload; user2.reload
    end

    it 'tests visibility on users' do
      expect(user1.visible?(user2)).to be false
      easy_user_type2.easy_user_visible_types = [easy_user_type]
      easy_user_type2.save; reload_users
      expect(user1.visible?(user2)).to be true
      easy_user_type2.easy_user_visible_types = []
      easy_user_type2.save; reload_users
      expect(user1.visible?(user2)).to be false
      easy_user_type2.easy_user_visible_types = [easy_user_type]
      easy_user_type2.save; reload_users
      easy_user_type2.destroy
      reload_users
      expect(user1.visible?(user2)).to be false
    end
  end


  describe "#copy" do

    let(:easy_translation) { EasyTranslation.new(value: 'haf', entity_column: 'name', lang: 'cs') }
    let(:submenu) { EasyCustomMenu.new(name: 'submenu', url: 'u/ra/l') }
    let(:easy_custom_menu) { EasyCustomMenu.new(name: 'ahoj', url: 'u/ro/luj/to', easy_translations: [easy_translation], submenus: [submenu]) }
    let(:easy_user_type1) { FactoryBot.build(:easy_user_type, easy_custom_menus: [easy_custom_menu, submenu]) }

    subject { easy_user_type1 }

    it 'name include (Copy)' do
      copy_subject = subject.copy
      expect(copy_subject.name).to include(I18n.t(:label_copied))
    end

    it 'menu and submenu' do
      copy_subject = subject.copy
      expect(subject.easy_custom_menus.size).to eq(copy_subject.easy_custom_menus.size)
      copy_custom_menu = copy_subject.easy_custom_menus.first
      expect(easy_custom_menu.submenus.size).to eq(copy_custom_menu.submenus.size)
    end

    it 'menu with translation' do
      copy_subject     = subject.copy
      copy_custom_menu = copy_subject.easy_custom_menus.first
      expect(copy_custom_menu.name).to eq('ahoj')
      expect(easy_custom_menu.easy_translations.size).to eq(copy_custom_menu.easy_translations.size)
    end

    it 'keeps is_default' do
      subject.is_default = true
      subject.easy_custom_menus = []
      expect(subject.save).to eq(true)
      copy = subject.copy
      expect(copy.is_default).to eq(false)
      expect(copy.save).to eq(true)
      expect(subject.reload.is_default).to eq(true)
    end
  end
end
