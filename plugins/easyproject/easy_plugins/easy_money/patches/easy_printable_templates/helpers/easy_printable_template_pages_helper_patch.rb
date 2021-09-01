module EasyMoney
  module EasyPrintableTemplatePagesHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :easy_printable_template_page_create_replacable_tokens_from_entity_project, :easy_money

        def easy_printable_template_page_create_replacable_tokens_from_entity_easy_money(entity)
          tokens = {}

          if entity.is_a?(Project)
            tokens['easy_money_entity_overview'] = proc do
              controller.render_to_string(
                partial: 'easy_money/entity_overview',
                locals: {
                  project: entity,
                  entity: entity,
                  url_params: {
                    project_id: entity
                  },
                  easy_currency_code: entity.easy_currency_code
                }
              )
            end
            tokens['easy_money_subprojects_overview'] = proc do
              controller.render_to_string(
                partial: 'easy_money/subprojects_overview',
                locals: {
                  project: entity,
                  subprojects: entity.children.active.has_module(:easy_money),
                  easy_currency_code: entity.easy_currency_code
                }
              )
            end
          end

          tokens
        end

      end
    end

    module InstanceMethods

      def easy_printable_template_page_create_replacable_tokens_from_entity_project_with_easy_money(project)
        tokens = easy_printable_template_page_create_replacable_tokens_from_entity_project_without_easy_money(project)

        if project.module_enabled?(:easy_money)
          tokens.merge!(easy_printable_template_page_create_replacable_tokens_from_entity_easy_money(project))
        end

        tokens
      end

    end

  end

end
EasyExtensions::PatchManager.register_helper_patch 'EasyPrintableTemplatePagesHelper', 'EasyMoney::EasyPrintableTemplatePagesHelperPatch', if: proc { Redmine::Plugin.installed?(:easy_printable_templates) }
