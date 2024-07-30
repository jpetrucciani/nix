{ mkTerraform }:
mkTerraform {
  version = "1.5.5";
  hash = "sha256-SBS3a/CIUdyIUJvc+rANIs+oXCQgfZut8b0517QKq64=";
  vendorHash = "sha256-lQgWNMBf+ioNxzAV7tnTQSIS840XdI9fg9duuwoK+U4=";
  patches = [ ./provider-path-0_15.patch ];
}
