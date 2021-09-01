module EasyEarnedValuesHelper

  def include_easy_earned_value_scripts
    return if @easy_earned_value_scripts_included
    @easy_earned_value_scripts_included = true

    if defined?(include_jqplot_scripts)
      include_jqplot_scripts
    else
      content_for(:header_tags) do
        stylesheet_link_tag('https://cdnjs.cloudflare.com/ajax/libs/c3/0.6.8/c3.min.css') +
        javascript_include_tag(
          'https://cdnjs.cloudflare.com/ajax/libs/d3/5.7.0/d3.min.js',
          'https://cdnjs.cloudflare.com/ajax/libs/c3/0.6.8/c3.min.js')
      end
    end

    # content_for(:header_tags) do
    #   javascript_include_tag('jquery.earnedValue', plugin: 'easy_earned_value')
    # end
  end

  def include_easy_earned_value_styles
    return if @include_easy_earned_value_styles_included
    @include_easy_earned_value_styles_included = true

    content_for(:header_tags) do
      stylesheet_link_tag('easy_earned_values', plugin: 'easy_earned_values')
    end
  end

  def get_epm_easy_earned_value_toggling_container_options(page_module, **options)
    if options[:edit]
      return {}
    end

    earned_value = options[:easy_page_modules_data][:earned_value]
    if earned_value
      heading = "#{earned_value.project} - #{earned_value.name}"
    else
      heading = l('easy_pages.modules.easy_earned_value')
    end

    { heading: heading }
  end

  def spi_css_classes(spi)
    if spi < 1
      'spi_bad'
    elsif spi > 1
      'spi_good'
    else
      'spi_ok'
    end
  end

  def cpi_css_classes(cpi)
    if cpi < 1
      'cpi_bad'
    elsif cpi > 1
      'cpi_good'
    else
      'cpi_ok'
    end
  end

  def evm_long_name_of(type, earned_value:)
    case type
    when :ac
      l('ac_long', scope: ['easy_earned_values', 'types', earned_value.data_type, 'values'],
                   default: l('easy_earned_values.values.ac'))
    when :ev
      l('ev_long', scope: ['easy_earned_values', 'types', earned_value.data_type, 'values'],
                   default: l('easy_earned_values.values.ev'))
    when :pv
      l('pv_long', scope: ['easy_earned_values', 'types', earned_value.data_type, 'values'],
                   default: l('easy_earned_values.values.pv'))
    end
  end

end
