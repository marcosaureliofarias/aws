require 'easy_extensions/spec_helper'

RSpec.describe EasyButton, type: :model, logged: :admin do

  def _create_button(entity_type, keys1, operators1, values1, keys2=nil, operators2=nil, values2=nil)
    button = EasyButton.new
    button.name = "EasyButton #{Time.now.to_f}"
    button.entity_type = entity_type
    button.conditions = {
      'fields'    => keys1,
      'operators' => Hash[keys1.zip(operators1)],
      'values'    => Hash[keys1.zip(values1)]
    }

    if keys2
      button.actions = {
        'fields'    => keys2,
        'operators' => Hash[keys2.zip(operators2)],
        'values'    => Hash[keys2.zip(values2)]
      }
    end

    button.save
    button.reload_button
    button
  end

  def create_button(keys1, operators1, values1, keys2=nil, operators2=nil, values2=nil)
    _create_button('Issue', keys1, operators1, values1, keys2, operators2, values2)
  end

  def create_crm_button(keys1, operators1, values1, keys2=nil, operators2=nil, values2=nil)
    _create_button('EasyCrmCase', keys1, operators1, values1, keys2, operators2, values2)
  end

  def get_cf(entity, cf)
    entity.custom_field_value(cf.id)
  end

  def set_cf(entity, cf, value)
    entity.custom_field_values = {cf.id.to_s => value.to_s}
  end

  let!(:opened_status) { FactoryGirl.create(:issue_status) }
  let!(:closed_status) { FactoryGirl.create(:issue_status, :closed) }
  let!(:tracker1) { FactoryGirl.create(:tracker, default_status: opened_status) }
  let!(:tracker2) { FactoryGirl.create(:tracker, default_status: opened_status) }
  let!(:user1) { FactoryGirl.create(:user) }
  let!(:user2) { FactoryGirl.create(:user) }

  let!(:float_cf) { FactoryGirl.create(:issue_custom_field, field_format: 'float', trackers: [tracker1, tracker2]) }
  let!(:integer_cf) { FactoryGirl.create(:issue_custom_field, field_format: 'int', trackers: [tracker1, tracker2]) }
  let!(:string_cf) { FactoryGirl.create(:issue_custom_field, field_format: 'string', trackers: [tracker1, tracker2]) }
  let!(:list_cf) do
    FactoryGirl.create(:issue_custom_field,
      field_format: 'list',
      possible_values: ['aaa', 'bbb', 'ccc'],
      trackers: [tracker1, tracker2]
    )
  end

  let!(:project_string_cf) { FactoryGirl.create(:project_custom_field, field_format: 'string') }

  let(:issue) { FactoryGirl.create(:issue, tracker: tracker1, status: opened_status, author: user1) }

  it 'button is private by default', logged: true do
    b = create_button(
        ['tracker_id', 'assigned_to_id', 'estimated_hours'], ['=', '=', '='], [[tracker1.id.to_s], [user1.id.to_s], ['10']],
        ['tracker_id', 'assigned_to_id', 'estimated_hours'], ['=', '=', '='], [[tracker2.id.to_s], [user2.id.to_s], ['20']]
      )
    expect(b.conditions_cache).to include("User.current.id == #{User.current.id}")
    expect(b.is_private?).to eq(true)
  end

  context 'buttons' do
    let!(:button1) do
      create_button(
        ['tracker_id', 'assigned_to_id', 'estimated_hours'], ['=', '=', '='], [[tracker1.id.to_s], [user1.id.to_s], ['10']],
        ['tracker_id', 'assigned_to_id', 'estimated_hours'], ['=', '=', '='], [[tracker2.id.to_s], [user2.id.to_s], ['20']]
      )
    end

    let!(:button2) do
      create_button(
        ['tracker_id', 'assigned_to_id', 'estimated_hours'], ['!', '!', '>='], [[tracker1.id.to_s], [user1.id.to_s], ['20']],
        ['tracker_id', 'assigned_to_id', 'estimated_hours'], ['=', '=', '='], [[tracker1.id.to_s], [user1.id.to_s], ['10']]
      )
    end

    let!(:button3) do
      create_button(
        ["cf_#{integer_cf.id}", "cf_#{float_cf.id}", "cf_#{list_cf.id}"], ['>=', '>=', '='], [['10'], ['10'], ['aaa', 'ccc']],
        ["cf_#{integer_cf.id}", "cf_#{float_cf.id}", "cf_#{list_cf.id}"], ['=', '=', '='], [['5'], ['5'], ['bbb']]
      )
    end

    let!(:button4) do
      create_button(
        ["cf_#{integer_cf.id}", "cf_#{float_cf.id}", "cf_#{list_cf.id}"], ['<=', '<=', '='], [['10'], ['10'], ['bbb']],
        ["cf_#{integer_cf.id}", "cf_#{float_cf.id}", "cf_#{list_cf.id}"], ['=', '=', '='], [['15'], ['15'], ['aaa']]
      )
    end

    it 'entity attribute' do
      issue.tracker = tracker2
      issue.assigned_to = nil
      issue.estimated_hours = 0

      expect(issue.easy_buttons).to_not include(button1)
      expect(issue.easy_buttons).to_not include(button2)

      issue.tracker = tracker1
      issue.assigned_to = user1
      issue.estimated_hours = 10

      expect(issue.easy_buttons).to include(button1)
      expect(issue.easy_buttons).to_not include(button2)
      issue.attributes = button1.execute(issue)[:issue]
      expect(issue.easy_buttons).to_not include(button1)
      expect(issue.easy_buttons).to include(button2)

      issue.attributes = button2.execute(issue)[:issue]

      expect(issue.easy_buttons).to include(button1)
      expect(issue.easy_buttons).to_not include(button2)
    end

    it 'custom fields' do
      set_cf(issue, integer_cf, '100')
      set_cf(issue, float_cf, '100')
      set_cf(issue, list_cf, '')

      expect(issue.easy_buttons).to_not include(button3)
      expect(issue.easy_buttons).to_not include(button4)

      issue.attributes = button3.execute(issue)[:issue]

      expect(issue.easy_buttons).to_not include(button3)
      expect(issue.easy_buttons).to include(button4)

      issue.attributes = button4.execute(issue)[:issue]

      expect(issue.easy_buttons).to include(button3)
      expect(issue.easy_buttons).to_not include(button4)
    end

    it 'entity association custom fields' do
      button = create_button(["project_cf_#{project_string_cf.id}"], ['='], ['aaa'])

      set_cf(issue.project, project_string_cf, '')
      expect( button.active_for?(issue) ).to be_falsey

      set_cf(issue.project, project_string_cf, 'aaa')
      expect( button.active_for?(issue) ).to be_truthy
    end

    # Test value: me, none, author, last_assigned
    context 'user columns' do
      let(:journal) { FactoryGirl.create(:journal, journalized_id: issue.id, journalized_type: 'Issue') }
      let(:journal_detail) { FactoryGirl.create(:journal_detail, journal: journal, property: 'attr', prop_key: 'assigned_to_id', old_value: User.current.id, value: user1.id) }

      it 'me' do
        button = create_button([], [], [], ['assigned_to_id'], ['='], ['me'])
        issue.attributes = button.execute(issue)[:issue]
        expect(issue.assigned_to).to eq(User.current)
      end

      it 'none' do
        button = create_button([], [], [], ['assigned_to_id'], ['='], ['none'])
        issue.attributes = button.execute(issue)[:issue]
        expect(issue.assigned_to).to be_nil
      end

      it 'author' do
        button = create_button([], [], [], ['assigned_to_id'], ['='], ['author'])
        issue.attributes = button.execute(issue)[:issue]
        expect(issue.assigned_to).to eq(user1)
      end

      it 'last_assignee' do
        issue.assigned_to = user1
        journal_detail
        issue.reload

        button = create_button([], [], [], ['assigned_to_id'], ['='], ['last_assigned'])
        issue.attributes = button.execute(issue)[:issue]
        expect(issue.assigned_to).to eq(User.current)
      end
    end

    # =   is
    # !   is not
    # >=  greater
    # <=  lesser
    # ~   contains
    # !~  doesn't contain
    # ^~  starts with
    # !*  none
    # *   any
    context 'operators' do
      it '>=' do
        button = create_button(["cf_#{float_cf.id}"], ['>='], ['10'])

        set_cf(issue, float_cf, 5)
        expect( button.active_for?(issue) ).to be_falsey

        set_cf(issue, float_cf, 15)
        expect( button.active_for?(issue) ).to be_truthy
      end

      it '~' do
        button = create_button(["cf_#{string_cf.id}"], ['~'], ['aaa'])

        set_cf(issue, string_cf, 'bbb ccc')
        expect( button.active_for?(issue) ).to be_falsey

        set_cf(issue, string_cf, 'bbb aaa xxx')
        expect( button.active_for?(issue) ).to be_truthy
      end

      it '~ with special characters' do
        button = create_button(["cf_#{string_cf.id}"], ['~'], ['aaa/bbb\ccc "ddd" [eee]'])

        set_cf(issue, string_cf, 'aaa')
        expect( button.active_for?(issue) ).to be_falsey

        set_cf(issue, string_cf, '--- aaa/bbb\ccc "ddd" [eee] ---')
        expect( button.active_for?(issue) ).to be_truthy

        # Should not raised an error
        button = create_button(["cf_#{string_cf.id}"], ['~'], ['raise "error"'])
        button.active_for?(issue)

        button = create_button(["cf_#{string_cf.id}"], ['~'], ['"raise "error""'])
        button.active_for?(issue)

        button = create_button(["cf_#{string_cf.id}"], ['~'], ['"raise """""""""error""'])
        button.active_for?(issue)

        button = create_button(["cf_#{string_cf.id}"], ['~'], ['}; "raise """""""""error""; %{'])
        button.active_for?(issue)

        button = create_button(["cf_#{string_cf.id}"], ['~'], ['#{raise "error"}'])
        button.active_for?(issue)
      end

      it '!~' do
        button = create_button(['subject'], ['!~'], ['aaa'])

        issue.subject = 'aaa bbb ccc'
        expect( button.active_for?(issue) ).to be_falsey

        issue.subject = 'bbb'
        expect( button.active_for?(issue) ).to be_truthy
      end

      it '^~' do
        button = create_button(['subject'], ['^~'], ['aaa'])

        issue.subject = 'bbb ccc aaa'
        expect( button.active_for?(issue) ).to be_falsey

        issue.subject = 'aaa bbb ccc'
        expect( button.active_for?(issue) ).to be_truthy
      end
    end

    context 'boolean' do

      let(:crm_case) { FactoryGirl.create(:easy_crm_case) }
      let(:bool_cf) { FactoryGirl.create(:issue_custom_field, field_format: 'bool', trackers: [tracker1, tracker2]) }

      it 'native field' do
        button = create_crm_button(
          ['is_canceled'], ['='], [['0']],
          ['is_canceled'], ['='], [['1']]
        )

        crm_case.is_canceled = true
        expect( button.active_for?(crm_case) ).to be_falsey

        crm_case.is_canceled = false
        expect( button.active_for?(crm_case) ).to be_truthy

        expect(crm_case.is_canceled).to be_falsey
        crm_case.attributes = button.execute(crm_case)[:easy_crm_case]
        expect(crm_case.is_canceled).to be_truthy
      end if Redmine::Plugin.installed?(:easy_crm)

      # Boolean is list_optional
      it 'custom field' do
        button = create_button(
          ["cf_#{bool_cf.id}"], ['='], [['0']],
          ["cf_#{bool_cf.id}"], ['='], [['1']]
        )

        set_cf(issue, bool_cf, '0')
        expect( button.active_for?(issue) ).to be_truthy

        issue.attributes = button.execute(issue)[:issue]
        expect( button.active_for?(issue) ).to be_falsey
      end

    end

    context 'lookup' do

      def create_lookup_cf(entity_class, multiple)
        FactoryGirl.create(:issue_custom_field,
          field_format: 'easy_lookup',
          settings: { entity_type: entity_class.to_s, entity_attribute: 'link_with_name' }.with_indifferent_access,
          multiple: multiple,
          trackers: [tracker1]
        )
      end

      let(:other_project) { FactoryGirl.create(:project) }
      let(:easy_lookup_cf) { create_lookup_cf(Project, false) }
      let(:easy_lookup_cf_multiple) { create_lookup_cf(Project, true) }
      let(:user_lookup_cf) { create_lookup_cf(User, false) }

      it 'single value' do
        button = create_button(
          ["cf_#{easy_lookup_cf.id}"], ['='], [[other_project.id.to_s]],
          ["cf_#{easy_lookup_cf.id}"], ['='], [[issue.project.id.to_s]]
        )

        expect( get_cf(issue, easy_lookup_cf) ).to be_nil
        expect( button.active_for?(issue) ).to be_falsey

        set_cf(issue, easy_lookup_cf, other_project.id.to_s)
        expect( button.active_for?(issue) ).to be_truthy

        issue.attributes = button.execute(issue)[:issue]
        expect( get_cf(issue, easy_lookup_cf) ).to eq(issue.project.id.to_s)
      end

      it 'multiple value' do
        options = easy_lookup_cf_multiple.query_filter_options(easy_lookup_cf_multiple)
        expect(options).to_not have_key(:attr_reader)
        expect(options).to_not have_key(:attr_writer)
      end

      it 'works with << me >>' do
        button = create_button(
            ["cf_#{user_lookup_cf.id}"], ['='], [[nil]],
            ["cf_#{user_lookup_cf.id}"], ['='], [['me']]
        )

        issue.attributes = button.execute(issue)[:issue]
        expect( get_cf(issue, user_lookup_cf) ).to eq(User.current.id.to_s)
      end

    end

  end
end
