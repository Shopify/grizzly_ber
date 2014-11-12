class GrizzlyBer
  attr_reader :value, :tag

  def initialize(hex_string = "")
    @tag = nil
    @length = nil
    @value = nil
    decode_hex(hex_string)
  end

  def value=(new_value)
    if new_value.is_a? String
      @value = new_value
      @tag = nil if isConstruct?
    elsif new_value.is_a? Array and new_value.all? {|tlv| tlv.is_a? GrizzlyBer}
      @value = new_value
      @tag = nil if not isConstruct?
    else
      @value = nil
    end
  end

  def tag=(new_tag)
    @tag = new_tag
    @value = nil if isConstruct? and @value.is_a? String
    @value = nil if not isConstruct? and @value.is_a? Array
    @value = [] if isConstruct? and @value.nil?
  end

  def decode_hex(hex_string)
    decode_binary([hex_string].pack("H*"))
  end

  def decode_binary(binary_string)
    decode_byte_array(binary_string.unpack("C*"))
  end

  def encode_hex
    encoded = ""
    encoded << @tag.to_s(16).upcase
    if length_of_length == 1
      encoded << length.to_s(16).rjust(2,'0').upcase
    else
      encoded << ((length_of_length-1) | 0x80).to_s(16).rjust(2,'0').upcase
      encoded << length.to_s(16).rjust((length_of_length-1)*2,'0').upcase
    end
    encoded << encode_only_values
  end

  def encode_only_values
    if @value.is_a? String
      @value.upcase
    else
      @value.inject("") {|encoded_children,child| encoded_children << child.encode_hex}
    end
  end

  protected

  def length
    return value.length/2 if value.is_a? String #because hex strings are 2 chars per byte
    value.inject(0) {|length, tlv| length += tlv.length_of_tag + tlv.length_of_length + tlv.length}
  end

  def length_of_tag
    [@tag.to_s(16)].pack("H*").unpack("C*").count
  end

  def length_of_length
    1 + ((length < 0x7F) ? 0 : [length.to_s(16)].pack("H*").unpack("C*").count)
  end

  def decode_byte_array(byte_array)
    decode_value decode_length decode_tag byte_array
    self
  end

  private

  def decode_tag(byte_array)
    byte_array.shift while byte_array.size > 0 and (byte_array[0] == 0x00 or byte_array[0] == 0xFF)
    return [] if byte_array.size < 1

    first_byte = byte_array.shift
    @tag = first_byte
    return byte_array if (first_byte & 0x1F) != 0x1F

    while byte_array.size > 0
      next_byte = byte_array.shift
      @tag = (@tag << 8) | next_byte
      return byte_array if (next_byte & 0x80) != 0x80
    end

    @tag = nil
    []
  end

  def decode_length(byte_array)
    return [] if byte_array.size < 1

    first_byte = byte_array.shift
    if (first_byte & 0x80) == 0x80
      decoded_length_of_length = first_byte & 0x7F

      return [] if byte_array.size < decoded_length_of_length
      @length = 0
      decoded_length_of_length.times { @length = (@length << 8) | byte_array.shift }
    else
      @length = first_byte
    end

    byte_array
  end

  def isConstruct?
    ([@tag.to_s(16)].pack("H*").unpack("C*").first & 0x20) == 0x20
  end

  def decode_value(byte_array)
    return [] if byte_array.size < 1 or byte_array.size < @length
    if isConstruct?
      @value = []
      children_bytes = byte_array.shift(@length)
      @value << GrizzlyBer.new.decode_byte_array(children_bytes) while children_bytes.size > 0
    else
      @value = byte_array.shift(@length).pack("C*").unpack("H*").first.upcase
    end
  end
end

