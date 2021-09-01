require 'easy_extensions/spec_helper'

describe 'issues/_new_form_static_attributes.html.erb' do

  def render_form(is_mobile: false, text_formatting: "HTML")
    allow(view).to receive(:in_mobile_view?).and_return(is_mobile)
    allow(view).to receive(:is_mobile_device?).and_return(is_mobile)

    stub_template "issues/edit_issue_repeat_options" => ""
    stub_template "attachments/form" => ""
    with_settings text_formatting: text_formatting do
      render partial: "issues/new_form_static_attributes", locals: { issue: spy }
    end
  end

  it "render form with CKeditor" do
    render_form
    expect(rendered).to include("ckeditor")
  end

  it "render form without CKeditor" do
    render_form text_formatting: "none"
    expect(rendered).not_to include("ckeditor")
  end

  it "render form with HTML in mobile" do
    render_form is_mobile: true
    expect(rendered).to include("ckeditor")
  end

end