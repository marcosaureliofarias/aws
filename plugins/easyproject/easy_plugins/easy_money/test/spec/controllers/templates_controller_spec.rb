require 'easy_extensions/spec_helper'

describe TemplatesController, :logged => :admin do
  let(:parent_project) { FactoryGirl.create(:project, :add_modules => ['easy_money']) }
  let(:template) { FactoryGirl.create(:project, :add_modules => ['easy_money'], :easy_is_easy_template => true) }

  context 'inherit easy money settings' do
    render_views

    def create_easy_money_settings(p)
      EasyMoneySettings.create!(:project_id => p.id, :name => 'rate_type', :value => 'all')
      p.reload
    end

    it 'not copied twice' do
      create_easy_money_settings(parent_project)
      create_easy_money_settings(template)
      post :make_project_from_template, :params => {:id => template.id.to_s, :template =>
        {:project => [{:id => template.id.to_s, :name => 'test project'}], :inherit_easy_money_settings => '1', :parent_id => parent_project.id.to_s}}
      expect(assigns(:new_project)).not_to be_nil
      expect(assigns(:new_project)).not_to be_new_record
    end
  end
end
