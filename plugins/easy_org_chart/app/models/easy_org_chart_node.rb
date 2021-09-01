class EasyOrgChartNode < ActiveRecord::Base

  include Redmine::NestedSet::IssueNestedSet

  belongs_to :user

  validates :user_id, uniqueness: true

  scope :without_user, -> user_id {
    where.not(user_id: user_id)
  }

  class << self
    def create_nodes!(params = {})
      transaction do
        delete_all
        create_from_hash!(params.presence || {})
        EasyOrgChart::Tree.clear_cache
      end
    end

    private

    def create_from_hash!(hash = {}, parent = nil)
      return if hash.empty?

      user = GlobalID.find(hash['id'])
      raise ActiveRecord::Rollback.new("Invalid user with GID #{hash['id']}") unless user

      node = create!(user: user, parent: parent)

      children = hash['children'].presence || {}
      children.each_value do |child|
        create_from_hash! child, node
      end

      node
    end
  end
end
