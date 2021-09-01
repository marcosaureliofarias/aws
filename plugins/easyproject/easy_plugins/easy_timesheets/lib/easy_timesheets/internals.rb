module EasyTimesheets

  class EasyTimesheetRow

    attr_reader :easy_timesheet
    attr_accessor :is_new_row, :read_only, :project, :issue, :activity, :over_time

    def initialize(easy_timesheet, cells)
      @easy_timesheet = easy_timesheet
      @cells = cells
    end
    alias_method :time_entry_activity, :activity

    [:project, :issue, :activity].each do |m|
      define_method "#{m}_id" do
        send(m).try(:id)
      end
    end

    def project_id=(arg)
      self.project = Project.find_by(id: arg)
    end

    def issue_id=(arg)
      self.issue = Issue.find_by(id: arg)
      self.project ||= issue.try(:project)
    end

    def activity_id=(arg)
      self.activity = @project && @project.project_time_entry_activities.find_by(id: arg)
    end

    def attributes=(attrs={})
      self.project_id = attrs['project_id']
      attrs.each do |name, v|
        next if name == 'project_id'
        send "#{name}=", v
      end
    end

    def is_new_row?
      !!@is_new_row
    end

    def read_only?
      !!@read_only
    end

    def deletable?
      @easy_timesheet.editable?
    end

    def to_key
      [self.project.try(:id), self.issue.try(:id), self.activity.try(:id)]
    end

    def fit_to_time_entry?(time_entry, over_time = nil)
      @project == time_entry.project &&
        @issue == time_entry.issue &&
        @activity == time_entry.activity &&
        (over_time.nil? ? true : self.over_time == !!over_time)
    end

    def add_time_entry(time_entry)
      tpk = time_entry.spent_on.to_s

      if @project && @project != time_entry.project
        raise ArgumentError, 'Bad project'
      end
      @project = time_entry.project

      if @issue && @issue != time_entry.issue
        raise ArgumentError, 'Bad issue'
      end
      @issue = time_entry.issue

      if @activity && @activity != time_entry.activity
        raise ArgumentError, 'Bad activity'
      end
      @activity = time_entry.activity

      if @cells[tpk]
        @cells[tpk].add_time_entry(time_entry)
        @cells[tpk].row = self
        @easy_timesheet.add_hours_to_sum_row(time_entry.spent_on, time_entry.hours)
      end
    end

    def add_value(spent_on, value)
      @cells[spent_on.to_s].add_hours(value)
    end

    def each_cell(&block)
      return @cells.values if !block_given?
      @cells.values.each do |cell|
        yield cell
      end
    end
    alias_method :cells, :each_cell

    def inspect
      "<#{self.class.name} project=#{project.try(:id)} issue=#{issue.try(:id)} activity=#{activity.try(:id)} cells_count=#{@cells.size}>"
    end

    def dom_id
      get_dom_id = []
      get_dom_id << (self.project.present? ? "project-#{self.project.id}" : 'no_project')
      get_dom_id << (self.issue.present? ? "issue-#{self.issue.id}" : 'no_issue')
      get_dom_id << (self.activity.present? ? "activity-#{self.activity.id}" : 'no_activity')
      get_dom_id << "over_time-#{self.over_time.to_boolean}" if EasySetting.value('easy_timesheets_over_time') == '1' && EasyTimesheet.monthly_calendar_enabled?
      get_dom_id.join('-')
    end
    alias_method :id, :dom_id
    alias_method :to_param, :dom_id

    def time_entries
      @time_entries ||= @cells.values.map(&:time_entries).flatten
    end

    def destroy(also_destroy_time_entries=false)
      if also_destroy_time_entries
        TimeEntry.transaction do
          time_entries.each {|time_entry| time_entry.easy_attendance.blank? && time_entry.editable_by?(User.current) && time_entry.destroy }
        end
      else
        @easy_timesheet.time_entries -= time_entries
      end
    end

    def new_record?
      to_key.compact.empty?
    end

    def sum_hours
      each_cell.sum(&:sum_hours)
    end


  end

  class EasyTimesheetRowCell

    attr_reader :time_entries, :spent_on, :easy_timesheet
    attr_accessor :row

    delegate :project, to: :row
    delegate :issue, to: :row
    delegate :activity, to: :row

    def initialize(easy_timesheet, spent_on = nil)
      @time_entries = []
      @hours = 0
      @spent_on = spent_on.to_s
      @easy_timesheet = easy_timesheet
    end

    def add_time_entry(time_entry)
      @time_entries.delete_if{|i| i.id == time_entry.id}
      @time_entries << time_entry unless time_entry.destroyed?
      @spent_on ||= time_entry.spent_on.to_s
    end

    def add_hours(h)
      @hours += h.to_f
    end

    def sum_hours
      return @hours if @hours > 0
      @hours = @time_entries.sum(&:hours)
    end

    def inspect
      "<#{self.class.name} time_entries_count=#{@time_entries.size} hours=#{sum_hours}>"
    end

    def to_param
      @spent_on
    end

    def time_entry
      @time_entry ||= (@time_entries.size == 1 && @time_entries.first) || nil
    end

    # Fake time entry for check validations on new cells
    def new_time_entry
      @new_time_entry ||= TimeEntry.new(user: @easy_timesheet.user, project: project, issue: issue, activity: activity, spent_on: @spent_on, hours: 0.1, comments: 'blank')
    end

    def readonly?
      if time_entry
        !time_entry.valid?
      elsif project # Fake time entry for check validations on new cells
        !new_time_entry.valid?
      end
    end

  end
end
