class CreateVersionForOldStory < ActiveRecord::Migration[4.2]
  def up
    say_with_time 'Please wait. Creating the first version of all stories. This will take a moment...' do
      EasyKnowledgeStory.find_each(batch_size: 200) {|s|
        if s.version.nil?
          s.update_column(:version, 1)
          s.send(:create_version)
        end
      }
    end
  end

  def down
  end
end

