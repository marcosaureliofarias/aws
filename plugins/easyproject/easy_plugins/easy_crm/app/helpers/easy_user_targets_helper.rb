module EasyUserTargetsHelper

  def select_options_by_entity(entity_type)
    collection = if entity_type == 'group'
                   Group.joins(:users).where(users_users: {status: User::STATUS_ACTIVE}).distinct.sorted.to_a
                 else
                   if entity_type && (entity = entity_type.classify.safe_constantize) # EasyUserType
                     entity.order(:position).to_a
                   else
                     []
                   end
                 end
    collection.collect { |t| [t.name, t.id.to_s] }
  end

  def prepare_user_targets_data
    months_in_quarter = fiscal_quarter_months(params[:date], params[:move])
    easy_user_targets = EasyUserTarget.where(user_id: @users, valid_from: months_in_quarter.first[:from]...months_in_quarter.last[:to])

    easy_user_target_map = Hash.new do |hash, key|
      hash[key] = Hash.new
    end
    easy_user_targets.each do |target|
      easy_user_target_map[target.user_id]["#{target.valid_from}-#{target.valid_to}"] = target
    end
    return { months_in_quarter: months_in_quarter, easy_user_target_map: easy_user_target_map }
  end

  def fiscal_quarter_months(date = nil, move = nil)
    date ||= Date.today
    date = date.to_date rescue Date.today
    date = date.send(move) if move.present?
    current_fiscal_quarter = EasyUtils::DateUtils.calculate_fiscal_quarter(date)

    months_in_quarter = []

    3.times do |i|
      months_in_quarter << {from: current_fiscal_quarter[:from].advance(months: i), to: current_fiscal_quarter[:from].advance(months: i).end_of_month}
    end
    months_in_quarter
  end

end
