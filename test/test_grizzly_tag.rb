require 'minitest/autorun'
require 'bundler/setup'
require 'grizzly_tag'
require 'byebug'

class GrizzlyTagTest < Minitest::Test  

  def test_tags_exist
    assert_kind_of Array, GrizzlyTag.all
    assert_operator 0, :<, GrizzlyTag.all.count
  end

  def test_find_by_tag
    assert_nil GrizzlyTag.tagged(0x00)
    refute_nil GrizzlyTag.tagged(0x5A)
    assert_equal GrizzlyTag.tagged(0x5A)[:tag], 0x5a
    assert_equal GrizzlyTag.tagged(0x5A)[:name], "Application Primary Account Number (PAN)"
    assert_equal GrizzlyTag.tagged(0x5A)[:description], "Valid cardholder account number"
    refute_nil GrizzlyTag.tagged(0x9F21)
    assert_equal GrizzlyTag.tagged(0x9F21)[:tag], 0x9F21
    assert_equal GrizzlyTag.tagged(0x9F21)[:name], "Transaction Time"
    assert_equal GrizzlyTag.tagged(0x9F21)[:description], "Local time that the transaction was authorised"
  end

  def test_find_by_name
    assert_nil GrizzlyTag.named("")
    refute_nil GrizzlyTag.named("Application Primary Account Number (PAN)")
    assert_equal GrizzlyTag.named("Application Primary Account Number (PAN)")[:tag], 0x5a
    assert_equal GrizzlyTag.named("Application Primary Account Number (PAN)")[:name], "Application Primary Account Number (PAN)"
    assert_equal GrizzlyTag.named("Application Primary Account Number (PAN)")[:description], "Valid cardholder account number"
    refute_nil GrizzlyTag.named("Transaction Time")
    assert_equal GrizzlyTag.named("Transaction Time")[:tag], 0x9F21
    assert_equal GrizzlyTag.named("Transaction Time")[:name], "Transaction Time"
    assert_equal GrizzlyTag.named("Transaction Time")[:description], "Local time that the transaction was authorised"
  end

  def test_finding_tag_from_name
    assert_nil GrizzlyTag.tag_from_name("")
    assert_equal GrizzlyTag.tag_from_name("Transaction Time"), 0x9F21
    assert_equal GrizzlyTag.tag_from_name("Application Primary Account Number (PAN)"), 0x5A
  end
end