shared_examples 'include_subordinates' do |options_parameter, action, expected_user_options, &block|
  context "additional options ##{action}", logged: true do
    let(:subordinates_options) do
      sub_opts = {"<< #{I18n.t(:label_my_subordinates)} >>" => 'my_subordinates', "<< #{I18n.t(:label_my_subordinates_tree)} >>" => 'my_subordinates_tree'}
      sub_opts.merge(expected_user_options || {})
    end

    def allow_user_to(perm)
      role = FactoryBot.create(:role, permissions: [perm])
      FactoryBot.create(:member, user: User.current, roles: [role])
    end

    def mark_as_supervisor
      allow(EasyOrgChart::Tree).to receive(:supervisor_user_ids) { [User.current.id] }
    end

    def params(action)
      { autocomplete_action: action, include_peoples: 'subordinates', format: 'json' }
    end

    subject(:additional_options) { assigns[options_parameter.to_sym] }

    it 'regular user without subordinates' do
      get :index, params: params(action)
      expect(additional_options).not_to match_array(subordinates_options.to_a)
    end

    it 'regular user with subordinates' do
      mark_as_supervisor
      get :index, params: params(action)
      expect(additional_options).to match_array(subordinates_options.to_a)
    end

    it 'regular user with subordinates', logged: :admin do
      get :index, params: params(action)
      expect(additional_options).to match_array(subordinates_options.to_a)
    end

    it 'regular user with permissions' do
      allow_user_to :manage_custom_dashboards
      get :index, params: params(action)
      expect(additional_options).to match_array(subordinates_options.to_a)
    end

    it 'regular user with permissions' do
      allow_user_to :manage_public_queries
      get :index, params: params(action)
      expect(additional_options).to match_array(subordinates_options.to_a)
    end

    it 'without options if term sent' do
      mark_as_supervisor
      get :index, params: params(action).merge(term: 'te')
      expect(additional_options).to be_empty
    end
  end
end
