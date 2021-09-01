require 'easy_extensions/spec_helper'

RSpec.describe EasyQueryCurrencyColumn do

  it 'does something' do
    query = EasyQuery.new

    # To bypass checking if a currency exists
    query.write_attribute(:easy_currency_code, 'EUR')

    column = described_class.new(:price, sortable: 'table.price', query: query)
    allow(Redmine::Database).to receive(:postgresql?) { true }

    should_be = EasyQuery.connection.quote_column_name('table') +
                '.' +
                EasyQuery.connection.quote_column_name('price_EUR')

    expect(column.sortable).to eq(should_be)
  end

end
