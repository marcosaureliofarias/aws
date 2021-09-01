class EasyIssueAllocator < ActiveRecord::Base

  validates_inclusion_of :allocator, in: EasyGanttResources.allocators

end
