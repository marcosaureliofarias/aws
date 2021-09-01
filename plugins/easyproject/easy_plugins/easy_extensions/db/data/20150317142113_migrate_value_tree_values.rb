class MigrateValueTreeValues < ActiveRecord::Migration[4.2]
  def up
    # There is format changing
    #
    # Possible values:
    # Value1
    # > Other
    # Value2
    # > Other
    #
    # Old saved value: "> Other"
    # New saved value: "Value2 > Other"
    #
    CustomField.where(field_format: 'value_tree').each do |cf|
      old_possible_values = cf.possible_values.dup

      cf.format.before_custom_field_save(cf)
      cf.save!

      # old key => new key
      old_new_possible_values = Hash[old_possible_values.zip(cf.possible_values)]

      cf.custom_values.each do |cv|
        cv.value = old_new_possible_values[cv.value].to_s
        cv.save!
      end
    end
  end

  def down
  end
end
