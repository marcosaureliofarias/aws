module EasyExtensions
  module PasswordNotification
    include Redmine::I18n

    def self.invalid
      warning = []

      warning << l('label_password_must_include.number') if EasySetting.value('passwd_constrains_number')
      warning << l('label_password_must_include.big_letter') if EasySetting.value('passwd_constrains_big_letter')
      warning << l('label_password_must_include.small_letter') if EasySetting.value('passwd_constrains_small_letter')
      warning << l('label_password_must_include.special_character') if EasySetting.value('passwd_constrains_special_character')

      warning.empty? ? '' : "#{l('label_password_must_include.must_include')}: #{warning.join(', ')}."
    end

  end
end
