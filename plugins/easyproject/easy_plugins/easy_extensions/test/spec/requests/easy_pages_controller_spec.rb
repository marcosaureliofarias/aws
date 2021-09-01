require 'easy_extensions/spec_helper'

describe EasyPagesController, type: :request do

  context 'logged as admin' do
    include_context 'logged as admin'

    let(:easy_page) { FactoryBot.create(:easy_page, strict_permissions: true) }
    let(:easy_user_type) { FactoryBot.create(:easy_user_type) }

    describe '#update' do
      it 'creates easy_page_permissions' do
        params = {
            id:        easy_page,
            easy_page: {
                permitted_principal_ids:      [User.current.id],
                permitted_easy_user_type_ids: [easy_user_type.id]
            }
        }
        expect { put easy_page_path(params) }.to change(EasyPagePermission, :count).by(2)
      end
    end

    describe '#create' do
      it do
        params = {
            easy_page:              {
                user_defined_name:            'custom page',
                strict_permissions:           '1',
                permitted_principal_ids:      [User.current.id],
                permitted_easy_user_type_ids: [easy_user_type.id]
            },
            page_layout_identifier: 'tchtrrs'
        }
        expect { post '/easy_pages', params: params }.to change(EasyPage, :count).by(1)
      end
    end

  end

end
