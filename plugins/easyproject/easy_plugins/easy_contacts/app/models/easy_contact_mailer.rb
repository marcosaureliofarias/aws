class EasyContactMailer < EasyMailer

  include EasyContactsHelper

  def send_contacts(contacts, recipients)
    @contacts, @user = contacts, User.current
    attachments["#{l(:label_easy_contacts)}.vcf"] = vcard_export(contacts)
    mail :to => recipients, :subject => l(:title_easy_contact_mailer, :contact_name => @contacts.collect(&:name).join(', '))
  end

end
