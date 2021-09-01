RSpec.describe 'CustomField', logged: :admin do
  context 'computed from query', logged: :admin do
    let(:issue) { FactoryBot.create(:issue, start_date: Date.today, due_date: Date.today + 3.days) }
    let(:issue_custom_field1) { FactoryBot.create(:issue_custom_field, field_format: 'date', trackers: [issue.tracker]) }
    let(:compute_from_query_custom_field) do
      FactoryBot.create(:computed_issue_from_query_custom_field, trackers: [issue.tracker])
    end
    let(:custom_field_with_date_columns) { FactoryBot.create(:rys_ccfff_computed_issue_custom_field, computed_token: "(%{issue_due_date} - %{cf_self_#{compute_from_query_custom_field.id}})", trackers: [issue.tracker]) }

    it 'computed dates', skip: !Redmine::Plugin.installed?(:easy_computed_custom_fields) do
      expect(compute_from_query_custom_field.settings['easy_computed_from_query_format']).to eq('date')
      expect(EasyRakeTaskComputedFromQuery.recalculate_entity(issue)).to be true
      custom_field_with_date_columns
      expect(issue.save).to be true
      custom_field_with_date_columns.recompute_computed_custom_field_values
      issue.reload
      expect(issue.custom_value_for(compute_from_query_custom_field).cast_value).to eq(issue.start_date)
      pending("dates accross winter/summer time") if issue.start_date.to_time.gmt_offset != issue.due_date.to_time.gmt_offset
      expect(issue.custom_value_for(custom_field_with_date_columns).cast_value).to eq('3.0')
    end

    context 'easy_crm', skip: !Redmine::Plugin.installed?(:easy_crm) || !Redmine::Plugin.installed?(:easy_contacts) do
      let!(:easy_crm_status) { FactoryBot.create(:rys_ccfff_easy_crm_case_status) }
      let(:easy_contact_type) { FactoryBot.create(:easy_contact_type, :personal) }
      let(:easy_crm_case5) { FactoryBot.create(:easy_crm_case, contract_date: Date.today + 3.days, easy_crm_case_status_id: easy_crm_status.id) }
      let!(:easy_contact_with_cf) { FactoryBot.create(:easy_contact, type_id: easy_contact_type.id, easy_crm_cases: [easy_crm_case5]) }
      let(:easy_crm_case4) { FactoryBot.create(:easy_crm_case, contract_date: Date.today + 3.days, easy_crm_case_status_id: easy_crm_status.id, easy_contacts: [easy_contact_with_cf]) }

      let(:compute_from_query_custom_field) do
        FactoryBot.create(:easy_crm_case_custom_field,
          field_format: 'easy_computed_from_query',
          name: 'comput test',
          easy_crm_case_status_ids: [easy_crm_status.id],
          settings: {
            associated_query: 'EasyCrmCaseQuery',
            easy_query_formula: 'min',
            easy_query_column: 'contract_date',
            easy_query_filters: { 'set_filter' => '1' }
          })
      end

      let(:contact_computed_cf) do
        FactoryBot.create(:easy_contact_custom_field,
          field_format: 'easy_computed_from_query',
          contact_types: [easy_contact_type],
          name: 'comput test1',
          settings: {
            associated_query: 'EasyCrmCaseQuery',
            easy_query_formula: 'min',
            easy_query_column: 'contract_date',
            easy_query_filters: { 'set_filter' => '1' }
          })
      end

      it 'crm and contacts computed custom fields recalculating' do
        expect(compute_from_query_custom_field.settings['easy_computed_from_query_format']).to eq('date')
        expect(EasyRakeTaskComputedFromQuery.recalculate_entity(easy_crm_case4)).to be true
        expect(easy_crm_case4.save).to be true
        easy_crm_case4.reload
        expect(easy_crm_case4.custom_value_for(compute_from_query_custom_field).cast_value).to eq(easy_crm_case4.contract_date)

        contact_computed_cf
        easy_contact_with_cf.reload
        expect(EasyRakeTaskComputedFromQuery.recalculate_entity(easy_contact_with_cf)).to be true
        expect(easy_contact_with_cf.save).to be true
        easy_contact_with_cf.reload
        expect(easy_contact_with_cf.custom_value_for(contact_computed_cf).cast_value).to eq(easy_crm_case5.contract_date)
      end
    end
  end
end
