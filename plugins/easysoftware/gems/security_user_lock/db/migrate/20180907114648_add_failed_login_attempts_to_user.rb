class AddFailedLoginAttemptsToUser < RedmineExtensions::Migration
  def self.up
    add_column :users, :failed_login_attempts, :integer, null: false, default: 0
    add_column :users, :blocked_at, :datetime, default: nil
  end

  def self.down
  end
end
