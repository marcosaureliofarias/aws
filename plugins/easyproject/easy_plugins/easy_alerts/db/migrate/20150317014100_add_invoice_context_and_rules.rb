class AddInvoiceContextAndRules < ActiveRecord::Migration[4.2]

  def self.up
    context = AlertContext.create!(:name => 'invoice')
    AlertRule.create!(:name => 'invoice_due_date', :context_id => context.id, :class_name => 'EasyAlerts::Rules::InvoiceDueDate', :position => 1)
    AlertRule.create!(:name => 'easy_invoice_query', :context_id => context.id, :class_name => 'EasyAlerts::Rules::EasyInvoiceQuery', :position => 2)
  end

  def self.down
  end
end