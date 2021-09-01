module RedmineTestCases
  module EasyAutoCompletesControllerPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        #alias_method_chain :index, :redmine_test_cases

      end
    end

    module InstanceMethods

      def issues_autocomplete
        @project = Project.find(params[:autocomplete_options][:project_id]) rescue nil
        @issues = Issue.visible.cross_project_scope(@project, Setting.display_subprojects_issues? && 'tree').where(["#{Issue.table_name}.subject like ?", "%#{params['term'].to_s}%"]).limit(EasySetting.value('easy_select_limit').presence || 25).order(:subject).map { |u| { value: u.to_s, id: u.id.to_s } }
        render :json => { issues_autocomplete: @issues }
      end

      def test_cases_autocomplete
        @project = Project.find(params[:autocomplete_options][:project_id]) rescue nil
        test_cases = TestCase.visible.like(params[:term]).where(project: @project).limit(EasySetting.value('easy_select_limit').presence || 25).order(:name).to_a.map{|t| {value: t.name, id: t.id.to_s}}
        render :json => { test_cases_autocomplete: test_cases }
      end

      def test_plans_autocomplete
        @project = Project.find(params[:autocomplete_options][:project_id]) rescue nil
        test_plans = TestPlan.visible.like(params[:term]).where(project: @project).limit(EasySetting.value('easy_select_limit').presence || 25).order(:name).to_a.map{|t| {value: t.name, id: t.id.to_s}}
        render json: { test_plans_autocomplete: test_plans }
      end

      def root_test_case
        @entities = get_root_test_case(params[:term], EasySetting.value('easy_select_limit').to_i)

        @name_column = :to_s
        respond_to do |format|
          format.api { render template: 'easy_auto_completes/entities_with_id', formats: [:api], locals: {additional_select_options: false} }
        end
      end

      private

      def get_root_test_case(term='', limit=nil)
        if term =~ /^\d+$/
          scope = TestCase.where(id: term)
        else
          scope = TestCase.where("LOWER(test_cases.name) LIKE ?" , "%#{term.to_s.downcase}%").limit(limit).sorted
        end
        scope
      end

    end

    module ClassMethods

    end

  end

end
RedmineExtensions::PatchManager.register_controller_patch 'EasyAutoCompletesController', 'RedmineTestCases::EasyAutoCompletesControllerPatch'
