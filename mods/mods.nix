prev: next:
with next;
rec {
  inherit (stdenv) isLinux isDarwin isAarch64;

  isNixOS = isLinux && (builtins.match ".*ID=nixos.*" (builtins.readFile /etc/os-release)) == [ ];
  isM1 = isDarwin && isAarch64;

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

  soundScript = name: url: hash:
    let
      file = pkgs.fetchurl {
        url = url;
        sha256 = hash;
      };
    in
    writeShellScriptBin name ''
      ${_.sox} --no-show-progress ${file} &
    '';

  soundFolder = "https://hexa.dev/static/sounds";

  coin = (soundScript "coin" "${soundFolder}/coin.wav" "18c7dfhkaz9ybp3m52n1is9nmmkq18b1i82g6vgzy7cbr2y07h93");
  guh = (soundScript "guh" "${soundFolder}/guh.wav" "1chr6fagj6sgwqphrgbg1bpmyfmcd94p39d34imq5n9ik674z9sa");
  bruh = (soundScript "bruh" "${soundFolder}/bruh.mp3" "11n1a20a7fj80xgynfwiq3jaq1bhmpsdxyzbnmnvlsqfnsa30vy3");
  fail = (soundScript "fail" "${soundFolder}/the-price-is-wrong.mp3" "1kj0n7qwl6saqqmjn8xlkfjwimi2hyxgaqdkkzn5z1rgnhwwvp91");
  meme_sounds = [
    coin
    guh
    bruh
    fail
  ];

  ### AWS STUFF
  aws_id = (
    writeBashBinChecked "aws_id" ''
      ${_.aws} sts get-caller-identity --query Account --output text
    ''
  );
  ecr_login = (
    writeBashBinChecked "ecr_login" ''
      region="''${1:-us-east-1}"
      ${_.aws} ecr get-login-password --region "''${region}" |
      ${_.d} login --username AWS \
          --password-stdin "$(${_.aws} sts get-caller-identity --query Account --output text).dkr.ecr.''${region}.amazonaws.com"
    ''
  );
  ecr_login_public = (
    writeBashBinChecked "ecr_login_public" ''
      region="''${1:-us-east-1}"
      ${_.aws} ecr-public get-login-password --region "''${region}" |
      ${_.d} login --username AWS \
          --password-stdin public.ecr.aws
    ''
  );
  aws_bash_scripts = [
    aws_id
    ecr_login
    ecr_login_public
  ];

  ### GENERAL STUFF
  _hms = {
    default = ''
      ${_.git} -C ~/.config/nixpkgs/ pull origin main
      home-manager switch
    '';
    nixOS = ''
      ${_.git} -C ~/cfg/ pull origin main
      sudo nixos-rebuild switch
    '';
    switch =
      if
        isNixOS then _hms.nixOS else _hms.default;
  };

  batwhich = (
    writeBashBinChecked "batwhich" ''
      ${_.bat} "$(which "$1")"
    ''
  );
  hms = (
    writeBashBinChecked "hms" _hms.switch
  );
  get_cert = (
    writeBashBinChecked "get_cert" ''
      ${_.curl} --insecure -I -vvv "$1" 2>&1 |
        ${_.awk} 'BEGIN { cert=0 } /^\* SSL connection/ { cert=1 } /^\*/ { if (cert) print }'
    ''
  );
  jql = (
    writeBashBinChecked "jql" ''
      echo "" | ${pkgs.fzf}/bin/fzf --print-query --preview-window wrap --preview "cat $1 | ${_.jq} -C {q}"
    ''
  );
  slack_meme = (
    writeBashBinChecked "slack_meme" ''
      word="$1"
      fg="$2"
      bg="$3"
      ${_.figlet} -f banner "$word" | \
        ${_.sed} 's/#/:'"$fg"':/g;s/ /:'"$bg"':/g' | \
        ${_.awk} '{print ":'"$bg"':" $1}'
    ''
  );
  ssh_fwd = (
    writeBashBinChecked "ssh_fwd" ''
      host="$1"
      port="$2"
      ${_.ssh} -L "$port:$host:$port" "$host"
    ''
  );
  fif = (
    writeBashBinChecked "fif" ''
      if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; exit 1; fi
      ${_.rg} --files-with-matches --no-messages "$1" | \
        ${_.fzfq} --preview \
          "highlight -O ansi -l {} 2> /dev/null | \
            ${_.rg} --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || \
            ${_.rg} --ignore-case --pretty --context 10 '$1' {}"
    ''
  );
  rot13 = (
    writeBashBinChecked "rot13" ''
      ${_.tr} 'A-Za-z' 'N-ZA-Mn-za-m'
    ''
  );
  sin = (
    writeBashBinChecked "sin" ''
      # shellcheck disable=SC2046
      ${_.awk} -v cols=$(tput cols) '{c=int(sin(NR/10)*(cols/6)+(cols/6))+1;print(substr($0,1,c-1) "\x1b[41m" substr($0,c,1) "\x1b[0m" substr($0,c+1,length($0)-c+2))}'
    ''
  );

  general_bash_scripts = [
    batwhich
    hms
    get_cert
    jql
    slack_meme
    ssh_fwd
    fif
    rot13
    sin
  ];


  nixup = (writeBashBinChecked "nixup" ''
    directory="$(pwd | ${_.sed} 's#.*/##')"
    tags=$(${nix-prefetch-git}/bin/nix-prefetch-git \
        --quiet \
        --no-deepClone \
        --branch-name nixpkgs-unstable \
        https://github.com/nixos/nixpkgs.git | \
      ${_.jq} '{ rev: .rev, sha256: .sha256 }');
    rev=$(echo "$tags" | jq -r '.rev')
    sha=$(echo "$tags" | jq -r '.sha256')
    cat <<EOF | ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt
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
            overlays = [];
          }
      }:
      let
        packages = with pkgs; [
          just
        ];
        env = pkgs.buildEnv {
          name = "$directory";
          paths = packages;
          buildInputs = packages;
        };
      in
      env
    EOF
  '');

  nix_bash_scripts = [
    nixup
  ];

  ### IMAGE STUFF
  scale_x = (
    writeBashBinChecked "scale_x" ''
      file="$1"
      px="$2"
      ${_.ffmpeg} -i "$file" -vf scale="$px:-1" "''${file%.*}.$px.''${file##*.}"
    ''
  );
  scale_y = (
    writeBashBinChecked "scale_y" ''
      file="$1"
      px="$2"
      ${_.ffmpeg} -i "$file" -vf scale="-1:$px" "''${file%.*}.$px.''${file##*.}"
    ''
  );
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
    tr = "${pkgs.coreutils}/bin/tr";
    yq = "${pkgs.yq-go}/bin/yq";

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

    # full commands
    drmi = "${di} | ${fzfqm} | ${get_image} | xargs -r ${d} rmi";
  };

  drmi = (writeBashBinChecked "drmi" _.drmi);
  drmif = (writeBashBinChecked "drmif" ''${_.drmi} --force'');
  docker_bash_scripts = [
    drmi
    drmif
  ];

  # K8S STUFF
  # helpful shorthands
  kex = (
    writeBashBinChecked "kex" ''
      namespace="''${1:-default}"
      pod_id=$(${_.k} --namespace "$namespace" get pods | \
        ${_.sed} '1d' | \
        ${_.fzfq} | \
        ${_.get_id})
      ${_.k} --namespace "$namespace" exec -it "$pod_id" -- sh
    ''
  );
  krm = (
    writeBashBinChecked "krm" ''
      namespace="''${1:-default}"
      ${_.k} --namespace "$namespace" get pods | \
        ${_.sed} '1d' | \
        ${_.fzfqm} | \
        ${_.get_id} | \
        ${_.xargs} ${_.k} --namespace "$namespace" delete pods
    ''
  );
  krmf = (
    writeBashBinChecked "krmf" ''
      namespace="''${1:-default}"
      ${_.k} --namespace "$namespace" get pods | \
        ${_.sed} '1d' | \
        ${_.fzfqm} | \
        ${_.get_id} | \
        ${_.xargs} ${_.k} --namespace "$namespace" delete pods --grace-period=0 --force
    ''
  );

  # deployment stuff
  _get_deployment_patch = (
    writeBashBinChecked "_get_deployment_patch" ''
      echo "spec.template.metadata.labels.date = \"$(${_.date} +'%s')\";" | \
        ${_.gron} -u | \
        ${_.tr} -d '\n' | \
        ${_.sed} -E 's#\s+##g'
    ''
  );
  refresh_deployment = (
    writeBashBinChecked "refresh_deployment" ''
      deployment_id="$1"
      namespace="''${2:-default}"
      ${_.k} --namespace "$namespace" \
        patch deployment "$deployment_id" \
        --patch "''$(_get_deployment_patch)"
      ${_.k} --namespace "$namespace" rollout status deployment/"$deployment_id"
    ''
  );
  k8s_bash_scripts = [
    kex
    krm
    krmf
    _get_deployment_patch
    refresh_deployment
  ];

  yank = next.yank.overrideAttrs (attrs: {
    makeFlags = if isDarwin then [ "YANKCMD=/usr/bin/pbcopy" ] else attrs.makeFlags;
  });
}
