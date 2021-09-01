class MigrateEasyUserTypes < ActiveRecord::Migration[4.2]
  def self.up
    unless EasyUserType.any?
      rejected         = [:administration, :sign_out, :user_profile]
      default_settings = EasyUserType.available_settings.values.flatten.reject! { |s| rejected.include?(s) }
      EasyUserType.create(:id => 1, :name => 'Internal', :is_default => true, :position => 1, :internal => true, :settings => default_settings)
      EasyUserType.create(:id => 2, :name => 'External', :is_default => false, :position => 2, :internal => false, :settings => default_settings)
    end
  end

  def self.down
    EasyUserType.delete_all
  end
end
