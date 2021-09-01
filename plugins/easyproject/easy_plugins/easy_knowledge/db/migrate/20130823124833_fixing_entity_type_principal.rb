class FixingEntityTypePrincipal < ActiveRecord::Migration[4.2]
  def up
    EasyKnowledgeCategory.where(:entity_type => 'User').update_all(:entity_type => 'Principal')
  end

  def down
  end
end
