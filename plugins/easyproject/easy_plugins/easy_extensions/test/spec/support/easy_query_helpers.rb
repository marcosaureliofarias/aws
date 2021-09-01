module EasyQueryHelpers

  class StubParent < ActiveRecord::Base

  end

  class StubEntity < ActiveRecord::Base
    acts_as_customizable
    belongs_to :stub_parent
  end

  class StubEntityCustomField < ::CustomField

  end

  class EasyStubEntityQuery < EasyQuery
    def entity;
      StubEntity;
    end

    def initialize_available_filters
      add_available_filter 'name', { :type => :string }
      add_available_filter 'date', { :type => :date_period, :time_column => true }
      add_custom_fields_filters(StubEntityCustomField.all)
    end

    def available_columns
      [].tap do |cols|
        cols << EasyQueryColumn.new(:name, groupable: true)
        cols << EasyQueryDateColumn.new(:date)
        cols << EasyQueryColumn.new(:value, sumable: :both, groupable: true)
        cols << EasyQueryColumn.new(:parent_value, sumable_sql: 'stub_parents.value', sumable: :both, joins: [:stub_parent])
        StubEntityCustomField.visible.collect do |cf|
          cols << EasyQueryCustomFieldColumn.new(cf)
        end
      end
    end

    def default_list_columns
      ['name', 'date', 'value']
    end

  end

  def create_stub_query_entity
    [:stub_entities, :stub_parents].each do |table|
      unless ActiveRecord::Base.connection.table_exists?(table)
        ActiveRecord::Base.connection.create_table(table) do |t|
          t.string :name
          t.date :date
          t.datetime :datetime
          t.integer :value
          t.references :stub_parent if table == :stub_entities

          t.timestamps null: true
        end
        ActiveRecord::Base.connection.pool.connections.each { |con| con.instance_variable_set(:@database_cleaner_tables, nil) }
      end
    end
    [:stub_entity, :stub_parent].each do |factory|
      unless FactoryGirl.factories.registered?(factory)
        FactoryGirl.define do
          factory factory, class: "EasyQueryHelpers::#{factory.to_s.camelize}" do
            sequence(:name) { |n| 'Random name' + (n % 4).to_s }
            date { Date.today }
            datetime { Time.now }
            if factory == :stub_entity
              stub_parent
            end
            value { Random.rand(5) }
          end
        end
      end
    end
  end

  def drop_stub_query_entity
    StubEntityCustomField.destroy_all
    [:stub_entities, :stub_parents].each do |table|
      ActiveRecord::Base.connection.drop_table(table) if ActiveRecord::Base.connection.table_exists?(table)
    end
    ActiveRecord::Base.connection.pool.connections.each { |con| con.instance_variable_set(:@database_cleaner_tables, nil) }
  end

end
