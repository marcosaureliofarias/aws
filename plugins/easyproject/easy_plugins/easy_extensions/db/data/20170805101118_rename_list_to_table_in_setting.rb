class RenameListToTableInSetting < ActiveRecord::Migration[4.2]
  def up
    [EasyPageZoneModule, EasyPageTemplateModule].each do |modules|
      modules.find_each(:batch_size => 50) do |m|
        if m.settings['output']
          m.settings['output'].gsub!(/^list$/, 'table')
          if m.settings['output'] == 'chart' && m.settings['chart_settings'].is_a?(Hash)
            renderer = m.settings['chart_settings']['primary_renderer']
            m.settings['chart_settings'].merge(m.settings['chart_settings'][renderer]) if m.settings['chart_settings'][renderer].is_a?(Hash)
            m.settings['chart_settings'].delete(renderer)
          end
          m.save
        end
      end
    end
  end

  def down
  end
end
