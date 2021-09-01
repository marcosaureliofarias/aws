module EasyCalculations
  class Calculation

    def initialize(project, settings={})
      self.project  = project
      self.header   = {}
      self.body     = {}
      self.settings = settings.dup
      load_data
    end

    attr_accessor :project, :header, :body, :phases, :settings

    def price_sum
      @price_sum ||= body[:phases].sum{|p| p.discounted_price_sum}
    end

    def discount_percent?
      project.calculation_discount_is_percent
    end

    def discount_percent
      @discount_percent ||= discount_percent? ? (project.calculation_discount || 0) : 0
    end

    def discount_amount
      if price_sum
        if discount_percent?
          @discount_amount ||= price_sum * discount_percent / 100
        else
          @discount_amount ||= project.calculation_discount || 0
        end
      end
    end

    def discounted_price_sum
      if price_sum && discount_amount
        @discounted_price_sum ||= ((price_sum - discount_amount) > 0) ? (price_sum - discount_amount) : 0
      end
    end

    def hours_sum
      @hours_sum ||= body[:phases].sum{|p| p.hours_sum}
    end

    def solution_discount_sum
      @solution_discount_sum ||= body[:phases].sum{|s| s.solution_discount_sum}
    end

    def show_phases?
      !!@show_phases
    end

    def total_amount_sum
      unless project.easy_money_settings.nil?
        project.easy_money_settings.show_price2? ? EasyMoneyEntity.compute_price1(project, discounted_price_sum) : discounted_price_sum
      end
    end

    private

    def load_data
      load_header
      load_body
    end

    def load_header
      if Redmine::Plugin.installed?(:easy_contacts)
        header[:client]  = project.client
      else
        header[:client] = project.client_name
      end
      header[:project] = project
      header[:date] = project.calculation_date || Date.today
    end


    def load_body
      body[:phases] = project.children.reorder(:calculation_position).collect{|p| Phase.new(p, self)}
      if body[:phases].empty?
        @show_phases = false
        body[:phases] = [Phase.new(project, self)]
      else
        @show_phases = true
      end
    end

    class Phase
      def initialize(phase_project, calculation)
        self.project     = phase_project
        self.calculation = calculation

        load_solutions
      end

      attr_accessor :project, :solutions, :calculation

      def load_solutions
        self.solutions = project.solution_entities(self.calculation.settings).collect{|i| Solution.new(i, self)}
      end

      def to_s
        project.to_s
      end

      def to_param
        project.to_param
      end

      def price_sum
        @price_sum ||= solutions.sum{|s| s.in_easy_calculation? ? s.discounted_price : 0}
      end

      def hours_sum
        @hours_sum ||= solutions.sum{|s| s.in_easy_calculation? ? s.hours : 0}
      end

      def discount_percent?
        project.calculation_discount_is_percent
      end

      def discount_percent
        @discount_percent ||= discount_percent? ? (project.calculation_discount || 0) : 0
      end

      def discount_amount
        return 0 unless calculation.show_phases?
        if price_sum
          if discount_percent?
            @discount_amount ||= price_sum * discount_percent / 100
          else
            @discount_amount ||= project.calculation_discount || 0
          end
        end
      end

      def discounted_price_sum
        if price_sum && discount_amount
          @discounted_price_sum ||= price_sum - discount_amount
        end
      end

      def solution_discount_sum
        @solution_discount_sum ||= solutions.sum{|s| s.in_easy_calculation? ? s.discount_price : 0}
      end

      def activities_disabled?
        !EasySetting.value('project_fixed_activity', self.project)
      end

    end

    class Solution
      def initialize(issue_or_calculation_item, phase)
        if issue_or_calculation_item.is_a?(Issue)
          self.issue = issue_or_calculation_item
        else
          self.calculation_item = issue_or_calculation_item
        end
        self.phase = phase
      end

      attr_accessor :issue, :calculation_item, :phase

      def type
        if issue
          :issue
        else
          :calculation_item
        end
      end

      def to_s
        (issue || calculation_item).to_s
      end

      def to_param
        (issue || calculation_item).to_param
      end

      def activity
        @activity ||= issue.try(:activity)
      end

      def activity?
        !!(calculation_item || activity.present?)
      end

      def hour_rate
        return @hour_rate if @hour_rate
        return @hour_rate = calculation_item.rate if calculation_item && calculation_item.rate
        return @hour_rate = issue.calculation_rate if issue && issue.calculation_rate
        return @hour_rate ||= 0 if !Redmine::Plugin.installed?(:easy_money)
        @hour_rate = 0
        if activity
          rate = activity.easy_money_rates.where(
            :project_id => issue.project,
            :rate_type_id => 2
          ).first || activity.easy_money_rates.where(
            :project_id => nil,
            :rate_type_id => 2
          ).first
          if rate && rate.unit_rate
            @hour_rate = rate.unit_rate
          end
        else
          @hour_rate = issue.calculation_rate if issue && issue.calculation_rate
        end
        @hour_rate
      end

      def hours
        if issue
          @hours ||= issue.estimated_hours || 0
        else
          @hours ||= calculation_item.hours || 0
        end
      end

      def unit
        if issue
          @unit ||= issue.calculation_unit
        else
          @unit ||= calculation_item.unit
        end
      end

      def price
        if issue || calculation_item.value.blank? || calculation_item.calculation_discount.present?
          @price ||= hour_rate * hours
        else
          @price ||= calculation_item.value
        end
      end

      def discount_percent?
        issue ? issue.calculation_discount_is_percent : calculation_item.calculation_discount_is_percent
      end

      def discount_percent
        if discount_percent?
          @discount_percent ||= (issue ? issue.calculation_discount : calculation_item.calculation_discount)
        end
        @discount_percent || 0
      end

      def discount_price
        if price
          if discount_percent?
            @discount_price ||= price * discount_percent / 100
          else
            @discount_price ||= (issue ? issue.calculation_discount : calculation_item.calculation_discount) || 0
          end
        end
        @discount_price || 0
      end

      def discounted_price
        if price && discount_price
          @discounted_price ||= ((price - discount_price) > 0) ? (price - discount_price) : 0
        end
      end

      def in_easy_calculation?
        return issue.in_easy_calculation? if self.issue
        return true
      end
    end

  end
end
