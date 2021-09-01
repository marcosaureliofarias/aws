Rys::Patcher.add('EasyExtensions::EasyAttributeFormatter') do
  apply_if_plugins :easy_extensions

  included do

    def format_easy_money_cashflow_price(price, project, options={})
      formatted = self.format_easy_money_price(price, project, options)
      unless options[:no_html]
        css_classes = price.to_f < 0 ? 'negative price' : 'positive price'
        formatted = content_tag(:span, formatted, :class => css_classes).html_safe
      end
      formatted
    end
  end
end
