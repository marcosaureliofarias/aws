class CleanDuplicatedTokensAndInsertApiAndFeedsToken < ActiveRecord::Migration[4.2]
  def self.up

    tokens2del = Token.where({ :value => '' }).to_a

    token_actions = Token.pluck(:action).uniq

    User.all.each do |user|
      token_actions.each do |token_action|
        user_toknes = Token.where({ :user_id => user.id, :action => token_action }).order('id ASC')
        if user_toknes.count > 1
          user_toknes[1..user_toknes.size].each do |t2d|
            tokens2del << t2d
          end
        end
      end
      #creating api token if not exists
      if !Token.where({ :user_id => user.id, :action => 'api' }).any?
        Token.create(:user => user, :action => 'api')
      end
      #creating feeds token if not exists
      if !Token.where({ :user_id => user.id, :action => 'feeds' }).any?
        Token.create(:user => user, :action => 'feeds')
      end
    end

    tokens2del.each { |t2d| t2d.delete }

  end

  def self.down

  end
end
