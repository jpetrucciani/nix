final: prev:
with prev;
with builtins; rec {
  inherit (prev.hax) isM1 isLinux isDarwin isOldMac isNixOS isAndroid isUbuntu isNixDarwin;

  nd = with builtins; fromJSON (readFile ../sources/darwin.json);
  nix-darwin = fetchFromGitHub {
    inherit (nd) rev sha256;
    owner = "LnL7";
    repo = "nix-darwin";
  };

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

  # ~magic~ for creating local envs
  enviro =
    { name
    , tools
    , packages ? prev.lib.flatten [ (lib.flatten (builtins.attrValues tools)) ]
    , mkDerivation ? false
    }:
    if mkDerivation then
      prev.stdenv.mkDerivation
        {
          inherit name;
          buildInputs = packages;
        } else
      prev.buildEnv {
        inherit name;
        buildInputs = packages;
        paths = packages;
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
    , showDefaultFlags ? false
    , shortDefaultFlags ? true
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
          start = name: ''_pog_start_${name}="$(${_.date} +%s.%N)"'';
          stop = name: ''"$(echo "$(${_.date} +%s.%N) - $_pog_start_${name}" | ${pkgs.bc}/bin/bc -l)"'';
        };
      };
      shortHelp = if shortDefaultFlags then "-h|" else "";
      shortVerbose = if shortDefaultFlags then "-v|" else "";
      shortHelpDoc = if shortDefaultFlags then "-h, " else "";
      shortVerboseDoc = if shortDefaultFlags then "-v, " else "";
      defaultFlagHelp = if showDefaultFlags then "[${shortHelp}--help] [${shortVerbose}--verbose] [--no-color] " else "";
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
          Usage: ${name} ${defaultFlagHelp}${concatStringsSep " " (map (x: x.ex) parsedFlags)} ${concatStringsSep " " (map (x: upper x.name) arguments)}

          ${description}

          Flags:
        ${ind (concatStringsSep "\n" (map (x: x.helpDoc) parsedFlags))}
          ${rightPad flagPadding "${shortHelpDoc}--help"}${"\t"}print this help and exit
          ${rightPad flagPadding "${shortVerboseDoc}--verbose"}${"\t"}enable verbose logging and info
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
            ${shortHelp}--help)
                help
                ;;
            ${shortVerbose}--verbose)
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
        ${concatStringsSep "\n" (filter (x: x != "") (map (x: x.flagPrompt) parsedFlags))}
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
      description = "a quick and easy way to play a sound meme!";
      flags = [
        {
          name = "speed";
          description = "the speed at which to play the sound";
          default = "1.0";
        }
        {
          name = "pitch";
          description = "the pitch modifier for the sound [-1000 to 1000]";
          default = "0.0";
        }
        {
          name = "tempo";
          description = "the tempo at which to play the sound";
          default = "1.0";
        }
        {
          name = "reverse";
          description = "play the sound in reverse!";
          bool = true;
        }
      ];
      script = ''
        # shellcheck disable=SC2068
        ${_.sox} --no-show-progress ${file} speed "$speed" tempo "$tempo" pitch "$pitch" ''${reverse:+reverse} $@
      '';
    };

  soundFolder = "https://cobi.dev/static/sound";

  bruh = soundScript "bruh" "${soundFolder}/bruh.mp3" "sha256-w28wlLYOa7pttev73vStcAWs5MCRO+tfB0i6o4BQwYY=";
  coin = soundScript "coin" "${soundFolder}/coin.wav" "sha256-I8EDvMiLHf/fNk+gGBYKeNZqk47BilLHXT59NaFrh6E=";
  dababy = soundScript "dababy" "${soundFolder}/dababy.mp3" "sha256-Vg/7/WrMgi2Fz27reG1iAdxFpvdyLWAhk9+8GACL0rg=";
  do_it = soundScript "do_it" "${soundFolder}/do_it.mp3" "sha256-98bR48sTooZqqb+gqPNiBymBoii6mQAJZA7yc2m0uXo=";
  error = soundScript "error" "${soundFolder}/xp_error.mp3" "sha256-OpvwYGEbDVhaU3pGs5EWSMQKPnKLHF778UfzPfmRWp4=";
  fail = soundScript "fail" "${soundFolder}/the_price_is_wrong.mp3" "sha256-Id3NObQvh1/sn7Nh9bqHItbIpZu0IysrxkobyvGxQM4=";
  fart = soundScript "fart" "${soundFolder}/reverb_fart.mp3" "sha256-ooEfsfXtIy4ZpWUoxcTBx67Rjfzvxpy9tdyio/fzJic=";
  guh = soundScript "guh" "${soundFolder}/guh.wav" "sha256-SqdPjpkx2YJrJKOlcUlqrDpf7wpvvQwv5k8b+ZQzGbI=";
  hello_mario = soundScript "hello_mario" "${soundFolder}/hello_mario.mp3" "sha256-hRKpRcM3o+LNdCzm5VkXkXbLkBby8fzNlDb0dd5+u20=";
  waluigi = soundScript "waluigi" "${soundFolder}/waluigi.mp3" "sha256-uT9BDNDaeuQPoE/WafS0Wo6FlrCvOmDJwG7rsFVf6Zw=";
  meme_sounds = [
    bruh
    coin
    dababy
    do_it
    error
    fail
    fart
    guh
    hello_mario
    waluigi
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

  ec2_spot_interrupt =
    let
      python = pkgs.python310.withPackages (p: with p; [ requests tabulate ]);
      spots.py = writeTextFile {
        name = "spots.py";
        text = ''
          import json
          import os
          import requests
          import sys
          from tabulate import tabulate
          from dataclasses import dataclass


          FREQ = ["<5%", "5-10%", "10-15%", "15-20%", ">20%"]


          def _get(name: str, default: str = "") -> str:
              return os.getenv(name, default)


          @dataclass
          class Spot:
              name: str
              cpu: int
              ram: float
              savings: float
              interrupt: int
              emr: bool = False

              @property
              def interrupt_frequency(self) -> str:
                  return FREQ[self.interrupt]

              def __lt__(self, other) -> bool:
                  return (self.interrupt < other.interrupt) or (
                      (self.interrupt == other.interrupt) and (self.savings > other.savings)
                  )


          if __name__ == "__main__":
              region = _get("region", default="us-east-1")
              min_ram = int(_get("min_ram", default="0"))
              min_cpu = int(_get("min_cpu", default="0"))
              response = requests.get(
                  "https://spot-bid-advisor.s3.amazonaws.com/spot-advisor-data.json"
              )
              data = json.loads(response.text)
              instance_data = data["instance_types"]
              regional_data = data["spot_advisor"][region]["Linux"]
              spots = []
              for instance in regional_data:
                  stats = instance_data[instance]
                  spots.append(
                      Spot(
                          name=instance,
                          cpu=stats["cores"],
                          ram=stats["ram_gb"],
                          emr=stats["emr"],
                          interrupt=regional_data[instance]["r"],
                          savings=regional_data[instance]["s"],
                      )
                  )
              spot_list = [
                  [x.name, x.cpu, x.ram, f"{x.savings}", x.interrupt_frequency]
                  for x in sorted(spots)
                  if x.ram >= min_ram and x.cpu >= min_cpu
              ]
              text = tabulate(
                  spot_list,
                  headers=[
                      "instance type",
                      "vCPU",
                      "RAM (GiB)",
                      "% savings over OD",
                      "freq of interruption",
                  ],
              )
              print(text)
        '';
      };
    in
    pog {
      name = "ec2_spot_interrupt";
      description = "a quick and easy way to lookup aws ec2 spot interruption rates";
      flags = [
        _.flags.aws.region
        {
          name = "min_cpu";
          short = "c";
          description = "the minimum amount of vCPUs for instance lookup";
          default = "0";
        }
        {
          name = "min_ram";
          short = "m";
          description = "the minimum amount of RAM for instance lookup";
          default = "0";
        }
      ];
      script = helpers: ''
        export region
        export min_cpu
        export min_ram
        ${python}/bin/python ${spots.py}
      '';
    };
  aws_pog_scripts = [
    aws_id
    ecr_login
    ecr_login_public
    ec2_spot_interrupt
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
      region="$(${_.gcloud} container clusters list --project "$project" 2>/dev/null | grep -E "^$cluster " | ${_.awk} '{print $2}')"

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
    if [[ $(realpath /run/current-system) != "$toplevel" || "$POG_FORCE" == "1" ]];then
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
      ${pkgs.python310Packages.mitmproxy2swagger}/bin/mitmproxy2swagger -i "$flows" -o "$spec" -p "$baseurl"
      ${_.yq} -i e 'del(.paths.[].options)' "$spec"
    '';
  };

  whereami = pog {
    name = "whereami";
    description = "a quick and easy way to try a geoip lookup (requires an api key)";
    flags = [ ];
    script = helpers: ''
      ${_.curl} -s --netrc-optional "https://api.cobi.dev/geoip/$(${_.curl} -s ifconfig.io)" | ${_.jq}
    '';
  };

  general_pog_scripts = [
    batwhich
    hms
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
    whereami
  ] ++ (if isLinux then [ mitm2openapi ] else [ ]);

  nixup = writeBashBinCheckedWithFlags {
    name = "nixup";
    description = "a quick tool to create a base nix environment!";
    flags = [
      {
        name = "mkderivation";
        description = "use 'stdenv.mkDerivation' instead of 'buildEnv'";
        bool = true;
      }
      _.flags.nix.with_python
      _.flags.nix.with_elixir
      _.flags.nix.with_vlang
      _.flags.nix.with_nim
      _.flags.nix.with_golang
      _.flags.nix.with_rust
      _.flags.nix.with_node
      _.flags.nix.with_terraform
    ];
    script = ''
      directory="$(pwd | ${_.sed} 's#.*/##')"
      jacobi=$(${nix_hash_jpetrucciani}/bin/nix_hash_jpetrucciani);
      rev=$(echo "$jacobi" | ${_.jq} -r '.rev')
      sha=$(echo "$jacobi" | ${_.jq} -r '.sha256')
      py=""
      [ "$with_python" = "1" ] && py="python = [(python310.withPackages ( p: with p; lib.flatten [requests]))];"
      vlang=""
      [ "$with_vlang" = "1" ] && vlang="vlang = [vlang.withPackages (p: with p; [])];" && mkderivation=1;
      nim=""
      [ "$with_nim" = "1" ] && nim="nim = [nim.withPackages (p: with p; [])];"
      node=""
      [ "$with_node" = "1" ] && node="node = [nodejs-18_x${"\n"}nodePackages.prettier];" && mkderivation=1;
      golang=""
      [ "$with_golang" = "1" ] && golang="go = [go_1_18];"
      rust=""
      [ "$with_rust" = "1" ] && rust="rust = [rustc${"\n"}rustfmt];"
      terraform=""
      [ "$with_terraform" = "1" ] && terraform="terraform = [terraform${"\n"}terraform-ls terrascan tfsec];"
      elixir=""
      [ "$with_elixir" = "1" ] && elixir="elixir = [elixir${"\n"}(with beamPackages; [${"\n"}hex])(ifIsLinux [inotify-tools]) (ifIsDarwin [ terminal-notifier (with darwin.apple_sdk.frameworks; [ CoreFoundation CoreServices ])])];"
      envtype=""
      [ "$mkderivation" = "1" ] && envtype="${"\n"}mkDerivation = true;";
      cat -s <<EOF | ${_.nixpkgs-fmt}
        { jacobi ? import
            (
              fetchTarball {
                name = "jpetrucciani-$(date '+%F')";
                url = "https://github.com/jpetrucciani/nix/archive/$rev.tar.gz";
                sha256 = "$sha";
              }
            )
            {}
        }:
        let
          inherit (jacobi.hax) ifIsLinux ifIsDarwin;
        
          name = "$directory";
          tools = with jacobi; {
            cli = [
              jq
              nixpkgs-fmt
            ];
            ''${golang} ''${node} ''${py} ''${rust} ''${terraform} ''${vlang} ''${nim} ''${elixir}
          };

          env = jacobi.enviro {
            inherit name tools; $envtype
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
  nixrender =
    pog {
      name = "nixrender";
      description = "a quick and easy way to use nix to render various other config files!";
      flags = [ ];
      arguments = [
        { name = "nix_file"; }
      ];
      script = ''
        template="$1"
        rendered="$(${pkgs.nix}/bin/nix eval --raw -f "$template")"
        echo "$rendered"
      '';
    };

  hex = pog {
    name = "hex";
    description = "a quick and easy way to render full kubespecs from nix files";
    flags = [
      {
        name = "target";
        description = "the file to render specs from";
        default = "./specs.nix";
      }
      {
        name = "dryrun";
        description = "just run the diff, don't prompt to apply";
        bool = true;
      }
      {
        name = "render";
        description = "only render and patch, do not diff or apply";
        bool = true;
      }
      {
        name = "check";
        description = "whether to check the hex for deprecations";
        bool = true;
      }
      {
        name = "prettify";
        description = "whether to run prettier on the hex output yaml";
        bool = true;
      }
      {
        name = "force";
        description = "force apply the resulting hex without a diff (WARNING - BE CAREFUL)";
        bool = true;
      }
    ];
    script =
      let
        steps = {
          render = "render";
          patch = "patch";
          diff = "diff";
          apply = "apply";
        };
        _ = {
          k = "${pkgs.kubectl}/bin/kubectl";
          nr = "${nixrender}/bin/nixrender";
          delta = "${pkgs.delta}/bin/delta";
          pluto = "${pluto}/bin/pluto";
          mktemp = "${pkgs.coreutils}/bin/mktemp";
          prettier = "${pkgs.nodePackages.prettier}/bin/prettier --write --config ${../.prettierrc.js}";
        };
      in
      helpers: ''
        ${helpers.file.notExists "target"} && die "the file to render ('$target') does not exist!"
        rendered=$(${_.mktemp})
        diffed=$(${_.mktemp})
        debug "''${GREEN}render to '$rendered'"
        ${helpers.timer.start steps.render}
        ${_.nr} "$target" >"$rendered"
        render_exit_code=$?
        render_runtime=${helpers.timer.stop steps.render}
        debug "''${GREEN}rendered to '$rendered' in $render_runtime''${RESET}"
        if [ $render_exit_code -ne 0 ]; then
          die "nixrender failed!" 2
        fi
        ${helpers.var.notEmpty "check"} && ${_.pluto} detect "$rendered"
        ${helpers.var.notEmpty "prettify"} && ${_.prettier} --parser yaml "$rendered" >/dev/null
        if ${helpers.var.notEmpty "render"}; then
          blue "rendered hex to '$rendered'"
          exit 0
        fi
        if ${helpers.var.notEmpty "force"}; then
          ${helpers.timer.start steps.apply}
          ${pkgs.kubectl}/bin/kubectl apply -f "$rendered"
          apply_runtime=${helpers.timer.stop steps.apply}
          debug "''${GREEN}force applied '$rendered' in $apply_runtime''${RESET}"
          exit 0
        fi
        ${helpers.timer.start steps.diff}
        ${_.k} diff -f "$rendered" >"$diffed"
        diff_exit_code=$?
        diff_runtime=${helpers.timer.stop steps.diff}
        debug "''${GREEN}diffed '$rendered' to '$diffed' in $diff_runtime [exit code $diff_exit_code]''${RESET}"
        if [ $diff_exit_code -ne 0 ] && [ $diff_exit_code -ne 1 ]; then
          die "diff of hex failed!" 3
        fi
        if [ -s "$diffed" ]; then
          debug "''${GREEN}changes detected!''${RESET}"
        else
          blue "no changes in hex detected!"
          exit 0
        fi
        ${_.delta} <"$diffed"
        ${helpers.var.notEmpty "dryrun"} && exit 0
        echo "---"
        ${helpers.yesno {prompt="Would you like to apply these changes?";}}
        echo "---"
        ${helpers.timer.start steps.apply}
        ${_.k} apply -f "$rendered"
        apply_runtime=${helpers.timer.stop steps.apply}
        debug "''${GREEN}applied '$rendered' in $apply_runtime''${RESET}"
      '';
  };

  nix_pog_scripts = [
    nixup
    nixpy
    y2n
    cache
    nixrender
    hex
  ];

  ### FFMPEG STUFF
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
    script = helpers: with helpers; ''
      file="$1"
      name=""
      scale=""
      ${var.empty "file"} && die "you must specify a source file!" 1
      ${var.notEmpty "horizontal"} && ${var.notEmpty "vertical"} && die "you can only scale in 1 dimension!" 1
      if ${var.notEmpty "horizontal"}; then
        name="''${horizontal}x"
        scale="$horizontal:-1"
      else
        name="''${vertical}y"
        scale="-1:$vertical"
      fi
      ${var.empty "output"} && output="''${file%.*}.$name.''${file##*.}"
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
    script = helpers: with helpers; ''
      file="$1"
      sep=""
      ${var.empty "file"} && die "you must specify a source file!" 1
      ${var.empty "horizontal"} && ${var.empty "vertical"} && die "you must specify at least one way to flip!" 1
      ${var.empty "output"} && output="''${file%.*}.flip.''${file##*.}"
      ${var.notEmpty "horizontal"} && ${var.notEmpty "vertical"} && sep=","
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
    script = helpers: with helpers; ''
      file="$1"
      ${var.empty "file"} && die "you must specify a source file!" 1
      ${file.notExists "file"} && die "the file '$file' does not exist!" 2
      ${var.empty "end"} && ${var.empty "duration"} && die "you must specify an end (-e|--end) or duration (-d|--duration)!" 3
      ${var.empty "output"} && output="''${file%.*}.cut.''${file##*.}"
        
      start_sec="$(echo "$start" | ${fn.ts_to_seconds})"
      if ${var.notEmpty "duration"}; then
        end_sec="$(echo "$start_sec" "$duration" | ${fn.add})"
      else
        end_sec="$(echo "$end" | ${fn.ts_to_seconds})"
      fi

      ${_.ffmpeg} -ss "$start_sec" -i "$file" -to "$end_sec" -c:v copy -c:a copy "$output"
    '';
  };
  crop_video = pog {
    name = "crop_video";
    description = "a quick and easy way to crop a video with ffmpeg!";
    arguments = [
      { name = "source"; }
    ];
    shortDefaultFlags = false;
    flags = [
      {
        name = "x";
        short = "x";
        description = "the x value to start the crop box at";
        default = "0";
      }
      {
        name = "y";
        short = "y";
        description = "the y value to start the crop box at";
        default = "0";
      }
      {
        name = "width";
        description = "the width of the crop box";
        default = "in_w";
      }
      {
        name = "height";
        description = "the height of the crop box";
        default = "in_h";
      }
      {
        name = "output";
        description = "the filename to output to [defaults to the current name with a tag]";
      }
    ];
    script = helpers: with helpers; ''
      file="$1"
      ${var.empty "file"} && die "you must specify a source file!" 1
      ${file.notExists "file"} && die "the file '$file' does not exist!" 2
      ${var.empty "output"} && output="''${file%.*}.crop.''${file##*.}"
      ${_.ffmpeg} -i "$file" -filter:v "crop=$width:$height:$x:$y" "$output"
    '';
  };
  to_mp3 = pog {
    name = "to_mp3";
    description = "a quick and easy way to convert an audio file to mp3!";
    arguments = [
      { name = "source"; }
    ];
    flags = [
      {
        name = "output";
        description = "the filename to output to [defaults to the current name with a tag]";
      }
      {
        name = "quality";
        description = "quality, 0 to 9 (lower is higher quality)";
        default = "4";
      }
    ];
    script = helpers: with helpers; ''
      # https://trac.ffmpeg.org/wiki/Encode/MP3
      file="$1"
      ${var.empty "file"} && die "you must specify a source file!" 1
      ${var.empty "output"} && output="''${file%.*}.mp3"
      ${_.ffmpeg} -i "$file" -c:v copy -c:a libmp3lame -q:a "$quality" "$output"
    '';
  };
  ffmpeg_pog_scripts = [
    scale
    flip
    cut_video
    crop_video
    to_mp3
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
    mktemp = "${pkgs.coreutils}/bin/mktemp";
    sort = "${pkgs.coreutils}/bin/sort";
    tail = "${pkgs.coreutils}/bin/tail";
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
    ffmpeg = "${pkgs.ffmpeg_5-full}/bin/ffmpeg";
    ssh = "${pkgs.openssh}/bin/ssh";
    which = "${pkgs.which}/bin/which";

    ## containers
    d = "${pkgs.docker-client}/bin/docker";
    k = "${pkgs.kubectl}/bin/kubectl";

    ## clouds
    aws = "${prev.awscli2}/bin/aws";
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
        with_golang = {
          name = "with_golang";
          short = "g";
          bool = true;
          description = "whether or not to include golang";
        };
        with_node = {
          name = "with_node";
          short = "n";
          bool = true;
          description = "whether or not to include node";
        };
        with_rust = {
          name = "with_rust";
          short = "r";
          bool = true;
          description = "whether or not to include rust";
        };
        with_terraform = {
          name = "with_terraform";
          short = "t";
          bool = true;
          description = "whether or not to include terraform";
        };
        with_vlang = {
          name = "with_vlang";
          short = "w";
          bool = true;
          description = "whether or not to include a vlang with dependencies";
        };
        with_nim = {
          name = "with_nim";
          short = "i";
          bool = true;
          description = "whether or not to include a nim with dependencies";
        };
        with_elixir = {
          name = "with_elixir";
          short = "e";
          bool = true;
          description = "whether or not to include elixir with dependencies";
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
        "alpine:3.16"
        "alpine:3.15"
        "jpetrucciani/nix:2.9"
        "jpetrucciani/nix:2.6"
        "mongo:5.0"
        "mongo:4.4.12"
        "mysql:8.0"
        "mysql:5.7"
        "nicolaka/netshoot:latest"
        "node:18"
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

  yank = prev.yank.overrideAttrs (attrs: {
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
