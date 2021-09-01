require 'easy_extensions/spec_helper'

describe UsersController, logged: :admin do

  context 'easy gantt resources attributes' do
    render_views
  
    let(:user) { FactoryBot.create(:user) }
    
    it 'get' do
      with_easy_settings({ easy_gantt_resources_users_estimated_ratios:     { user.id.to_s => '1.0' },
                           easy_gantt_resources_users_hours_limits:         { user.id.to_s => '8.0' },
                           easy_gantt_resources_users_advance_hours_limits: { user.id.to_s => ["8.0", "8.0", "8.0", "8.0", "8.0", "0.0", "0.0"] }
                         }) do
        user
        get :show, params: { 'id' => user.id, 'format' => 'json' }
        expect(response).to be_successful
        data = JSON.parse(response.body)
        expect(data['user']['easy_gantt_resources_estimated_ratio']).to eq('1.0')
        expect(data['user']['easy_gantt_resources_hours_limit']).to eq('8.0')
        expect(data['user']['easy_gantt_resources_advance_hours_limits']).to eq(["8.0", "8.0", "8.0", "8.0", "8.0", "0.0", "0.0"])
      end
    end

    it 'post' do
      with_easy_settings({ easy_gantt_resources_users_estimated_ratios:     nil,
                           easy_gantt_resources_users_hours_limits:         nil,
                           easy_gantt_resources_users_advance_hours_limits: nil
                         }) do
        post :create, params: { 'format' => 'json',
                                'user' => { 'login' => 'resourceful.user',
                                            'mail' => 'resourceful.user@example.com',
                                            'firstname' => 'User',
                                            'lastname' => 'Resourceful',
                                            'easy_gantt_resources_estimated_ratio' => '1.0',
                                            'easy_gantt_resources_hours_limit' => '8.0',
                                            'easy_gantt_resources_advance_hours_limits' => ["8.0", "8.0", "8.0", "8.0", "8.0", "0.0", "0.0"]
                                          }
                              }
        expect(response).to be_successful
        data = JSON.parse(response.body)
        created_user = User.find(data['user']['id'])
        expect(created_user.easy_gantt_resources_estimated_ratio).to eq('1.0')
        expect(created_user.easy_gantt_resources_hours_limit).to eq('8.0')
        expect(created_user.easy_gantt_resources_advance_hours_limits).to eq(["8.0", "8.0", "8.0", "8.0", "8.0", "0.0", "0.0"])
      end
    end

    it 'put when nil' do
      with_easy_settings({ easy_gantt_resources_users_estimated_ratios:     nil,
                           easy_gantt_resources_users_hours_limits:         nil,
                           easy_gantt_resources_users_advance_hours_limits: nil
                         }) do
        user
        put :update, params: { 'id' => user.id,
                               'format' => 'json',
                               'user' => { 'easy_gantt_resources_estimated_ratio' => '1.0',
                                           'easy_gantt_resources_hours_limit' => '8.0',
                                           'easy_gantt_resources_advance_hours_limits' => ["8.0", "8.0", "8.0", "8.0", "8.0", "0.0", "0.0"]
                                         }
                             }
        expect(response).to be_successful
        expect(user.easy_gantt_resources_estimated_ratio).to eq('1.0')
        expect(user.easy_gantt_resources_hours_limit).to eq('8.0')
        expect(user.easy_gantt_resources_advance_hours_limits).to eq(["8.0", "8.0", "8.0", "8.0", "8.0", "0.0", "0.0"])
      end
    end

    it 'put when not nil' do
      with_easy_settings({ easy_gantt_resources_users_estimated_ratios:     { user.id.to_s => '1.0' },
                           easy_gantt_resources_users_hours_limits:         { user.id.to_s => '8.0' },
                           easy_gantt_resources_users_advance_hours_limits: { user.id.to_s => ["8.0", "8.0", "8.0", "8.0", "8.0", "0.0", "0.0"] }
                         }) do
        user
        put :update, params: { 'id' => user.id,
                               'format' => 'json',
                               'user' => { 'easy_gantt_resources_estimated_ratio' => '2.0',
                                           'easy_gantt_resources_hours_limit' => '4.0',
                                           'easy_gantt_resources_advance_hours_limits' => ["4.0", "4.0", "4.0", "4.0", "4.0", "0.0", "0.0"]
                                         }
                             }
        expect(response).to be_successful
        expect(user.easy_gantt_resources_estimated_ratio).to eq('2.0')
        expect(user.easy_gantt_resources_hours_limit).to eq('4.0')
        expect(user.easy_gantt_resources_advance_hours_limits).to eq(["4.0", "4.0", "4.0", "4.0", "4.0", "0.0", "0.0"])
      end
    end
  end

end