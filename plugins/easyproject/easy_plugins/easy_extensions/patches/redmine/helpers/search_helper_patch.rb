module EasyPatch
  module SearchHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :project_select_tag, :easy_extensions
        alias_method_chain :highlight_tokens, :easy_extensions

        def additional_search_results(entity, tokens)
          normalize_tokens = get_normalize_tokens(tokens)
          regexp           = /(#{(Array(tokens) + normalize_tokens).map { |t| Regexp.escape(t) }.join('|')})(?!(?:[^<]*?)(?:["'])[^<>]*>)/i

          r = ''

          case entity.class.name
          when 'Document', 'Issue', 'Project'
            lis = Array.new
            if entity.respond_to?(:attachments)
              entity.attachments.each do |a|
                row = link_to_attachment(a, { :download => true })
                row << " - #{a.description}" unless a.description.blank?
                next unless row.match(regexp)
                lis << content_tag(:li, row)
              end
              unless lis.empty?
                r << content_tag(:h4, l(:label_attachment_plural))
                r << content_tag(:ul, lis.join.html_safe, :class => 'attachments')
              end
            end

            if entity.respond_to?(:journals)
              entity.journals.visible.each do |journal|
                j = journal.notes || ''

                if j.size > Redmine::Search::MAX_TEXT_SIZE_FOR_HIGHLIGHT
                  r << content_tag(:em, l(:error_text_is_too_large)) + truncate_html(j, 100)
                  next
                end

                next unless i = j.match(regexp)

                splitting_text = j.split(regexp)
                index          = splitting_text.index(i.to_s)
                text           = "#{truncate_html(splitting_text.at(index - 1).reverse, 20).reverse if index > 0} #{splitting_text.at(index)} #{splitting_text.at(index + 1) if index < splitting_text.size}"
                r << highlight_tokens(text, normalize_tokens, regexp)
              end
            end
          end

          if entity.respond_to?(:custom_values)
            entity.custom_field_values.select { |cv| cv.custom_field.searchable? && cv.value.to_s.match(regexp) }.each do |custom_field_value|
              s = content_tag(:span, custom_field_value.custom_field.translated_name, :class => 'custom-field-name')
              s << ':'
              s << content_tag(:span, custom_field_value.cast_value, :class => 'custom-field-value')
              r << content_tag(:div, s.html_safe, :class => 'custom-field')
            end
          end

          hook_context = { :entity => entity, :additional_result => r, :tokens => tokens }
          call_hook(:helper_easy_extensions_search_helper_patch, hook_context)
          r = hook_context[:additional_result] unless hook_context[:additional_result].blank?

          r
        end

        def get_normalize_tokens(tokens)
          normalize_tokens = Array.new
          Array(tokens).collect { |i| normalize_tokens << i.parameterize } #i.mb_chars.normalize(:kd).gsub(/[^x00-\x7F]/n, '').to_s}

          return normalize_tokens.uniq.reject(&:empty?)
        end

        def search_scope_type_input(scope_select, project)
          available_options = []
          available_options << [l(:label_project_all), 'all']
          available_options << [l(:label_and_its_subprojects, project.name), 'subprojects'] if project.is_a?(Project) && project.descendants.active.any?
          available_options << [l(:label_project), 'project']

          select_tag(:scope_type, options_for_select(available_options, scope_select),
                     :onchange => 'selectSearchRange(this)',
                     :style    => 'width:auto',
                     :id       => '')
        end

      end
    end

    module InstanceMethods

      def project_select_tag_with_easy_extensions
        # projects = Project.where(:id => params[:scope])

        # selected_values = EasyExtensions::FieldFormats::EasyLookup.entity_to_lookup_values(projects.any? ? projects.all : @project)
        # easy_modal_selector_field_tag('Project', 'link_with_name', 'scope', 'search_scope', selected_values, {:multiple => '1'})

        selected_value = params[:scope] && /\d+/.match?(params[:scope]) ? Project.find(params[:scope]) : @project
        easy_select_tag('scope', { :name => selected_value.try(:name), :id => selected_value.try(:id) }, nil, easy_autocomplete_path('visible_projects'), :include_blank => true, :root_element => 'projects')

      end

      def highlight_tokens_with_easy_extensions(text, tokens, regexp = nil)
        return text unless text && tokens && !tokens.empty?
        unless regexp
          normalize_tokens = get_normalize_tokens(tokens)
          regexp           = /(#{(Array(tokens) + normalize_tokens).map { |t| Regexp.escape(t) }.join('|')})(?!(?:[^<]*?)(?:["'])[^<>]*>)/i
        end
        normalize_tokens ||= tokens
        plain_text       = Loofah::Helpers.strip_tags(text)
        result           = ''
        plain_text.split(regexp).each_with_index do |words, i|
          if i.even?
            result << (words.length > 150 ? "#{words.slice(0..69)} ... #{words.slice(-70..-1)}" : words)
          else
            #mb_chars.normalize(:kd).gsub(/[^x00-\x7F]/n, '').to_s
            t = (normalize_tokens.index(words.downcase.parameterize) || 0) % 4
            result << "<span class='highlight token-#{t}'>" + words + '</span>'
          end
        end

        result.html_safe
      end

    end

  end
end
EasyExtensions::PatchManager.register_helper_patch 'SearchHelper', 'EasyPatch::SearchHelperPatch'
