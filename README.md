# Grizzly BER

This library implements a TLV-BER parser, used for processing EMV transaction-related data.

## Installation

Add this line to your application's Gemfile:

    gem 'grizzly_ber'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install grizzly_ber

## Usage

    # Instantiate a TLV instance with a TLV-BER-encoded hex string to decode it
    tlv = GrizzlyBer.new("DFAE22015A")

    # Access the tag as an integer
    tlv = GrizzlyBer.new
    tlv.tag = 0xDFAE22

    # Access the value as a String for non-construct TLVs
    tlv = GrizzlyBer.new
    tlv.tag = 0xDFAE22
    tlv.value = "5A"

    # Access the value as an Array for construct TLVs
    tlv = GrizzlyBer.new
    tlv.tag = 0xE1
    tlv.value << GrizzlyBer.new
    tlv.value.last.tag = 0x5A
    tlv.value.last.value = "AA1234"
    tlv.value << GrizzlyBer.new
    tlv.value.last.tag = 0x57
    tlv.value.last.value = "55A55A"

    # Encode the TLV instance back out to a hex string
    hex_string = tlv.encode_hex
  
## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
