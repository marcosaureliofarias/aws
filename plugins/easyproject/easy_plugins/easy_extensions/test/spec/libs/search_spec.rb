require 'easy_extensions/spec_helper'

describe 'RedmineSearch', :logged => :admin, :null => true do
  before(:all) do
    @project = FactoryGirl.create(:project)
  end

  after(:all) do
    @project = nil
  end

  Redmine::Search.available_search_types.each do |search_type|
    it "search type #{search_type}" do
      expect {
        search_type.classify.constantize.search_result_ranks_and_ids('term', User.current, nil, { titles_only: true })
        search_type.classify.constantize.search_result_ranks_and_ids('term')
      }.not_to raise_exception
    end

    it "search type #{search_type} on projects" do
      expect {
        search_type.classify.constantize.search_result_ranks_and_ids('term', User.current, @project, { titles_only: true })
        search_type.classify.constantize.search_result_ranks_and_ids('term', User.current, @project)
      }.not_to raise_exception
    end
  end
end
