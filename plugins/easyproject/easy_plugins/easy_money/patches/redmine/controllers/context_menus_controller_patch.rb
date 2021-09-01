module EasyMoney
  module ContextMenusControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def easy_money
          @project = Project.find(params[:project_id]) if params[:project_id]
          @easy_money_entity_type = "EasyMoney#{params[:money_entity_type].camelcase}".classify
          @ids = params[:ids]
          @easy_money_entities = @easy_money_entity_type.constantize.where(:id => @ids).to_a
          if @easy_money_entities.count == 1
            @easy_money_entity = @easy_money_entities.first
          end
          cogs = {'Other' => 'Expected'}
          m = @easy_money_entity_type.match(/EasyMoney(other|expected)(.+)/i)

          if m
            t = cogs[m[1]] || cogs.key(m[1])
            @easy_money_entity_target = "EasyMoney#{t}#{m[2]}"

            @opts = {
                :label_copy => "button_easy_money_copy_to_#{t.downcase}",
                :label_move => "button_easy_money_move_to_#{t.downcase}"
            }
          end
          edit_allowed = @easy_money_entities.all?(&:editable?)
          @can = { :edit => edit_allowed, :delete => edit_allowed }
          render :layout => false
        rescue ActiveRecord::RecordNotFound
          render_404
        end

        alias_method :easy_money_expected_expenses, :easy_money
        alias_method :easy_money_expected_revenues, :easy_money
        alias_method :easy_money_other_expenses, :easy_money
        alias_method :easy_money_other_revenues, :easy_money
        alias_method :easy_money_travel_expenses, :easy_money
        alias_method :easy_money_travel_costs, :easy_money

      end
    end

    module InstanceMethods
      def easy_money_user_rates
        @project = Project.find(params[:project_id]) if params[:project_id]
        @ids = params[:ids]

        render :layout => false
      end
    end
  end
end
EasyExtensions::PatchManager.register_controller_patch 'ContextMenusController', 'EasyMoney::ContextMenusControllerPatch'
