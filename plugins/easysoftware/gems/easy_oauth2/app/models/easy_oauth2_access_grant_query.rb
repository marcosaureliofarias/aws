class EasyOauth2AccessGrantQuery < EasyQuery

  def initialize_available_columns
    on_column_group(default_group_label) do
      add_available_column EasyQueryColumn.new(:access_token, title: EasyOauth2AccessGrant.human_attribute_name(:access_token))
      add_available_column EasyQueryColumn.new(:refresh_token, title: EasyOauth2AccessGrant.human_attribute_name(:refresh_token))
      add_available_column EasyQueryColumn.new(:access_token_expires_at, title: EasyOauth2AccessGrant.human_attribute_name(:access_token_expires_at))
      add_available_column EasyQueryColumn.new(:referrer, title: EasyOauth2AccessGrant.human_attribute_name(:referrer))
      add_available_column EasyQueryColumn.new(:created_at, title: EasyOauth2AccessGrant.human_attribute_name(:created_at))
      add_available_column EasyQueryColumn.new(:updated_at, title: EasyOauth2AccessGrant.human_attribute_name(:updated_at))
    end

    add_associated_columns EasyUserQuery, association_name: :user
  end

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'access_token', name: EasyOauth2AccessGrant.human_attribute_name(:access_token)
      add_available_filter 'refresh_token', name: EasyOauth2AccessGrant.human_attribute_name(:refresh_token)
      add_available_filter 'access_token_expires_at', name: EasyOauth2AccessGrant.human_attribute_name(:access_token_expires_at)
      add_available_filter 'referrer', name: EasyOauth2AccessGrant.human_attribute_name(:referrer)
      add_available_filter 'created_at', name: EasyOauth2AccessGrant.human_attribute_name(:created_at)
      add_available_filter 'updated_at', name: EasyOauth2AccessGrant.human_attribute_name(:updated_at)
    end
  end

  def searchable_columns
    %w(#{EasyOauth2AccessGrant.table_name}.access_token)
  end

  def entity
    EasyOauth2AccessGrant
  end

  def default_list_columns
    super.presence || %w[user.name referrer]
  end

end
