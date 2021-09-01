module EpmEasySchedulerHelper
  def get_epm_scheduler_toggling_container_options(_page_module, options = {})
    tc_options = {}
    unless options[:edit]
      query = options[:easy_page_modules_data][:query]
      save_as_tagged_query_link = link_to '', new_easy_query_path(query.to_params.merge(back_url: request.url)),
                                          class: 'icon icon-save',
                                          title: l('easy_scheduler.label_save_filter')

      header_toggler = link_to '', 'javascript:void(0)',
                               class: 'icon icon-settings',
                               onclick: '$(".easy-calendar__mobile-header-toggler").click()'

      tc_options[:heading_links] = header_toggler + save_as_tagged_query_link

      query_links_options = [
        { icon: 'edit', title: l(:title_edit_projectquery), data: { action: 'edit' } },
        { icon: 'delete', title: l(:title_delete_projectquery), data: { action: 'destroy' } },
        { icon: 'group', title: l(:title_copy_projectquery), data: { action: 'copy_to_users' } }
      ]

      query_links = query_links_options.map do |options|
        options[:class] = "icon icon-#{options.delete(:icon)} do_not_toggle"
        link_to('', 'javascript:void(0)', options)
      end

      query_links = "<span class='easy-query-heading-wrapper query_tooltip hidden'><span class='tooltip'>#{query_links.join}</span></span>"

      tc_options[:heading] = query_links + l(:scheduler, scope: [:easy_pages, :modules])
    end
    tc_options
  end
end
