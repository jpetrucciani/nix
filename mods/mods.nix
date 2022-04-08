prev: next:
with next;
with builtins; rec {
  inherit (stdenv) isLinux isDarwin isAarch64;

  nd = with builtins; fromJSON (readFile ../sources/darwin.json);
  nix-darwin = fetchFromGitHub {
    inherit (nd) rev sha256;
    owner = "LnL7";
    repo = "nix-darwin";
  };

  isM1 = isDarwin && isAarch64;
  isOldMac = isDarwin && !isAarch64;
  isNixOS = isLinux && (match ''.*ID="?nixos.*'' (readFile /etc/os-release)) == [ ];
  isAndroid = isAarch64 && !isDarwin && !isNixOS;
  isUbuntu = isLinux && (match ''.*ID="?ubuntu.*'' (readFile /etc/os-release)) == [ ];
  isNixDarwin = getEnv "NIXDARWIN_CONFIG" != "";

  writeBashBinChecked = name: text:
    stdenv.mkDerivation {
      inherit name text;
      dontUnpack = true;
      passAsFile = "text";
      nativeBuildInputs = [ pkgs.shellcheck ];
      installPhase = ''
        mkdir -p $out/bin
        echo '#!/bin/bash' > $out/bin/${name}
        cat $textPath >> $out/bin/${name}
        chmod +x $out/bin/${name}
        shellcheck $out/bin/${name}
      '';
    };

  bashEsc = ''\033'';
  bashColors = [
    {
      name = "reset";
      code = ''${bashEsc}[0m'';
    }
    # styles
    {
      name = "bold";
      code = ''${bashEsc}[1m'';
    }
    {
      name = "dim";
      code = ''${bashEsc}[2m'';
    }
    {
      name = "italic";
      code = ''${bashEsc}[3m'';
    }
    {
      name = "underlined";
      code = ''${bashEsc}[4m'';
    }
    {
      # note: this probably doesn't work in the majority of terminal emulators
      name = "blink";
      code = ''${bashEsc}[5m'';
    }
    {
      name = "invert";
      code = ''${bashEsc}[7m'';
    }
    {
      name = "hidden";
      code = ''${bashEsc}[8m'';
    }
    # foregrounds
    {
      name = "black";
      code = ''${bashEsc}[1;30m'';
    }
    {
      name = "red";
      code = ''${bashEsc}[1;31m'';
    }
    {
      name = "green";
      code = ''${bashEsc}[1;32m'';
    }
    {
      name = "yellow";
      code = ''${bashEsc}[1;33m'';
    }
    {
      name = "blue";
      code = ''${bashEsc}[1;34m'';
    }
    {
      name = "purple";
      code = ''${bashEsc}[1;35m'';
    }
    {
      name = "cyan";
      code = ''${bashEsc}[1;36m'';
    }
    {
      name = "grey";
      code = ''${bashEsc}[1;90m'';
    }
    # backgrounds
    {
      name = "red_bg";
      code = ''${bashEsc}[41m'';
    }
    {
      name = "green_bg";
      code = ''${bashEsc}[42m'';
    }
    {
      name = "yellow_bg";
      code = ''${bashEsc}[43m'';
    }
    {
      name = "blue_bg";
      code = ''${bashEsc}[44m'';
    }
    {
      name = "purple_bg";
      code = ''${bashEsc}[45m'';
    }
    {
      name = "cyan_bg";
      code = ''${bashEsc}[46m'';
    }
    {
      name = "grey_bg";
      code = ''${bashEsc}[100m'';
    }
  ];
  bashColorsList = concatStringsSep " " (map (x: x.name) (filter (x: x.name != "reset") bashColors));

  writeBashBinCheckedWithFlags = pog;
  pog =
    { name
    , version ? "0.0.0"
    , script
    , description ? "a helpful bash script with flags, created through nix + pog!"
    , flags ? [ ]
    , parsedFlags ? map flag flags
    , arguments ? [ ]
    , argumentCompletion ? "files"
    , bashBible ? false
    , beforeExit ? ""
    , strict ? false
    , flagPadding ? 20
    }:
    let
      helpers = {
        fn = {
          add = "${_.awk} '{print $1 + $2}'";
          sub = "${_.awk} '{print $1 - $2}'";
          ts_to_seconds = "${_.awk} -F\: '{ for(k=NF;k>0;k--) sum+=($k*(60^(NF-k))); print sum }'";
        };
        var = {
          empty = name: ''[ -z "''${${name}}" ]'';
          notEmpty = name: ''[ -n "''${${name}}" ]'';
        };
        file = {
          exists = name: ''[ -f "''${${name}}" ]'';
          notExists = name: ''[ ! -f "''${${name}}" ]'';
          empty = name: ''[ ! -s "''${${name}}" ]'';
          notEmpty = name: ''[ -s "''${${name}}" ]'';
        };
        yesno = { prompt ? "Would you like to continue?" }: ''
          while true; do
            read -r -p "${prompt} " yn
            case $yn in
              [Yy]* ) break;;
              [Nn]* ) exit;;
              * ) echo "Please answer y/yes or n/no!";;
            esac
          done
        '';
        timer = {
          start = name: ''_pog_start_${name}="$(${pkgs.coreutils}/bin/date +%s.%N)"'';
          stop = name: ''"$(echo "$(${pkgs.coreutils}/bin/date +%s.%N) - $_pog_start_${name}" | ${pkgs.bc}/bin/bc -l)"'';
        };
      };
    in
    stdenv.mkDerivation {
      inherit name version;
      dontUnpack = true;
      nativeBuildInputs = [ installShellFiles pkgs.shellcheck ];
      passAsFile = [
        "text"
        "completion"
      ];
      text = ''
        ${if strict then "set -o errexit -o pipefail -o noclobber" else ""}
        VERBOSE="''${POG_VERBOSE-}"
        NO_COLOR="''${POG_NO_COLOR-}"

        help() {
          cat <<EOF
          Usage: ${name} [-h|--help] [-v|--verbose] [--no-color] ${concatStringsSep " " (map (x: x.ex) parsedFlags)} ${concatStringsSep " " (map (x: upper x.name) arguments)}

          ${description}

          Flags:
        ${ind (concatStringsSep "\n" (map (x: x.helpDoc) parsedFlags))}
          ${rightPad flagPadding "-h, --help"}${"\t"}print this help and exit
          ${rightPad flagPadding "-v, --verbose"}${"\t"}enable verbose logging and info
          ${rightPad flagPadding "--no-color"}${"\t"}disable color and other formatting
        EOF
          exit 0
        }
      
        setup_colors() {
          if [[ -t 2 ]] && [[ -z "''$NO_COLOR" ]] && [[ "''$TERM" != "dumb" ]]; then
            ${concatStringsSep " " (map (x: ''${upper x.name}="${x.code}"'') bashColors)}
          else
            ${concatStringsSep " " (map (x: ''${upper x.name}=""'') bashColors)}
          fi
        }

        OPTIONS="h,v,${concatStringsSep "," (map (x: x.shortOpt) parsedFlags)}"
        LONGOPTS="help,no-color,verbose,${concatStringsSep "," (map (x: x.longOpt) parsedFlags)}"

        # shellcheck disable=SC2251
        ! PARSED=$(${_.getopt} --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
        if [[ ''${PIPESTATUS[0]} -ne 0 ]]; then
            exit 2
        fi
        eval set -- "$PARSED"

        # defaults
        ${concatStringsSep "\n" (map (x: x.flagDefault) parsedFlags)}

        while true; do
          case "$1" in
            -h|--help)
                help
                ;;
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            --no-color)
                NO_COLOR=1
                shift
                ;;
        ${ind (ind (concatStringsSep "\n" (map (x: x.definition) parsedFlags)))}
            --)
                shift
                break
                ;;
            *)
                echo "unknown flag passed"
                exit 3
                ;;
          esac
        done
        debug() {
          if [ -n "$VERBOSE" ]; then
            echo -e "$1"
          fi
        }
        cleanup() {
          trap - SIGINT SIGTERM ERR EXIT
        ${ind beforeExit}
        }
        trap cleanup SIGINT SIGTERM ERR EXIT

        ${concatStringsSep "\n" (map (x: ''
          ${x.name}(){
            echo -e "''${${upper x.name}}$1''${RESET}"
          }
        '') bashColors)}

        die() {
          local msg=$1
          local code=''${2-1}
          echo >&2 -e "''${RED}$msg''${RESET}"
          exit "$code"
        }
        setup_colors
        ${if bashBible then bashbible.bible else ""}
        ${concatStringsSep "\n" (map (x: x.flagPrompt) parsedFlags)}
        # script
        ${if builtins.isFunction script then script helpers else script}
      '';
      completion = ''
        #!/bin/bash
        _${name}()
        {
          local current previous completions
          compopt +o default

          flags(){
            echo "\
              -h -v ${concatStringsSep " " (map (x: "-${x.short}") parsedFlags)} \
              --help --verbose --no-color ${concatStringsSep " " (map (x: "--${x.name}") parsedFlags)}"
          }
          files(){
            ${_.ls}
          }
          executables(){
            echo -n "$PATH" |
              ${_.xargs} -d: -I{} -r -- find -L {} -maxdepth 1 -mindepth 1 -type f -executable -printf '%P\n' 2>/dev/null |
              ${_.sort} -u
          }

          COMPREPLY=()
          current="''${COMP_WORDS[COMP_CWORD]}"
          previous="''${COMP_WORDS[COMP_CWORD-1]}"

          if [[ $current = -* ]]; then
            completions=$(flags)
            # shellcheck disable=SC2207
            COMPREPLY=( $(compgen -W "$completions" -- "$current") )
          ${concatStringsSep "\n" (map (x: x.completionBlock) parsedFlags)}
          elif [[ $COMP_CWORD = 1 ]] || [[ $previous = -* && $COMP_CWORD = 2 ]]; then
            completions=$(${argumentCompletion} "$current")
            # shellcheck disable=SC2207
            COMPREPLY=( $(compgen -W "$completions" -- "$current") )
          else
            compopt -o default
            COMPREPLY=()
          fi
          return 0
        }
        complete -F _${name} ${name}
      '';
      installPhase = ''
        mkdir -p $out/bin
        echo '#!/bin/bash' >$out/bin/${name}
        cat $textPath >>$out/bin/${name}
        chmod +x $out/bin/${name}
        shellcheck $out/bin/${name}
        shellcheck $completionPath
        installShellCompletion --bash --name ${name} $completionPath
      '';
    };

  upper = lib.strings.toUpper;
  reverse = x: concatStringsSep "" (lib.lists.reverseList (lib.stringToCharacters x));
  rightPad = num: text: reverse (lib.strings.fixedWidthString num " " (reverse text));

  ind = text: concatStringsSep "\n" (map (x: "  ${x}") (filter isString (split "\n" text)));
  flag =
    { name
    , short ? substring 0 1 name
    , default ? ""
    , hasDefault ? (stringLength default) > 0
    , bool ? false
    , marker ? if bool then "" else ":"
    , description ? "a flag"
    , argument ? "VAR"
    , envVar ? "POG_" + (replaceStrings [ "-" ] [ "_" ] (upper name))
    , required ? false
    , prompt ? if required then "true" else ""
    , promptError ? "you must specify a value for '--${name}'!"
    , promptErrorExitCode ? 3
    , hasPrompt ? (stringLength prompt) > 0
    , completion ? ""
    , hasCompletion ? (stringLength completion) > 0
    , flagPadding ? 20
    }: {
      inherit name short default bool marker description;
      shortOpt = "${short}${marker}";
      longOpt = "${name}${marker}";
      flagDefault = ''${name}="''${${envVar}:-${default}}"'';
      flagPrompt =
        if hasPrompt then ''
          [ -z "''${${name}}" ] && ${name}="$(${prompt})"
          [ -z "''${${name}}" ] && die "${promptError}" ${toString promptErrorExitCode}
        '' else "";
      ex = "[-${short}|--${name}${if bool then "" else " ${argument}"}]";
      helpDoc =
        (rightPad flagPadding "-${short}, --${name}") +
        "\t${description}" +
        "${if hasDefault then " [default: '${default}']" else ""}" +
        "${if hasPrompt then " [will prompt if not passed in]" else ""}" +
        "${if bool then " [bool]" else ""}"
      ;
      definition = ''
        -${short}|--${name})
            ${name}=${if bool then "1" else "$2"}
            shift ${if bool then "" else "2"}
            ;;'';
      completionBlock =
        if hasCompletion then ''
          elif [[ $previous = -${short} ]] || [[ $previous = --${name} ]]; then
            # shellcheck disable=SC2116
            completions=$(${completion})
            # shellcheck disable=SC2207
            COMPREPLY=( $(compgen -W "$completions" -- "$current") )
        '' else "";
    };

  foo = pog {
    name = "foo";
    description = "a tester script for pog, my classic bash bin + flag + bashbible meme";
    bashBible = true;
    beforeExit = ''
      green "this is beforeExit - foo test complete!"
    '';
    flags = [
      _.flags.common.color
      {
        name = "functions";
        description = "list all functions! (this is a lot of text)";
        bool = true;
      }
    ];
    script = ''
      color="''${color^^}"
      trim_string "     foo       "
      upper 'foo'
      lower 'FOO'
      lstrip "The Quick Brown Fox" "The "
      urlencode "https://github.com/dylanaraps/pure-bash-bible"
      remove_array_dups 1 1 2 2 3 3 3 3 3 4 4 4 4 4 5 5 5 5 5 5
      hex_to_rgb "#FFFFFF"
      rgb_to_hex "255" "255" "255"
      date "%a %d %b  - %l:%M %p"
      uuid
      bar 1 10
      ''${functions:+get_functions}
      debug "''${GREEN}this is a debug message, only visible when passing -v (or setting POG_VERBOSE)!''${RESET}"
      black "this text is 'black'"
      red "this text is 'red'"
      green "this text is 'green'"
      yellow "this text is 'yellow'"
      blue "this text is 'blue'"
      purple "this text is 'purple'"
      cyan "this text is 'cyan'"
      grey "this text is 'grey'"
      green_bg "this text has a green background"
      purple_bg "this text has a purple background"
      yellow_bg "this text has a yellow background"
      bold "this text should be bold!"
      dim "this text should be dim!"
      italic "this text should be italic!"
      underlined "this text should be underlined!"
      blink "this text might blink on certain terminal emulators!"
      invert "this text should be inverted!"
      hidden "this text should be hidden!"
      echo -e "''${GREEN_BG}''${RED}this text is red on a green background and looks awful''${RESET}"
      echo -e "''${!color}this text has its color set by a flag '--color' or env var 'POG_COLOR' (default green)''${RESET}"
      die "this is a die" 0
    '';
  };

  soundScript = name: url: sha256:
    let
      file = pkgs.fetchurl {
        inherit url sha256;
      };
    in
    pog {
      inherit name;
      flags = [
        {
          name = "wait";
          description = "wait until done playing";
          bool = true;
        }
      ];
      script = ''
        if [ -z "$wait" ]; then
          ${_.sox} --no-show-progress ${file}
        else
          ${_.sox} --no-show-progress ${file} &
        fi
      '';
    };

  soundFolder = "https://hexa.dev/static/sounds";

  coin = soundScript "coin" "${soundFolder}/coin.wav" "18c7dfhkaz9ybp3m52n1is9nmmkq18b1i82g6vgzy7cbr2y07h93";
  guh = soundScript "guh" "${soundFolder}/guh.wav" "1chr6fagj6sgwqphrgbg1bpmyfmcd94p39d34imq5n9ik674z9sa";
  bruh = soundScript "bruh" "${soundFolder}/bruh.mp3" "11n1a20a7fj80xgynfwiq3jaq1bhmpsdxyzbnmnvlsqfnsa30vy3";
  fail = soundScript "fail" "${soundFolder}/the-price-is-wrong.mp3" "1kj0n7qwl6saqqmjn8xlkfjwimi2hyxgaqdkkzn5z1rgnhwwvp91";
  meme_sounds = [
    coin
    guh
    bruh
    fail
  ];

  ### AWS STUFF
  aws_id = pog {
    name = "aws_id";
    description = "a quick and easy way to get your AWS account ID";
    flags = [
      _.flags.aws.region
    ];
    script = ''
      ${_.aws} sts get-caller-identity --query Account --output text --region "$region"
    '';
  };
  ecr_login = pog {
    name = "ecr_login";
    description = "a quick helper script to facilitate login to AWS ECR";
    flags = [
      _.flags.aws.region
    ];
    script = ''
      ${_.aws} ecr get-login-password --region "''${region}" |
      ${_.d} login --username AWS \
        --password-stdin "$(${_.aws} sts get-caller-identity --query Account --output text).dkr.ecr.''${region}.amazonaws.com"
    '';
  };
  ecr_login_public = pog {
    name = "ecr_login_public";
    description = "a quick helper script to facilitate login to AWS public ECR";
    flags = [
      _.flags.aws.region
    ];
    script = ''
      ${_.aws} ecr-public get-login-password --region "''${region}" |
      ${_.d} login --username AWS \
          --password-stdin public.ecr.aws
    '';
  };
  aws_pog_scripts = [
    aws_id
    ecr_login
    ecr_login_public
  ];

  ### GCP STUFF
  glist = pog {
    name = "glist";
    description = "list out the gcloud projects that we can see!";
    script = ''
      ${_.gcloud} projects list
    '';
  };
  gke_config = pog {
    name = "gke_config";
    description = "fetch a kubeconfig for the given cluster";
    flags = [
      {
        name = "project";
        description = "the project to load the cluster from";
        envVar = "GCP_PROJECT";
        required = true;
      }
      {
        name = "cluster";
        description = "the cluster to load a kubeconfig for";
        envVar = "CLOUDSDK_CONTAINER_CLUSTER";
        prompt = ''
          ${_.gcloud} container clusters list 2>/dev/null |
          ${_.fzfqm} --header-lines=1 |
          ${_.awk} '{print $1}'
        '';
      }
    ];
    script = helpers: ''
      debug "getting cluster config for '$cluster' in '$region'"
      region="$(${_.gcloud} container clusters list --project "$project" 2>/dev/null | grep "$cluster " | ${_.awk} '{print $2}')"

      ${_.gcloud} \
        container clusters get-credentials \
        "$cluster" \
        --project "$project" \
        --region "$region"
    '';
  };
  gcp_pog_scripts = [
    glist
    gke_config
  ];

  ### GENERAL STUFF
  _nixos-switch = { host }: writeBashBinChecked "switch" ''
    set -eo pipefail
    toplevel=$(nix-build --expr 'with import ~/cfg {}; (nixos ~/cfg/hosts/${host}/configuration.nix).toplevel')
    if [[ $(realpath /run/current-system) != "$toplevel" ]];then
      ${nvd}/bin/nvd diff /run/current-system "$toplevel"
      sudo nix-env -p /nix/var/nix/profiles/system --set "$toplevel"
      sudo "$toplevel"/bin/switch-to-configuration switch
    fi
  '';
  _hms = {
    default = ''
      ${_.git} -C ~/.config/nixpkgs/ pull origin main
      home-manager switch
    '';
    nixOS = ''
      ${_.git} -C ~/cfg/ pull origin main
      "$(nix-build --expr 'with import ~/cfg {}; _nixos-switch' --argstr host "$HOSTNAME")"/bin/switch
    '';
    darwin = ''
      ${_.git} -C ~/.config/nixpkgs/ pull origin main
      darwin-rebuild switch -I darwin=${nix-darwin} -I darwin-config="$NIXDARWIN_CONFIG"
    '';
    switch =
      if
        isNixOS then _hms.nixOS else (if isNixDarwin then _hms.darwin else _hms.default);
  };

  batwhich = pog {
    name = "batwhich";
    argumentCompletion = "executables";
    script = ''
      ${_.bat} "$(${_.which} "$1")"
    '';
  };

  hms = writeBashBinChecked "hms" _hms.switch;

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

  srv = pog {
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
      ${pkgs.python39}/bin/python -m http.server ''${cgi:+--cgi} --bind "$bind" --directory "$directory" "$port"
    '';
  };

  general_pog_scripts = [
    batwhich
    hms
    get_cert
    jql
    slack_meme
    fif
    rot13
    sin
    srv
  ];

  nixup = writeBashBinCheckedWithFlags {
    name = "nixup";
    description = "a quick tool to create a base nix environment!";
    flags = [ _.flags.nix.with_python ];
    script = ''
      directory="$(pwd | ${_.sed} 's#.*/##')"
      tags=$(${_.curl} -fsSL https://raw.githubusercontent.com/jpetrucciani/nix/main/sources/nixpkgs.json);
      rev=$(echo "$tags" | ${_.jq} -r '.rev')
      sha=$(echo "$tags" | ${_.jq} -r '.sha256')
      py=""
      [ "$with_python" = "1" ] && py="(python39.withPackages ( p: with p; lib.flatten [requests]))"
      cat <<EOF | ${_.nixpkgs-fmt}
        with builtins;
        { pkgs ? import
            (
              fetchTarball {
                name = "nixpkgs-unstable-$(date '+%F')";
                url = "https://github.com/NixOS/nixpkgs/archive/$rev.tar.gz";
                sha256 = "$sha";
              }
            )
            {
              config = {
                allowUnfree = true;
              };
              overlays = [];
            }
        }:
        let
          inherit (pkgs.stdenv) isLinux isDarwin isAarch64;
          isM1 = isDarwin && isAarch64;
          
          packages = with pkgs; [
            just
            ''${py}
          ];
          env = pkgs.buildEnv {
            name = "$directory";
            paths = packages;
            buildInputs = packages;
          };
        in
        env
      EOF
    '';
  };
  nixpy = writeBashBinCheckedWithFlags {
    name = "nixpy";
    flags = [
      _.flags.python.package
      _.flags.python.version
    ];
    script = ''
      [ -z "$package" ] && echo "please pass a package!"; exit 1;
      [ -z "$version" ] && echo "please pass a version!"; exit 1;
      ${nix-prefetch}/bin/nix-prefetch python.pkgs.fetchPypi --pname "$package" --version "$version"
    '';
  };
  y2n = writeBashBinChecked "y2n" ''
    yaml="$1"
    json=$(${_.y2j} "$yaml") \
      nix eval --raw --impure --expr \
      'with import ${pkgs.path} {}; lib.generators.toPretty {} (builtins.fromJSON (builtins.getEnv "json"))'
  '';
  cache = writeBashBinCheckedWithFlags {
    name = "cache";
    description = "an easy tool to build nix configs and cache them to cachix!";
    flags = [
      {
        name = "cache_name";
        description = "the cachix to push to";
        default = "medable";
      }
      {
        name = "oldmac";
        description = "optionally build for x86_64-darwin (mac only)";
        bool = true;
      }
    ];
    script = ''
      ${pkgs.nix}/bin/nix-build ''${oldmac:+--system x86_64-darwin} | ${_.cachix} push "$cache_name"
    '';
  };
  j2y.py = writeTextFile {
    name = "j2y.py";
    text = ''
      import json
      import sys
      import yaml

      if __name__ == "__main__":
          data = sys.stdin.read()
          json_docs = data.split("---")
          docs = [json.loads(x) for x in json_docs if x]
          rendered = "\n---\n".join([yaml.dump(x) for x in docs])
          print(f"---\n{rendered}")
    '';
  };
  nixrender = writeBashBinCheckedWithFlags {
    name = "nixrender";
    description = "a quick and easy way to use nix to render various other config files!";
    flags = [
      {
        name = "raw";
        description = "don't apply the python post-processing";
        bool = true;
      }
    ];
    arguments = [
      { name = "nix_file"; }
    ];
    script = ''
      template="$1"
      rendered="$(${pkgs.nix_2_6}/bin/nix eval --raw -f "$template")"
      if [ -z "''${raw}" ]; then
        echo "$rendered" | ${pkgs.python39}/bin/python ${j2y.py}
      else
        echo "$rendered"
      fi
    '';
  };

  nix_pog_scripts = [
    nixup
    nixpy
    y2n
    cache
    nixrender
  ];

  ### IMAGE STUFF
  scale = pog {
    name = "scale";
    description = "a quick and easy way to scale an image/video!";
    arguments = [
      { name = "source"; }
    ];
    flags = [
      {
        name = "horizontal";
        short = "x";
        description = "the number of pixels wide the image should scale to";
      }
      {
        name = "vertical";
        short = "y";
        description = "the number of pixels high the image should scale to";
      }
      {
        name = "output";
        description = "the filename to output to [defaults to the current name with a tag]";
      }
    ];
    script = helpers: ''
      file="$1"
      name=""
      scale=""
      ${helpers.var.empty "file"} && die "you must specify a source file!" 1
      ${helpers.var.notEmpty "horizontal"} && ${helpers.var.notEmpty "vertical"} && die "you can only scale in 1 dimension!" 1
      if ${helpers.var.notEmpty "horizontal"}; then
        name="''${horizontal}x"
        scale="$horizontal:-1"
      else
        name="''${vertical}y"
        scale="-1:$vertical"
      fi
      ${helpers.var.empty "output"} && output="''${file%.*}.$name.''${file##*.}"
      ${_.ffmpeg} -i "$file" -vf scale="$scale" "$output"
    '';
  };
  flip = pog {
    name = "flip";
    description = "a quick and easy way to flip an image/video!";
    arguments = [
      { name = "source"; }
    ];
    flags = [
      {
        name = "horizontal";
        short = "x";
        description = "flip the source horizontally";
        bool = true;
      }
      {
        name = "vertical";
        short = "y";
        description = "flip the source vertically";
        bool = true;
      }
      {
        name = "output";
        description = "the filename to output to [defaults to the current name with a tag]";
      }
    ];
    script = helpers: ''
      file="$1"
      sep=""
      ${helpers.var.empty "file"} && die "you must specify a source file!" 1
      ${helpers.var.empty "horizontal"} && ${helpers.var.empty "vertical"} && die "you must specify at least one way to flip!" 1
      ${helpers.var.empty "output"} && output="''${file%.*}.flip.''${file##*.}"
      ${helpers.var.notEmpty "horizontal"} && ${helpers.var.notEmpty "vertical"} && sep=","
      ${_.ffmpeg} -i "$file" -filter:v "''${vertical:+vflip}''${sep}''${horizontal:+hflip}" -c:a copy "$output"
    '';
  };
  cut_video = pog {
    name = "cut_video";
    description = "a quick and easy way to cut a video with ffmpeg!";
    arguments = [
      { name = "source"; }
    ];
    flags = [
      {
        name = "start";
        description = "the start timestamp to cut from";
        default = "0.0";
      }
      {
        name = "end";
        description = "the end timestamp to cut to";
      }
      {
        name = "duration";
        description = "the length of time to cut out. will override --end if passed";
      }
      {
        name = "output";
        description = "the filename to output to [defaults to the current name with a tag]";
      }
    ];
    script = helpers: ''
      file="$1"
      ${helpers.var.empty "file"} && die "you must specify a source file!" 1
      ${helpers.file.notExists "file"} && die "the file '$file' does not exist!" 2
      ${helpers.var.empty "end"} && ${helpers.var.empty "duration"} && die "you must specify an end (-e|--end) or duration (-d|--duration)!" 3
      ${helpers.var.empty "output"} && output="''${file%.*}.cut.''${file##*.}"
        
      start_sec="$(echo "$start" | ${helpers.fn.ts_to_seconds})"
      if ${helpers.var.notEmpty "duration"}; then
        end_sec="$(echo "$start_sec" "$duration" | ${helpers.fn.add})"
      else
        end_sec="$(echo "$end" | ${helpers.fn.ts_to_seconds})"
      fi

      ${_.ffmpeg} -i "$file" -ss "$start_sec" -to "$end_sec" -c:v copy -c:a copy "$output"
    '';
  };
  ffmpeg_pog_scripts = [
    scale
    flip
    cut_video
  ];

  ### snippets
  _ = rec {
    # binaries
    ## text
    awk = "${pkgs.gawk}/bin/awk";
    bat = "${pkgs.bat}/bin/bat";
    curl = "${pkgs.curl}/bin/curl";
    figlet = "${pkgs.figlet}/bin/figlet";
    git = "${pkgs.git}/bin/git";
    gron = "${pkgs.gron}/bin/gron";
    jq = "${pkgs.jq}/bin/jq";
    rg = "${pkgs.ripgrep}/bin/rg";
    sed = "${pkgs.gnused}/bin/sed";
    grep = "${pkgs.gnugrep}/bin/grep";
    shfmt = "${pkgs.shfmt}/bin/shfmt";
    head = "${pkgs.coreutils}/bin/head";
    sort = "${pkgs.coreutils}/bin/sort";
    tr = "${pkgs.coreutils}/bin/tr";
    uniq = "${pkgs.coreutils}/bin/uniq";
    uuid = "${pkgs.libossp_uuid}/bin/uuid";
    yq = "${pkgs.yq-go}/bin/yq";
    y2j = "${pkgs.remarshal}/bin/yaml2json";

    ## nix
    cachix = "${pkgs.cachix}/bin/cachix";
    nixpkgs-fmt = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt";

    ## common
    ls = "${pkgs.coreutils}/bin/ls";
    date = "${pkgs.coreutils}/bin/date";
    xargs = "${pkgs.findutils}/bin/xargs";
    getopt = "${pkgs.getopt}/bin/getopt";
    fzf = "${pkgs.fzf}/bin/fzf";
    sox = "${pkgs.sox}/bin/play";
    ffmpeg = "${pkgs.ffmpeg}/bin/ffmpeg";
    ssh = "${pkgs.openssh}/bin/ssh";
    which = "${pkgs.which}/bin/which";

    ## containers
    d = "${pkgs.docker-client}/bin/docker";
    k = "${pkgs.kubectl}/bin/kubectl";

    ## clouds
    aws = "${pkgs.awscli2}/bin/aws";
    gcloud = "${pkgs.google-cloud-sdk}/bin/gcloud";

    # fzf partials
    fzfq = ''${fzf} -q "$1" --no-sort --header-first --reverse'';
    fzfqm = ''${fzfq} -m'';

    # docker partials
    di = "${d} images";
    get_image = "${awk} '{ print $3 }'";

    # k8s partials
    ka = "${k} get pods | ${sed} '1d'";
    get_id = "${awk} '{ print $1 }'";

    # json partials
    refresh_patch = ''
      echo "spec.template.metadata.labels.date = \"$(${_.date} +'%s')\";" |
       ${_.gron} -u |
       ${_.tr} -d '\n' |
       ${_.sed} -E 's#\s+##g'
    '';

    # flags to reuse
    flags = {
      aws = {
        region = {
          name = "region";
          default = "us-east-1";
          description = "the AWS region in which to do this operation";
          argument = "REGION";
          completion = ''echo -e '${concatStringsSep "\\n" _.globals.aws.regions}' '';
        };
      };
      gcp = {
        project = {
          name = "project";
          description = "the GCP project in which to do this operation";
          argument = "PROJECT_ID";
          completion = ''${_.gcloud} projects list | ${_.sed} '1d' | ${_.awk} '{print $1}' '';
        };
      };
      k8s = {
        namespace = {
          name = "namespace";
          default = "default";
          description = "the namespace in which to do this operation";
          argument = "NAMESPACE";
          completion = ''${_.k} get ns | ${_.sed} '1d' | ${_.awk} '{print $1}' '';
        };
        nodes = {
          name = "nodes";
          description = "the node(s) on which to perform this operation";
          argument = "NODES";
          completion = ''${_.k} get nodes -o wide | ${_.sed} '1d' | ${_.awk} '{print $1}' '';
          prompt = ''
            ${_.k} get nodes -o wide |
              ${_.fzfqm} --header-lines=1 |
              ${_.get_id}
          '';
          promptError = "you must specify one or more nodes!";
        };
      };
      docker = {
        image = {
          name = "image";
          description = "the docker image to use";
          argument = "IMAGE";
          prompt = ''
            echo -e "${globals.hacks.docker.default_images}\n$(${globals.hacks.docker.get_local_images})" |
              ${_.sort} -u |
              ${_.fzfq} --header "IMAGE"'';
          promptError = "you must specify a docker image!";
          completion = ''
            echo -e "${globals.hacks.docker.default_images}\n$(${globals.hacks.docker.get_local_images})" |
              ${_.sort} -u
          '';
        };
      };
      common = {
        force = {
          name = "force";
          bool = true;
          description = "forcefully do this thing";
        };
        color = {
          name = "color";
          description = "the bash color/style to use [${bashColorsList}]";
          argument = "COLOR";
          default = "green";
          completion = ''echo "${bashColorsList} ${upper bashColorsList}"'';
        };
      };
      nix = {
        with_python = {
          name = "with_python";
          short = "p";
          bool = true;
          description = "whether or not to include a python with packages";
        };
        with_node = {
          name = "with_node";
          short = "n";
          bool = true;
          description = "whether or not to include node";
        };
        with_terraform = {
          name = "with_terraform";
          short = "t";
          bool = true;
          description = "whether or not to include terraform";
        };
      };
      python = {
        package = {
          name = "package";
        };
        version = {
          name = "version";
          short = "r";
        };
      };
    };
    globals = rec {
      hacks = {
        bash_or_sh = "if command -v bash >/dev/null 2>/dev/null; then exec bash; else exec sh; fi";
        docker = {
          default_images = concatStringsSep "\\n" _.globals.images;
          get_local_images = ''
            docker image ls --format "{{.Repository}}:{{.Tag}}" 2>/dev/null |
              ${_.grep} -v '<none>' |
              ${_.sort} -u
          '';
        };
      };

      # docker images to use in various spots
      images = [
        "alpine:latest"
        "alpine:3.15"
        "jpetrucciani/nix:2.6"
        "mongo:5.0"
        "mongo:4.4.12"
        "mysql:8.0"
        "mysql:5.7"
        "nicolaka/netshoot:latest"
        "node:16"
        "node:14"
        "node:12"
        "postgres:14.2"
        "postgres:13.6"
        "postgres:12.10"
        "postgres:11.15"
        "postgres:10.20"
        "postgres:9.6"
        "python:3.11-rc"
        "python:3.10"
        "python:3.9"
        "ubuntu:22.04"
        "ubuntu:20.04"
      ];
      aws = rec {
        regions = [
          "us-east-1"
          "us-east-2"
          "us-west-1"
          "us-west-2"
          "us-gov-west-1"
          "ca-central-1"
          "eu-west-1"
          "eu-west-2"
          "eu-central-1"
          "ap-southeast-1"
          "ap-southeast-2"
          "ap-south-1"
          "ap-northeast-1"
          "ap-northeast-2"
          "sa-east-1"
          "cn-north-1"
        ];
      };
      gcp = rec {
        regions = [
          "asia-east1"
          "asia-east2"
          "asia-northeast1"
          "asia-northeast2"
          "asia-northeast3"
          "asia-south1"
          "asia-south2"
          "asia-southeast1"
          "asia-southeast2"
          "australia-southeast1"
          "australia-southeast2"
          "europe-central2"
          "europe-north1"
          "europe-west1"
          "europe-west2"
          "europe-west3"
          "europe-west4"
          "europe-west6"
          "northamerica-northeast1"
          "northamerica-northeast2"
          "southamerica-east1"
          "southamerica-west1"
          "us-central1"
          "us-east1"
          "us-east4"
          "us-west1"
          "us-west2"
          "us-west3"
          "us-west4"
        ];
      };
      tencent = rec {
        regions = [
          "ap-guangzhou"
          "ap-shanghai"
          "ap-nanjing"
          "ap-beijing"
          "ap-chengdu"
          "ap-chongqing"
          "ap-hongkong"
          "ap-singapore"
          "ap-jakarta"
          "ap-seoul"
          "ap-tokyo"
          "ap-mumbai"
          "ap-bangkok"
          "na-toronto"
          "sa-saopaulo"
          "na-siliconvalley"
          "na-ashburn"
          "eu-frankfurt"
          "eu-moscow"
        ];
      };
    };
  };

  drmi = pog {
    name = "drmi";
    description = "quickly remove images from your docker daemon!";
    flags = [
      _.flags.common.force
    ];
    script = ''
      ${_.di} | ${_.fzfqm} --header-lines=1 | ${_.get_image} | ${_.xargs} -r ${_.d} rmi ''${force:+--force}
    '';
  };
  _dex = pog {
    name = "dex";
    description = "a quick and easy way to exec into a k8s pod!";
    flags = [
      {
        name = "container";
        description = "the container to exec into";
        prompt = ''
          ${_.d} ps -a | ${_.fzfq} --header-lines=1 | ${_.get_id}
        '';
        promptError = "you must specify a container to exec into!";
      }
    ];
    script = ''
      debug "''${GREEN}exec'ing into '$container'!''${RESET}"
      ${_.d} exec --interactive --tty "$container" bash
    '';
  };
  dshell = pog {
    name = "dshell";
    description = "a quick and easy way to pop a shell on docker!";
    flags = [
      _.flags.docker.image
      {
        name = "port";
        description = "a port to expose to the host";
      }
      {
        name = "command";
        description = "the command to run within this shell";
        default = _.globals.hacks.bash_or_sh;
      }
      {
        name = "nix";
        description = "mount the /nix store as readonly in the container";
        bool = true;
      }
    ];
    script = ''
      debug "''${GREEN}running image '$image' docker!''${RESET}"
      pod_name="$(echo "''${USER:-user}-dshell-''$(${_.uuid} | ${_.head} -c 8)" | tr -cd '[:alnum:]-')"
      # shellcheck disable=SC2086
      ${_.d} run \
        --interactive \
        --tty \
        --rm \
        ''${port:+--publish $port:$port} \
        ''${nix:+--volume /nix:/nix:ro} \
        --name "$pod_name" \
        "$image" \
        sh -c "$command"
    '';
  };
  dlint = pog {
    name = "dlint";
    description = "a prescriptive hadolint dockerfile linter config";
    flags = [
      {
        name = "file";
        description = "the dockerfile to analyze";
        default = "./Dockerfile";
      }
    ];
    script = ''
      ${pkgs.hadolint}/bin/hadolint \
        --ignore DL3008 \
        --ignore DL3009 \
        --ignore DL3028 \
        --ignore DL3015 \
        --ignore DL4006 \
        "$file"
    '';
  };

  docker_pog_scripts = [
    drmi
    dshell
    dlint
    _dex
  ];

  # K8S STUFF
  # helpful shorthands
  kex = pog {
    name = "kex";
    description = "a quick and easy way to exec into a k8s pod!";
    flags = [
      _.flags.k8s.namespace
      {
        name = "pod";
        description = "the id of the pod to exec into";
        prompt = ''
          ${_.k} --namespace "$namespace" get pods |
          ${_.fzfq} --header-lines=1 |
          ${_.get_id}
        '';
        promptError = "you must specify a pod id!";
      }
    ];
    script = ''
      ${_.k} --namespace "$namespace" exec -it "$pod" -- sh -c "${_.globals.hacks.bash_or_sh}"
    '';
  };

  krm = pog {
    name = "krm";
    description = "a quick and easy way to delete one or more pods on k8s!";
    flags = [
      _.flags.k8s.namespace
      _.flags.common.force
    ];
    script = ''
      ${_.k} --namespace "$namespace" get pods |
        ${_.fzfqm} --header-lines=1 |
        ${_.get_id} |
        ${_.xargs} --no-run-if-empty ${_.k} --namespace "$namespace" delete pods ''${force:+--grace-period=0 --force}
    '';
  };

  klist = pog {
    name = "klist";
    description = "list out all the images in use on this k8s cluster!";
    script = ''
      ${_.k} get pods --all-namespaces -o jsonpath='{..image}' |
        ${_.tr} -s '[[:space:]]' '\\n' |
        ${_.sort} |
        ${_.uniq} -c
    '';
  };

  kshell = pog {
    name = "kshell";
    description = "a quick and easy way to pop a shell on k8s!";
    flags = [
      _.flags.k8s.namespace
      _.flags.docker.image
    ];
    script = ''
      debug "''${GREEN}running image '$image' on the '$namespace' namespace!''${RESET}"
      pod_name="$(echo "''${USER:-user}-kshell-''$(${_.uuid} | ${_.head} -c 8)" | tr -cd '[:alnum:]-')"
      ${_.k} run \
        --stdin \
        --tty \
        --rm \
        --restart Never \
        --namespace "$namespace" \
        --image-pull-policy=Always \
        --image="$image" \
        "$pod_name" \
        -- \
        sh -c "${_.globals.hacks.bash_or_sh}"
    '';
  };

  kroll = pog {
    name = "kroll";
    description = "a quick and easy way to roll a deployment's pods!";
    flags = [
      _.flags.k8s.namespace
      {
        name = "deployment";
        description = "the deployment to roll. if not passed in, a dialog will pop up to select from";
        prompt = ''${_.k} --namespace "$namespace" get deployment -o wide | ${_.fzfq} --header-lines=1 | ${_.get_id}'';
        promptError = "you must specify a deployment to roll!";
        completion = ''${_.k} get deployment | ${_.sed} '1d' | ${_.awk} '{print $1}' '';
      }
    ];
    script = ''
      ${_.k} --namespace "$namespace" \
        patch deployment "$deployment" \
        --patch "''$(${_.refresh_patch})"
      ${_.k} --namespace "$namespace" rollout status deployment/"$deployment"
    '';
  };

  kdesc = pog {
    name = "kdesc";
    description = "a quick and easy way to describe k8s objects!";
    flags = [
      _.flags.k8s.namespace
      {
        name = "object";
        description = "the object to describe";
        prompt = ''${_.k} --namespace "$namespace" get all | ${_.fzfq} | ${_.get_id}'';
        promptError = "you must specify an object to describe!";
      }
    ];
    script = ''
      debug "''${GREEN}describing object '$object' in the '$namespace' namespace!''${RESET}"
      ${_.k} --namespace "$namespace" describe "$object"
    '';
  };

  kdrain = pog {
    name = "kdrain";
    description = "a quick and easy way to drain one or more nodes on k8s!";
    flags = [
      _.flags.common.force
      _.flags.k8s.nodes
    ];
    script = ''
      for node in $nodes; do
        green "draining node '$node'"
        ${_.k} drain ''${force:+--delete-emptydir-data --ignore-daemonsets} "$node"
      done
    '';
  };

  k8s_pog_scripts = [
    kdesc
    kex
    krm
    kroll
    kshell
    kdrain
  ];


  github_tags = pog {
    name = "github_tags";
    description = "a nice wrapper for getting github tags for a repo!";
    flags = [
      {
        name = "latest";
        description = "fetch only the latest tag";
        bool = true;
      }
      {
        name = "owner";
        description = "the github user or organization that owns the repo";
        required = true;
      }
      {
        name = "repo";
        description = "the github repo to pull tags from";
        required = true;
      }
    ];
    script = ''
      tags="$(${_.curl} -Ls "https://api.github.com/repos/''${owner}/''${repo}/tags" |
        ${_.jq} -r '.[].name')"
      if [ -n "''${latest}" ]; then
        echo "$tags" | ${_.head} -n 1
      else
        echo "$tags"
      fi
    '';
  };

  github_pog_scripts = [
    github_tags
  ];

  yank = next.yank.overrideAttrs (attrs: {
    makeFlags = if isDarwin then [ "YANKCMD=/usr/bin/pbcopy" ] else attrs.makeFlags;
  });


  # bash bible functions implemented as a set of attribute sets in nix
  # https://github.com/dylanaraps/pure-bash-bible
  bashbible = rec {
    functions = {
      strings = rec {
        trim_string = ''
          trim_string() {
            # Usage: trim_string "   example   string    "
            : "''${1#"''${1%%[![:space:]]*}"}"
            : "''${_%"''${_##*[![:space:]]}"}"
            printf '%s\n' "$_"
          }
        '';
        trim_all = ''
          # shellcheck disable=SC2086,SC2048
          trim_all() {
            # Usage: trim_all "   example   string    "
            set -f
            set -- $*
            printf '%s\n' "$*"
            set +f
          }
        '';
        regex = ''
          regex() {
            # Usage: regex "string" "regex"
            [[ $1 =~ $2 ]] && printf '%s\n' "''${BASH_REMATCH[1]}"
          }
        '';
        split = ''
          split() {
            # Usage: split "string" "delimiter"
            IFS=$'\n' read -d "" -ra arr <<< "''${1//$2/$'\n'}"
            printf '%s\n' "''${arr[@]}"
          }
        '';
        lower = ''
          lower() {
            # Usage: lower "string"
            printf '%s\n' "''${1,,}"
          }
        '';
        upper = ''
          upper() {
            # Usage: upper "string"
            printf '%s\n' "''${1^^}"
          }
        '';
        reverse_case = ''
          reverse_case() {
            # Usage: reverse_case "string"
            printf '%s\n' "''${1~~}"
          }
        '';
        trim_quotes = ''
          trim_quotes() {
            # Usage: trim_quotes "string"
            : "''${1//\'}"
            printf '%s\n' "''${_//\"}"
          }
        '';
        strip_all = ''
          strip_all() {
            # Usage: strip_all "string" "pattern"
            printf '%s\n' "''${1//$2}"
          }
        '';
        strip = ''
          strip() {
            # Usage: strip "string" "pattern"
            printf '%s\n' "''${1/$2}"
          }
        '';
        lstrip = ''
          # shellcheck disable=SC2295
          lstrip() {
            # Usage: lstrip "string" "pattern"
            printf '%s\n' "''${1##$2}"
          }
        '';
        rstrip = ''
          # shellcheck disable=SC2295
          rstrip() {
            # Usage: rstrip "string" "pattern"
            printf '%s\n' "''${1%%$2}"
          }
        '';
        urlencode = ''
          urlencode() {
            # Usage: urlencode "string"
            local LC_ALL=C
            for (( i = 0; i < ''${#1}; i++ )); do
              : "''${1:i:1}"
              case "$_" in
                [a-zA-Z0-9.~_-])
                    printf '%s' "$_"
                ;;

                *)
                    printf '%%%02X' "'$_"
                ;;
              esac
            done
            printf '\n'
          }
        '';
        urldecode = ''
          urldecode() {
            # Usage: urldecode "string"
            : "''${1//+/ }"
            printf '%b\n' "''${_//%/\\x}"
          }
        '';
      };
      arrays = rec {
        reverse_array = ''
          reverse_array() {
            # Usage: reverse_array "array"
            shopt -s extdebug
            f()(printf '%s\n' "''${BASH_ARGV[@]}"); f "$@"
            shopt -u extdebug
          }
        '';
        remove_array_dups = ''
          remove_array_dups() {
            # Usage: remove_array_dups "array"
            declare -A tmp_array

            for i in "$@"; do
                [[ $i ]] && IFS=" " tmp_array["''${i:- }"]=1
            done

            printf '%s\n' "''${!tmp_array[@]}"
          }
        '';
        random_array_element = ''
          random_array_element() {
            # Usage: random_array_element "array"
            local arr=("$@")
            printf '%s\n' "''${arr[RANDOM % $#]}"
          }
        '';
        cycle = ''
          cycle() {
            printf '%s ' "''${arr[''${i:=0}]}"
            ((i=i>=''${#arr[@]}-1?0:++i))
          }
        '';
      };
      files = rec {
        head = ''
          head() {
            # Usage: head "n" "file"
            mapfile -tn "$1" line < "$2"
            printf '%s\n' "''${line[@]}"
          }
        '';
        tail = ''
          tail() {
            # Usage: tail "n" "file"
            mapfile -tn 0 line < "$2"
            printf '%s\n' "''${line[@]: -$1}"
          }
        '';
        lines = ''
          lines() {
            # Usage: lines "file"
            mapfile -tn 0 lines < "$1"
            printf '%s\n' "''${#lines[@]}"
          }
        '';
        count = ''
          count() {
            # Usage: count /path/to/dir/*
            #        count /path/to/dir/*/
            printf '%s\n' "$#"
          }
        '';
        extract = ''
          extract() {
            # Usage: extract file "opening marker" "closing marker"
            while IFS=$'\n' read -r line; do
              [[ $extract && $line != "$3" ]] &&
                printf '%s\n' "$line"

              [[ $line == "$2" ]] && extract=1
              [[ $line == "$3" ]] && extract=
            done < "$1"
          }
        '';
      };
      paths = rec {
        dirname = ''
          dirname() {
            # Usage: dirname "path"
            local tmp=''${1:-.}

            [[ $tmp != *[!/]* ]] && {
              printf '/\n'
              return
            }

            tmp=''${tmp%%"''${tmp##*[!/]}"}

            [[ $tmp != */* ]] && {
              printf '.\n'
              return
            }

            tmp=''${tmp%/*}
            tmp=''${tmp%%"''${tmp##*[!/]}"}

            printf '%s\n' "''${tmp:-/}"
          }
        '';
        basename = ''
          basename() {
            # Usage: basename "path" ["suffix"]
            local tmp

            tmp=''${1%"''${1##*[!/]}"}
            tmp=''${tmp##*/}
            tmp=''${tmp%"''${2/"$tmp"}"}

            printf '%s\n' "''${tmp:-/}"
          }
        '';
      };
      terminal = rec {
        get_term_size = ''
          get_term_size() {
            # Usage: get_term_size

            # (:;:) is a micro sleep to ensure the variables are
            # exported immediately.
            shopt -s checkwinsize; (:;:)
            printf '%s\n' "$LINES $COLUMNS"
          }
        '';
        get_window_size = ''
          # shellcheck disable=SC2141
          get_window_size() {
            # Usage: get_window_size
            printf '%b' "''${TMUX:+\\ePtmux;\\e}\\e[14t''${TMUX:+\\e\\\\}"
            IFS=';t' read -d t -t 0.05 -sra term_size
            printf '%s\n' "''${term_size[1]}x''${term_size[2]}"
          }
        '';
        get_cursor_pos = ''
          get_cursor_pos() {
            # Usage: get_cursor_pos
            IFS='[;' read -p $'\e[6n' -d R -rs _ y x _
            printf '%s\n' "$x $y"
          }
        '';
      };
      conversion = rec {
        hex_to_rgb = ''
          hex_to_rgb() {
            # Usage: hex_to_rgb "#FFFFFF"
            #        hex_to_rgb "000000"
            : "''${1/\#}"
            ((r=16#''${_:0:2},g=16#''${_:2:2},b=16#''${_:4:2}))
            printf '%s\n' "$r $g $b"
          }
        '';
        rgb_to_hex = ''
          rgb_to_hex() {
            # Usage: rgb_to_hex "r" "g" "b"
            printf '#%02x%02x%02x\n' "$1" "$2" "$3"
          }
        '';
      };
      other = rec {
        read_sleep = ''
          read_sleep() {
            # Usage: read_sleep 1
            #        read_sleep 0.2
            read -rt "$1" <> <(:) || :
          }
        '';
        date = ''
          date() {
            # Usage: date "format"
            # See: 'man strftime' for format.
            printf "%($1)T\\n" "-1"
          }
        '';
        uuid = ''
          uuid() {
            # Usage: uuid
            C="89ab"

            for ((N=0;N<16;++N)); do
              B="$((RANDOM%256))"

              case "$N" in
                6)  printf '4%x' "$((B%16))" ;;
                8)  printf '%c%x' "''${C:$RANDOM%''${#C}:1}" "$((B%16))" ;;

                3|5|7|9)
                  printf '%02x-' "$B"
                ;;

                *)
                  printf '%02x' "$B"
                ;;
              esac
            done

            printf '\n'
          }
        '';
        bar = ''
          bar() {
            # Usage: bar 1 10
            #            ^----- Elapsed Percentage (0-100).
            #               ^-- Total length in chars.
            ((elapsed=$1*$2/100))

            # Create the bar with spaces.
            printf -v prog  "%''${elapsed}s"
            printf -v total "%$(($2-elapsed))s"

            printf '%s\r' "[''${prog// /-}''${total}]"
          }
        '';
        get_functions = ''
          get_functions() {
            # Usage: get_functions
            IFS=$'\n' read -d "" -ra functions < <(declare -F)
            printf '%s\n' "''${functions[@]//declare -f }"
          }
        '';
        bkr = ''
          bkr() {
            (nohup "$@" &>/dev/null &)
          }
        '';
      };
    };

    bible = with lib; ''
      ## bash bible
      ### strings
      ${concatStrings (attrValues functions.strings)}
      ### arrays
      ${concatStrings (attrValues functions.arrays)}
      ### files
      ${concatStrings (attrValues functions.files)}
      ### paths
      ${concatStrings (attrValues functions.paths)}
      ### terminal
      ${concatStrings (attrValues functions.terminal)}
      ### conversion
      ${concatStrings (attrValues functions.conversion)}
      ### other
      ${concatStrings (attrValues functions.other)}
      ## end bash bible
    '';
  };
}
