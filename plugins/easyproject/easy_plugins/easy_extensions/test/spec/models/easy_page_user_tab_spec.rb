require "easy_extensions/spec_helper"
RSpec.describe EasyPageUserTab do

  let(:easy_page) { EasyPage.find 1 }
  let!(:page_module) { FactoryBot.create(:easy_page_zone_module, easy_pages_id: easy_page.id, user_id: nil) }

  describe "#copy!" do
    it "just copy" do
      t       = EasyPageUserTab.add(easy_page, nil, nil, name: "tab 1")
      new_tab = nil
      expect { new_tab = t.copy! }.to change(EasyPageUserTab, :count).by 1
      expect(new_tab.name).to eq "tab 2"
    end

    it "check position shifting" do
      t1      = EasyPageUserTab.add(easy_page, nil, nil, name: "tab 1", position: 1)
      t2      = EasyPageUserTab.add(easy_page, nil, nil, name: "tab 2", position: 2)
      new_tab = nil
      expect { new_tab = t1.copy! }.to change(EasyPageUserTab, :count).by 1
      expect(new_tab.position).to eq 2
      expect(EasyPageUserTab.order(:position).pluck(:position)).to eq [1, 2, 3]
    end
  end

  it "#copy_modules_to" do
    t1 = EasyPageUserTab.add(easy_page, nil, nil, name: "tab 1")
    t2 = EasyPageUserTab.add(easy_page, nil, nil, name: "tab 2")
    expect { t2.copy_modules_to(t2) }.to change(EasyPageZoneModule, :count)
  end
end