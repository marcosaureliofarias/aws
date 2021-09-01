require 'easy_extensions/spec_helper'

describe EasyPage, logged: true do

  let(:user) { User.current }

  describe '#editable?' do
    let(:principal_permission) { FactoryBot.create(:easy_page_permission, easy_page: easy_page, entity_type: 'Principal', entity_id: user.id, permission_type: :edit) }
    let(:easy_user_type_permission) { FactoryBot.create(:easy_page_permission, easy_page: easy_page, entity_type: 'EasyUserType', entity_id: user.easy_user_type_id, permission_type: :edit) }

    context 'using strict permissions' do
      let(:easy_page) { FactoryBot.create(:easy_page, strict_permissions: true) }

      context 'with no permissions' do
        it { expect(easy_page.editable?(user)).to eq(false) }
      end

      context 'with permission for principal' do
        it do
          principal_permission
          expect(easy_page.editable?(user)).to eq(true)
        end
      end

      context 'with permission for user type' do
        it do
          easy_user_type_permission
          expect(easy_page.editable?(user)).to eq(true)
        end
      end

    end
    context 'not using strict permissions' do
      let(:easy_page) { FactoryBot.create(:easy_page, strict_permissions: false) }

      context 'with permission for principal' do
        it do
          principal_permission
          expect(easy_page.editable?(user)).to eq(false)
        end
      end

      context 'with manage_custom_dashboards permission' do
        it do
          allow(user).to receive(:allowed_to_globally?).with(:manage_custom_dashboards).and_return(true)
          expect(easy_page.editable?(user)).to eq(true)
        end
      end

      context 'with custom permission' do
        it do
          allow(user).to receive(:allowed_to_globally?).with(:manage_custom_dashboards).and_return(false)
          allow(user).to receive(:allowed_to_globally?).with(:edit_easy_calendar_layout).and_return(true)
          expect(easy_page.editable?(user, permission: :edit_easy_calendar_layout)).to eq(true)
        end
      end

    end
  end

  describe '#visible?' do
    let(:principal_permission) { FactoryBot.create(:easy_page_permission, easy_page: easy_page, entity_type: 'Principal', entity_id: user.id, permission_type: :show) }
    let(:easy_user_type_permission) { FactoryBot.create(:easy_page_permission, easy_page: easy_page, entity_type: 'EasyUserType', entity_id: user.easy_user_type_id, permission_type: :show) }

    context 'using strict permissions' do
      let(:easy_page) { FactoryBot.create(:easy_page, strict_show_permissions: true) }

      context 'with no permissions' do
        it { expect(easy_page.visible?(user)).to eq(false) }
      end

      context 'with permission for principal' do
        it do
          principal_permission
          expect(easy_page.visible?(user)).to eq(true)
        end
      end

      context 'with permission for user type' do
        it do
          easy_user_type_permission
          expect(easy_page.visible?(user)).to eq(true)
        end
      end

    end
    context 'not using strict permissions' do
      let(:easy_page) { FactoryBot.create(:easy_page, strict_show_permissions: false) }

      context 'with permission for principal' do
        it do
          principal_permission
          expect(easy_page.visible?(user)).to eq(false)
        end
      end

      context 'with manage_custom_dashboards permission' do
        it do
          allow(user).to receive(:allowed_to_globally?).with(:manage_custom_dashboards).and_return(true)
          expect(easy_page.visible?(user)).to eq(true)
        end
      end

      context 'with custom permission' do
        it do
          allow(user).to receive(:allowed_to_globally?).with(:manage_custom_dashboards).and_return(false)
          allow(user).to receive(:allowed_to_globally?).with(:edit_easy_calendar_layout).and_return(true)
          expect(easy_page.visible?(user, permission: :edit_easy_calendar_layout)).to eq(true)
        end
      end

    end
  end

end
