require 'test_helper'

class SignedFormBuilder
  include ActionView::Helpers::SignedFormBuilder

  def object_name
    "test_object_name"
  end
end


class ActionViewHelpersSignedFormBuilderTest < ActiveSupport::TestCase

  setup do
    @builder = SignedFormBuilder.new
  end

  test "should start with an empty field_list" do
    assert @builder.field_list.empty?
  end

  test "allow_parameters should add the raw parameters" do
    @builder.allow_parameters "foo", "bar"
    assert_equal ["foo", "bar"], @builder.field_list
  end

  test "allow_fields should add the parameters with the object name" do
    @builder.allow_fields "foo", "bar"
    assert_equal ["test_object_name[foo]", "test_object_name[bar]"], @builder.field_list
  end

  test "form_signature should generate a hidden field for the field_list" do
    @builder.allow_parameters "foo", "bar"
    sig = @builder.form_signature
    assert_match /input.*type=\"hidden\"/, sig
    assert_match /name=\"form_signature\"/, sig
    assert_match /value=\"foo,bar\"/, sig
    assert sig.html_safe?
  end

end