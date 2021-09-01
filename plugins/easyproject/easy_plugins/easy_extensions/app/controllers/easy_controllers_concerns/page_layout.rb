module EasyControllersConcerns
  module PageLayout

    def save_tabs_settings!(tabs, all_page_tabs)
      if !params['page_tabs'].is_a?(ActionController::Parameters)
        return
      end

      mobile_default_tab = nil

      tabs.each do |params_id, tab|
        tab_params = params['page_tabs'][params_id]
        next if !tab_params

        if tab_params[:mobile_default] == '1'
          mobile_default_tab = tab
        end

        tab.attributes = tab_params.permit(:name, :mobile_default)
        tab.save
      end

      # Not all tabs are loaded at once
      # and I need nechanism to ensure max one default
      if mobile_default_tab
        all_page_tabs.where.not(id: mobile_default_tab.id).update_all(mobile_default: false)
      end
    end

    def ensure_tabs_for_settings(tab_class, add:)
      tab_ids = []

      if params['global_filters'].is_a?(ActionController::Parameters)
        tab_ids.concat(params['global_filters'].keys)
      end

      if params['global_currency'].is_a?(ActionController::Parameters)
        tab_ids.concat(params['global_currency'].keys)
      end

      if params['page_tabs'].is_a?(ActionController::Parameters)
        tab_ids.concat(params['page_tabs'].keys)
      end

      tab_ids.compact!
      tab_ids.map!(&:to_s)
      tab_ids.uniq!

      # There are data only for one tab which does not exist yet
      if tab_ids == ['0']
        tab  = add.call
        tabs = [['0', tab]]
      else
        tabs = tab_class.where(id: tab_ids).map { |t| [t.id.to_s, t] }
      end

      tabs
    end

    def save_global_filters!(tabs)
      if !params['global_filters'].is_a?(ActionController::Parameters)
        return
      end

      tabs.each do |params_id, tab|
        tab_filters = params['global_filters'][params_id]
        if tab_filters
          tab_filters = tab_filters.to_unsafe_hash
        else
          next
        end

        # To send data even if there are no filters
        tab_filters.delete('__keep__')

        tab.settings['global_filters'] = tab_filters
        tab.save
      end
    end

    def save_global_currency!(tabs)
      if !params['global_currency'].is_a?(ActionController::Parameters)
        return
      end

      tabs.each do |params_id, tab|
        currency_params         = params.dig('global_currency', params_id)
        default_currency_params = params.dig('global_currency_defaults', params_id)
        next if !currency_params

        tab.settings['global_currency']          = currency_params
        tab.settings['global_currency_defaults'] = default_currency_params
        tab.save
      end
    end

  end
end
