class CreateEasyContactEntityAssignments < ActiveRecord::Migration[4.2]
  def self.up
    create_table :easy_contact_entity_assignments do |t|
      t.integer :easy_contact_id, :null => false
      t.references :entity, :polymorphic => true
      t.timestamps
    end
    say_with_time 'Transfer contacts from old groups to projects or users' do
      EasyContactGroup.all.select{|i| !i.easy_contacts.blank?}.each do |ecg|
        ecg.entity.easy_contacts = ecg.easy_contacts unless ecg.entity.nil?
      end
    end
    say_with_time 'Destroy blank or unused groups' do
      EasyContactGroup.where(:parent_id => nil).delete_all
    end

    execute "DELETE FROM easy_contacts_group_assignments WHERE easy_contacts_group_assignments.group_id NOT IN (SELECT id FROM easy_contacts_groups)"

    say_with_time 'Transfer remaining undergroups to root groups' do
      EasyContactGroup.all.each do |ecg|
        ecg.move_to_root
      end
    end
  end

  def self.down
    drop_table :easy_contact_entity_assignments
  end
end
