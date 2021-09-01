class EasyButtonQuery < EasyQuery

  def entity
    EasyButton
  end

  def entity_easy_query_path(options)
    easy_buttons_path options
  end

  def initialize_available_filters
    add_available_filter 'name', { type: :string, order: 1 }
    add_available_filter 'active', { type: :boolean, order: 2 }
    add_principal_autocomplete_filter 'author_id', { order: 4 }
    add_available_filter 'entity_type', { type: :list, order: 5, values: [%w(Issue Issue), %w(EasyCrmCase EasyCrmCase)] }

    on_filter_group(default_group_label) do
      add_available_filter 'created_at', { type: :date_period, order: 6 }
      add_available_filter 'updated_at', { type: :date_period, order: 7 }
    end
  end

  def available_columns
    unless @available_columns_added
      group = default_group_label
      @available_columns = [
        EasyQueryColumn.new(:name, :sortable => "#{EasyButton.table_name}.name", :groupable => true, :group => group),
        EasyQueryColumn.new(:entity_type, :sortable => "#{EasyButton.table_name}.entity_type", :groupable => true, :group => group),
        EasyQueryColumn.new(:active, :sortable => "#{EasyButton.table_name}.active", :group => group),
        EasyQueryColumn.new(:is_private, :sortable => "#{EasyButton.table_name}.is_private", :group => group),
        EasyQueryDateColumn.new(:created_at, :sortable => "#{EasyButton.table_name}.created_at", :groupable => true, :group => group),
        EasyQueryDateColumn.new(:updated_at, :sortable => "#{EasyButton.table_name}.updated_at", :groupable => true, :group => group)
      ]

      group = l('label_user_plural')
      @available_columns << EasyQueryColumn.new(:author, :sortable => lambda { User.fields_for_order_statement }, :groupable => true, :includes => [:author => :easy_avatar], :group => group)

      @available_columns_added = true
    end
    @available_columns
  end

  def default_list_columns
    super.presence || ['active', 'name', 'entity_type', 'author', 'is_private']
  end

  def self.list_support?
    false
  end

  def self.report_support?
    false
  end

end
