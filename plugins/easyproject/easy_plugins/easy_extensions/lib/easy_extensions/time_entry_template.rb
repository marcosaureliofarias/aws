module EasyExtensions
  class TimeEntryTemplate

    def initialize(file_name, user = nil)
      raise ArgumentError if !File.exists?(file_name)

      @user     = user || User.current
      @all      = YAML.load_file(file_name)
      @calendar = EasyUserTimeCalendar.find_by_user(@user)
    end

    def self.create_current_month(file_name = nil)
      t = new(file_name || Rails.root.join('config', 'time_entry_templates.yml'))
      d = Date.today.beginning_of_month
      t.create_for_date(d..d.end_of_month)
    end

    def self.create_last_month(file_name = nil)
      t = new(file_name || Rails.root.join('config', 'time_entry_templates.yml'))
      d = Date.today.beginning_of_month - 1.month
      t.create_for_date(d..d.end_of_month)
    end

    def create_for_date(date_or_dates)
      Array(date_or_dates).each do |date|
        create_required_for_date(date)

        while hours_needed?(date)
          create_random_for_date(date)
        end
      end
    end

    private

    def create_required_for_date(date)
      return true unless hours_needed?(date)

      required(date.wday).each do |attrs|
        create_time_entry(date, attrs)
      end
    end

    def create_random_for_date(date)
      return true unless hours_needed?(date)

      create_time_entry(date, random.sample)
    end

    def create_time_entry(date, attrs)
      t          = new_time_entry
      t.spent_on = date
      t          = assign_from(t, attrs)
      t.save!(validate: false)
    end

    def new_time_entry
      t             = TimeEntry.new
      t.project_id  = default[:project_id]
      t.user_id     = @user.id
      t.activity_id = default[:activity_id]
      t.hours       = default[:hours]
      t
    end

    def assign_from(time_entry, attrs)
      time_entry.project_id = attrs[:project_id] if attrs[:project_id].present?
      time_entry.hours      = case attrs[:hours]
                              when Array
                                attrs[:hours].sample
                              when Integer, Float
                                attrs[:hours]
                              end
      time_entry.comments   = attrs[:comments] if attrs[:comments].present?
      time_entry
    end

    def default
      @all[:default] || {}
    end

    def required(day)
      @all[:required][day] || {}
    end

    def random
      @all[:random] || []
    end

    def time_entry_hours_sum(date)
      TimeEntry.where(user_id: @user.id, spent_on: date).sum(:hours)
    end

    def hours_needed?(date)
      time_entry_hours_sum(date) < @calendar.working_hours(date)
    end

  end


end

