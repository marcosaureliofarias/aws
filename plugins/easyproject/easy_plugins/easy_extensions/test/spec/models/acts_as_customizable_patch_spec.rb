require "easy_extensions/spec_helper"

RSpec.describe "EasyPatch::ActsAsCustomizableInstanceMethodsPatch" do
  context "#277357" do

    describe "#save_custom_field_values_with_easy_extensions" do
      let(:tracker_bug) { FactoryBot.create(:tracker, name: "bug") }
      let(:tracker_feature) { FactoryBot.create(:tracker, name: "feature") }

      let(:cf_1) { FactoryBot.create(:issue_custom_field, name: "cf1", trackers: [tracker_bug]) }
      let(:cf_2) { FactoryBot.create(:issue_custom_field, name: "cf2", trackers: [tracker_bug]) }
      let(:cf_3) { FactoryBot.create(:issue_custom_field, name: "cf3", trackers: [tracker_feature]) }

      let(:cfv_params) { { cf_1.id => "x", cf_2.id => "y", cf_3.id => "z" } }

      let(:issue) { FactoryBot.create(:issue, tracker: tracker_bug, custom_field_values: cfv_params) }

      it "v05.00 function" do
        expect(CustomValue.count).to eq 0
        expect { issue }.to change(CustomValue, :count).by 2 # x, y

        expect { issue.update(tracker: tracker_feature, custom_field_values: cfv_params) }.to change(CustomValue, :count).by -1 # - x,y + z
        expect {
          issue.update(tracker: tracker_bug, custom_field_values: { cf_1.id => "a", cf_2.id => "e", cf_3.id => "i" })
        }.to change(CustomValue, :count).by 1 # -z, + a, e
        expect(CustomValue.pluck(:value)).to match_array %w[a e]

        expect { issue.update(tracker: tracker_feature, custom_field_values: cfv_params) }.to change(CustomValue, :count).by -1 # - x,y + z
        expect { issue.update(tracker: tracker_feature, custom_field_values: { cf_1.id => "x" }) }.not_to change(CustomValue, :count)
      end

      it "do not replace custom_values on customizable" do
        skip "Easy Query's group loading not work with this"
        expect(CustomValue.count).to eq 0
        expect { issue }.to change(CustomValue, :count).by 2

        expect { issue.update(tracker: tracker_feature, custom_field_values: cfv_params) }.to change(CustomValue, :count).by 1
        expect {
          issue.update(tracker: tracker_bug, custom_field_values: { cf_1.id => "a", cf_2.id => "e", cf_3.id => "i" })
        }.to change(CustomValue, :count).by 0
        expect(CustomValue.pluck(:value)).to match_array %w[a e z]
      end

    end
  end
end