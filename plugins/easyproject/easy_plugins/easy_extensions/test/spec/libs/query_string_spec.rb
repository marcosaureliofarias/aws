require 'easy_extensions/spec_helper'

RSpec.describe EasyExtensions::QueryString::Parser do

  let(:transform) { EasyExtensions::QueryString::Transform.new }
  let(:query) { EasyIssueQuery.new }

  let(:valid_items) {
    [
        {
            query_string: %{status_id = 1},
            tree:         { filter: { field: 'status_id', operator: '=', value: { string: '1' } } },
            postgresql:   %{(("issues"."status_id" IN ('1')))},
            mysql:        %{((`issues`.`status_id` IN ('1')))},
        },
        {
            query_string: %{status_id = "1" OR tracker_id = 2},
            tree:         { or:
                                { left:  { filter: { field: 'status_id', operator: '=', value: { string: '1' } } },
                                  right: { filter: { field: 'tracker_id', operator: '=', value: { string: '2' } } } } },
            postgresql:   %{((("issues"."status_id" IN ('1'))) OR (("issues"."tracker_id" IN ('2'))))},
            mysql:        %{(((`issues`.`status_id` IN ('1'))) OR ((`issues`.`tracker_id` IN ('2'))))},
        },
        {
            query_string: %{(status_id = "1" OR tracker_id = 2) AND (assigned_to_id >< 1 | 6 )},
            tree:         { and:
                                { left:
                                         { or:
                                               { left:  { filter: { field: 'status_id', operator: '=', value: { string: '1' } } },
                                                 right: { filter: { field: 'tracker_id', operator: '=', value: { string: '2' } } } } },
                                  right: { filter: { field: 'assigned_to_id', operator: '><', value1: { value: { string: '1' } }, value2: { value: { string: '6' } } } } } },
            postgresql:   %{(((("issues"."status_id" IN ('1'))) OR (("issues"."tracker_id" IN ('2')))) AND (issues.assigned_to_id BETWEEN 1.0 AND 6.0))},
            mysql:        %{((((`issues`.`status_id` IN ('1'))) OR ((`issues`.`tracker_id` IN ('2')))) AND (issues.assigned_to_id BETWEEN 1.0 AND 6.0))},
        },
        {
            query_string: %{(status_id = [1, "2", "3"])},
            tree:         { filter:
                                { field:    'status_id',
                                  operator: '=',
                                  value:
                                            { array:
                                                  [{ value: { string: '1' } },
                                                   { value: { string: '2' } },
                                                   { value: { string: '3' } }] } } },
            postgresql:   %{(("issues"."status_id" IN ('1', '2', '3')))},
            mysql:        %{((`issues`.`status_id` IN ('1', '2', '3')))},
        },
        {
            query_string: %{(((status_id = 1)) AND (((((tracker_id = [2,3])))) OR assigned_to_id >< 4 | "5"))},
            tree:         { and:
                                { left:
                                      { filter:
                                            { field: 'status_id', operator: '=', value: { string: '1' } } },
                                  right:
                                      { or:
                                            { left:
                                                  { filter:
                                                        { field:    'tracker_id',
                                                          operator: '=',
                                                          value:
                                                                    { array:
                                                                          [{ value: { string: '2' } }, { value: { string: '3' } }] } } },
                                              right:
                                                  { filter:
                                                        { field:    'assigned_to_id',
                                                          operator: '><',
                                                          value1:   { value: { string: '4' } },
                                                          value2:   { value: { string: '5' } } } } } } } },
            postgresql:   %{((("issues"."status_id" IN ('1'))) AND ((("issues"."tracker_id" IN ('2', '3'))) OR (issues.assigned_to_id BETWEEN 4.0 AND 5.0)))},
            mysql:        %{(((`issues`.`status_id` IN ('1'))) AND (((`issues`.`tracker_id` IN ('2', '3'))) OR (issues.assigned_to_id BETWEEN 4.0 AND 5.0)))},
        }
    ]
  }

  let(:invalid_items) {
    [
        %{},
        %{status_id},
        %{status_id =}
    ]
  }

  it 'VALID #parse' do
    valid_items.each do |item|
      tree = subject.parse(item[:query_string])
      expect(tree).to eq(item[:tree])

      sql = transform.apply(tree, easy_query: query)

      if Redmine::Database.postgresql?
        expect(sql).to eq(item[:postgresql])
      else
        expect(sql).to eq(item[:mysql])
      end
    end
  end

  it 'INVALID #parse' do
    invalid_items.each do |item|
      expect { subject.parse(item) }.to raise_error(Parslet::ParseFailed)
    end
  end

end
