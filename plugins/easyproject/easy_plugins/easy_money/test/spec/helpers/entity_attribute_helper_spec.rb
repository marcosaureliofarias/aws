require 'easy_extensions/spec_helper'

describe EntityAttributeHelper do
  let!(:entity_class) { EasyMoneyExpectedExpense }
  let!(:attribute) do
    EasyEntityAttribute.new(
                           :name,
                           caption_key: 'field_name'
    )
  end
  let!(:unformatted_value) { 'planned expense' }
  let!(:entity) do
    FactoryGirl.create(
        :easy_money_expected_expense,
        project: FactoryGirl.create(:project),
        price1: 0.336e3,
        price2: 0.28e3,
        vat: 0.2e2,
        spent_on: 'Mon, 09 Dec 2019',
        description: "",
        name: "planned expense",
        version_id: nil,
        easy_external_id: nil,
        tyear: 2019,
        tmonth: 12,
        tweek: 50,
        tday: 9,
        easy_repeat_settings: {"simple_period"=>"", "end_date"=>"", "endtype_count_x"=>"", "start_timepoint"=>nil, "repeated"=>nil},
        easy_is_repeating: nil,
        easy_next_start: nil,
        project_id: 63,
        easy_currency_code: "EUR"
    )
  end
  let!(:options) do
    {
        entity: entity,
        custom_field: nil,
        editable: false,
        no_link: false
    }
  end


  describe '#format_html_easy_money_expected_expense_attribute' do
    subject(:method_call_result) do
      helper.format_html_easy_money_expected_expense_attribute(
          entity_class, attribute, unformatted_value, options
      )
    end

    it 'Produces link to edit url of the entity' do
      expect(method_call_result).to include(
                                        "href=\"#{edit_easy_money_expected_expense_path(entity)}\""
                                    )
    end
  end

  describe '#format_html_easy_money_expected_revenue_attribute' do
    subject(:method_call_result) do
      helper.format_html_easy_money_expected_revenue_attribute(
                entity_class, attribute, unformatted_value, options
      )
    end

    it 'Produces link to edit url of the entity' do
      expect(method_call_result).to include(
                                        "href=\"#{edit_easy_money_expected_revenue_path(entity)}\""
                                    )
    end
  end

  describe '#format_html_easy_money_other_expense_attribute' do
    subject(:method_call_result) do
      helper.format_html_easy_money_other_expense_attribute(
          entity_class, attribute, unformatted_value, options
      )
    end

    it 'Produces link to edit url of the entity' do
      expect(method_call_result).to include(
                                        "href=\"#{edit_easy_money_other_expense_path(entity)}\""
                                    )
    end
  end

  describe '#format_html_easy_money_other_revenue_attribute' do
    subject(:method_call_result) do
      helper.format_html_easy_money_other_revenue_attribute(
          entity_class, attribute, unformatted_value, options
      )
    end

    it 'Produces link to edit url of the entity' do
      expect(method_call_result).to include(
                                        "href=\"#{edit_easy_money_other_revenue_path(entity)}\""
                                    )
    end
  end
end
