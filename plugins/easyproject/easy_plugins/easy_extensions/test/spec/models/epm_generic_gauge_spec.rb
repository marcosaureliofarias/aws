require 'easy_extensions/spec_helper'

describe 'epm generic gauge', logged: :admin do
  let(:settings_issue) { { "query_type"                  => "2",
                           "query_name"                  => "xxx",
                           "name"                        => "xxx",
                           "needle_easy_query_klass"     => "easy_issue_query",
                           "needle_query_sumable_column" => "estimated_hours",
                           "action_range"                => "dynamic_range",
                           "range_easy_query_klass"      => "easy_issue_query",
                           "tags"                        =>
                             { "0" =>
                                 { "easy_query_settings"        => { "set_filter" => "1" },
                                   "name"                       => "Tag 1",
                                   "plan"                       => "",
                                   "needle_easy_query_settings" => { "fields" => ["updated_on"], "values" => { "updated_on" => { "period" => "all", "period_days2" => "", "period_days" => "", "from" => "2017-08-03", "to" => "2017-08-04" } }, "operators" => { "updated_on" => "date_period_2" } },
                                   "range_easy_query_settings"  =>
                                     { "fields" => ["updated_on"], "operators" => { "updated_on" => "date_period_1" }, "values" => { "updated_on" => { "period" => "yesterday", "period_days2" => "", "period_days" => "", "from" => "2017-08-31", "to" => "2017-09-01" } } } },
                               "1" =>
                                 { "easy_query_settings"        => { "set_filter" => "1" },
                                   "name"                       => "Tag 2",
                                   "plan"                       => "",
                                   "needle_easy_query_settings" => { "fields" => ["updated_on"], "values" => { "updated_on" => { "period" => "all", "period_days2" => "", "period_days" => "", "from" => "2017-08-03", "to" => "2017-08-04" } }, "operators" => { "updated_on" => "date_period_2" } },
                                   "range_easy_query_settings"  =>
                                     { "fields" => ["updated_on"], "operators" => { "updated_on" => "date_period_1" }, "values" => { "updated_on" => { "period" => "last_month", "period_days2" => "", "period_days" => "", "from" => "2017-08-31", "to" => "2017-09-01" } } } },
                               "2" =>
                                 { "easy_query_settings"        => { "set_filter" => "1" },
                                   "name"                       => "Tag 3",
                                   "plan"                       => "",
                                   "needle_easy_query_settings" => { "fields" => ["updated_on"], "values" => { "updated_on" => { "period" => "all", "period_days2" => "", "period_days" => "", "from" => "2017-08-03", "to" => "2017-08-04" } }, "operators" => { "updated_on" => "date_period_2" } },
                                   "range_easy_query_settings"  =>
                                     { "fields" => ["updated_on"], "operators" => { "updated_on" => "date_period_1" }, "values" => { "updated_on" => { "period" => "last_week", "period_days2" => "", "period_days" => "", "from" => "2017-08-31", "to" => "2017-09-01" } } } } },
                           "range_query_sumable_column"  => "estimated_hours" } }
  let(:page_zone_module_1) { double('EasyPageZoneModule', uuid: 'abc123', 'css_class=': nil, 'floating=': nil) }

  subject { EpmGenericGauge.new }

  it 'edit' do
    subject.page_zone_module = page_zone_module_1
    edit_data                = subject.get_edit_data(settings_issue, User.current)
    periods                  = edit_data[:range_queries].values.map { |queries| queries.filters }.map { |filters| filters['updated_on'][:values]['period'] }

    expect(periods).to eq %w[yesterday last_month last_week]
  end

  context 'EasyTimeEntryQuery' do
    context 'in project context' do
      let(:settings_time_entry) { { "query_type"                  => "2",
                                    "query_name"                  => "time entries",
                                    "name"                        => "time entries",
                                    "needle_easy_query_klass"     => "easy_time_entry_query",
                                    "needle_query_sumable_column" => "hours",
                                    "action_range"                => "dynamic_range",
                                    "range_easy_query_klass"      => "easy_time_entry_query",
                                    "range_query_sumable_column"  => "hours",
                                    "tags"                        =>
                                      { "0" =>
                                          { "easy_query_settings"        => { "set_filter" => "1" },
                                            "name"                       => "Tag 1",
                                            "plan"                       => "",
                                            "needle_easy_query_settings" =>
                                              { "fields"    => ["user_ids"],
                                                "operators" => { "user_ids" => "=" },
                                                "values"    => { "user_ids" => ["#{User.current.id}"] } },
                                            "range_easy_query_settings"  =>
                                              { "fields"    => ["user_ids"],
                                                "operators" => { "user_ids" => "=" },
                                                "values"    => { "user_ids" => ["#{User.current.id}"] } } },
                                      },
      } }

      let!(:project) { FactoryBot.create(:project, add_modules: ['issue_tracking']) }
      let!(:outside_issue) { FactoryBot.create(:issue) }
      let!(:outside_time_entry) { FactoryBot.create(:time_entry, user: User.current, issue: outside_issue, hours: 15) }
      let(:page_zone_module_2) { double('EasyPageZoneModule', uuid: 'def456', 'css_class=': nil, 'floating=': nil) }

      context 'with cloned gauges on the same page' do
        it 'have same value' do
          # using *subject* for both to simulate *easy_page_zone_module.rb:204#get_show_data* returning the same cached instance
          subject.page_zone_module = page_zone_module_1
          show_data_1              = subject.get_show_data(settings_time_entry, User.current, { project: project })
          subject.page_zone_module = page_zone_module_2
          show_data_2              = subject.get_show_data(settings_time_entry, User.current, { project: project })

          expect(show_data_1[:value]).to eq(show_data_2[:value])
        end
      end

      context 'with dynamic_range with same query classes' do
        it 'keeps project context' do
          subject.page_zone_module = page_zone_module_1
          show_data_1              = subject.get_show_data(settings_time_entry, User.current, { project: project })

          expect(show_data_1[:max_value]).to eq(0.0)
        end
      end
    end
  end
end
