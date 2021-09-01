class MigrateOldTypesSprintRelations < ActiveRecord::Migration[4.2]

  TYPE_BACKLOG     = :backlog
  TYPE_DONE        = :done
  #TO DEL
  TYPE_NEW         = :new
  TYPE_REALIZATION = :realization
  TYPE_TO_CHECK    = :to_check
  #NEW
  TYPE_PROGRESS    = :progress
 
  OLD_TYPES = ActiveSupport::OrderedHash[{
    TYPE_BACKLOG      => 1,
    TYPE_NEW          => 2,
    TYPE_REALIZATION  => 3,
    TYPE_TO_CHECK     => 4,
    TYPE_DONE         => 5
  }]



  def up
    IssueEasySprintRelation.all.each do |rel|
      case rel.relation_type
      when OLD_TYPES[TYPE_NEW], OLD_TYPES[TYPE_REALIZATION], OLD_TYPES[TYPE_TO_CHECK]
        rel.relation_position = rel.relation_type - 1
        rel.relation_type = TYPE_PROGRESS
      when OLD_TYPES[TYPE_DONE]
        rel.relation_type = TYPE_DONE
      when OLD_TYPES[TYPE_BACKLOG]
        rel.relation_type = TYPE_BACKLOG
      end
      rel.save
    end
  end

  def down
  end
end
