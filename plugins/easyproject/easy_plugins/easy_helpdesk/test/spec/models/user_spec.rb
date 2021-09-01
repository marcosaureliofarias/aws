require 'easy_extensions/spec_helper'

describe User, logged: true do

  context '#hide_sla_data?' do
    it 'admin', logged: :admin do
      expect(User.current.hide_sla_data?).to eq false
    end

    it 'based on pref' do
      with_user_pref(hide_sla_data: true) do
        expect(User.current.hide_sla_data?).to eq true
      end
    end

    it 'based on user type' do
      allow(User.current.easy_user_type).to receive(:easy_user_type_for?).with(:hide_sla_data).and_return(true)
      expect(User.current.hide_sla_data?).to eq true
    end
  end

end
