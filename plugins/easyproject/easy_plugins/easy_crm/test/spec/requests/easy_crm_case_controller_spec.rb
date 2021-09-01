require 'easy_extensions/spec_helper'
describe EasyCrmCasesController do
  include_context "a requests actions", :easy_crm_case, [:view_easy_crms]
end