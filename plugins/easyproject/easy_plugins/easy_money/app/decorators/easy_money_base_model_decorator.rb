class EasyMoneyBaseModelDecorator < EasyMoneyDecorator
  def render_easy_money_details
    if User.current.allowed_to?(:view_easy_money, project)
      _h.render model.to_partial_path
    end
  end

  def render_easy_money_tabs
    if User.current.allowed_to?(:view_easy_money, project) && (tabs = easy_money_base_model_tabs).any?
      _h.render 'common/entity_tabs', tabs: tabs, tabs_container: 'easy-money-detail'
    end
  end

  def project
    model.project
  end

  def easy_money_base_model_tabs
    tabs = []

    _h.call_hook(:view_easy_money_base_model_tabs, tabs: tabs, easy_money_base_model: model)

    tabs
  end
end
