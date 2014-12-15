require 'minitest/autorun'
require 'bundler/setup'
require 'grizzly_ber'
require 'byebug'

class GrizzlyBerTest < Minitest::Test
  TEST_EMV = "E4820130500B564953412043524544495457114761739001010119D151220117589893895A0847617390010101195F201A564953412"\
                    "04143515549524552205445535420434152442030315F24031512315F280208405F2A0208265F300202015F34010182025C008407A0"\
                    "000000031010950502000080009A031408259B02E8009C01009F02060000000734499F03060000000000009F0607A00000000310109"\
                    "F0902008C9F100706010A03A080009F120F4352454449544F20444520564953419F1A0208269F1C0831373030303437309F1E083137"\
                    "3030303437309F2608EB2EC0F472BEA0A49F2701809F3303E0B8C89F34031E03009F3501229F360200C39F37040A27296F9F4104000"\
                    "001319F4502DAC5DFAE5711476173FFFFFF0119D15122011758989389DFAE5A08476173FFFFFF0119"
  TEST_EMV_TAGS = [0x50, 0x57, 0x5a, 0x5f20, 0x5f24, 0x5f28, 0x5f2a, 0x5f30, 0x5f34, 0x82, 0x84, 0x95, 0x9a, 0x9b, 0x9c, 0x9f02, 
                   0x9f03, 0x9f06, 0x9f09, 0x9f10, 0x9f12, 0x9f1a, 0x9f1c, 0x9f1e, 0x9f26, 0x9f27, 0x9f33, 0x9f34, 0x9f35, 0x9f36, 
                   0x9f37, 0x9f41, 0x9f45, 0xdfae57, 0xdfae5a]

  def test_decode_min_tag
    tlv = GrizzlyBer.new("5A015A")
    assert_equal 0x5a, tlv.tag
  end
  def test_decode_2byte_tag
    tlv = GrizzlyBer.new("9F1E015A")
    assert_equal 0x9f1e, tlv.tag
  end
  def test_decode_3byte_tag
    tlv = GrizzlyBer.new("DFAE22015A")
    assert_equal 0xdfae22, tlv.tag
  end

  def test_decode_min_length
    tlv = GrizzlyBer.new("5A015AFFFF")
    assert_equal "5A", tlv.value
  end
  def test_decode_2byte_length
    tlv = GrizzlyBer.new("5A81015AFFFF")
    assert_equal "5A", tlv.value
  end
  def test_decode_3byte_length
    tlv = GrizzlyBer.new("5A8200015AFF")
    assert_equal "5A", tlv.value
  end

  def test_decode_min_value
    tlv = GrizzlyBer.new("5A015A")
    assert_equal "5A", tlv.value
  end
  def test_decode_long_value
    tlv = GrizzlyBer.new("5A080102030405060708")
    assert_equal "0102030405060708", tlv.value
  end
  def test_decode_long_value_2byte_length
    tlv = GrizzlyBer.new("5A81080102030405060708")
    assert_equal "0102030405060708", tlv.value
  end

  def test_decode_min_construct
    tlv = GrizzlyBer.new("E4035A01AA")
    assert_kind_of Array, tlv.value
    assert_equal 1, tlv.value.size
    assert_kind_of GrizzlyBer, tlv.value.first
    assert_equal 0x5A, tlv.value.first.tag
    assert_equal "AA", tlv.value.first.value
  end
  def test_decode_construct_2children
    tlv = GrizzlyBer.new("E4065A01AA570155")
    assert_kind_of Array, tlv.value
    assert_equal 2, tlv.value.size
    assert_kind_of GrizzlyBer, tlv.value[0]
    assert_kind_of GrizzlyBer, tlv.value[1]
    assert_equal 0x5A, tlv.value[0].tag
    assert_equal 0x57, tlv.value[1].tag
    assert_equal "AA", tlv.value[0].value
    assert_equal "55", tlv.value[1].value
  end
  def test_decode_emv
    tlv = GrizzlyBer.new(TEST_EMV)
    assert_kind_of Array, tlv.value
    assert_equal 35, tlv.value.size
    assert_equal TEST_EMV_TAGS, tlv.value.map {|tlv| tlv.tag}
  end

  def test_encode_min
    tlv = GrizzlyBer.new
    tlv.tag = 0x5A
    tlv.value = "02"
    assert_equal "5A0102", tlv.encode_hex
  end
  def test_encode_2byte_tag
    tlv = GrizzlyBer.new
    tlv.tag = 0x9f1e
    tlv.value = "02"
    assert_equal "9F1E0102", tlv.encode_hex
  end
  def test_encode_long_value
    tlv = GrizzlyBer.new
    tlv.tag = 0x57
    tlv.value = "0102030405060708"
    assert_equal "57080102030405060708", tlv.encode_hex
  end
  def test_encode_min_construct
    tlv = GrizzlyBer.new
    tlv.tag = 0xe1
    tlv.value << GrizzlyBer.new
    tlv.value.last.tag = 0x5A
    tlv.value.last.value = "AA"
    assert_equal "E1035A01AA", tlv.encode_hex
  end
  def test_encode_construct_2children
    tlv = GrizzlyBer.new
    tlv.tag = 0xe1
    tlv.value << GrizzlyBer.new
    tlv.value.last.tag = 0x5A
    tlv.value.last.value = "AA"
    tlv.value << GrizzlyBer.new
    tlv.value.last.tag = 0x57
    tlv.value.last.value = "55"
    assert_equal "E1065A01AA570155", tlv.encode_hex
  end

  def test_modify_recode
    tlv = GrizzlyBer.new("5A080102030405060708")
    tlv.value["04"] = "FF"
    assert_equal "5A08010203FF05060708", tlv.encode_hex
  end
  def test_recode_emv
    tlv = GrizzlyBer.new(TEST_EMV)
    assert_equal 35, tlv.value.size
    assert_equal TEST_EMV, tlv.encode_hex
  end
  def test_encode_only_values
    tlv = GrizzlyBer.new("E4065A01AA570155")
    assert_equal "5A01AA570155", tlv.encode_only_values
  end

  def test_decode_corrupt_length
    tlv = GrizzlyBer.new("5A825A")
    assert_nil tlv.value
    tlv = GrizzlyBer.new("5A815A")
    assert_nil tlv.value
    tlv = GrizzlyBer.new("5A025A")
    assert_nil tlv.value
  end

  def test_discard_leading_scratch_bytes
    tlv = GrizzlyBer.new("00FF5A015A")
    assert_equal 0x5a, tlv.tag
    assert_equal "5A", tlv.value
    tlv = GrizzlyBer.new("E409FF5A01AA0000570155")
    assert_kind_of Array, tlv.value
    assert_equal 2, tlv.value.size
    assert_kind_of GrizzlyBer, tlv.value[0]
    assert_kind_of GrizzlyBer, tlv.value[1]
    assert_equal 0x5A, tlv.value[0].tag
    assert_equal 0x57, tlv.value[1].tag
    assert_equal "AA", tlv.value[0].value
    assert_equal "55", tlv.value[1].value
  end

  def test_decode_array_of_2children
    tlv_array = GrizzlyBer.decode_all_hex("5A01AA570155")
    assert_kind_of Array, tlv_array
    assert_equal 2, tlv_array.size
    assert_kind_of GrizzlyBer, tlv_array[0]
    assert_kind_of GrizzlyBer, tlv_array[1]
    assert_equal 0x5A, tlv_array[0].tag
    assert_equal 0x57, tlv_array[1].tag
    assert_equal "AA", tlv_array[0].value
    assert_equal "55", tlv_array[1].value
  end

  def test_binary_handling
    tlv = GrizzlyBer.new("5A015A")
    assert_equal "5A015A", tlv.encode_hex
    assert_equal "\x5A\x01\x5A", tlv.encode_binary
    tlv = GrizzlyBer.new.decode_binary("\x5A\x01\x5A")
    assert_equal "5A015A", tlv.encode_hex
    assert_equal "\x5A\x01\x5A", tlv.encode_binary
  end

  def test_find_tags
    tlv = GrizzlyBer.new("E4065A01AA570155")
    assert_equal tlv.find(0xe4), tlv
    assert_nil tlv.find(0xdfae02)
    assert_nil tlv.find("")
    assert_equal tlv.value[0], tlv.find(0x5a)
    assert_equal tlv.value[0], tlv.find("Application Primary Account Number (PAN)")
    assert_equal tlv.value[1], tlv.find(0x57)
    assert_equal tlv.value[1], tlv.find("Track 2 Equivalent Data")
  end

  def test_removing_tags
    tlv = GrizzlyBer.new("E4065A01AA570155")
    tlv_to_remove = tlv.value[0]
    assert_equal 2, tlv.value.count
    refute_nil tlv.find(0x5A)
    refute_nil tlv.find(0x57)
    assert_equal tlv_to_remove, tlv.remove!(0x5A)
    assert_equal 1, tlv.value.count
    assert_nil tlv.find(0x5A)
    refute_nil tlv.find(0x57)
    assert_equal "E403570155", tlv.encode_hex
  end

  def test_pretty_print
    tlv = GrizzlyBer.new("E4035A01AA")
    info = GrizzlyTag.tagged(0x5a)
    refute_nil tlv.to_s["E4"]
    refute_nil tlv.to_s["5A"]
    refute_nil tlv.to_s[info[:name]]
    refute_nil tlv.to_s[info[:description]]

    tlv = GrizzlyBer.new "500B5649534120435245444954"
    info = GrizzlyTag.tagged(0x50)
    refute_nil tlv.to_s["50"]
    refute_nil tlv.to_s[info[:name]]
    refute_nil tlv.to_s[info[:description]]
    refute_nil tlv.to_s["VISA CREDIT"]
  end


end
