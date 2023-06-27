require 'minitest/autorun'
require 'bundler/setup'
require 'grizzly_ber'

class GrizzlyBerTest < Minitest::Test
  TEST_EMV = "E4820130500B564953412043524544495457114761739001010119D151220117589893895A0847617390010101195F201A564953412"\
                    "04143515549524552205445535420434152442030315F24031512315F280208405F2A0208265F300202015F34010182025C008407A0"\
                    "000000031010950502000080009A031408259B02E8009C01009F02060000000734499F03060000000000009F0607A00000000310109"\
                    "F0902008C9F100706010A03A080009F120F4352454449544F20444520564953419F1A0208269F1C0831373030303437309F1E083137"\
                    "3030303437309F2608EB2EC0F472BEA0A49F2701809F3303E0B8C89F34031E03009F3501229F360200C39F37040A27296F9F4104000"\
                    "001319F4502DAC5DFAE5711476173FFFFFF0119D15122011758989389DFAE5A08476173FFFFFF0119"
  TEST_EMV_TAGS = ["50", "57", "5A", "5F20", "5F24", "5F28", "5F2A", "5F30", "5F34", "82", "84", "95", "9A", "9B", "9C", "9F02", 
                   "9F03", "9F06", "9F09", "9F10", "9F12", "9F1A", "9F1C", "9F1E", "9F26", "9F27", "9F33", "9F34", "9F35", "9F36", 
                   "9F37", "9F41", "9F45", "DFAE57", "DFAE5A"]

  def test_decode_min_tag
    tlv = GrizzlyBer.new("5A015A")
    assert_equal "5A", tlv[0].tag
    assert_equal 0x5A, tlv[0].value.first
    assert_equal [0x5A], tlv.value_of_first_element_with_tag("5A")
    assert_equal "5A", tlv.hex_value_of_first_element_with_tag("5A")
    assert_equal 0x5A, tlv["5A"].first
    assert_equal 0x5A, tlv["5a"].first
    assert_nil tlv["FF"]
  end
  def test_decode_2byte_tag
    tlv = GrizzlyBer.new("9F1E015A")
    assert_equal "9F1E", tlv[0].tag
    assert_equal 0x5A, tlv[0].value.first
    assert_equal 0x5A, tlv["9F1E"].first
  end
  def test_decode_3byte_tag
    tlv = GrizzlyBer.new("DFAE22015A")
    assert_equal "DFAE22", tlv[0].tag
    assert_equal 0x5A, tlv[0].value.first
    assert_equal 0x5A, tlv["DFAE22"].first
  end

  def test_decode_min_length
    tlv = GrizzlyBer.new("5A015A")
    assert_equal [0x5A], tlv["5A"]
  end
  def test_decode_2byte_length
    tlv = GrizzlyBer.new("5A81015A")
    assert_equal [0x5A], tlv["5A"]
  end
  def test_decode_3byte_length
    tlv = GrizzlyBer.new("5A8200015A")
    assert_equal [0x5A], tlv["5A"]
  end

  def test_decode_min_value
    tlv = GrizzlyBer.new("5A015A")
    assert_equal [0x5A], tlv["5A"]
  end
  def test_decode_long_value
    tlv = GrizzlyBer.new("5A080102030405060708")
    assert_equal "0102030405060708", tlv.hex_value_of_first_element_with_tag("5A")
  end
  def test_decode_long_value_2byte_length
    tlv = GrizzlyBer.new("5A81080102030405060708")
    assert_equal "0102030405060708", tlv.hex_value_of_first_element_with_tag("5A")
  end

  def test_decode_min_construct
    tlv = GrizzlyBer.new("E4035A01AA")
    assert_equal "E4", tlv[0].tag
    assert_equal 1, tlv.size
    assert_kind_of GrizzlyBer, tlv[0].value
    assert_kind_of GrizzlyBer, tlv["E4"]
    assert_equal "5A", tlv["E4"][0].tag
    assert_equal [0xAA], tlv["E4"]["5A"]
    assert_equal "AA", tlv["E4"].hex_value_of_first_element_with_tag("5A")
  end
  def test_decode_construct_2children
    tlv = GrizzlyBer.new("E4065A01AA570155")
    assert_equal "E4", tlv[0].tag
    assert_equal 1, tlv.size
    assert_kind_of GrizzlyBer, tlv[0].value
    assert_kind_of GrizzlyBer, tlv["E4"]
    assert_equal 2, tlv["E4"].size
    assert_equal "5A", tlv["E4"][0].tag
    assert_equal "57", tlv["E4"][1].tag
    assert_equal [0xAA], tlv["E4"]["5A"]
    assert_equal [0x55], tlv["E4"]["57"]
  end
  def test_decode_emv
    tlv = GrizzlyBer.new(TEST_EMV)
    assert_equal 35, tlv["E4"].size
    assert_equal TEST_EMV_TAGS, tlv["E4"].map {|element| element.tag}
  end

  def test_encode_min
    tlv = GrizzlyBer.new
    tlv.set_value_for_tag("5A", [0x02])
    assert_equal "5A0102", tlv.to_ber
    tlv["5A"] = [0x03]
    assert_equal "5A0103", tlv.to_ber
    tlv["50"] = [0x04]
    assert_equal "5A0103500104", tlv.to_ber
  end
  def test_encode_2byte_tag
    tlv = GrizzlyBer.new
    tlv["9f1e"] = [0x02]
    assert_equal "9F1E0102", tlv.to_ber
  end
  def test_encode_long_value
    tlv = GrizzlyBer.new
    tlv.set_hex_value_for_tag("57", "0102030405060708")
    assert_equal "57080102030405060708", tlv.to_ber
  end
  def test_encode_min_construct
    tlv = GrizzlyBer.new
    tlv["E1"] = GrizzlyBer.new
    tlv["E1"]["5A"] = [0xAA]
    assert_equal "E1035A01AA", tlv.to_ber
  end
  def test_encode_construct_2children
    tlv = GrizzlyBer.new
    tlv["E1"] = GrizzlyBer.new
    tlv["E1"]["5A"] = [0xAA]
    tlv["E1"].set_hex_value_for_tag("57", "55")
    assert_equal "E1065A01AA570155", tlv.to_ber
  end

  def test_modify_recode
    tlv = GrizzlyBer.new("5A080102030405060708")
    tlv["5A"][3] = 0xFF #Array modification, not tag lookup
    assert_equal "5A08010203FF05060708", tlv.to_ber
  end
  def test_recode_emv
    tlv = GrizzlyBer.new(TEST_EMV)
    assert_equal TEST_EMV, tlv.to_ber
  end

  def test_decode_corrupt_length
    assert_raises GrizzlyBer::ParsingError do
      GrizzlyBer.new("5A825A")
    end
    assert_raises GrizzlyBer::ParsingError do
      GrizzlyBer.new("5A815A")
    end
    assert_raises GrizzlyBer::ParsingError do
      GrizzlyBer.new("5A025A")
    end
  end

  def test_discard_leading_scratch_bytes
    tlv = GrizzlyBer.new("00FF5A015A")
    assert_equal [0x5a], tlv["5A"]
    tlv = GrizzlyBer.new("E409FF5A01AA0000570155")
    assert_equal 2, tlv["E4"].size
    assert_equal [0xaa], tlv["E4"]["5A"]
    assert_equal [0x55], tlv["E4"]["57"]
  end

  def test_decode_array_of_2children
    tlv = GrizzlyBer.new("5A01AA570155")
    assert_equal 2, tlv.size
    assert_equal [0xaa], tlv["5A"]
    assert_equal [0x55], tlv["57"]
  end

  def test_find_tags
    tlv = GrizzlyBer.new("E4065A01AA570155")
    refute_nil tlv["e4"]
    refute_nil tlv["E4"]
    refute_nil tlv["E4"]["5A"]
    refute_nil tlv["E4"]["57"]
    assert_nil tlv["DFAE22"]
    assert_nil tlv["E4"]["DFAE22"]
    refute_nil tlv["E4"].value_of_first_element_with_tag("Application Primary Account Number (PAN)") #tag 5A
    refute_nil tlv["E4"].value_of_first_element_with_tag("Track 2 Equivalent Data") #tag 57
  end

  def test_add_tag_by_name
    tlv = GrizzlyBer.new
    tlv["Authorisation Response Code"] = [0x30, 0x30]
    assert_equal [0x30, 0x30], tlv["Authorisation Response Code"]
    assert_equal [0x30, 0x30], tlv["8A"]
  end

  def test_removing_tags
    tlv = GrizzlyBer.new("E4065A01AA570155")
    assert_equal 2, tlv["E4"].size
    refute_nil tlv["E4"]["5A"]
    refute_nil tlv["E4"]["57"]
    tlv["E4"].remove!("5A")
    assert_equal 1, tlv["E4"].size
    assert_nil tlv["E4"]["5A"]
    refute_nil tlv["E4"]["57"]
    assert_equal "E403570155", tlv.to_ber
  end

  def test_pretty_print
    tlv = GrizzlyBer.new("E4035A01AA")
    info = GrizzlyTag.tagged("5A")
    refute_nil tlv.to_s["E4"]
    refute_nil tlv.to_s["5A"]
    refute_nil tlv.to_s[info[:name]]
    refute_nil tlv.to_s[info[:description]]

    tlv = GrizzlyBer.new "500B5649534120435245444954"
    info = GrizzlyTag.tagged("50")
    refute_nil tlv.to_s["50"]
    refute_nil tlv.to_s[info[:name]]
    refute_nil tlv.to_s[info[:description]]
    refute_nil tlv.to_s["VISA CREDIT"]
  end

  def test_add_extra_string
    tlv = GrizzlyBer.new("5A01AA")
    refute_nil tlv.from_ber_hex_string("570155")
    assert_equal 2, tlv.size
    refute_nil tlv["5A"]
    refute_nil tlv["57"]
    assert_equal [0xAA], tlv["5A"]
    assert_equal [0x55], tlv["57"]
  end

  def test_bad_tags_are_bad
    tlv = GrizzlyBer.new
    assert_raises ArgumentError do
      tlv["FFFF"] = [5]
    end
    assert_raises ArgumentError do
      tlv["1F808080"] = [0]
    end
    assert_raises ArgumentError do 
      tlv["0100"] = [0]
    end
    assert_raises ArgumentError do
      tlv["FF"] = [0]
    end

    #these tags are valid so won't raise errors
    tlv["1F808000"] = [5]
    tlv["01"] = [0]
    tlv["1f00"] = [0]
  end

  def test_cyrillic_application_name_doesnt_crash
    tlv = GrizzlyBer.new "9F120CB2D8E1D020B4D5D1D5E22032"
    tlv.to_s
  end

  def test_invalid_cardholder_name_doesnt_crash
    tlv = GrizzlyBer.new "5F200CE789A9E79086E695B8E5ADB89F0607A0000000041010"
    tlv.to_s
  end

  def test_pad_between_tags
    tlv = GrizzlyBer.new("5A01AA570155")
    refute_nil tlv.from_ber_hex_string("9F1E01AA00009F1D0155")
    refute_nil tlv.from_ber_hex_string("9F1C01A1FFFF9F1B0151")
    assert_equal 6, tlv.size
    assert_equal [0xAA], tlv["5A"]
    assert_equal [0x55], tlv["57"]
    assert_equal [0xAA], tlv["9F1E"]
    assert_equal [0x55], tlv["9F1D"]
    assert_equal [0xA1], tlv["9F1C"]
    assert_equal [0x51], tlv["9F1B"]
  end

  def test_pad_after_tags
    tlv = GrizzlyBer.new("5A01AA570155")
    refute_nil tlv.from_ber_hex_string("9F1E01AA9F1D01550000")
    refute_nil tlv.from_ber_hex_string("9F1C01A19F1B0151FFFF")
    assert_equal 6, tlv.size
    refute_nil tlv["5A"]
    refute_nil tlv["57"]
    refute_nil tlv["9F1E"]
    refute_nil tlv["9F1D"]
    refute_nil tlv["9F1C"]
    refute_nil tlv["9F1B"]
    assert_equal [0xAA], tlv["5A"]
    assert_equal [0x55], tlv["57"]
    assert_equal [0xAA], tlv["9F1E"]
    assert_equal [0x55], tlv["9F1D"]
    assert_equal [0xA1], tlv["9F1C"]
    assert_equal [0x51], tlv["9F1B"]
  end

  def test_decoding_garbage
    assert_raises GrizzlyBer::ParsingError do
      GrizzlyBer.new("F9D8711C60EB0E1D25EA")
    end
  end

  def test_tags_with_FFs
    tlv = GrizzlyBer.new("FF0E035A01AA", allow_FF_tags: true)
    assert_equal [0xAA], tlv["FF0E"]["5A"]
  end

  def test_decoding_response
    tlv = GrizzlyBer.new("8A023030910815BDF04000820000721F86158424000210202020202020202020202020202020202020202020202020",
                         ignore_nested: true)
    assert_equal 2, tlv["8A"].size
    assert_equal 8, tlv["91"].size
    assert_equal 31, tlv["72"].size
  end
end
