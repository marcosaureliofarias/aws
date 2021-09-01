class ChangeEasyQueryPeriodSettingsCoder < ActiveRecord::Migration[4.2]
  def up
    scope   = EasyQuery.where.not(:period_settings => nil).select(:id, :period_settings).to_sql
    queries = EasyQuery.connection.select_all(scope).to_a
    decoder = ActiveRecord::Coders::YAMLColumn.new(EasyQuery)

    queries.each do |query|
      EasyQuery.where(:id => query['id']).update_all(:period_settings => EasyExtensions::EasyQueryHelpers::PeriodSetting.new(decoder.load(query['period_settings'])))
    end
  end
end
