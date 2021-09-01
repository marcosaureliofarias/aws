class EasyProjectAttachmentsController < ApplicationController

  accept_api_auth :index

  before_action :find_optional_project
  before_action :authorize_global

  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper
  helper :attachments
  include EntityAttributeHelper
  helper :custom_fields

  def index
    index_for_easy_query EasyProjectAttachmentQuery, [['created_on', 'desc']]
  end

end
