require 'easy_extensions/spec_helper'

describe 'easy queries', :null => true, :slow => true do

  def prepare_data
    entities = {}

    FactoryGirl.create(:easy_user_time_calendar, :user_id => nil)

    @easy_query_cache.each_key do |easy_query|
      entity_name_sym = @easy_query_cache[easy_query].entity.name.underscore.to_sym
      if !FactoryGirl.factories.registered?(entity_name_sym)
        # puts "Factory #{entity_name_sym} for #{easy_query.name.underscore} is undefined, skipping"
      else
        entities[easy_query] = FactoryGirl.create(entity_name_sym)
      end
    end

    entities
  end

  before(:all) do
    @admin_user          = FactoryGirl.create(:admin_user)
    @easy_query_cache    = HelperMethods.instanced_easy_queries
    @easy_query_entities = prepare_data
  end

  after(:all) do
    @easy_query_cache    = nil
    @easy_query_entities = nil
    @admin_user          = nil
  end

  HelperMethods.instanced_easy_queries.each do |qc|
    easy_query = qc[0]; instance = qc[1]
    context "Query - #{easy_query.name.underscore} / #{instance.entity.name.underscore}" do
      before(:each) do
        logged_user(@admin_user)
        if @easy_query_entities[easy_query].nil?
          pending "Factory #{instance.entity.name.underscore} for #{easy_query.name.underscore} is undefined, skipping"
          raise
        end
        instance.filters  = {}
        instance.group_by = ''
      end

      it 'selects entities' do
        expect { instance.entity_count }.not_to raise_exception # .to be > 0
        expect { instance.entities }.not_to raise_exception # .to be > 0.to be_present
      end

      instance.groupable_columns.map { |group| group.name.to_s }.each do |group_name|
        it "groups by #{group_name}" do
          instance.group_by = group_name
          expect(instance.grouped?).to be true
          expect { instance.groups }.not_to raise_exception #.to be_present
        end
      end

      instance.available_columns.select(&:sortable?).map { |col| col.name.to_s }.each do |sort_name|
        it "sorts by #{sort_name}" do
          original_sort_criteria = instance.sort_criteria.dup
          begin
            instance.sort_criteria = [[sort_name, 'asc']]
            expect { instance.entities }.not_to raise_exception #.to be_present
          ensure
            instance.sort_criteria = original_sort_criteria
          end
        end
      end

      it 'shows all attrs' do
        e = instance.entities.first || @easy_query_entities[easy_query]
        expect(e).to be_present
        instance.available_columns.each do |c|
          expect { c.value(e) }.not_to raise_exception
        end
      end

      instance.available_filters.reject { |_, options| /date/.match?(options[:type]) }.each do |filter, options|
        it "can apply filter #{filter}" do
          instance.add_filter(filter.to_s, instance.operators_by_filter_type[options[:type]].sample, ['1'])
          expect { instance.entities }.not_to raise_exception
        end

        it "can load filter values #{filter}" do
          if options[:values].is_a?(Proc)
            expect { options[:values].call }.not_to raise_exception
          end
        end
      end

      it 'search' do
        instance.use_free_search    = true
        instance.free_search_tokens = ['xxx']
        expect { instance.entities.to_a }.not_to raise_exception
        instance.use_free_search = false
      end

      it 'return entity_easy_query_path' do
        expect { instance.entity_easy_query_path({}) }.not_to raise_exception
      end

      if EasyExtensions::EasyQueryOutputs::ReportOutput.available_for?(instance) && instance.columns_with_position.any?
        report_output = EasyExtensions::EasyQueryOutputs::ReportOutput.new(instance, ['report'])

        instance.columns_with_position.each do |column_name|
          it "can sort report top line by #{column_name}" do
            instance.group_by = [column_name]
            allow(report_output).to receive(:top_report_group_by).and_return(column_name)
            expect { report_output.sort_top_line([1, 3, 2]) }.not_to raise_exception # parameters don't matter
          end
        end
      end

    end
  end

end
