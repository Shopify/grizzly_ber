# Grizzly BER

This library implements a TLV-BER parser, used for processing EMV transaction-related data.

This works differently from OpenSSL::ASN1 in that it does not decode tags (EMV-style). The reason that this is importand can be seen when processing a long tag like 9F02 (Amount Authorized in EMV). OpenSSL will write it as the TLV-DER tag 82. GrizzlyBer maintains the original TLV-BER tag 9F02.

```ruby
tlv_string = "9F0206000000000612"
 => "9F0206000000000612" 

OpenSSL::ASN1.decode([tlv_string].pack("H*")).to_der.unpack("H*").first.upcase
 => "8206000000000612" 

GrizzlyBer.new(tlv_string).to_ber
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

Instantiate a TLV instance with a TLV-BER-encoded hex string to decode it

    tlv = GrizzlyBer.new("DFAE22015A")

Access a value by tag

    tlv = GrizzlyBer.new
    tlv["DFAE22"] #returns [0x5A]

Set a value by tag

    tlv = GrizzlyBer.new
    tlv.tag = 0xDFAE22
    tlv["DFAE22"] = [0xAA]
    tlv.set_hex_value_for_tag("DFAE22", "AA")

Create multi-dimensional structures

    tlv = GrizzlyBer.new
    tlv["E1"] = GrizzlyBer.new
    tlv["E1"]["5A"] = [0xaa, 0x12, 0x34]
    tlv["E1"].set_hex_value_for_tag("57", "55A55A")

Encode the TLV instance back out to a hex string

    tlv = GrizzlyBer.new("DFAE22015A")
    hex_string = tlv.to_ber

Access EMV-specific values by name

    tlv = GrizzlyBer.new
    tlv["8A"] = [0x30, 0x30]
    tlv["Authorisation Response Code"] = [0x30, 0x30]

Pretty-print EMV-specific data

    puts GrizzlyBer.new "500B5649534120435245444954"
    #50: Application Label
    # Description: Mnemonic associated with the AID according to ISO/IEC 7816-5
    # Value: 5649534120435245444954, "VISA CREDIT"

  
## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
