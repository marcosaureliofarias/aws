RSpec::Matchers.define :responds_to_each do |expected|
  match do |actual|
    actual.respond_to?(:each) == true
  end
end

RSpec.describe "Hotkeys translations consistence" do
  curr_path = File.expand_path('../../../config/locales', __FILE__)
  locales = Dir.glob("#{curr_path}/*.yml").map{ |filename| File.basename(filename, '.*').to_sym }

  locales.each do |locale|
    context "locale: #{locale}" do
      before(:each) do
        I18n.locale = locale
      end

      it "keyboard_data" do
        keyboard_data = I18n.t(:keyboard, scope: [:easy_mindmup, :hotkeys])
        expect(keyboard_data).to responds_to_each
        keyboard_data.each do |group|
          expect(group[:hotkeys]).to responds_to_each
        end
      end

      it "mouse_data" do
        mouse_data = I18n.t(:mouse, scope: [:easy_mindmup, :hotkeys])
        expect(mouse_data).to responds_to_each
      end
    end
  end
end

