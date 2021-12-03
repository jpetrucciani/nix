prev: next:
with next;
rec {
  inherit (stdenv) isLinux isDarwin isAarch64;

  isNixOS = isLinux && (builtins.match ".*ID=nixos.*" (builtins.readFile /etc/os-release)) == [ ];
  isM1 = isDarwin && isAarch64;

  github = "https://raw.githubusercontent.com/jpetrucciani/nix/main";

  foo = prev.writeShellScriptBin "foo" ''echo foo'';

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
        ${shellcheck}/bin/shellcheck $out/bin/${name}
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
      ${pkgs.sox}/bin/play --no-show-progress ${file} &
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
      ${pkgs.awscli2}/bin/aws sts get-caller-identity --query Account --output text
    ''
  );
  ecr_login = (
    writeBashBinChecked "ecr_login" ''
      region="''${1:-us-east-1}"
      ${pkgs.awscli2}/bin/aws ecr get-login-password --region "''${region}" |
      ${pkgs.docker-client}/bin/docker login --username AWS \
          --password-stdin "$(${pkgs.awscli2}/bin/aws sts get-caller-identity --query Account --output text).dkr.ecr.''${region}.amazonaws.com"
    ''
  );
  ecr_login_public = (
    writeBashBinChecked "ecr_login_public" ''
      region="''${1:-us-east-1}"
      ${pkgs.awscli2}/bin/aws ecr-public get-login-password --region "''${region}" |
      ${pkgs.docker-client}/bin/docker login --username AWS \
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
      ${pkgs.git}/bin/git -C ~/.config/nixpkgs/ pull origin main
      home-manager switch
    '';
    nixOS = ''
      ${pkgs.git}/bin/git -C ~/cfg/ pull origin main
      sudo nixos-rebuild switch
    '';
    switch =
      if
        isNixOS then _hms.nixOS else _hms.default;
  };

  batwhich = (
    writeBashBinChecked "batwhich" ''
      ${pkgs.bat}/bin/bat "$(which "$1")"
    ''
  );
  hms = (
    writeBashBinChecked "hms" _hms.switch
  );
  get_cert = (
    writeBashBinChecked "get_cert" ''
      ${pkgs.curl}/bin/curl --insecure -I -vvv "$1" 2>&1 |
        ${pkgs.gawk}/bin/awk 'BEGIN { cert=0 } /^\* SSL connection/ { cert=1 } /^\*/ { if (cert) print }'
    ''
  );
  jql = (
    writeBashBinChecked "jql" ''
      echo "" | ${pkgs.fzf}/bin/fzf --print-query --preview-window wrap --preview "cat $1 | ${pkgs.jq}/bin/jq -C {q}"
    ''
  );
  slack_meme = (
    writeBashBinChecked "slack_meme" ''
      word="$1"
      fg="$2"
      bg="$3"
      ${pkgs.figlet}/bin/figlet -f banner "$word" | \
        ${pkgs.gnused}/bin/sed 's/#/:'"$fg"':/g;s/ /:'"$bg"':/g' | \
        ${pkgs.gawk}/bin/awk '{print ":'"$bg"':" $1}'
    ''
  );
  ssh_fwd = (
    writeBashBinChecked "ssh_fwd" ''
      host="$1"
      port="$2"
      ${pkgs.openssh}/bin/ssh -L "$port:$host:$port" "$host"
    ''
  );
  fif = (
    writeBashBinChecked "fif" ''
      if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; exit 1; fi
      ${pkgs.ripgrep}/bin/rg --files-with-matches --no-messages "$1" | \
        ${pkgs.fzf}/bin/fzf --preview \
          "highlight -O ansi -l {} 2> /dev/null | \
            ${pkgs.ripgrep}/bin/rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || \
            ${pkgs.ripgrep}/bin/rg --ignore-case --pretty --context 10 '$1' {}"
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
  ];

  ### IMAGE STUFF
  scale_x = (
    writeBashBinChecked "scale_x" ''
      file="$1"
      px="$2"
      ${pkgs.ffmpeg}/bin/ffmpeg -i "$file" -vf scale="$px:-1" "''${file%.*}.$px.''${file##*.}"
    ''
  );
  scale_y = (
    writeBashBinChecked "scale_y" ''
      file="$1"
      px="$2"
      ${pkgs.ffmpeg}/bin/ffmpeg -i "$file" -vf scale="-1:$px" "''${file%.*}.$px.''${file##*.}"
    ''
  );
  image_bash_scripts = [
    scale_x
    scale_y
  ];


  ### DOCKER STUFF
  _ = rec {
    # binaries
    d = "${pkgs.docker-client}/bin/docker";
    k = "${pkgs.kubectl}/bin/kubectl";
    sed = "${pkgs.gnused}/bin/sed";
    awk = "${pkgs.gawk}/bin/awk";
    gron = "${pkgs.gron}/bin/gron";
    tr = "${pkgs.coreutils}/bin/tr";
    xargs = "${pkgs.findutils}/bin/xargs";
    date = "$(${pkgs.coreutils}/bin/date";

    # fzf partials
    fzf = ''${pkgs.fzf}/bin/fzf -q "$1" --no-sort'';
    fzfm = ''${fzf} -m'';

    # docker partials
    di = "${d} images | ${sed} '1d'";
    get_image = "${awk} '{ print $3 }'";

    # k8s partials
    ka = "${k} get pods | ${sed} '1d'";
    get_id = "${awk} '{ print $1 }'";

    # full commands
    drmi = "${di} | ${fzfm} | ${get_image} | xargs -r ${d} rmi";
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
        ${_.fzf} | \
        ${_.get_id})
      ${_.k} --namespace "$namespace" exec -it "$pod_id" -- sh
    ''
  );
  krm = (
    writeBashBinChecked "krm" ''
      namespace="''${1:-default}"
      ${_.k} --namespace "$namespace" get pods | \
        ${_.sed} '1d' | \
        ${_.fzfm} | \
        ${_.get_id} | \
        ${_.xargs} ${_.k} --namespace "$namespace" delete pods
    ''
  );
  krmf = (
    writeBashBinChecked "krmf" ''
      namespace="''${1:-default}"
      ${_.k} --namespace "$namespace" get pods | \
        ${_.sed} '1d' | \
        ${_.fzfm} | \
        ${_.get_id} | \
        ${_.xargs} ${_.k} --namespace "$namespace" delete pods --grace-period=0 --force
    ''
  );

  # deployment stuff
  _get_deployment_patch = (
    writeBashBinChecked "_get_deployment_patch" ''
      echo "spec.template.metadata.labels.date = \"${_.date} +'%s')\";" | \
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

}
