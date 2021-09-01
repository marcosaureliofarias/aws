module EasyKnowledgeCategoriesHelper

  def css_category_classes(category, uniq_prefix = nil)
    s = ''
    s << ' root' if category.root?
    s << ' child' if category.child?
    s << (category.leaf? ? ' leaf' : ' parent')
    s << ' subcategory' if category.child?
    s << (' '+ uniq_prefix.to_s + 'parenteasy_knowledge_category_' + category.parent_id.to_s) if category.child?
    s << toggle_open_css_row(uniq_prefix.to_s + "easy_knowledge_category-#{category.id}")
    s
  end

  def parent_category_select_tag(category)
    selected = (params[:easy_knowledge_category] && params[:easy_knowledge_category][:parent_id]) || params[:parent_id] || category.parent_id
    parents = category.allowed_parents
    sel_options = options_for_select(
      parents.compact.collect{|c| [c.family_name(:self_only => true).html_safe, c.id]},
      :selected => selected
    )
    select_tag 'easy_knowledge_category[parent_id]', sel_options, :include_blank => parents.include?(nil)
  end

  def category_tree_options_for_select(categories, options = {})
    s = ''
    categories.sort_by(&:lft).each do |category|
      tag_options = {:value => category.id}
      if category == options[:selected] || (options[:selected].respond_to?(:include?) && options[:selected].include?(category))
        tag_options[:selected] = 'selected'
      else
        tag_options[:selected] = nil
      end
      tag_options.merge!(yield(category)) if block_given?
      s << content_tag('option', category.family_name(:self_only => true), tag_options)
    end
    s
  end

  def grouped_category_tree_options_for_select(grouped_categories, options = {})
    gc = []
    grouped_categories.each do |category|
      gc << [category.first, category.last.collect{|subcategory| [subcategory.family_name(:self_only => true).html_safe, subcategory.id]}]
    end
    grouped_options_for_select(gc, options)
  end

end
