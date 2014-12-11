# Grizzly BER

This library implements a TLV-BER parser, used for processing EMV transaction-related data.

This works differently from OpenSSL::ASN1 in that it does not decode tags (EMV-style). The reason that this is importand can be seen when processing a long tag like 9F02 (Amount Authorized in EMV). OpenSSL will write it as the TLV-DER tag 82. GrizzlyBer maintains the original TLV-BER tag 9F02.
GrizzlyBer also handles both hex and binary strings cleanly. :)

```ruby
tlv_string = "9F0206000000000612"
 => "9F0206000000000612" 

OpenSSL::ASN1.decode([tlv_string].pack("H*")).to_der.unpack("H*").first.upcase
 => "8206000000000612" 

GrizzlyBer.new(tlv_string).encode_hex
 => "9F0206000000000612" 
```


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
