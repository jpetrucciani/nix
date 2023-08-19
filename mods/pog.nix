final: prev:
let
  inherit (builtins) isString;
  inherit (builtins) concatStringsSep filter replaceStrings split stringLength substring;
  inherit (prev.lib) stringToCharacters;
  inherit (prev.lib.lists) reverseList;
  inherit (prev.lib.strings) fixedWidthString toUpper;
  upper = toUpper;
  reverse = x: concatStringsSep "" (reverseList (stringToCharacters x));
  rightPad = num: text: reverse (fixedWidthString num " " (reverse text));
  ind = text: concatStringsSep "\n" (map (x: "  ${x}") (filter isString (split "\n" text)));
in
rec {
  _ = with prev; rec {
    # binaries
    ## text
    awk = "${pkgs.gawk}/bin/awk";
    bat = "${pkgs.bat}/bin/bat";
    curl = "${pkgs.curl}/bin/curl";
    figlet = "${pkgs.figlet}/bin/figlet";
    git = "${pkgs.git}/bin/git";
    gum = "${pkgs.gum}/bin/gum";
    gron = "${pkgs.gron}/bin/gron";
    jq = "${pkgs.jq}/bin/jq";
    rg = "${pkgs.ripgrep}/bin/rg";
    sed = "${pkgs.gnused}/bin/sed";
    grep = "${pkgs.gnugrep}/bin/grep";
    shfmt = "${pkgs.shfmt}/bin/shfmt";
    cut = "${pkgs.coreutils}/bin/cut";
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

    # ssh partials
    _ssh = {
      hosts = ''${_.grep} '^Host' ~/.ssh/config ~/.ssh/config.d/* 2>/dev/null | ${_.grep} -v '[?*]' | ${_.cut} -d ' ' -f 2- | ${_.sort} -u'';
    };

    # docker partials
    docker = {
      di = "${d} images";
      da = "${d} ps -a";
      get_image = "${awk} '{ print $3 }'";
      get_container = "${awk} '{ print $1 }'";
    };

    # k8s partials
    k8s = {
      ka = "${k} get pods | ${sed} '1d'";
      get_id = "${awk} '{ print $1 }'";
      fmt = rec {
        _fmt =
          let
            parseCol = col: "${col.k}:${col.v}";
          in
          columns: "-o custom-columns='${concatStringsSep "," (map parseCol columns)}'";
        _cols = {
          name = { k = "NAME"; v = ".metadata.name"; };
          namespace = { k = "NAMESPACE"; v = ".metadata.namespace"; };
          ready = { k = "READY"; v = ''status.conditions[?(@.type=="Ready")].status''; };
          status = { k = "STATUS"; v = ".status.phase"; };
          ip = { k = "IP"; v = ".status.podIP"; };
          node = { k = "NODE"; v = ".spec.nodeName"; };
          image = { k = "IMAGE"; v = ".spec.containers[*].image"; };
          host_ip = { k = "HOST_IP"; v = ".status.hostIP"; };
          start_time = { k = "START_TIME"; v = ".status.startTime"; };
        };
        pod = _fmt (with _cols; [
          name
          namespace
          ready
          status
          ip
          node
          image
        ]);
      };
    };

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
          envVar = "AWS_REGION";
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
        all_namespaces = {
          name = "all_namespaces";
          short = "A";
          description = "operate across all namespaces";
          bool = true;
        };
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
              ${_.k8s.get_id}
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
      github = {
        owner = {
          name = "owner";
          description = "the github user or organization that owns the repo";
          required = true;
        };
        repo = {
          name = "repo";
          description = "the github repo to pull tags from";
          required = true;
        };
      };
      nix = {
        overmind = {
          name = "overmind";
          short = "o";
          bool = true;
          description = "include an overmind config";
        };
        with_db_pg = {
          name = "with_db_pg";
          short = "d";
          bool = true;
          description = "include postgres db and helper scripts";
        };
        with_db_redis = {
          name = "with_db_redis";
          short = "";
          bool = true;
          description = "include redis db and helper scripts";
        };
        with_python = {
          name = "with_python";
          short = "p";
          bool = true;
          description = "include a python with packages";
        };
        with_golang = {
          name = "with_golang";
          short = "g";
          bool = true;
          description = "include golang";
        };
        with_node = {
          name = "with_node";
          short = "n";
          bool = true;
          description = "include node";
        };
        with_rust = {
          name = "with_rust";
          short = "";
          bool = true;
          description = "include rust";
        };
        with_ruby = {
          name = "with_ruby";
          short = "";
          bool = true;
          description = "include ruby";
        };
        with_terraform = {
          name = "with_terraform";
          short = "t";
          bool = true;
          description = "include terraform";
        };
        with_pulumi = {
          name = "with_pulumi";
          short = "";
          bool = true;
          description = "include pulumi";
        };
        with_vlang = {
          name = "with_vlang";
          short = "v";
          bool = true;
          description = "include a vlang with dependencies";
        };
        with_nim = {
          name = "with_nim";
          short = "";
          bool = true;
          description = "include a nim with dependencies";
        };
        with_elixir = {
          name = "with_elixir";
          short = "";
          bool = true;
          description = "include elixir with dependencies";
        };
        with_crystal = {
          name = "with_crystal";
          short = "";
          bool = true;
          description = "include crystal with dependencies";
        };
        with_php = {
          name = "with_php";
          short = "";
          bool = true;
          description = "include a php with packages";
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
      ssh = {
        host = {
          name = "host";
          short = "H";
          description = "the ssh host to use";
          completion = _._ssh.hosts;
          prompt = ''${_._ssh.hosts} | ${_.fzfq} --header "HOST"'';
          promptError = "you must specify a ssh host!";
        };
      };
    };
    globals = {
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
        "alpine:3.18"
        "ghcr.io/jpetrucciani/foundry-nix:latest"
        "ghcr.io/jpetrucciani/foundry-python311:latest"
        "ghcr.io/jpetrucciani/foundry-python312:latest"
        "nicolaka/netshoot:latest"
        "node:16"
        "node:20"
        "python:3.11"
        "python:3.12"
        "ubuntu:22.04"
      ];
      aws = {
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
      gcp = {
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
      tencent = {
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

  writeBashBinChecked = name: text:
    prev.stdenv.mkDerivation {
      inherit name text;
      dontUnpack = true;
      passAsFile = "text";
      nativeBuildInputs = [ prev.pkgs.shellcheck ];
      installPhase = ''
        mkdir -p $out/bin
        echo '#!/bin/bash' > $out/bin/${name}
        cat $textPath >> $out/bin/${name}
        chmod +x $out/bin/${name}
        shellcheck $out/bin/${name}
      '';
    };

  # bad
  enviro =
    { name
    , tools
    , packages ? prev.lib.flatten [ (builtins.attrValues tools) ]
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
  _toolset = tools: prev.lib.flatten [ (builtins.attrValues tools) ];

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
  pog = {
    helpers = rec {
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
      dir = {
        exists = name: ''[ -d "''${${name}}" ]'';
        notExists = name: ''[ ! -d "''${${name}}" ]'';
        empty = name: ''[ -z "$(ls -A '${name}')" ]'';
        notEmpty = name: ''[ ! -z "$(ls -A '${name}')" ]'';
      };
      timer = {
        start = name: ''_pog_start_${name}="$(${_.date} +%s.%N)"'';
        stop = name: ''"$(echo "$(${_.date} +%s.%N) - $_pog_start_${name}" | ${prev.pkgs.bc}/bin/bc -l)"'';
        round = places: ''${prev.pkgs.coreutils}/bin/printf '%.*f\n' ${toString places}'';
      };
      confirm = yesno;
      yesno = { prompt ? "Would you like to continue?", exit_code ? 0 }: ''
        ${_.gum} confirm "${prompt}" || exit ${toString exit_code}
      '';

      spinner = { command, spinner ? "dot", align ? "left", title ? "processing..." }: ''
        ${_.gum} spin --spinner="${spinner}" --align="${align}" --title="${title}" ${command}
      '';
      spinners = [
        "line"
        "dot"
        "minidot"
        "jump"
        "pulse"
        "points"
        "globe"
        "moon"
        "monkey"
        "meter"
        "hamburger"
      ];

      # shorthands
      flag = var.notEmpty;
      notFlag = var.empty;
    };
    __functor = _: pogFn;
  };
  pogFn =
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
      inherit (pog) helpers;
      filterBlank = filter (x: x != "");
      shortHelp = if shortDefaultFlags then "-h|" else "";
      shortVerbose = if shortDefaultFlags then "-v|" else "";
      shortHelpDoc = if shortDefaultFlags then "-h, " else "";
      shortVerboseDoc = if shortDefaultFlags then "-v, " else "";
      defaultFlagHelp = if showDefaultFlags then "[${shortHelp}--help] [${shortVerbose}--verbose] [--no-color] " else "";
    in
    prev.stdenv.mkDerivation {
      inherit version;
      pname = name;
      dontUnpack = true;
      nativeBuildInputs = [ prev.installShellFiles prev.shellcheck ];
      passAsFile = [
        "text"
        "completion"
      ];
      text = ''
        # shellcheck disable=SC2317
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

        OPTIONS="${if shortDefaultFlags then "h,v," else ""}${concatStringsSep "," (map (x: x.shortOpt) parsedFlags)}"
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
            echo -e "''${PURPLE}$1''${RESET}" >&2
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
        ${if bashBible then prev.bashbible.bible else ""}
        ${concatStringsSep "\n" (filterBlank (map (x: x.flagPrompt) parsedFlags))}
        # script
        ${if builtins.isFunction script then script helpers else script}
      '';
      completion =
        let
          argCompletion =
            if argumentCompletion == "files" then ''
              compopt -o default
              COMPREPLY=()
            '' else ''
              completions=$(${argumentCompletion} "$current")
              # shellcheck disable=SC2207
              COMPREPLY=( $(compgen -W "$completions" -- "$current") )
            '';
        in
        ''
          #!/bin/bash
          # shellcheck disable=SC2317
          _${name}()
          {
            local current previous completions
            compopt +o default

            flags(){
              echo "\
                ${if shortDefaultFlags then "-h -v " else ""}${concatStringsSep " " (map (x: "-${x.short}") (filter (x: x.short != "") parsedFlags))} \
                --help --verbose --no-color ${concatStringsSep " " (map (x: "--${x.name}") parsedFlags)}"
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
              ${argCompletion}
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
      meta = {
        inherit description;
        mainProgram = name;
      };
    };

  flag =
    { name
    , _name ? (replaceStrings [ "-" ] [ "_" ] name)
    , short ? substring 0 1 name
    , shortDef ? if short != "" then "-${short}|" else ""
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
      inherit short default bool marker description;
      name = _name;
      shortOpt = "${short}${marker}";
      longOpt = "${_name}${marker}";
      flagDefault = ''${_name}="''${${envVar}:-${default}}"'';
      flagPrompt =
        if hasPrompt then ''
          [ -z "''${${_name}}" ] && ${_name}="$(${prompt})"
          [ -z "''${${_name}}" ] && die "${promptError}" ${toString promptErrorExitCode}
        '' else "";
      ex = "[${shortDef}--${_name}${if bool then "" else " ${argument}"}]";
      helpDoc =
        let
          base = (if short != "" then "-${short}, " else "") + "--${_name}";
        in
        (rightPad flagPadding base) +
        "\t${description}" +
        "${if hasDefault then " [default: '${default}']" else ""}" +
        "${if hasPrompt then " [will prompt if not passed in]" else ""}" +
        "${if bool then " [bool]" else ""}"
      ;
      definition = ''
        ${shortDef}--${_name})
            ${_name}=${if bool then "1" else "$2"}
            shift ${if bool then "" else "2"}
            ;;'';
      completionBlock =
        if hasCompletion then ''
          elif [[ $previous = -${short} ]] || [[ $previous = --${_name} ]]; then
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
        short = "";
        description = "list all functions! (this is a lot of text)";
        bool = true;
      }
    ];
    script = h: with h; ''
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
      debug "''${GREEN}this is a debug message, only visible when passing -v (or setting POG_VERBOSE)!"
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
      ${spinner {command="sleep 3";}}
      ${confirm {exit_code=69;}}
      die "this is a die" 0
    '';
  };
}
