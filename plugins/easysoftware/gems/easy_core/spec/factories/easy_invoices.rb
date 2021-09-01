FactoryBot.define do

  factory :easy_invoice_document, class: "EasyInvoice" do
    association :project, factory: :project, enabled_module_names: ['easy_invoicing']
    association :status, factory: :easy_invoice_status
    association :payment_method, factory: :easy_invoice_payment_method
    association :easy_invoice_sequence, factory: :easy_invoice_sequence
    client_name { 'Test client' }
    client_street { 'Some street 3' }
    client_city { 'Some city on Vltava' }
    client_postal_code { '00 000' }
    client_country { 'GB' }
    supplier_name { 'Test supplier' }
    supplier_street { 'Some street 3' }
    supplier_city { 'Some city on Vltava' }
    supplier_postal_code { '00 000' }
    supplier_country { 'GB' }
    taxable_fulfillment_due_at { Date.new(2016, 1, 1) }

    factory :easy_invoice_with_line_items do
      transient do
        easy_invoice_line_item_count { 1 }
      end

      after(:create) do |easy_invoice, evaluator|
        create_list(:easy_invoice_line_item, evaluator.easy_invoice_line_item_count, easy_invoice: easy_invoice)
      end

    end
  end

  factory :easy_invoice, parent: :easy_invoice_document do
  end

  factory :easy_invoice_template, parent: :easy_invoice do
    is_template { true }
  end

  factory :easy_invoice_proforma, class: "EasyInvoiceProforma", parent: :easy_invoice do
  end

  factory :easy_invoice_credit_note, class: "EasyInvoiceCreditNote", parent: :easy_invoice do
    after(:create) do |easy_invoice_cn, _evaluator|
      FactoryBot.create(:easy_invoice, project: easy_invoice_cn.project, easy_invoice_credit_note_id: easy_invoice_cn.id)
    end
  end

  factory :easy_invoice_sequence do
    sequence(:name) { |n| "Invoice sequence ##{n}" }
    format { '%y%%3n%' }
  end

  factory :easy_invoice_status do
    sequence(:name) { |n| "Invoice status ##{n}" }
  end

  factory :easy_invoice_payment_method do
    sequence(:name) { |n| "Invoice PM ##{n}" }
  end

  factory :invoice_custom_field, parent: :custom_field, class: 'EasyInvoiceCustomField'

  factory :easy_invoice_line_item do
    association :easy_invoice, factory: :easy_invoice_document
    name { 'item' }
    unit_price { 5 }
    quantity { 1 }
    vat_rate { 20 }
    unit_name { 'test' }
    with_vat { false }
  end

end  if defined?(EasyInvoice)

