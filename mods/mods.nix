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
  isNixOS = isLinux && (match ".*ID=nixos.*" (readFile /etc/os-release)) == [ ];
  isAndroid = isAarch64 && !isDarwin && !isNixOS;
  isUbuntu = isLinux && (match ".*ID=ubuntu.*" (readFile /etc/os-release)) == [ ];
  isNixDarwin = getEnv "NIXDARWIN_CONFIG" != "";

  writeBashBinChecked = name: text:
    stdenv.mkDerivation {
      inherit name text;
      dontUnpack = true;
      passAsFile = "text";
      installPhase = ''
        mkdir -p $out/bin
        echo '#!/bin/bash' > $out/bin/${name}
        cat $textPath >> $out/bin/${name}
        chmod +x $out/bin/${name}
        ${_.shellcheck} $out/bin/${name}
      '';
    };

  bashColors = [
    {
      name = "reset";
      code = ''\033[0m'';
    }
    {
      name = "black";
      code = ''\033[0;30m'';
    }
    {
      name = "red";
      code = ''\033[0;31m'';
    }
    {
      name = "green";
      code = ''\033[0;32m'';
    }
    {
      name = "yellow";
      code = ''\033[1;33m'';
    }
    {
      name = "blue";
      code = ''\033[0;34m'';
    }
    {
      name = "purple";
      code = ''\033[0;35m'';
    }
    {
      name = "cyan";
      code = ''\033[0;36m'';
    }
    {
      name = "grey";
      code = ''\033[0;90m'';
    }
  ];

  writeBashBinCheckedWithFlags =
    { name
    , script
    , description ? "a helpful script with flags, created through nix!"
    , flags ? [ ]
    , parsedFlags ? map flag flags
    , bashBible ? false
    , beforeExit ? ""
    , strict ? false
    }: writeBashBinChecked name ''
      ${if strict then "set -o errexit -o pipefail -o noclobber" else ""}
      VERBOSE=""
      NO_COLOR=""

      help() {
        cat <<EOF
        Usage: ${name} [-h|--help] [-v|--verbose] [-r|--raw] ${concatStringsSep " " (map (x: x.ex) parsedFlags)}

        ${description}

        Available flags:

        ${rightPad 20 "-h, --help"}${"\t"}Print this help and exit
        ${rightPad 20 "-v, --verbose"}${"\t"}Enable verbose logging and info
        ${rightPad 20 "--raw"}${"\t"}Disable color and other formatting
      ${ind (concatStringsSep "\n" (map (x: x.helpDoc) parsedFlags))}
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

      OPTIONS="h,r,v,${concatStringsSep "," (map (x: x.shortOpt) parsedFlags)}"
      LONGOPTS="help,raw,verbose,${concatStringsSep "," (map (x: x.longOpt) parsedFlags)}"

      # shellcheck disable=SC2251
      ! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
      if [[ ''${PIPESTATUS[0]} -ne 0 ]]; then
          exit 2
      fi
      eval set -- "$PARSED"

      # defaults
      ${concatStringsSep "\n" (map (x: x.flagDefault) parsedFlags)}

      while true; do
        case "$1" in
      ${ind (ind (concatStringsSep "\n" (map (x: x.definition) parsedFlags)))}
          -h|--help)
              help
              ;;
          -v|--verbose)
              VERBOSE=1
              shift
              ;;
          --raw)
              NO_COLOR=1
              shift
              ;;
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
      # script
      ${script}
    '';

  upper = lib.strings.toUpper;
  reverse = x: concatStringsSep "" (lib.lists.reverseList (lib.stringToCharacters x));
  rightPad = num: text: reverse (lib.strings.fixedWidthString num " " (reverse text));

  ind = text: concatStringsSep "\n" (map (x: "  ${x}") (filter isString (split "\n" text)));
  flag =
    { name
    , short ? substring 0 1 name
    , default ? ""
    , bool ? false
    , marker ? if bool then "" else ":"
    , description ? "a flag"
    }: {
      inherit name short default bool marker description;
      shortOpt = "${short}${marker}";
      longOpt = "${name}${marker}";
      flagDefault = ''${name}="${default}"'';
      ex = "[-${short}|--${name}${if bool then "" else " VAR"}]";
      helpDoc = (rightPad 20 "-${short}, --${name}") + "\t${description}${if bool then " [bool]" else ""}";
      definition = ''
        -${short}|--${name})
            ${name}=${if bool then "1" else "$2"}
            shift ${if bool then "" else "2"}
            ;;'';
    };

  foo = writeBashBinCheckedWithFlags {
    name = "foo";
    description = "a tester script for my classic bash bin + flag + bashbible memes";
    bashBible = true;
    beforeExit = ''
      green "this is beforeExit - foo test complete!"
    '';
    script = ''
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
      get_functions
      debug "''${GREEN}this is a debug message, only visible when passing -v!''${RESET}"
      black "this text is 'black'"
      red "this text 'is' red"
      green "this text is 'green'"
      yellow "this text is 'yellow'"
      blue "this text is 'blue'"
      purple "this text is 'purple'"
      cyan "this text is 'cyan'"
      grey "this text is 'grey'"
      die "this is a die" 0
    '';
  };

  soundScript = name: url: sha256:
    let
      file = pkgs.fetchurl {
        inherit url sha256;
      };
    in
    writeShellScriptBin name ''
      ${_.sox} --no-show-progress ${file} &
    '';

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
  aws_id = writeBashBinChecked "aws_id" ''
    ${_.aws} sts get-caller-identity --query Account --output text
  '';
  ecr_login = writeBashBinCheckedWithFlags {
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
  ecr_login_public = writeBashBinCheckedWithFlags {
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
  aws_bash_scripts = [
    aws_id
    ecr_login
    ecr_login_public
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

  batwhich = writeBashBinChecked "batwhich" ''
    ${_.bat} "$(which "$1")"
  '';
  hms = writeBashBinChecked "hms" _hms.switch;
  get_cert = writeBashBinChecked "get_cert" ''
    ${_.curl} --insecure -I -vvv "$1" 2>&1 |
      ${_.awk} 'BEGIN { cert=0 } /^\* SSL connection/ { cert=1 } /^\*/ { if (cert) print }'
  '';
  jql = writeBashBinChecked "jql" ''
    echo "" | ${pkgs.fzf}/bin/fzf --print-query --preview-window wrap --preview "cat $1 | ${_.jq} -C {q}"
  '';
  slack_meme = writeBashBinChecked "slack_meme" ''
    word="$1"
    fg="$2"
    bg="$3"
    ${_.figlet} -f banner "$word" | \
      ${_.sed} 's/#/:'"$fg"':/g;s/ /:'"$bg"':/g' | \
      ${_.awk} '{print ":'"$bg"':" $1}'
  '';
  fif = writeBashBinChecked "fif" ''
    if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; exit 1; fi
    ${_.rg} --files-with-matches --no-messages "$1" | \
      ${_.fzfq} --preview \
        "highlight -O ansi -l {} 2> /dev/null | \
          ${_.rg} --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || \
          ${_.rg} --ignore-case --pretty --context 10 '$1' {}"
  '';
  rot13 = writeBashBinChecked "rot13" ''
    ${_.tr} 'A-Za-z' 'N-ZA-Mn-za-m'
  '';
  sin = writeBashBinChecked "sin" ''
    # shellcheck disable=SC2046
    ${_.awk} -v cols=$(tput cols) '{c=int(sin(NR/10)*(cols/6)+(cols/6))+1;print(substr($0,1,c-1) "\x1b[41m" substr($0,c,1) "\x1b[0m" substr($0,c+1,length($0)-c+2))}'
  '';
  y2n = writeBashBinChecked "y2n" ''
    yaml="$1"
    json=$(${_.y2j} "$yaml") \
      nix eval --raw --impure --expr \
      'with import ${pkgs.path} {}; lib.generators.toPretty {} (builtins.fromJSON (builtins.getEnv "json"))'
  '';
  cache = writeBashBinCheckedWithFlags {
    name = "cache";
    flags = [
      {
        name = "cache_name";
        default = "medable";
      }
    ];
    script = ''
      ${pkgs.nix}/bin/nix-build | ${_.cachix} push "$cache_name"
    '';
  };

  general_bash_scripts = [
    batwhich
    hms
    get_cert
    jql
    slack_meme
    fif
    rot13
    sin
    y2n
    cache
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

  nix_bash_scripts = [
    nixup
    nixpy
  ];

  ### IMAGE STUFF
  scale_x = writeBashBinChecked "scale_x" ''
    file="$1"
    px="$2"
    ${_.ffmpeg} -i "$file" -vf scale="$px:-1" "''${file%.*}.$px.''${file##*.}"
  '';
  scale_y = writeBashBinChecked "scale_y" ''
    file="$1"
    px="$2"
    ${_.ffmpeg} -i "$file" -vf scale="-1:$px" "''${file%.*}.$px.''${file##*.}"
  '';
  image_bash_scripts = [
    scale_x
    scale_y
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
    shellcheck = "${pkgs.shellcheck}/bin/shellcheck";
    sort = "${pkgs.coreutils}/bin/sort";
    tr = "${pkgs.coreutils}/bin/tr";
    uniq = "${pkgs.coreutils}/bin/uniq";
    yq = "${pkgs.yq-go}/bin/yq";
    y2j = "${pkgs.remarshal}/bin/yaml2json";

    ## nix
    cachix = "${pkgs.cachix}/bin/cachix";
    nixpkgs-fmt = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt";

    ## common
    date = "${pkgs.coreutils}/bin/date";
    xargs = "${pkgs.findutils}/bin/xargs";
    fzf = "${pkgs.fzf}/bin/fzf";
    sox = "${pkgs.sox}/bin/play";
    ffmpeg = "${pkgs.ffmpeg}/bin/ffmpeg";
    ssh = "${pkgs.openssh}/bin/ssh";

    ## containers
    d = "${pkgs.docker-client}/bin/docker";
    k = "${pkgs.kubectl}/bin/kubectl";

    ## clouds
    aws = "${pkgs.awscli2}/bin/aws";

    # fzf partials
    fzfq = ''${fzf} -q "$1" --no-sort'';
    fzfqm = ''${fzfq} -m'';

    # docker partials
    di = "${d} images | ${sed} '1d'";
    get_image = "${awk} '{ print $3 }'";

    # k8s partials
    ka = "${k} get pods | ${sed} '1d'";
    get_id = "${awk} '{ print $1 }'";

    # flags to reuse
    flags = {
      aws = {
        region = {
          name = "region";
          default = "us-east-1";
          description = "the AWS region in which to do this operation";
        };
      };
      gcp = { };
      k8s = {
        ns = {
          name = "namespace";
          default = "default";
          description = "the namespace in which to do this operation";
        };
      };
      docker = { };
      common = {
        force = {
          name = "force";
          bool = true;
          description = "forcefully do this thing";
        };
      };
      nix = {
        with_python = {
          name = "with_python";
          bool = true;
          description = "whether or not to include a python with packages";
        };
        with_node = {
          name = "with_node";
          bool = true;
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
    # docker images to use in various spots
    images = [
      "alpine:latest"
      "alpine:3.15"
      "jpetrucciani/nix:2.6"
      "nicolaka/netshoot:latest"
      "node:16"
      "node:14"
      "node:12"
      "python:3.11-rc"
      "python:3.10"
      "python:3.9"
      "ubuntu:22.04"
      "ubuntu:20.04"
    ];
  };

  drmi = writeBashBinCheckedWithFlags {
    name = "drmi";
    description = "quickly remove images from your docker daemon!";
    flags = [
      _.flags.common.force
    ];
    script = ''
      ${_.di} | ${_.fzfqm} | ${_.get_image} | xargs -r ${_.d} rmi ''${force:+--force}
    '';
  };
  dshell = writeBashBinCheckedWithFlags {
    name = "dshell";
    description = "a quick and easy way to pop a shell on docker!";
    flags = [
      {
        name = "image";
        description = "the image to use for this shell";
      }
      {
        name = "port";
        description = "a port to expose to the host";
      }
      {
        name = "command";
        description = "the command to run within this shell";
        default = "bash";
      }
    ];
    script = ''
      [ -z "''${image}" ] && image=$(echo -e '${concatStringsSep "\\n" _.images}' | ${_.fzfq})
      debug "''${GREEN}running image '$image' docker!''${RESET}"
      ${_.d} run \
        -it \
        --rm \
        ''${port:+--publish $port:$port}\
        --name "''${USER}-dshell-''${RANDOM}" \
        "$image" "$command"
    '';
  };

  docker_bash_scripts = [
    drmi
    dshell
  ];

  # K8S STUFF
  # helpful shorthands
  kex = writeBashBinCheckedWithFlags {
    name = "kex";
    description = "a quick and easy way to exec into a k8s pod!";
    flags = [
      _.flags.k8s.ns
    ];
    script = ''
      pod_id=$(${_.k} --namespace "$namespace" get pods | \
        ${_.sed} '1d' | \
        ${_.fzfq} | \
        ${_.get_id})
      ${_.k} --namespace "$namespace" exec -it "$pod_id" -- sh
    '';
  };
  krm = writeBashBinCheckedWithFlags {
    name = "krm";
    description = "a quick and easy way to delete one or more pods on k8s!";
    flags = [
      _.flags.k8s.ns
      _.flags.common.force
    ];
    script = ''
      ${_.k} --namespace "$namespace" get pods | \
        ${_.sed} '1d' | \
        ${_.fzfqm} | \
        ${_.get_id} | \
        ${_.xargs} ${_.k} --namespace "$namespace" delete pods ''${force:+--grace-period=0 --force}
    '';
  };
  klist = writeBashBinCheckedWithFlags {
    name = "klist";
    description = "list out all the images in use on this k8s cluster!";
    script = ''
      ${_.k} get pods --all-namespaces -o jsonpath='{..image}' | \
        ${_.tr} -s '[[:space:]]' '\\n' | \
        ${_.sort} | \
        ${_.uniq} -c
    '';
  };
  kshell = writeBashBinCheckedWithFlags {
    name = "kshell";
    description = "a quick and easy way to pop a shell on k8s!";
    flags = [
      _.flags.k8s.ns
      {
        name = "image";
        description = "the image to use for this shell";
      }
    ];
    script = ''
      [ -z "''${image}" ] && image=$(echo -e '${concatStringsSep "\\n" _.images}' | ${_.fzfq})
      debug "''${GREEN}running image '$image' on the '$namespace' namespace!''${RESET}"
      ${_.k} run \
        -it \
        --rm \
        --restart Never \
        --namespace "$namespace" \
        --image-pull-policy=Always \
        --image="$image" \
        "''${USER}-kshell-''${RANDOM}"
    '';
  };

  kroll = writeBashBinCheckedWithFlags {
    name = "kroll";
    description = "a quick and easy way to roll a deployment's pods!";
    flags = [
      _.flags.k8s.ns
      {
        name = "deployment";
        description = "the deployment to roll. if not passed in, a dialog will pop up to select from";
      }
    ];
    script = ''
      [ -z "''${deployment}" ] && deployment=$(${_.k} --namespace "$namespace" get deployment -o wide | ${_.sed} '1d' | ${_.fzfq} | ${_.get_id})
      ${_.k} --namespace "$namespace" \
        patch deployment "$deployment" \
        --patch "''$(_get_deployment_patch)"
      ${_.k} --namespace "$namespace" rollout status deployment/"$deployment"
    '';
  };

  # deployment stuff
  _get_deployment_patch = writeBashBinChecked "_get_deployment_patch" ''
    echo "spec.template.metadata.labels.date = \"$(${_.date} +'%s')\";" | \
      ${_.gron} -u | \
      ${_.tr} -d '\n' | \
      ${_.sed} -E 's#\s+##g'
  '';
  refresh_deployment = writeBashBinCheckedWithFlags {
    name = "refresh_deployment";
    flags = [
      _.flags.k8s.ns
    ];
    script = ''
      deployment_id="$1"
      ${_.k} --namespace "$namespace" \
        patch deployment "$deployment_id" \
        --patch "''$(_get_deployment_patch)"
      ${_.k} --namespace "$namespace" rollout status deployment/"$deployment_id"
    '';
  };
  k8s_bash_scripts = [
    kex
    krm
    kroll
    kshell
    _get_deployment_patch
    refresh_deployment
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
