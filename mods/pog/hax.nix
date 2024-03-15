# This module provides some hacky `pog` tools!
final: prev:
with prev;
{
  mitm2openapi = pog {
    name = "mitm2openapi";
    description = "convert mitmproxy flows into openapi specs!";
    flags = [
      {
        name = "flows";
        description = "the exported flows output from mitmproxy";
        default = "./flows";
      }
      {
        name = "spec";
        description = "the OpenAPI spec file to use";
        default = "./schema.yaml";
      }
      {
        name = "baseurl";
        description = "the base url for the api to generate for";
      }
    ];
    script = helpers: ''
      ${pkgs.python311Packages.mitmproxy2swagger}/bin/mitmproxy2swagger -i "$flows" -o "$spec" -p "$baseurl"
      ${_.yq} -i e 'del(.paths.[].options)' "$spec"
    '';
  };

  hax_pog_scripts = [ ];
}
