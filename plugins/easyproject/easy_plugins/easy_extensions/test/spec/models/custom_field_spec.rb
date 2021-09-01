require 'easy_extensions/spec_helper'

describe CustomField do

  context 'value tree' do
    context 'before save' do
      it 'simple' do
        cf                 = CustomField.new(name: 'value_tree_1', field_format: 'value_tree')
        cf.possible_values = [
            'Value 1',
            '> Value 1.1',
            '> Value 1.2',
            'Value 2'
        ]

        expect(cf.save).to be(true)
        expect(cf.possible_values).to eq([
                                             'Value 1',
                                             'Value 1 > Value 1.1',
                                             'Value 1 > Value 1.2',
                                             'Value 2'
                                         ])
      end

      it 'complex' do
        cf                 = CustomField.new(name: 'value_tree_2', field_format: 'value_tree')
        cf.possible_values = [
            'Value 1',
            '> Value 1.1',
            '> Value 1.2',
            '>> Value 1.2.1',
            '>>> Value 1.2.1.1',
            '>> Value 1.2.2',
            '>> Value 1.2.3',
            'Value 2',
            '> Value 2.1',
            '>> Value 2.1.1',
            '>>> Value 2.1.1.1',
            '>>>> Value 2.1.1.1.1',
            'Value 3'
        ]

        expect(cf.save).to be(true)
        expect(cf.possible_values).to eq([
                                             'Value 1',
                                             'Value 1 > Value 1.1',
                                             'Value 1 > Value 1.2',
                                             'Value 1 > Value 1.2 > Value 1.2.1',
                                             'Value 1 > Value 1.2 > Value 1.2.1 > Value 1.2.1.1',
                                             'Value 1 > Value 1.2 > Value 1.2.2',
                                             'Value 1 > Value 1.2 > Value 1.2.3',
                                             'Value 2',
                                             'Value 2 > Value 2.1',
                                             'Value 2 > Value 2.1 > Value 2.1.1',
                                             'Value 2 > Value 2.1 > Value 2.1.1 > Value 2.1.1.1',
                                             'Value 2 > Value 2.1 > Value 2.1.1 > Value 2.1.1.1 > Value 2.1.1.1.1',
                                             'Value 3'
                                         ])
      end

      it 'ended on high level' do
        cf                 = CustomField.new(name: 'value_tree_3', field_format: 'value_tree')
        cf.possible_values = [
            'Value 1',
            '> Value 1.1',
            '>> Value 1.1.1',
            '>>> Value 1.1.1.1',
            '>>>> Value 1.1.1.1.1',
        ]

        expect(cf.save).to be(true)
        expect(cf.possible_values).to eq([
                                             'Value 1',
                                             'Value 1 > Value 1.1',
                                             'Value 1 > Value 1.1 > Value 1.1.1',
                                             'Value 1 > Value 1.1 > Value 1.1.1 > Value 1.1.1.1',
                                             'Value 1 > Value 1.1 > Value 1.1.1 > Value 1.1.1.1 > Value 1.1.1.1.1',
                                         ])
      end

      it 'validation' do
        cf                 = CustomField.new(name: 'value_tree_5', field_format: 'value_tree')
        cf.possible_values = [
            '> Value 1',
            'Value 1.1',
        ]

        expect(cf.save).to be(false)

        cf.possible_values = [
            'Value 1',
            '>> Value 1.1',
        ]

        expect(cf.save).to be(false)

        cf.possible_values = [
            'Value 1',
            '> Value 1.1',
            '>> Value 1.1.1',
            '>>>> Value 1.1.1',
        ]

        expect(cf.save).to be(false)

        cf.possible_values = [
            'Value 1',
            '> Value 1.1',
            '>> Value 1.1.1',
            '>>> Value 1.1.1',
            'Value 2',
        ]

        expect(cf.save).to be(true)
      end
    end

    it 'custom field edit' do
      values = [
          'Value 1',
          '> Value 1.1',
          '> Value 1.2',
          'Value 2'
      ]
      saved  = [
          'Value 1',
          'Value 1 > Value 1.1',
          'Value 1 > Value 1.2',
          'Value 2'
      ]

      cf                 = CustomField.new(name: 'value_tree_4', field_format: 'value_tree')
      cf.possible_values = values

      expect(cf.save).to be(true)
      expect(cf.possible_values).to eq(saved)
      expect(cf.format.possible_values_for_edit_page(cf)).to eq(values)
    end
  end

  context 'visibility condition' do
    let(:tracker) { FactoryBot.create(:tracker) }
    let(:project) { FactoryBot.create(:project, members: [User.current], trackers: [tracker]) }

    context 'projects' do
      let(:role) { FactoryBot.create(:role) }
      let!(:project_cf) { FactoryBot.create(:project_custom_field, is_for_all: true, visible: true) }
      let!(:project_cf_for_role) { FactoryBot.create(:project_custom_field, is_for_all: true, visible: false, roles: [role]) }

      it '#visibility_by_project_condition', logged: true do
        expect(Project.where(project_cf.visibility_by_project_condition(project, User.current)).exists?).to eq(true)
        expect(Project.where(project_cf_for_role.visibility_by_project_condition(project, User.current)).exists?).to eq(false)
      end

      it '#visible', logged: true do
        expect(ProjectCustomField.visible).to contain_exactly(project_cf)
      end
    end

    context 'issues' do
      let(:cf_list) { FactoryBot.create_list(:issue_custom_field, 2, is_for_all: false, visible: false, roles: Role.all, projects: [project.id], trackers: [tracker.id]) }

      it 'by project', logged: true do
        cf_list.each do |cf|
          expect(Issue.where(cf.visibility_by_project_condition(nil, User.current)).exists?).to eq(true)
        end
      end
    end

    context 'time entries' do
      let(:project) { FactoryGirl.create(:project, :members => [User.current], :trackers => [tracker], :activities => [time_entry_activity, time_entry_activity2]) }
      let(:time_entry_activity) { FactoryGirl.create(:time_entry_activity) }
      let(:time_entry_activity2) { FactoryGirl.create(:time_entry_activity) }
      let(:cf_time_entry) { FactoryGirl.create(:time_entry_custom_field, :visible => true) }
      let(:cf_time_entry_activity) { FactoryGirl.create(:time_entry_custom_field, :visible => false, :activities => [time_entry_activity]) }
      let(:time_entry) { FactoryGirl.create(:time_entry, :activity => time_entry_activity) }
      let(:time_entry2) { FactoryGirl.create(:time_entry, :activity => time_entry_activity2) }

      it 'by project', logged: :admin do
        time_entry; time_entry2
        expect(TimeEntry.eager_load(:activity).where(cf_time_entry.visibility_by_project_condition(nil, User.current)).count).to eq(2)
        expect(TimeEntry.eager_load(:activity).where(cf_time_entry_activity.visibility_by_project_condition(nil, User.current)).count).to eq(1)
      end
    end
  end

  describe 'generated lists' do
    let(:names) { ["C", "A", "B"] }

    context 'when list of users', logged: :admin do
      let!(:users) { names.collect { |name| FactoryGirl.create(:user, :firstname => name) } }
      let(:user_cf) { FactoryGirl.build(:custom_field, :field_format => 'user') }
      let(:users_names) { user_cf.possible_values_options.collect { |user| user[0] } }
      let(:member) { users.first }
      let(:project) { FactoryGirl.create(:project, :members => [member]) }

      it 'lists users sorted by first name' do
        expect(users_names).to eq users_names.sort
        expect(users_names).not_to be_empty
      end

      it 'lists project members' do
        expect(user_cf.possible_values_options(project).map { |user| user[0] }).to eq [member.name]
      end
    end

    context 'when list of milestones (Version)' do
      let(:issue) { FactoryGirl.create(:issue) }
      let!(:versions) { names.collect { |name| FactoryGirl.create(:version, :project => issue.project, :name => name) } }
      let(:milestone_cf) { FactoryGirl.create(:custom_field, :field_format => 'version') }
      let(:milestones_cf_name_values) { milestone_cf.possible_values_options(issue).collect { |milestone| milestone[0] } }
      let(:milestones_sorted) { Version.all.sort.collect(&:name) }

      it 'lists milestones sorted by Version.<=>' do
        expect(milestones_cf_name_values).to eq milestones_sorted
        expect(milestones_cf_name_values).not_to be_empty
      end
    end
  end

  describe '#possible_values_records' do
    context 'format user' do
      let(:user_cf) { FactoryBot.build(:project_custom_field, field_format: 'user', is_for_all: true) }
      let(:project) { Project.new }
      let(:issue) { double(Issue, project: project) }

      it do
        allow(user_cf).to receive(:user_role).and_return(%w(4, 7))
        expect(user_cf.format.possible_values_records(user_cf, issue)).to eq([])
      end
    end
  end
end
