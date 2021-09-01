class ChangeEasyLookupMultiple < ActiveRecord::Migration[4.2]

  def self.up
    CustomField.where(:field_format => 'easy_lookup').each do |cf|
      cf.settings['multiple'] ||= '1'
      cf.save!
    end
  end

  def self.down
  end

end