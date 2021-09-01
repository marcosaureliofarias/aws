class EasyMoneyIssueDecorator < EasyMoneyDecorator

  def issue_budget_box_heading
    _h.content_tag(:h3, _h.l('easy_reports_categories.easy_money'), class: 'icon icon-money') +
        _h.content_tag(:span, "#{heading_label}: #{heading_value}".html_safe, class: 'module-heading-links')
  end

private

  def css_class_expected
    expected_profit < 0 ? 'color-negative' : ''
  end

  def css_class_other
    other_profit > 0 ? 'color-positive' : 'color-negative'
  end

  def project
    entity.project
  end

  def expected_profit_formatted
    _h.format_easy_money_price(expected_profit, project, easy_currency_code, humanize: true, no_html: true)
  end

  def other_profit_formatted
    _h.format_easy_money_price(other_profit, project, easy_currency_code, humanize: true, no_html: true)
  end

  def show_expected_profit?
    User.current.allowed_to?(:easy_money_show_expected_profit, project) && project.easy_money_settings.show_expected?
  end

  def show_other_profit?
    User.current.allowed_to?(:easy_money_show_other_profit, project)
  end

  def heading_label
    label = ''
    if show_expected_profit?
      label += _h.l(:label_easy_money_expected_budget)
    end
    if show_expected_profit? && show_other_profit?
      label += '/'
    end
    if show_other_profit?
      label += _h.l(:label_easy_money_real_budget)
    end

    label
  end

  def heading_value
    value = ''
    if show_expected_profit?
      value += _h.content_tag(:span, expected_profit_formatted, class: css_class_expected)
    end
    if show_expected_profit? && show_other_profit?
      value += ' / '
    end
    if show_other_profit?
      value += _h.content_tag(:span, other_profit_formatted, class: css_class_other)
    end

    value
  end

end