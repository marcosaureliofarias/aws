require 'easy_extensions/spec_helper'

RSpec.feature 'Translatable Page Modules', js: true, logged: :admin do

  # Add module "Tasks from filters"
  def add_issue_query_module
    first('.add-module-select option', text: I18n.t('easy_pages.modules.issue_query')).select_option
    wait_for_ajax
  end

  def add_trend_module(query_class)
    first('.add-module-select option', text: I18n.t('easy_pages.modules.trends')).select_option
    wait_for_ajax

    first('.easy-page-module .easy-query-type').find("option[value='#{query_class}']").select_option
    wait_for_ajax
  end

  def add_modules(save = false)
    find('.customize-button').click
    add_issue_query_module
    add_trend_module(EasyIssueQuery)

    save_easy_page_modules if save
  end

  def test_first_module_to_be_translatable
    add_modules

    page_module          = first('.easy-page-module.box')
    translatable_input   = page_module.first('.easy-translator-input-field')
    link_to_translations = page_module.first('.easy-translation-link')

    link_to_translations.click
    wait_for_ajax

    # Add englishTranslation
    modal = first('#ajax-modal')
    modal.first('input').set('originalValue')

    modal.first('option[value="en"]').click
    modal.first('input.easy-flag.en').set('englishValue')

    # submit form
    modal.first(:xpath, './/..').first('button.submit').click

    expect(translatable_input.value).to eq('englishValue')
    save_easy_page_modules

    page_module = first('.easy-page-module.box')
    page_module.first('.module-heading').assert_text('englishValue')
    page_module.hover.first('.icon-edit').click

    easy_module_edit_modal = first('#easy_module_edit_modal')
    translatable_input     = easy_module_edit_modal.first('.easy-translator-input-field')
    link_to_translations   = easy_module_edit_modal.first('.easy-translation-link')

    link_to_translations.click
    wait_for_ajax

    # Remove englishTranslation
    modal = first('#ajax-modal')

    modal.first('.easy-translator-input-field.en').first('a').click
    expect(modal).to have_selector('option[value="en"]')

    # submit form
    modal.first(:xpath, './/..').first('button.submit').click

    expect(translatable_input.value).to eq('originalValue')
    easy_module_edit_modal.first(:xpath, './/..').first('button.button-positive').click

    first('.easy-page-module.box .module-heading').assert_text('originalValue')
  end

  it 'Normal page' do
    visit home_path

    test_first_module_to_be_translatable
  end

  it 'Template page' do
    my_page_template = EasyPageTemplate.find_by(template_name: 'my-page-template')
    visit easy_page_templates_show_page_template_path(id: my_page_template.id)

    test_first_module_to_be_translatable
  end

end
