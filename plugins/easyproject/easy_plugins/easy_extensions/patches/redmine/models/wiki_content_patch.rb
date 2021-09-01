module EasyPatch
  module WikiContentPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do

        acts_as_user_readable

        html_fragment :text, :scrub => :strip

        include EasyExtensions::EasyInlineFragmentStripper
        strip_inline_images :text, :autosave => Proc.new { true }

        before_update :remove_nested_tables

        def remove_nested_tables
          if Setting.text_formatting == 'HTML'
            _text = Nokogiri::HTML.fragment(text)
            _text.search('th/table', 'td/table').each { |x| x.replace(x.search('td', 'th').inner_html) }

            self.text = _text.to_html
          end
        end

      end
    end

    module InstanceMethods

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'WikiContent', 'EasyPatch::WikiContentPatch'
