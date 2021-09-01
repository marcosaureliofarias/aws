module EasyKnowledge
  module ApplicationHelperPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        class << self
          alias_method_chain :redmine_links_allowed_prefixes, :easy_knowledge
        end

        def knowledge_headers_tags
          tags = Array.new
          tags << stylesheet_link_tag('easy_knowledge', :media => 'all', :plugin => 'easy_knowledge')

          return tags
        end

        def include_knowledge_headers_tags
          unless @knowledge_headers_tags_included
            @knowledge_headers_tags_included = true
            content_for :header_tags do

              knowledge_headers_tags.join.html_safe
            end
          end
        end

        def render_easy_knowledge_story_selector(mode, url_options={}, options={})
          if mode == :assignment
            render_easy_knowledge_story_selector_assignment(url_options, options)
          elsif mode == :reference
            render_easy_knowledge_story_selector_reference(url_options, options)
          end
        end

        def render_easy_knowledge_story_selector_assignment(url_options={}, options={})
          render :partial => 'easy_knowledge_stories/selector/selector', :locals => { :url_options => { :mode => :assignment }.merge(url_options).symbolize_keys, :options => options.symbolize_keys}
        end

        def render_easy_knowledge_story_selector_reference(url_options={}, options={})
          render :partial => 'easy_knowledge_stories/selector/selector', :locals => { :url_options => { :mode => :reference }.merge(url_options).symbolize_keys, :options => options.symbolize_keys}
          end

        def url_to_easy_knowledge_story(easy_knowledge_story, options={})
          easy_knowledge_story_url(easy_knowledge_story, url_standard_options(options))
        end

        def link_to_easy_knowledge_story(easy_knowledge_story, options={})
          link_to(easy_knowledge_story.name, easy_knowledge_story_path(easy_knowledge_story, {:project_id => @project}.merge(options.delete(:url) || {})), {:class => entity_css_icon(easy_knowledge_story)}.merge(options))
        end

        def render_easy_entity_card_easy_knowledge_story(easy_knowledge_story, source_entity, options = {})
          easy_entity_card(easy_knowledge_story, source_entity, options) do |eec|
            eec.link_to_entity link_to_easy_knowledge_story(easy_knowledge_story)

            eec.avatar(avatar(easy_knowledge_story.author, :style => :medium, :no_link => true)) if easy_knowledge_story.author

            eec.detail content_tag(:p, Sanitize.clean(easy_knowledge_story.get_description, :output => :html).truncate(300))

            eec.footer_left content_tag(:span, easy_knowledge_story.tag_list.map{|t| link_to(t, easy_tag_path(t))} .join(', ').html_safe, :class => 'entity-array') if !easy_knowledge_story.tag_list.blank?
          end
        end

      end
    end

    module InstanceMethods

    end

    module ClassMethods
      def redmine_links_allowed_prefixes_with_easy_knowledge
        redmine_links_allowed_prefixes_without_easy_knowledge + ['easy_knowledge_story']
      end
    end

  end

end
EasyExtensions::PatchManager.register_helper_patch 'ApplicationHelper', 'EasyKnowledge::ApplicationHelperPatch'
