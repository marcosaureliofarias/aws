require 'easy_extensions/spec_helper'

feature 'easy printable templates', js: true, logged: :admin do
  let(:easy_printable_template) { FactoryGirl.create(:easy_printable_template, :with_easy_printable_template_pages) }

  context 'invoicing', skip: !Redmine::Plugin.installed?(:easy_invoicing) || !Redmine::Plugin.installed?(:easy_contacts) do
    let(:cf1) { FactoryGirl.create(:easy_contact_custom_field, :name => 'primary-show-empty', :field_format => 'string', :is_primary => true, :show_empty => true) }
    let(:cf2) { FactoryGirl.create(:easy_contact_custom_field, :name => 'primary-hide-empty', :field_format => 'string', :is_primary => false, :show_empty => false) }
    let(:cf3) { FactoryGirl.create(:easy_contact_custom_field, :name => 'lookup', :field_format => 'easy_lookup', :is_primary => false, :show_empty => false,
        :settings => {'entity_type' => 'User', 'entity_attribute' => 'mail'})
    }

    let(:project) { FactoryGirl.create(:project, :add_modules => ['easy_invoicing']) }
    let(:user) { FactoryGirl.create(:user) }

    let(:personal_easy_contact) {
      pec = FactoryGirl.build(:personal_easy_contact)
      cf1.contact_types << pec.easy_contact_type
      cf2.contact_types << pec.easy_contact_type
      cf3.contact_types << pec.easy_contact_type
      User.first.update_attributes(:mail => 'test@kkk.kk')
      pec.custom_field_values = {cf1.id => 'panda', cf2.id => 'panda2', cf3.id => user.id.to_s}
      pec.save
      pec
    }

    let(:easy_invoice) {
      ei = FactoryGirl.build(:easy_invoice, :project => project)
      ei.client = personal_easy_contact
      # it validates client_ values, which are set from client
      ei.save(:validate => false)
      ei
    }

    let(:easy_printable_template_tokens_check) {
      t = FactoryGirl.create(:easy_printable_template, :with_easy_printable_template_pages)
      p = t.easy_printable_template_pages.first
      p.page_text = "total in supplier currency: %easy_invoice_total_in_supplier_currency% "
      p.save
      t
    }
    let(:supplier_easy_contact) { FactoryGirl.create(:easy_contact) }
    let(:client_easy_contact) { FactoryGirl.create(:easy_contact) }
    let(:easy_invoice_in_euro_currency) {
      ei = FactoryGirl.build(:easy_invoice_with_line_items, project: project, easy_currency_code: 'EUR')
      ei.easy_invoice_line_items = FactoryBot.build_list(:easy_invoice_line_item, 1, easy_invoice: ei, vat_rate: 21)
      ei.client = client_easy_contact
      ei.supplier = supplier_easy_contact
      ei.supplier_country = 'CZ'
      # it validates client_ values, which are set from client
      ei.save(validate: false)
      ei
    }

    before(:each) do
      cf1; cf2; cf3; personal_easy_contact; supplier_easy_contact; client_easy_contact

      p = easy_printable_template.easy_printable_template_pages.first
      p.page_text = "cf: %easy_invoice_client_cf_#{cf1.id}% lookup value: %easy_invoice_client_cf_#{cf3.id}%"
      p.save
    end

    it 'shows contact custom field in invoice correctly' do
      easy_invoice
      easy_printable_template
      easy_printable_template_page = easy_printable_template.easy_printable_template_pages.first
      visit preview_easy_printable_template_path(easy_printable_template, entity_type: easy_invoice.class.to_s, entity_id: easy_invoice.id)
      expect(page.find("#page_content_#{easy_printable_template_page.id} p")).to have_text("cf: panda lookup value: #{user.mail}")
    end

    it 'shows contact custom field in invoice correctly when client is nil' do
      easy_printable_template

      easy_invoice.update_column(:client_id, nil)

      easy_printable_template_page = easy_printable_template.easy_printable_template_pages.first

      visit preview_easy_printable_template_path(easy_printable_template, entity_type: easy_invoice.class.to_s, entity_id: easy_invoice.id)
      expect(page.find("#page_content_#{easy_printable_template_page.id} p").text).to eq 'cf: lookup value:'
    end

    it 'show and hide currency rate and original currency if invoice currency and supplier currency same' do
      easy_invoice_in_euro_currency
      easy_printable_template_tokens_check

      visit preview_easy_printable_template_path(easy_printable_template_tokens_check, entity_type: easy_invoice_in_euro_currency.class.to_s, entity_id: easy_invoice_in_euro_currency.id)

      expect(page).to have_text(sprintf("%.2f", easy_invoice_in_euro_currency.total).to_s + " CZK")

      easy_invoice_in_euro_currency.update_column(:easy_currency_code, 'CZK')
      easy_invoice_in_euro_currency.reload

      visit preview_easy_printable_template_path(easy_printable_template_tokens_check, entity_type: easy_invoice_in_euro_currency.class.to_s, entity_id: easy_invoice_in_euro_currency.id)

      expect(page).to have_text("total in supplier currency:")
      expect(page).not_to have_text(sprintf("%.2f", easy_invoice_in_euro_currency.total).to_s + " CZK")
    end
  end

  context 'default templates' do
    let(:easy_invoice_sequence) { FactoryGirl.create(:easy_invoice_sequence, format: 'ER-%y%-%3n%') }
    let(:easy_invoice) { FactoryGirl.create(:easy_invoice, easy_invoice_sequence: easy_invoice_sequence) }
    let(:attachment) { FactoryGirl.create(:attachment, container: easy_invoice) }

    it 'invoicing', skip: !Redmine::Plugin.installed?(:easy_invoicing) do
      tmpl = EasyInvoice.update_default_printable_template!
      attachment
      visit preview_easy_printable_template_path(tmpl, entity_type: easy_invoice.class.to_s, entity_id: easy_invoice.id)
      link_number = page.find("a[href='#{project_easy_invoice_path(easy_invoice.project, easy_invoice)}']")
      expect(link_number).to have_content(easy_invoice.number)
      expect(page.find('.totals')).to have_content(I18n.t(:field_easy_invoicing_subtotal))
      expect(page).to have_content(easy_invoice.payment_method.to_s)
    end
  end

  context 'print on issues' do
    let!(:project) { FactoryGirl.create(:project) }
    let(:easy_issue_query) { FactoryGirl.create(:easy_issue_query) }
    let(:document) { FactoryGirl.create(:document) }

    before(:each) { easy_printable_template }

    def open_print_dialog
      page.find('#sidebar_exports a.print').click
      wait_for_ajax
      expect(page).to have_css('#easy_printable_templates')
    end

    it 'switch orientation' do
      p = easy_printable_template.easy_printable_template_pages.first
      p.page_text = "%query_#{easy_issue_query.id}%"
      p.save
      visit preview_easy_printable_template_path(easy_printable_template.id)
      orientation = page.find('#pages_orientation')
      expect(page.text).not_to include('%query')
      orientation.find("option[value='landscape']").select_option
      wait_for_ajax
      expect(page).to have_css('#pages_orientation')
      expect(page.text).not_to include('%query')
    end

    it 'custom size' do
      visit preview_easy_printable_template_path(easy_printable_template.id, pages_size: 'custom')
      expect(page.find("#pages_size option[value='custom']")).to be_selected
    end

    it 'modal' do
      visit issues_path
      sidebar_closed = page.has_css?('.nosidebar')
      if sidebar_closed
        page.find(".sidebar-control > a").click
      end
      open_print_dialog
    end

    it 'modal with applied query' do
      visit issues_path(:query_id => easy_issue_query.id)
      sidebar_closed = page.has_css?('.nosidebar')
      if sidebar_closed
        page.find(".sidebar-control > a").click
      end
      open_print_dialog
    end

    it 'save to documents' do
      p = easy_printable_template.easy_printable_template_pages.first
      p.page_text = "%query_#{easy_issue_query.id}%"
      p.save
      document
      visit preview_easy_printable_template_path(easy_printable_template.id)
      wait_for_ajax
      page.find('.easy-printable-toolbar-container .icon-new-document').click
      wait_for_ajax
      expect(page).to have_css(".documents tr.document_#{document.id}")
    end
  end

  it 'index' do
    easy_printable_template
    visit easy_printable_templates_path(:set_filter => '1', :group_by => 'category_caption', :load_groups_opened => '1')
    wait_for_ajax
    expect(page).to have_css('.group', :count => 1)
    expect(page.find('.list td.name')).to have_content(easy_printable_template.name)
  end

end
