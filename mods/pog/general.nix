final: prev:
with prev;
rec {
  batwhich = pog {
    name = "batwhich";
    argumentCompletion = "executables";
    script = ''
      ${_.bat} "$(${_.which} "$1")"
    '';
  };

  get_cert = pog {
    name = "get_cert";
    script = ''
      ${_.curl} --insecure -I -vvv "$1" 2>&1 |
        ${_.awk} 'BEGIN { cert=0 } /^\* SSL connection/ { cert=1 } /^\*/ { if (cert) print }'
    '';
  };

  jql = pog {
    name = "jql";
    description = "a nice way to interactively query json";
    script = ''
      echo "" | ${pkgs.fzf}/bin/fzf --print-query --preview-window wrap --preview "cat $1 | ${_.jq} -C {q}"
    '';
  };

  jqf = pog {
    name = "jqf";
    description = "a nice way to tail -f and process each line with jq";
    arguments = [{ name = "file"; }];
    flags = [{
      name = "eval";
      description = "eval";
      default = ".";
    }];
    script = helpers: ''
      file="''${1:-/dev/stdin}"
      process_line() {
        read -r
        while true
        do
          echo "$REPLY" | ${_.jq} ''${NO_COLOR:+--monochrome-output} "$eval"
          read -r
        done
      }
      ${_.tail} -f "$file" | process_line
    '';
  };

  jwtdecode = pog {
    name = "jwtdecode";
    description = "decode a jwt on the command line!";
    script = ''
      token="$1"
      echo "$token" | ${_.jq} -R 'gsub("-";"+") | gsub("_";"/") | split(".") | .[1] | @base64d | fromjson'
    '';
  };

  slack_meme = pog {
    name = "slack_meme";
    description = "a quick and easy way to do emoji word art for slack/discord!";
    flags = [
      {
        name = "fg";
        description = "the foreground emoji";
        default = "cooldoge";
      }
      {
        name = "bg";
        description = "the background emoji";
        default = "sharkdab";
      }
    ];
    arguments = [
      { name = "word"; }
    ];
    script = ''
      word="$1"
      ${_.figlet} -f banner "$word" |
        ${_.sed} 's/#/:'"$fg"':/g;s/ /:'"$bg"':/g' |
        ${_.awk} '{print ":'"$bg"':" $1}'
    '';
  };

  fif = pog {
    name = "fif";
    description = "search for all instances of the given text within your files!";
    script = ''
      if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; exit 1; fi
      ${_.rg} --files-with-matches --no-messages "$1" |
        ${_.fzfq} --preview \
          "highlight -O ansi -l {} 2> /dev/null |
            ${_.rg} --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' ||
            ${_.rg} --ignore-case --pretty --context 10 '$1' {}"
    '';
  };

  rot13 = writeBashBinChecked "rot13" ''
    ${_.tr} 'A-Za-z' 'N-ZA-Mn-za-m'
  '';

  sin = pog {
    name = "sin";
    flags = [
      _.flags.common.color
    ];
    script = ''
      color="''${color^^}"
      # shellcheck disable=SC2046
      debug "using color $color"
      ${_.awk} -v cols="$(tput cols)" \
        '{c=int(sin(NR/10)*(cols/6)+(cols/6))+1;print(substr($0,1,c-1) "'"''${!color}"'" substr($0,c,1) "'"$RESET"'" substr($0,c+1,length($0)-c+2))}'
    '';
  };

  srv =
    let
      python = pkgs.python311.withPackages (p: with p; [ ]);
    in
    pog {
      name = "srv";
      description = "a quick and easy way to serve a directory on a given port";
      flags = [
        {
          name = "port";
          description = "the port to serve on";
          default = "7777";
        }
        {
          name = "directory";
          description = "the directory to serve";
          default = ".";
        }
        {
          name = "cgi";
          description = "run in cgi mode";
          bool = true;
        }
        {
          name = "bind";
          description = "the host to bind to";
          default = "0.0.0.0";
        }
      ];
      script = ''
        ${python}/bin/python -m http.server ''${cgi:+--cgi} --bind "$bind" --directory "$directory" "$port"
      '';
    };

  sqlfmt = pog {
    name = "sqlfmt";
    description = "a quick and easy way to do some sql formatting";
    flags = [ ];
    arguments = [
      { name = "sql_file"; }
    ];
    script = helpers: ''
      ${pkgs.python310Packages.sqlparse}/bin/sqlformat -k upper -r "$1"
      echo
    '';
  };

  whatip = pog {
    name = "whatip";
    description = "fetch the current ip of the main network interface!";
    flags = [ ];
    script = helpers: ''
      ${_.curl} -s ifconfig.io
    '';
  };

  whereami = pog {
    name = "whereami";
    description = "a quick and easy way to try a geoip lookup! (requires an api key)";
    flags = [ ];
    script = helpers: ''
      ${_.curl} -s --netrc-optional "https://api.cobi.dev/geoip/$(${whatip}/bin/whatip)" | ${_.jq}
    '';
  };

  general_pog_scripts = [
    batwhich
    get_cert
    jql
    jqf
    jwtdecode
    slack_meme
    fif
    rot13
    sin
    srv
    sqlfmt
    whatip
    whereami
  ];
}
