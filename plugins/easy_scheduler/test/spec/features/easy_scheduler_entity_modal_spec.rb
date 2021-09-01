require_relative '../spec_helper'

# feature 'Scheduler entity modal', logged: :admin, js: true do
#   include_context 'scheduler entity modal stuff'
#   around(:each) do |example|
#     with_settings(rest_api_enabled: 1) { example.run }
#   end
# 
#   describe 'available tabs' do
#     it_behaves_like 'scheduler modal', 'meeting', Date.today, '08:00', '11:00'
#     it_behaves_like 'scheduler modal', 'allocation', Date.today, '08:00', '11:00'
#     it_behaves_like 'scheduler modal', 'easy_attendance', Date.today, '08:00', '11:00'
#     it_behaves_like 'scheduler modal', 'easy_entity_activity', Date.today, '08:00', '11:00'
#   end
# 
#   describe 'allocation modal' do
#     include_context 'allocation stuff'
# 
#     it 'create allocation:success' do
#       expect(create_allocation('2018-05-14', '2018-05-18', '2018-05-15', '08:00', '10:00')).to exist
#     end
# 
#     it 'create allocation:failed' do
#       create_allocation('2018-05-14', '2018-05-18', '2018-05-19', '08:00', '10:00')
#       error = /Allocation is projected out of issue duration/
#       expect(find('#calendar_modal')).to have_css('.easy-calendar__modal_flash.easy-calendar__modal_flash--error', text: error)
#     end
#   end
# 
#   describe 'sales activity modal' do
#     include_context 'sales activity stuff'
# 
#     it 'default entity, reload entity' do
#       expect(find_field('CRM case')).to be_checked
# 
#       choose_entity('Contact')
#       expect(find('p.easy-scheduler-activity-entity-id')).to have_css('label', text: 'Contact')
#     end
# 
#     it 'reload contacts from crm case' do
#       contact = FactoryGirl.create(:easy_contact)
#       crm_case = FactoryGirl.create(:easy_crm_case, easy_contacts: Array.wrap(contact))
#       select_entity(crm_case)
#       expect(find('p.easy-scheduler-contacts-attendees')).to have_css('.entity-array span', text: contact.name)
#     end
# 
#     it 'reload contacts from contact' do
#       contact = FactoryGirl.create(:easy_contact, :personal)
#       choose_entity('Contact')
#       select_entity(contact)
#       expect(find('p.easy-scheduler-contacts-attendees')).to have_css('.entity-array span', text: contact.name)
#     end
# 
#     it 'create sales activity:entity exists' do
#       expect(sales_activity = create_sales_activity).to exist
# 
#       expect(page).to have_css('.dhx_cal_event.easy-calendar__entity-activity')
# 
#       event = page.find('.dhx_cal_event.easy-calendar__entity-activity')
#       expect(event).to have_text(sales_activity.last.entity.name)
# 
#       expect(event).to have_text('1h')
#     end
#   end
# 
#   describe 'calendar event' do
#     it_behaves_like 'scheduler event', 'meeting', Date.today, '08:00', '11:25', 'easy-calendar__meeting'
#     it_behaves_like 'scheduler event', 'allocation', Date.today, '08:00', '11:00', 'easy-calendar__issue'
#     it_behaves_like 'scheduler event', 'easy_attendance', Date.today, '08:00', '11:00', 'easy-calendar__attendance'
#     it_behaves_like 'scheduler event', 'easy_entity_activity', Date.today, '08:00', '11:00', 'easy-calendar__entity-activity'
#   end
# 
#   describe 'all-day event' do    
#     it_behaves_like 'all-day from month view', 'meeting', Date.today
#     it_behaves_like 'all-day from month view', 'allocation', Date.today
#     it_behaves_like 'all-day from month view', 'easy_attendance', Date.today
#     it_behaves_like 'all-day from month view', 'easy_entity_activity', Date.today   
#   end
# end
