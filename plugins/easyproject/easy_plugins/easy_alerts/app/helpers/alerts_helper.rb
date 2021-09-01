module AlertsHelper

  def milestones_for_select(versions, selected=[])
    grouped = Hash.new {|h,k| h[k] = Array.new}
    versions.each do |version|
      grouped[version.project.name] << [version.name, version.id]
    end

    if grouped.keys.size > 1
      grouped_options_for_select(grouped, selected)
    else
      options_for_select((grouped.values.first || []), selected)
    end
  end

end