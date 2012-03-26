module ActionView
  module Helpers

    module SignedFormBuilder

      def params_for_sig
        @allowed_fields ||= [] 
        {object_name => @allowed_fields}
      end

      # Use this method to allow fields on this form builder.
      def allow_fields(*fields)
        @allowed_fields ||= []
        params = fields.map { |f| f.to_s }
        @allowed_fields += params
      end

      # Use this to allow a whole hash of fields, ie from fields_for
      def allow_subfields(h)
        @allowed_fields ||= []
        @allowed_fields << h        
      end

      def form_signature
        sig = ERB::Util.html_escape(params_for_sig.to_json)
        "<input type=\"hidden\" name=\"form_signature\" value=\"#{sig}\" />".html_safe
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
        if builder.respond_to?(:params_for_sig) && pb = options[:parent_builder]
          pb.allow_subfields(builder.params_for_sig)
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
        output << builder.form_signature if builder.respond_to?(:form_signature)

        output.safe_concat('</form>')
      end
    end

  end
end

ActionView::Base.default_form_builder.send :include, ActionView::Helpers::SignedFormBuilder