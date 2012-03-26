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

  test "should start with an empty params_for_sig" do
    assert_equal({"test_object_name" => []}, @builder.params_for_sig)
  end


  test "allow_fields should add the parameters with the object name" do
    @builder.allow_fields "foo", "bar"
    expected = {"test_object_name" => ["foo", "bar"]}
    assert_equal(expected, @builder.params_for_sig)
  end

  test "allow_subfields should add the given hash" do
    @builder.allow_fields("simple")
    @builder.allow_subfields({ "sub_object_name" => ['foo'] })
    expected = { "test_object_name" => ["simple", { "sub_object_name" => ['foo'] }] }
    assert_equal(expected, @builder.params_for_sig)
  end  

  test "form_signature should generate a hidden field named form_signature" do
    sig = @builder.form_signature
    assert_match /input.*type=\"hidden\"/, sig
    assert_match /name=\"form_signature\"/, sig
    assert sig.html_safe?
  end

end