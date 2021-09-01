require 'easy_extensions/spec_helper'

describe ApplicationHelper do
  describe '#easy_entity_replace_tokens' do
    # TODO
  end

  describe "#render_easy_entity_assignments" do
    # TODO
  end

  describe '#get_page_module_toggling_container_options' do
    let(:page_module) { double(settings: { 'easy_query_type' => 'EasyDocument', 'name' => 'main documents' }, new_on_page: false) }
    let(:module_definition) { double }
    before do
      allow(page_module).to receive(:module_definition).and_return(module_definition)
      allow(module_definition).to receive(:translated_name).and_return('Trends')
      allow(module_definition).to receive(:page_module_toggling_container_options_helper_method).and_return(nil)
    end

    context 'edit' do
      it 'heading format should be #module_name: #heading' do
        heading    = "<span>Trends: <span class='small'>main documents</span></span>"
        tc_options = helper.get_page_module_toggling_container_options(page_module, { edit: true })

        expect(tc_options[:heading]).to eq(heading)

        # heading should have title
        expect(tc_options[:heading_title]).to eq(I18n.t("easy_query.name.easy_document"))
      end

      it 'create new' do
        allow(page_module).to receive(:settings).and_return({})
        tc_options = helper.get_page_module_toggling_container_options(page_module, { edit: true })

        expect(tc_options[:heading]).to eq(nil)

        # heading should have title
        expect(tc_options[:heading_title]).to eq(nil)
      end
    end

    context 'show' do
      it 'heading format should be #heading' do
        expect(helper.get_page_module_toggling_container_options(page_module, {})[:heading]).to eq('<span>main documents</span>')
      end
    end
  end
end
