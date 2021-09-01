module EasyExtensions
  module FieldFormats

    class EasyRating < Redmine::FieldFormat::IntFormat
      add 'easy_rating'

      self.form_partial = 'custom_fields/formats/easy_rating'

      attr_accessor :values

      def label
        :label_rating
      end

      def rating
        if @rating && @rating < 0
          0
        elsif @rating && @rating > 100
          100
        else
          @rating
        end
      end

      def get_value_from_params(value, id = nil)
        self.values ||= {}
        if value.is_a?(Hash)
          if id
            description = value['description'].to_s
            rating      = value['rating'].to_f

            self.values[id] = { rating: rating, description: description }
          end

          value['rating']
        end
      end

      def cast_single_value(custom_field, value, customized = nil)
        value.to_f
      end

      def formatted_value(view, custom_field, value, customized = nil, html = false)
        view.rating_stars(cast_single_value(custom_field, value, customized), custom_field.star_no, :no_html => !html)
      end

      def edit_tag(view, tag_id, tag_name, custom_value, options = {})
        sn = custom_value.custom_field.star_no
        s  = ActiveSupport::SafeBuffer.new
        if custom_value.customized.custom_value_for(custom_value.custom_field).user_already_rated?
          s << formatted_value(view, custom_value.custom_field, custom_value.value, custom_value.customized, !options[:no_html])
        else
          sn.times { |i| s << view.radio_button_tag(tag_name + '[rating]', i * (100 / (sn - 1)), false, :class => 'star {required: true}') }
          custom_value.value = nil
          s << view.content_tag(:p, :class => 'easy-rating-desc') do
            view.text_area_tag(tag_name + '[description]', '', :id => tag_id + '_description', :rows => 4, :cols => 50)
          end
        end

        s
      end

      def custom_value_before_save(custom_value)

        id = custom_value.custom_field_id.to_s

        if self.values.blank? || self.values[id].blank?
          rating      = nil
          description = nil
        else
          rating      = self.values[id][:rating]
          description = self.values[id][:description]
        end

        custom_value.easy_custom_field_ratings.build(
            :rating      => rating,
            :description => description,
            :user_id     => User.current ? User.current.id : nil
        )
        ratings = custom_value.easy_custom_field_ratings.collect(&:rating).compact

        if ratings.blank?
          custom_value.value = nil
        else
          custom_value.value = (ratings.sum / ratings.length).round
        end
      end

      def custom_value_after_save(custom_value)
        rating_values       = custom_value.customized.custom_values.where(CustomField.table_name => { :field_format => 'easy_rating' }).joins(:custom_field).to_a.collect(&:cast_value).compact
        global_rating       = custom_value.customized.easy_global_rating || EasyGlobalRating.new(:customized => custom_value.customized)
        global_rating_sum   = rating_values.inject { |sum, x| sum + x }
        global_rating.value = global_rating_sum ? (global_rating_sum / rating_values.length) : nil
        global_rating.save
      end

    end

  end
end
