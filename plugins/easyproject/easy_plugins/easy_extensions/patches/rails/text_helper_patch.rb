require 'nokogiri'

module EasyPatch
  module TextHelperPatch

    def self.included(base)

      base.class_eval do

        # https://gist.github.com/jrochkind/3893745
        def nokogiri_truncate(node, max_length, omission = '...', seperator = nil)
          om = Nokogiri::HTML::DocumentFragment.parse(omission)
          if node.kind_of?(::Nokogiri::XML::Text)
            if node.content.length > max_length
              allowable_endpoint = [0, max_length - omission.length].max
              if seperator
                allowable_endpoint = (node.content.rindex(seperator, allowable_endpoint) || allowable_endpoint)
              end

              content = ::Nokogiri::XML::Text.new(node.content.slice(0, allowable_endpoint), node.parent)
              span    = ::Nokogiri::XML::Node.new 'span', node
              span.add_child(content)
              span.add_child(om)
              span
            else
              node.dup
            end
          else # DocumentFragment or Element
            return node if node.inner_text.length <= max_length

            truncated_node = node.dup
            truncated_node.children.remove
            remaining_length = max_length

            node.children.each do |child|
              if remaining_length == 0
                truncated_node.add_child(om)
                break
              elsif remaining_length < 0
                break
              end
              truncated_node.add_child nokogiri_truncate(child, remaining_length, omission, seperator)
              remaining_length = remaining_length - child.inner_text.length
            end
            truncated_node
          end
        end

        def truncate_html(text, max_length, omission = '...')
          omission_length = omission.length
          doc             = Nokogiri::HTML::DocumentFragment.parse(text)
          content_length  = doc.inner_text.length
          actual_length   = max_length - omission_length

          if content_length > actual_length
            nokogiri_truncate(doc, actual_length, omission).delete_empty_node.inner_html.html_safe
          else
            text.to_s.html_safe
          end
        end

      end
    end
  end

  module NokogiriTruncator
    module NodeWithChildren
      def truncate(max_length)
        return self if inner_text.length <= max_length
        truncated_node = self.dup
        truncated_node.children.remove

        self.children.each do |node|
          node.remove and next if node.is_a?(Nokogiri::XML::ProcessingInstruction)
          remaining_length = max_length - truncated_node.inner_text.length

          if remaining_length <= 0
            self.children.remove
            break
          end
          truncated_node.add_child node.truncate(remaining_length)
        end
        truncated_node
      end

      def delete_empty_node
        self.children.each do |child|
          child.remove and next if child.is_a?(Nokogiri::XML::ProcessingInstruction)
          if child.inner_text.blank?
            if child.parent.children.count > 1
              child.remove
            else
              child.parent.remove
            end
          else
            child.delete_empty_node
          end
        end

        return self
      end
    end

    module TextNode
      def truncate(max_length)
        Nokogiri::XML::Text.new(content.first(max_length - 1), parent)
      end

      def delete_empty_node
        return self
      end
    end

  end

end
EasyExtensions::PatchManager.register_rails_patch ['Nokogiri::HTML::DocumentFragment', 'Nokogiri::XML::Element', 'Nokogiri::XML::Comment'], 'EasyPatch::NokogiriTruncator::NodeWithChildren'
EasyExtensions::PatchManager.register_rails_patch 'Nokogiri::XML::Text', 'EasyPatch::NokogiriTruncator::TextNode'

EasyExtensions::PatchManager.register_rails_patch 'ActionView::Helpers::TextHelper', 'EasyPatch::TextHelperPatch'
