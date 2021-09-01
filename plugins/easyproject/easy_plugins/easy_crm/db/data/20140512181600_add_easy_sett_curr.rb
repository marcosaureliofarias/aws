# encoding: utf-8
class AddEasySettCurr < ActiveRecord::Migration[4.2]

  def self.up

    EasySetting.create :name => 'crm_currency', :value => 'EUR'
    EasySetting.create :name => 'crm_currency_rate', :value => '1'

  end

  def self.down

    EasySetting.where(:name => 'crm_currency').destroy_all
    EasySetting.where(:name => 'crm_currency_rate').destroy_all

  end

end
