require 'grizzly_tag'

class GrizzlyBerElement
  attr_reader :tag, :value

  def initialize(byte_array = [])
    raise ArgumentError, "byte_array must be of type Array" unless byte_array.is_a?(Array)
    @tag = "" # is an uppercase hex string
    @value = nil # is a byte array if this is a data element or a GrizzlyBer if it's a sequence element
    decode_value decode_length decode_tag byte_array
  end

  def tag=(tag)
    raise ArgumentError, "tag must be a valid hex string" unless tag.is_a? String and tag.size.even? and tag =~ /^[0-9A-F]*$/
    @tag = tag
  end

  def value=(value)
    raise ArgumentError, "value must be of type Array or GrizzlyBer" unless value.is_a?(Array) || value.is_a?(GrizzlyBer)
    @value = value 
  end

  def to_ber
    ber_array = ""
    ber_array += @tag.upcase
    value_hex_string = @value.pack("C*").unpack("H*").first.upcase if @value.is_a? Array
    value_hex_string = @value.to_ber if @value.is_a? GrizzlyBer
    value_byte_count = value_hex_string.size/2
    if value_byte_count < 0x7F # if the length of the value array is only one byte long and does not have its upper bit set
      ber_array << byte_to_hex(value_byte_count)
    else
      #pack("w") was meant to do this length calc but doesn't work right...
      number_of_bytes_in_byte_count = ((value_byte_count).to_s(16).size/2.0).ceil
      ber_array << byte_to_hex(number_of_bytes_in_byte_count | 0x80)
      ber_array += (value_byte_count).to_s(16).rjust(number_of_bytes_in_byte_count*2,'0').upcase
    end
    ber_array += value_hex_string
  end

  private

  def byte_to_hex(byte)
    byte.to_s(16).rjust(2,'0').upcase
  end

  def decode_tag(byte_array)
    byte_array.shift while byte_array.size > 0 and (byte_array[0] == 0x00 or byte_array[0] == 0xFF)
    return [] if byte_array.size < 1

    first_byte = byte_array.shift
    @tag << byte_to_hex(first_byte)
    return byte_array if (first_byte & 0x1F) != 0x1F

    while byte_array.size > 0
      next_byte = byte_array.shift
      @tag << byte_to_hex(next_byte)
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

  def decode_value(byte_array)
    return [] if byte_array.size < 1 or byte_array.size < @length
    return @value = byte_array.shift(@length) if [@tag].pack("H*").unpack("C*").first & 0x20 == 0
    @value = GrizzlyBer.new.from_ber byte_array.shift(@length)
  end
end

class GrizzlyBer
  include Enumerable

  def initialize(hex_string = "")
    raise ArgumentError, "hex_string must be a valid hex string" unless hex_string.is_a? String and hex_string.size.even? and hex_string =~ /^[0-9A-F]*$/
    @elements = [] # is an array of GrizzlyBerElement
    from_ber_hex_string(hex_string)
  end

  def from_ber_hex_string(hex_string)
    raise ArgumentError, "hex_string must be a valid hex string" unless hex_string.is_a? String and hex_string.size.even? and hex_string =~ /^[0-9A-F]*$/
    self.from_ber [hex_string].pack("H*").unpack("C*")
  end

  def from_ber(byte_array)
    raise ArgumentError, "byte_array must be an array of bytes" unless byte_array.is_a? Array and byte_array.all? {|byte| byte.is_a? Integer and byte <= 0xFF}
    while byte_array.size > 0
      element = GrizzlyBerElement.new(byte_array)
      return nil if element.tag.nil?
      return nil if element.value.nil?
      @elements << element
    end
    self
  end

  def to_ber
    @elements.reduce("") {|ber_array, element| ber_array += element.to_ber}
  end

  def [](index_or_tag)
    return value_of_first_element_with_tag(index_or_tag) if index_or_tag.is_a? String
    @elements[index_or_tag]
  end

  def []=(index_or_tag,value)
    return set_value_for_tag(index_or_tag, value) if index_or_tag.is_a? String
    @elements[index].value = value
    @elements[index]
  end

  def size
    @elements.size
  end

  def each &block
    @elements.each &block
  end

  def value_of_first_element_with_tag(tag)
    first_tagged_element = @elements.find {|element| tag.upcase == element.tag}
    first_tagged_element ||= @elements.find {|element| element.tag == GrizzlyTag.named(tag)[:tag]} if GrizzlyTag.named(tag)
    first_tagged_element &&= first_tagged_element.value
  end

  def hex_value_of_first_element_with_tag(tag)
    first_tagged_element = value_of_first_element_with_tag(tag)
    first_tagged_element &&= first_tagged_element.pack("C*").unpack("H*").first.upcase
  end

  def set_value_for_tag(tag, value)
    tag.upcase!
    first_tagged_element = @elements.find {|element| tag == element.tag}
    first_tagged_element ||= @elements.find {|element| element.tag == GrizzlyTag.named(tag)[:tag]} if GrizzlyTag.named(tag)
    if first_tagged_element.nil?
      first_tagged_element = GrizzlyBerElement.new
      first_tagged_element.tag = tag
      @elements << first_tagged_element
    end
    first_tagged_element.value = value
    first_tagged_element
  end

  def set_hex_value_for_tag(tag, value)
    set_value_for_tag(tag, [value].pack("H*").unpack("C*"))
  end

  def remove!(tag)
    @elements = @elements.select {|element| element.tag != tag.upcase}
    self
  end

  def to_s(indent_size: 0)
    indent = " " * 3 * indent_size
    @elements.reduce("") do |output, element| 
      info = GrizzlyTag.tagged(element.tag) || {:name => "Unknown Tag", :description => "Unknown"}
      output += "#{indent}#{element.tag}: #{info[:name]}\n"
      output += "#{indent} Description: #{info[:description]}\n"
      if element.value.is_a? GrizzlyBer
        output += element.value.to_s(indent_size: indent_size+1)
      else
        output += "#{indent} Value: #{element.value.pack("C*").unpack("H*").first}"
        output += ", \"#{element.value.pack("C*")}\"" if info[:format] == :string
        output += "\n"
      end
    end
  end

  private


end
