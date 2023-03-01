{ fetchFromGitHub }:
{
  chalk = {
    name = "chalk";
    src = fetchFromGitHub {
      owner = "etienne-napoleone";
      repo = "chalk";
      rev = "9ba93156e937b17c00d4802de531f535d4b2882c";
      hash = "sha256-hcyiVdpWfG5rI0u79cUqm0Naf5WfN0Wj7LNCL3k94/8=";
    };
    meta = {
      home = "https://github.com/thecodrr/chalk";
      description = "A terminal string colorizer for the V language";
    };
  };
  crayon = {
    name = "crayon";
    src = fetchFromGitHub {
      owner = "thecodrr";
      repo = "crayon";
      rev = "1ad0ed63d606850759f7a571a9aa1a5c411e0a61";
      hash = "sha256-xSJmj4M+1dP0V1TTuRMDmyjevbVHu1dv+MAV1OU8mLE=";
    };
    meta = {
      home = "https://github.com/thecodrr/crayon";
      description = "Paint your terminal output like Picasso";
    };
  };
  lol = rec {
    name = "lol";
    src = fetchFromGitHub {
      owner = "0xLeif";
      repo = name;
      rev = "f2f2603a561b8a50ae3b3d74d6790da3b43de36d";
      hash = "sha256-cHNLOoGvT1Vd/t1CbyTo548/A43CWuQgEEMqqbdRB40=";
    };
    meta = {
      home = "https://github.com/0xLeif/lol";
      description = "V version of lolcat";
    };
  };
  progressbar = rec {
    name = "progressbar";
    sub = "/progressbar";
    src = fetchFromGitHub {
      owner = "Waqar144";
      repo = name;
      rev = "0d178b592241d2d613cd54064b99d6ca74e8f6dc";
      hash = "sha256-5gHTrzYGeaJJRHUk+x93XYUpKU8gIkcSPD8rQxaun5I=";
    };
    meta = {
      home = "https://github.com/Waqar144/progressbar";
      description = "An easy to use V library for creating progress bar";
    };
  };
  termtable = rec {
    name = "termtable";
    src = fetchFromGitHub {
      owner = "serkonda7";
      repo = name;
      rev = "34e977018072ede3363f0d33d0729898e1049dd0";
      hash = "sha256-Xz0/siGUVz7Rnaouujj7o5ymUE5vqYYomDV6qRWvzEU=";
    };
    meta = {
      home = "https://github.com/serkonda7/termtable";
      description = "Simple and highly customizable library to display tables in the terminal";
    };
  };
  vesseract = rec {
    name = "vesseract";
    src = fetchFromGitHub {
      owner = "jeenyuhs";
      repo = name;
      rev = "54781c306c4f3b32de7a1a2f0765eec654edcb8c";
      hash = "sha256-fifvDRJrTjyClxYTcTdfpNNHUCj/9HV0jAbFEdimvJQ=";
    };
    meta = {
      home = "https://github.com/jeenyuhs/vesseract";
      description = "A V wrapper for Tesseract-OCR";
    };
  };
  vex = rec {
    name = "vex";
    src = fetchFromGitHub {
      owner = "nedpals";
      repo = name;
      rev = "ff48b08c845e324391db83082cec55e025fe9c73";
      hash = "sha256-E5M8XHfgoBsIlWePMeyd3MDMuqryVJk32r+G99kU9r0=";
    };
    meta = {
      home = "https://github.com/nedpals/vex";
      description = "Easy-to-use, modular web framework built for V";
    };
  };
  discord-v = rec {
    name = "discord.v";
    src = fetchFromGitHub {
      owner = "Terisback";
      repo = name;
      rev = "da464bf4534a0d89e82dcd5c14df4469a14877fb";
      hash = "sha256-oDZDkQ9oY34Erig/ReiFUB5rsA/T/hMfcyDPD5lUkfU=";
    };
    meta = {
      home = "https://github.com/nedpals/discord.v";
      description = "Discord Bot Framework written in V";
    };
  };
  range = rec {
    name = "range";
    src = fetchFromGitHub {
      owner = "Delta456";
      repo = name;
      rev = "76de43cb6a554900ff7517d6d946aa187936a398";
      hash = "sha256-wKfn2Q1bhx7Yyvd7Dd0rD4q9bMnJZpjd38vtj2OlwEQ=";
    };
    meta = {
      home = "https://github.com/Delta456/range";
      description = "Functionality of Python's range() in V";
    };
  };
  random = rec {
    name = "random";
    src = fetchFromGitHub {
      owner = "Delta456";
      repo = name;
      rev = "0cc424a5ab88867ebcc3676758bc8f676d07e745";
      hash = "sha256-tLqMr3M5B7r5vYaSZjFG+OJkyqp+UQ7S0mbqLBWZKFA=";
    };
    meta = {
      home = "https://github.com/Delta456/random";
      description = "An all purpose random library written in V";
    };
  };
  vaker = rec {
    name = "vaker";
    src = fetchFromGitHub {
      owner = "ChAoSUnItY";
      repo = name;
      rev = "62b413b250739f0e1a6483a19c338debdec0376c";
      hash = "sha256-qfHvXUSM09BiRHqfYs1fMvISHArJkgORdC8+TI6R+DA=";
    };
    meta = {
      home = "https://github.com/ChAoSUnItY/vaker";
      description = "Light-weight data faker built in V to generate massive amounts of fake (but realistic) data for testing and development";
    };
  };
  vdotenv = rec {
    name = "vdotenv";
    src = fetchFromGitHub {
      owner = "zztkm";
      repo = name;
      rev = "ea0908614cd9ec9a06cc086cad3b6084cca8fe4b";
      hash = "sha256-E7+3wTfFPYMxeNWLZ6+ByRJIXlQQwlc0nBUV6u98arc=";
    };
    meta = {
      home = "https://github.com/zztkm/vdotenv";
      description = "loads env vars from a .env file";
    };
  };
  yaml = rec {
    name = "vlang-yaml";
    src = fetchFromGitHub {
      owner = "jdonnerstag";
      repo = name;
      rev = "ad2fb4ea8be0b62766c1767937f039470c071976";
      hash = "sha256-+YtVuxJkYvNaU/mN5RnESC/yMu/qIvGdXnDM5xryjVg=";
    };
    meta = {
      home = "https://github.com/jdonnerstag/vlang-yaml";
      description = "YAML reader in native Vlang";
    };
  };
}
