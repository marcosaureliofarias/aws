class EpmListQuery < EpmEasyQueryBase

  def category_name
    @category_name ||= 'others'
  end

  def edit_path
    'easy_page_modules/others/list_query_edit'
  end

  def get_query_class(settings)
    settings['easy_query_type'].safe_constantize if settings['easy_query_type']
  end

  def output(settings)
    'list'
  end

  def show_preview?
    false
  end
end
