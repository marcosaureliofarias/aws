module EasyEntityImports
  class EasyIssueXmlImportMolMsProject < EasyEntityXmlImport

    attr_reader :entities, :unsaved, :relations, :map, :non_save_relation2

    def entity_type
      'Issue'
    end

    def get_available_entity_types
      []
    end

    def assignable_entity_columns
      return @assignable_entity_columns if @assignable_entity_columns.present?

      @assignable_entity_columns = AvailableColumns.new
      @assignable_entity_columns << EasyEntityImportAttribute.new('id', required: false)
      %w(subject project_id author_id tracker_id priority_id status_id).each do |col|
        @assignable_entity_columns << EasyEntityImportAttribute.new(col, required: self.required_attribute?(required_column_names, col))
      end

      %w(assigned_to_id start_date due_date estimated_hours is_private fixed_version_id done_ratio category_id description parent_id easy_external_id).each do |col|
        @assignable_entity_columns << EasyEntityImportAttribute.new(col, required: self.required_attribute?(required_column_names, col))
      end
      IssueCustomField.find_each do |cf|
        @assignable_entity_columns << EasyEntityImportAttribute.new(cf.name, required: cf.is_required?, title: cf.translated_name)
      end

      %w(id name).each do |col|
        @assignable_entity_columns << EasyEntityImportAttribute.new(col, required: true, assoc: :project)
      end

      %w(easy_start_date easy_due_date author_id status parent_id description is_public).each do |col|
        @assignable_entity_columns << EasyEntityImportAttribute.new(col, assoc: :project, required: self.required_attribute?(required_column_names, col))
      end

      IssueCustomField.find_each do |cf|
        @assignable_entity_columns << EasyEntityImportAttribute.new(cf.name, required: cf.is_required?, title: cf.translated_name, assoc: :project)
      end


      @assignable_entity_columns
    end

    # def process_preview_file
    #   binding.pry
    # end

    def import(file = nil)

      if file
        @xml = Nokogiri::XML.parse(file.try(:read) || file)
      end
      #  tree
      # 1 - root
      # 1.1 -parent
      # 1.1.1 -sub
      # 1.2 - parent
      # 1.2.1 - sub
      # 1.3 - parent
      # ["0",
      # "1",
      # "1.1",
      # "1.1.1",
      # "1.2",
      # "1.2.1",
      # "1.3",
      # "1.3.1",
      # "1.4",
      # "1.4.1",
      # "1.5",
      # "1.5.1",
      # "1.5.1.1",
      # "1.5.2",
      # "1.5.2.1",
      # "1.5.3",
      # "1.5.3.1",
      # "1.5.3.1.1",
      # "1.5.3.1.1.1",
      # "1.5.3.1.1.1.1",
      # "1.5.3.1.1.1.2",
      @tree = {}

      defaults = {
          priority: IssuePriority.default,
          trackers: {
              5 => Tracker.find(20),
              6 => Tracker.find(1),
              7 => Tracker.find(21)
          }
      }

      users
      root                = Project.find_by(id: 57)
      @map                = { 1 => root, '1' => root } # (Issue.where.not(easy_external_id: nil) + Project.where.not(easy_external_id: nil)).inject({}) { |mem, var| mem[var.easy_external_id.to_s] = var; mem }
      User.current.admin  = true
      @entities, @unsaved = [], []
      @relations          = []
      # EasyMailer.with_deliveries(false) do
      @xml.xpath('//xmlns:Task').each do |node|
        uid      = read(node, 'UID')
        level    = read(node, 'OutlineLevel').to_i
        name     = read(node, 'Name')
        wbs_code = read(node, 'WBS')
        indexies = read(node, 'OutlineNumber').split('.')
        parent   = find_parent(indexies)
        entity   = @map[uid]
        if level <= 4
          # its project
          entity                     ||= Project.new(name: name, easy_start_date: read(node, 'Start'), easy_due_date: read(node, 'Finish'))
          entity.parent              = parent if parent.is_a?(Project)
          entity.custom_field_values = { '107' => wbs_code }
        else
          # its task
          # entity.assigned_to_id = @users[@xml.xpath("//xmlns:Assignment[xmlns:TaskUID = #{uid}]/xmlns:ResourceUID").text.strip.presence]

          entity ||= Issue.new(project: parent.project)
          unless entity.new_record?
            entity.init_journal(User.current)
          end
          entity.subject    = name
          entity.tracker    = defaults[:trackers][level]
          entity.priority   = defaults[:priority]
          entity.status     = entity.default_status
          entity.start_date = read(node, 'Start')
          entity.due_date   = read(node, 'Finish')
          entity.parent if parent.is_a?(Issue)
          entity.custom_field_values = { '106' => wbs_code }

          # est = read(node, 'Work')

          # entity.estimated_hours = est.to_s[/[\dH]+M/].to_hours

        end
        entity.author = User.current

        entity.easy_external_id = "#{Date.today}_#{uid}"

        @tree[indexies.join('-')] = entity
        begin
          if entity.save(validate: false)
            parent && entity.update_columns(parent_id: parent.id)
            @entities << entity
            @map.store(uid, entity)
            duplicate_precedes_to = []
            if entity.is_a?(Issue)
              issue_estimated_hours = node.xpath('xmlns:ExtendedAttribute[xmlns:FieldID = 188743737]/xmlns:Value/text()').to_s.to_f
              coeficient            = xml.xpath("//xmlns:Assignment[xmlns:TaskUID = #{uid}]/xmlns:Units/text()").inject(0.0) { |mem, var| mem += var.to_s.to_f; mem } * 100
              assignables           = Array(xml.xpath("//xmlns:Assignment[xmlns:TaskUID = #{uid}]")).inject({}) do |mem, var|
                resource_uid              = read(var, 'ResourceUID')
                unit                      = read(var, 'Units').to_f * 100
                mem[@users[resource_uid]] ||= 0.0
                mem[@users[resource_uid]] += (unit / coeficient * issue_estimated_hours)
                mem
              end
              # issue_estimated_hours = read(node, 'Work').to_s[/[\dH]+M/].to_hours
              # binding.pry
              if assignables.size < 2
                entity.assigned_to_id  = assignables.keys.first
                entity.estimated_hours = (entity.assigned_to && assignables.values.first) || issue_estimated_hours
                entity.save(validate: false)
              else
                init_user_id, init_hours = assignables.shift
                entity.assigned_to_id    = init_user_id
                entity.estimated_hours   = (entity.assigned_to && init_hours) || issue_estimated_hours
                entity.save(validate: false)
                assignables.each do |user_id, hours|
                  key  = "#{uid}_#{user_id}"
                  copy = @map[key] || entity.dup
                  unless copy.new_record?
                    copy.init_journal(User.current)
                  end
                  copy.assigned_to_id  = user_id
                  copy.estimated_hours = hours
                  copy.save(validate: false)
                  if @map[key].nil?
                    @map.store(key, copy)
                    @entities << copy
                    relation               = IssueRelation.new
                    relation.issue_from    = copy
                    relation.issue_to      = entity
                    relation.relation_type = 'relates'
                    unless relation.save
                      @non_save_relation << relation
                    end
                    duplicate_precedes_to << copy
                  end
                end
              end
            end
            Array(node.xpath('xmlns:PredecessorLink/xmlns:PredecessorUID/text()')).each do |preced|
              @relations << { from: preced.text, to: uid, type: 'precedes', duplicate_precedes_to: duplicate_precedes_to }
            end

          else
            @unsaved << entity
          end
        rescue StandardError => e
          @unsaved << entity
          # binding.pry
        end
      end
      @non_save_relation  = []
      @non_save_relation2 = []
      @relations.each do |r|
        if r[:from] && r[:to] && (from = @map[r[:from]].presence) && (to = @map[r[:to]].presence)
          # if from.start_date == to.start_date
          #   r[:type] = 'relates'
          # end
          relation       = IssueRelation.new; relation.issue_from = from; relation.issue_to = to; relation.relation_type = r[:type]
          delay          = (relation.issue_to.reload.start_date - relation.issue_from.reload.due_date).to_f
          relation.delay = (delay - 1) #(delay.zero? ? 0 : (delay - 1))
          begin
            relation.save!
            r[:duplicate_precedes_to].each do |issue|
              rel          = relation.dup
              rel.issue_to = issue
              rel.save(validate: false)
            end
          rescue ActiveRecord::RecordNotSaved
            @non_save_relation << relation
          rescue ActiveRecord::RecordInvalid
            # already taken
          end
        end
      end

      @non_save_relation.each do |relation|
        relation.issue_from.reload
        relation.issue_to.reload
        begin
          relation.save!
        rescue ActiveRecord::RecordNotSaved
          @non_save_relation2 << relation
        end
      end
      Issue.where.not(parent_id: nil).find_each { |i| i.parent.nil? && i.update_column(:parent_id, nil) }
      Issue.rebuild_tree!
      Project.rebuild_tree!
      @non_save_relation3 = []
      @non_save_relation2.each do |relation|
        relation.relation_type = 'relates'
        begin
          relation.save!
        rescue ActiveRecord::RecordNotSaved
          @non_save_relation3 << relation
        end
      end

      custom_field = CustomField.find 94
      custom_field.ensure_custom_field_values
      custom_field.recompute_computed_token_values
      @non_save_relation3
      # end

    end

    def users
      @unsaved_users = []
      @users_by_mail = {}
      @users         = {}
      EmailAddress.where(is_default: true).select(:address, :user_id).each do |var|
        @users_by_mail[var.address] = var.user_id
      end

      @xml.xpath('//xmlns:Resource').each do |node|
        uid                   = read(node, 'UID')
        first_name, last_name = read(node, 'Name').split(' ')
        mail                  = read(node, 'EmailAddress').presence
        next if mail.blank?
        next if first_name.blank?
        if (user_id = @users_by_mail[mail])
          @users.store uid, user_id
          next
        end
        if @users[uid]
          @users_by_mail[mail] ||= @users[uid]
          next
        end
        user                  = User.new
        user.firstname        = first_name
        user.lastname         = last_name
        user.mail             = mail
        user.login            = user.mail.split('@').first
        user.password         = 'molmol'
        user.easy_external_id = "#{Date.today}_#{uid}"
        if user.save(validate: false)
          @users.store uid, user.id
          @users_by_mail[mail] ||= user.id
        else
          puts user.errors.full_messages.join('; ')
          @unsaved_users << user
        end
      end

      @users
    end


    private

    def create_issue(issue)

    end

    def find_parent(indexies)
      parent_index = indexies[0..(indexies.size - 2)].join('-')
      @tree[parent_index]
    end

    def read(node, attribute)
      (obj = node.at_xpath("xmlns:#{attribute}")) && obj.text.strip || ''
    end

  end
end
# require "./easy_issue_xml_import_mol_ms_project.rb"
# x = EasyEntityImports::EasyIssueXmlImportMolMsProject.new
# r = x.import(File.open('./tmp/Sample.xml'))
