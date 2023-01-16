{ fetchFromGitHub, fetchFromGitLab }:
rec {
  argon2 = rec {
    name = "argon2";
    src = fetchFromGitHub {
      owner = "Ahrotahn";
      repo = name;
      rev = "10691c6291ecb6448cdc1c328ecaacfca79916d0";
      sha256 = "sha256-gN2pgx8VZzP5dC9IQIyCA0J4kTOwIdeKnwuXGZOqHQ8=";
    };
    meta = { };
  };

  arraymancer = rec {
    name = "arraymancer";
    sub = "/src";
    src = fetchFromGitHub {
      owner = "mratsim";
      repo = name;
      rev = "v0.7.0";
      sha256 = "sha256-XEP2XnWtfQzhU5+Us7sIOLt1S7k5Z5A93Oj3nlUyDVc=";
    };
    dependencies = [
      nimblas
      nimlapack
      nimcuda
      nimcl
      clblast
      stb_image
      untar
      zip
    ];
    meta = { };
  };

  bumpy =
    rec {
      name = "bumpy";
      version = "1.0.3";
      src = fetchFromGitHub {
        owner = "treeform";
        repo = name;
        rev = version;
        sha256 = "sha256-mDmDlhOGoYYjKgF5j808oT2NqRlfcOdLSDE3WtdJFQ0=";
      };
      meta = {
        description = "2d collision library";
      };
    };

  c2nim = rec {
    name = "c2nim";
    src = fetchFromGitHub {
      owner = "nim-lang";
      repo = name;
      rev = "6547d14cf79e8208a801023237252d5a7a377794";
      sha256 = "sha256-IJh49tkOFy1wsoMKgtOjbEkDkSTXSJdwvSXi1jAPV9A=";
    };
    meta = { };
  };

  chronicles = {
    name = "chronicles";
    src = fetchFromGitHub {
      owner = "status-im";
      repo = "nim-chronicles";
      rev = "972f25d6c3a324848728d2d05796209f1b9d120e";
      sha256 = "sha256-KaqOXRugDRUkllTIEL5g1qWZuDxn0aGguu7QJ4t+9NI=";
    };
    meta = { };
  };

  chroma = rec {
    name = "chroma";
    sub = "/src";
    src = fetchFromGitHub {
      owner = "treeform";
      repo = name;
      rev = "0.2.5";
      sha256 = "sha256-6lNHpO2aMorgkaPfo6kRcOs9r5R6T/kislVmkeoulw8=";
    };
    meta = { };
  };

  chronos = {
    name = "nim-chronos";
    src = fetchFromGitHub {
      owner = "status-im";
      repo = "nim-chronos";
      rev = "59f611f0fc2fb6ee0ade065b0d651246c6656020";
      sha256 = "sha256-j4Gvn/kMMp6SM3MHU8sMBhgDXdX0xDbvj4lMwp/Bde0=";
    };
    meta = { };
  };

  clblast = rec {
    name = "nim-clblast";
    src = fetchFromGitHub {
      owner = "numforge";
      repo = name;
      rev = "4a602c9135160ffc89f779432acba7e51097e717";
      sha256 = "sha256-9Cjc/xDM06y4apqnC+50e8gz3+B30tLBH5++VipqG/s=";
    };
    meta = { };
  };

  cligen = rec {
    name = "cligen";
    src = fetchFromGitHub {
      owner = "c-blake";
      repo = name;
      rev = "bba13a5746ba09b967548a2c63dda3e800b2444e";
      sha256 = "sha256-xFxFb21Tad+10VB2akGO2yD29fJZZz4Z7JK+sZPnpgA=";
    };
    meta = { };
  };

  cookiejar = rec {
    name = "cookiejar";
    src = fetchFromGitHub {
      owner = "planety";
      repo = name;
      rev = "0934b18dc6acd5639bad985e15fcab2552bff1b0";
      sha256 = "sha256-m/FA1WLf4gfYP/KXQXIPuW5vnYquWzGHJ7IRKBDH5Zg=";
    };
    meta = { };
  };

  dimscord = rec {
    name = "dimscord";
    src = fetchFromGitHub {
      owner = "krisppurg";
      repo = name;
      rev = "4f5e8f2b2fde0f3e160504c43810c64519034625";
      sha256 = "sha256-xFxFb21Tad+10VB2akGO2yD29fJZZz4Z7JK+sZPnpgA=";
    };
    meta = { };
  };

  ed25519 = rec {
    name = "ed25519.nim";
    src = fetchFromGitHub {
      owner = "niv";
      repo = name;
      rev = "176aff141a27ec94f954e961be21671b64531b39";
      sha256 = "sha256-dLn4E0DwZXF2/ZEi4sIMmHMZpvp/Oz8ynrVhte3IDCw=";
    };
    meta = { };
  };

  faker = rec {
    name = "faker";
    sub = "/src";
    src = fetchFromGitHub {
      owner = "jiro4989";
      repo = name;
      rev = "c17b9fddf731f4fc7b3f5bf6949a473df23b28f9";
      sha256 = "sha256-KUd9//6MGzw5MzBbgFnShxF8vv1czYFtSRmorbb5YaI=";
    };
    meta = { };
  };

  frosty = rec {
    name = "frosty";
    src = fetchFromGitHub {
      owner = "disruptek";
      repo = name;
      rev = "c347ce2470f5578b37c0f6ce778e889b364fb3ff";
      sha256 = "sha256-gPmPf7i5H6p6r0JVdTLfnyCQXIbayhJCECl9tT/45Vs=";
    };
    meta = { };
  };

  genny = rec {
    name = "genny";
    sub = "/src";
    src = fetchFromGitHub {
      owner = "treeform";
      repo = name;
      rev = "33f0e5a3e6d370c63f11ac0572f6396af684a314";
      sha256 = "sha256-K67guJ28KEZM/Z8Ui2j3U8cuaVHa48vG+ID34UVfFm8=";
    };
    meta = { };
  };

  httpbeast = rec {
    name = "httpbeast";
    sub = "/src";
    src = fetchFromGitHub {
      owner = "dom96";
      repo = name;
      rev = "abc13d11c210b614960fe8760e581d44cfb2e3e9";
      sha256 = "sha256-8ncCj94UeirSevgZP717NiNtecDyH5jHky+QId31IvQ=";
    };
    meta = { };
  };

  httpx = rec {
    name = "httpx";
    sub = "/src";
    src = fetchFromGitHub {
      owner = "xflywind";
      repo = name;
      rev = "96acabafbba089bba09616d54aa8e51b311e4710";
      sha256 = "sha256-CEVbc1oPWKKZhhLz8+TYsKAEareC3u5dz/4sTSN+b/w=";
    };
    meta = { };
  };

  illwill = rec {
    name = "illwill";
    src = fetchFromGitHub {
      owner = "johnnovak";
      repo = name;
      rev = "4cab69806f02c954b5712686f60b183aa1dcb7d5";
      sha256 = "sha256-WXxW9OL/43BxXR4HWJB8LsZGAb9df2j9lyasMmWQFyU=";
    };
    meta = { };
  };

  jester = rec {
    name = "jester";
    src = fetchFromGitHub {
      owner = "dom96";
      repo = name;
      rev = "d2210c6e29387ce0817343035ace84c27c31ed20";
      sha256 = "sha256-QDwhDjmve9eKWn4wRlTX6C9bEwqdp+WlPe8R1/dGUQM=";
    };
    dependencies = [
      httpbeast
    ];
    meta = { };
  };

  jsonschema = rec {
    name = "jsonschema";
    src = fetchFromGitHub {
      owner = "PMunch";
      repo = name;
      rev = "7b41c03e3e1a487d5a8f6b940ca8e764dc2cbabf";
      sha256 = "1js64jqd854yjladxvnylij4rsz7212k31ks541pqrdzm6hpblbz";
    };
    meta = { };
  };

  json_serialization = {
    name = "json_serialization";
    src = fetchFromGitHub {
      owner = "status-im";
      repo = "nim-json-serialization";
      rev = "5a7f9a86cb201606ae669ed4f7f605047c26628c";
      sha256 = "sha256-5WDk0sMcvB8grbg1xd8Gjbmk3J+FzgosNBwjviaiXJA=";
    };
    meta = { };
  };

  karax = rec {
    name = "karax";
    src = fetchFromGitHub {
      owner = "karaxnim";
      repo = name;
      rev = "11e56317633f3e9dc03b3b61250c587e2775c9fd";
      sha256 = "sha256-TzHR2f+W/LuK9WxfVOPc02BFYU+lR06sUEY0DAego/E=";
    };
    meta = { };
  };

  logue = rec {
    name = "logue";
    sub = "/src";
    src = fetchFromGitHub {
      owner = "planety";
      repo = name;
      rev = "18338a1acc044aad65eea07af07e7e6437193215";
      sha256 = "sha256-mcLMxtgQSnanL+uOnCE+v2Bcum3cdMdn1gsqUz22f2I=";
    };
    meta = { };
  };

  nexus = rec {
    name = "nexus";
    sub = "/src";
    src = fetchFromGitHub {
      owner = "jfilby";
      repo = name;
      rev = "e8d201005eee16f335fb525d05a637ed55037de7";
      sha256 = "sha256-jH7v/EQX1J+OplwkGCJtCMnWxr2GY3uyXWiEcKOWhv4=";
    };
    dependencies = [
      argon2
      chronicles
      jester
      karax
      quickjwt
      yaml
    ];
    meta = { };
  };

  nimcrypto = rec {
    name = "nimcrypto";
    src = fetchFromGitHub {
      owner = "cheatfate";
      repo = name;
      rev = "a5742a9a214ac33f91615f3862c7b099aec43b00";
      sha256 = "sha256-X/NUVtNS05OBrJTqZIPKd0P6Am4JJDtM9htVFpWWgCo=";
    };
    meta = { };
  };

  nimblas = rec {
    name = "nimblas";
    src = fetchFromGitHub {
      owner = "andreaferretti";
      repo = name;
      rev = "da7907887efed7bf2114f0ea48340d81a9d5c8ed";
      sha256 = "sha256-Vp+MIJ+3ZHUYCcdLmA06htGqmVykrJHLHzEJkddEPlY=";
    };
    meta = { };
  };

  nimcl = rec {
    name = "nimcl";
    src = fetchFromGitHub {
      owner = "andreaferretti";
      repo = name;
      rev = "3bf5ebc7290425a5634854cc8e8b30a9a3408d82";
      sha256 = "sha256-WZKj+ICzLGZKh4YZFNgLzY3G66gr+6XRUhihqpmDR60=";
    };
    meta = { };
  };

  nimcuda = rec {
    name = "nimcuda";
    src = fetchFromGitHub {
      owner = "andreaferretti";
      repo = name;
      rev = "eb9a7ad738fafed0eef36f57560f8098ca72fe8a";
      sha256 = "sha256-3F6ER2sp8KisS9xiZrAZKhUThxkVYlmvwzk91v0Ezr4=";
    };
    meta = { };
  };

  nimlapack = rec {
    name = "nimlapack";
    src = fetchFromGitHub {
      owner = "andreaferretti";
      repo = name;
      rev = "983fa690c98814ddef92747de70586a50379a804";
      sha256 = "sha256-nCjjN/gWjptK7laFeWQiv594/FhB8LD98oFrxftQm8E=";
    };
    meta = { };
  };

  norm = {
    name = "norm";
    sub = "/src";
    src = fetchFromGitHub {
      owner = "moigagoo";
      repo = "norm";
      rev = "b9f0e8e8030afe3277d5c365f644ba8fd9d634c0";
      sha256 = "sha256-i9lw5vMxXH9i69NkLOnuPq3EgWz2/aXvIvpJ7mDaErc=";
    };
    meta = { };
  };

  oauth = rec {
    name = "oauth";
    sub = "/src";
    src = fetchFromGitHub {
      owner = "CORDEA";
      repo = name;
      rev = "b8c163b0d9cfad6d29ce8c1fb394e5f47182ee1c";
      sha256 = "sha256-ZQvzIKqTkRbvE28uOoVFGTlVMZy+gQWeyW09K7+nukw=";
    };
    dependencies = [
      sha1
    ];
    meta = { };
  };

  pixie = rec {
    name = "pixie";
    version = "3.1.2";
    src = fetchFromGitHub {
      owner = "treeform";
      repo = name;
      rev = version;
      sha256 = "sha256-rF72ybfsipBHgQmH0e6DBn1e7WWY6dGn9yp1qvLIS3A=";
    };
  };

  prologue = rec {
    name = "prologue";
    version = "0.6.4";
    sub = "/src";
    src = fetchFromGitHub {
      owner = "planety";
      repo = name;
      rev = "v${version}";
      sha256 = "sha256-CrInegW+qASgw9Uyx9wIckTmbs9k9v9oEgPruAM8sMY=";
    };
    dependencies = [
      regex
      nimcrypto
      cookiejar
      httpx
      logue
    ];
    meta = { };
  };

  q = {
    name = "q";
    src = fetchFromGitHub {
      owner = "OpenSystemsLab";
      repo = "q.nim";
      rev = "7931d15c8e5bbd50a3d1188fc95fd9fd347cb130";
      sha256 = "sha256-juYoPW1pIizSNeEf203gs/3zm64iHxzV41fKFeSuqaY=";
    };
    meta = {
      home = "https://github.com/OpenSystemsLab/q.nim";
    };
  };

  quickjwt = rec {
    name = "quickjwt";
    src = fetchFromGitHub {
      owner = "treeform";
      repo = name;
      rev = "bd250da664c38cf97a8f0960bbc5586b177f0810";
      sha256 = "sha256-S4hVO1cVySAhlIKpZldj4H5pSgMEQ6lKcgh4aA1d0V0=";
    };
    meta = { };
  };

  random = rec {
    name = "nim-random";
    sub = "/src";
    src = fetchFromGitHub {
      owner = "oprypin";
      repo = name;
      rev = "6256f0269428cf60dd31d4b74f71a62c7cc2fd10";
      sha256 = "sha256-YnXk2pjqVLNmOZgRg93xpwuYXcVQfWsh4KFIQ2pflBA=";
    };
    meta = { };
  };

  regex = rec {
    name = "nim-regex";
    sub = "/src";
    src = fetchFromGitHub {
      owner = "nitely";
      repo = name;
      rev = "v0.19.0";
      sha256 = "sha256-wam5El/S2N24zrbhw+Jo1Flkw8udrcTNu/v6QEl7KYE=";
    };
    meta = { };
  };

  segmentation = {
    name = "segmentation";
    sub = "/src";
    src = fetchFromGitHub {
      owner = "nitely";
      repo = "nim-segmentation";
      rev = "47bae531c657e01a92734e57aed552957981ad1c";
      sha256 = "sha256-1mIdSorg0EIZ0ERB9yZQmxqvFAgqv+IbFdfmII1rp7I=";
    };
    meta = { };
  };

  sequtils2 = rec {
    name = "sequtils2";
    src = fetchFromGitHub {
      owner = "Michedev";
      repo = name;
      rev = "7efcb0e34c583e73f34f6f407cb173f58ae79846";
      sha256 = "sha256-bLXQL2EM+05YjXYhSL2nPeRIDDoGuV98T3DLzrQpE4Y=";
    };
    meta = { };
  };

  sha1 = rec {
    name = "sha1";
    src = fetchFromGitHub {
      owner = "onionhammer";
      repo = name;
      rev = "92ccc5800bb0ac4865b275a2ce3c1544e98b48bc";
      sha256 = "sha256-tWHouIa6AFRmbvJaMsoWKNZX7bzqd3Je1kJ4rVHb+wM=";
    };
    meta = { };
  };

  stb_image = rec {
    name = "stb_image";
    src = fetchFromGitLab {
      owner = "define-private-public";
      repo = "stb_image-Nim";
      rev = "ba5f45286bfa9bed93d8d6b941949cd6218ec888";
      sha256 = "sha256-3xeqUumBOxuXsikgcETp5oe1GAw8jyhP3ZSpm0+Imo0=";
    };
    meta = { };
  };

  tempfile = rec {
    name = "tempfile";
    src = fetchFromGitHub {
      owner = "OpenSystemsLab";
      repo = "tempfile.nim";
      rev = "96fe74e69838c99641e4f7138c987d5f346c26f1";
      sha256 = "sha256-p7rggmIQx88gmeM8XMKS/zfNN5QrniIMLsJUV9Lehqc=";
    };
    meta = {
      home = "https://github.com/OpenSystemsLab/tempfile.nim";
    };
  };

  templates = rec {
    name = "templates";
    src = fetchFromGitHub {
      owner = "onionhammer";
      repo = "nim-templates";
      rev = "9c18d46fc1ba70e86eed2515502da34377bee088";
      sha256 = "sha256-ATvvaFwXkk7WwD+LNFp0Hv1y8CeOpSdfOcJ71W/5bCQ=";
    };
    meta = { };
  };

  unicodedb = rec {
    name = "unicodedb";
    sub = "/src";
    src = fetchFromGitHub {
      owner = "nitely";
      repo = "nim-unicodedb";
      rev = "c3c9ae079ab2eed33ffe5ca27ec4013beed7647f";
      sha256 = "sha256-1mIdSorg0EIZ0ERB9yZQmxqvFAgqv+IbFdfmII1rp7I=";
    };
    meta = { };
  };

  unicodeplus = rec {
    name = "unicodeplus";
    sub = "/src";
    src = fetchFromGitHub {
      owner = "nitely";
      repo = "nim-unicodeplus";
      rev = "fd553314df9d9a45aa0d14218e20e7c029f0baa1";
      sha256 = "sha256-y3Uqm9bppKEW9AyDC00VD37AiMYeqvM0JI/hR57iz60=";
    };
    dependencies = [
      segmentation
      unicodedb
    ];
    meta = { };
  };

  untar = rec {
    name = "untar";
    sub = "/src";
    src = fetchFromGitHub {
      owner = "dom96";
      repo = name;
      rev = "b49f6ac94974fe11cb3d396a8a9c533824a497a7";
      sha256 = "sha256-BxQaRj2td/BxxW/CvDNKyvQyzlp6xNgmjmde81iYoIs=";
    };
    meta = { };
  };

  vmath = rec {
    name = "vmath";
    sub = "/src";
    src = fetchFromGitHub {
      owner = "treeform";
      repo = name;
      rev = "1.1.4";
      sha256 = "sha256-NoGRK1cgFDTFdvjnV8e9alw7isGm2NstzIRUVm1nFRA=";
    };
    meta = { };
  };

  yaml = rec {
    name = "yaml";
    src = fetchFromGitHub {
      owner = "flyx";
      repo = "nimyaml";
      rev = "741fd18047c4940ff7cd5a1f7b3b7694a5838452";
      sha256 = "sha256-/vDKYvyx9jp1iFyNqQP64oPvwGtB7+v7kyxlSxpnunc=";
    };
    meta = { };
  };

  zip = rec {
    name = "zip";
    src = fetchFromGitHub {
      owner = "nim-lang";
      repo = name;
      rev = "6f627c7d7354e274aaf72f008cf46b09f3a37742";
      sha256 = "sha256-ZUwvIlkSaUFC0me/y8HKqItT0TQzPPH+UjGmT8FCQBo=";
    };
    meta = { };
  };

  zippy = rec {
    name = "zippy";
    src = fetchFromGitHub {
      owner = "guzba";
      repo = name;
      rev = "0.10.3";
      sha256 = "sha256-S1YulZ7ELjsQdqoL3EntHKdnpiYU47VS4sQxU6UJSkE=";
    };
    meta = { };
  };
}
