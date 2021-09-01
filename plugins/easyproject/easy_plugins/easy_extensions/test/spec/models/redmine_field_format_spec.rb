require 'easy_extensions/spec_helper'

describe 'redmine field format', :logged => :admin do
  let(:custom_field) { FactoryGirl.create(:issue_custom_field) }
  let(:easy_issue_query) { FactoryGirl.create(:easy_issue_query) }

  it 'query filter values' do
    Redmine::FieldFormat.formats_for_custom_field_class(Issue).each do |format|
      options = format.query_filter_options(custom_field, easy_issue_query)
      if options[:values] && options[:values].is_a?(Proc)
        options[:values].call
      end
    end
  end
end
