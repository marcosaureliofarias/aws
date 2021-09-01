class EasyChartBaseline < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :page_module, class_name: 'EasyPageZoneModule'

  serialize :data
  serialize :ticks, Array
  serialize :options

  safe_attributes 'name', 'chart_type', 'data', 'ticks', 'options'

  scope :visible, ->(user = User.current) {
    at = EasyPageZoneModule.arel_table
    joins(:page_module).where(at[:user_id].eq(user.id).or(at[:user_id].eq(nil)))
  }

  def data=(data)
    if data.is_a?(Hash)
      data['json']    = data['json'].values if data['json'].is_a?(Hash)
      data['columns'] = data['columns'].values if data['columns'].is_a?(Hash)
      data['groups']  = data['groups'].values if data['groups'].is_a?(Hash)
    end
    super(data)
  end

end
