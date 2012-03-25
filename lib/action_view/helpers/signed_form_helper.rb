module ActionView
  module Helpers

    module SignedFormBuilder

      def field_list
        @field_list ||= []
      end

      # Use this method to allow "raw" parameters
      def allow_parameters(*params)
        @field_list ||= []
        @field_list += params.map { |p| p.to_s }
      end

      # Use this method to allow fields on this form builder.
      def allow_fields(*fields)
        params = fields.map { |f| "#{object_name}[#{f}]" }
        allow_parameters *params
      end

      def form_signature
        field_list_csv = field_list.join(',')
        "<input type=\"hidden\" name=\"form_signature\" value=\"#{field_list_csv}\" />".html_safe
      end
    end

    module FormHelper
      # Implementation note: monkey-patching fields_for and form_for here
      # seems ugly.  Ideas?

      def fields_for(record_name, record_object = nil, options = {}, &block)
        builder = instantiate_builder(record_name, record_object, options, &block)
        output = capture(builder, &block)
        output.concat builder.hidden_field(:id) if output && options[:hidden_field_id] && !builder.emitted_hidden_id?

        # patch to pass the field_list up to parent builder
        if builder.respond_to?(:field_list) && pb = options[:parent_builder]
          pb.allow_parameters(*(builder.field_list))
        end

        output
      end

      def form_for(record, options = {}, &proc)
        raise ArgumentError, "Missing block" unless block_given?

        options[:html] ||= {}

        case record
        when String, Symbol
          object_name = record
          object      = nil
        else
          object      = record.is_a?(Array) ? record.last : record
          object_name = options[:as] || ActiveModel::Naming.param_key(object)
          apply_form_for_options!(record, options)
        end

        options[:html][:remote] = options.delete(:remote) if options.has_key?(:remote)
        options[:html][:method] = options.delete(:method) if options.has_key?(:method)
        options[:html][:authenticity_token] = options.delete(:authenticity_token)

        builder = options[:parent_builder] = instantiate_builder(object_name, object, options, &proc)
        fields_for = fields_for(object_name, object, options, &proc)
        default_options = builder.multipart? ? { :multipart => true } : {}
        output = form_tag(options.delete(:url) || {}, default_options.merge!(options.delete(:html)))
        output << fields_for

        # patch to insert the form sigature
        output << builder.form_signature

        output.safe_concat('</form>')
      end
    end

  end
end

ActionView::Base.default_form_builder.send :include, ActionView::Helpers::SignedFormBuilder