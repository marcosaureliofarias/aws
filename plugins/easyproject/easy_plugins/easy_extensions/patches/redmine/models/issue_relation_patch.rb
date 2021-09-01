module EasyPatch
  module IssueRelationPatch
    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
      base.class_eval do

        const_set(:NOT_COPIED_RELATIONS, [IssueRelation::TYPE_COPIED_TO, IssueRelation::TYPE_COPIED_FROM])

        const_set(:EASY_TYPES,
                  {
                      IssueRelation::TYPE_PRECEDES => { :name  => :label_preceding, :sym_name => :label_following,
                                                        :order => 6, :sym => IssueRelation::TYPE_FOLLOWS },
                      IssueRelation::TYPE_FOLLOWS  => { :name  => :label_following, :sym_name => :label_preceding,
                                                        :order => 7, :sym => IssueRelation::TYPE_PRECEDES, :reverse => IssueRelation::TYPE_PRECEDES }
                  }
        )

        alias_method_chain :label_for, :easy_extensions

        define_method(:'<=>_with_easy_extensions') do |relation|
          r = IssueRelation::TYPES[self.relation_type][:order] <=> IssueRelation::TYPES[relation.relation_type][:order]
          if r == 0
            if self.id.nil?
              1
            elsif relation.nil? || relation.id.nil?
              -1
            else
              self.id <=> relation.id
            end
          else
            r
          end
        end
        alias_method_chain :<=>, :easy_extensions

      end
    end

    module InstanceMethods

      def label_for_with_easy_extensions(issue)
        if IssueRelation::EASY_TYPES[relation_type]
          IssueRelation::EASY_TYPES[relation_type][(self.issue_from_id == issue.id) ? :name : :sym_name]
        else
          label_for_without_easy_extensions(issue)
        end
      end

    end

    module ClassMethods

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'IssueRelation', 'EasyPatch::IssueRelationPatch'
