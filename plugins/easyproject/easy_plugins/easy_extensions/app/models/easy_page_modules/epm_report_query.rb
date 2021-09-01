class EpmReportQuery < EpmEasyQueryBase

  def category_name
    @category_name ||= 'others'
  end

  def edit_path
    'easy_page_modules/others/report_query_edit'
  end

  def get_edit_data(settings, user, page_context = {})
    h                     = super
    h[:available_queries] = available_queries
    h
  end

  def get_query_class(settings)
    if settings['easy_query_type'] && query = settings['easy_query_type'].safe_constantize
      query if report_support?(query)
    end
  end

  def output(_)
    'report'
  end

  def show_preview?
    false
  end

  private

  def available_queries
    @available_queries ||= EasyQuery.constantized_subclasses.select { |query| report_support?(query) }
  end

  def report_support?(query)
    query.report_support? && (i = query.new; i.groupable_columns.count > 2 && i.sumable_columns?)
  end
end
