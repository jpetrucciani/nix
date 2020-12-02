{ config, pkgs, ... }:
let
  inherit (pkgs.hax) isDarwin fetchFromGitHub;

  # name stuff
  firstName = "jacobi";
  lastName = "petrucciani";
  personalEmail = "j@cobi.dev";
  workEmail = "jacobi@hackerrank.com";

  promptChar = if isDarwin then "ᛗ" else "ᛥ";
  # chief keefs stuff
  kwbauson-cfg = import (fetchFromGitHub {
    owner = "kwbauson";
    repo = "cfg";
    rev = "d8cfbac41eb04a8460f5bd117dca75c95b2bc088";
    sha256 = "0lh1spmrpmcipi3ij67dxpcfgkv87dp2g48gy5b9xs2myb50622h";
  });
in with pkgs.hax; {
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home = {
    username = if isDarwin then "${firstName}${lastName}" else firstName;
    homeDirectory = if isDarwin then
      "/Users/${firstName}${lastName}"
    else
      "/home/${firstName}";
    stateVersion = "21.03";

    sessionVariables = {
      EDITOR = "nano";
      HISTCONTROL = "ignoreboth";
      PAGER = "less";
      LESS = "-iR";
      BASH_SILENCE_DEPRECATION_WARNING = "1";
    };

    packages = with pkgs; [
      amazon-ecr-credential-helper
      atool
      bash-completion
      bashInteractive
      bat
      bc
      bzip2
      cachix
      coreutils-full
      cowsay
      curl
      diffutils
      dos2unix
      ed
      exa
      fd
      figlet
      file
      gawk
      gitAndTools.delta
      gnugrep
      gnused
      gnutar
      gron
      gzip
      htop
      jq
      less
      libarchive
      libnotify
      lolcat
      loop
      lsof
      man-pages
      moreutils
      nano
      ncdu
      netcat-gnu
      nix-bash-completions
      nix-direnv
      nix-index
      nix-info
      nix-prefetch-github
      nix-prefetch-scripts
      nix-tree
      nixfmt
      nmap
      openssh
      p7zip
      patch
      perl
      php
      pigz
      procps
      pssh
      pv
      ranger
      re2c
      ripgrep
      ripgrep-all
      rlwrap
      rsync
      scc
      sd
      shellcheck
      shfmt
      socat
      swaks
      time
      unzip
      watch
      watchexec
      wget
      which
      xxd
      zip
      kwbauson-cfg.better-comma
      kwbauson-cfg.nle
      kwbauson-cfg.git-trim
      (writeShellScriptBin "hms" ''
        git -C ~/.config/nixpkgs/ pull origin main
        home-manager switch
      '')
      (writeShellScriptBin "get_cert" ''
        curl --insecure -I -vvv $1 2>&1 |
          awk 'BEGIN { cert=0 } /^\* SSL connection/ { cert=1 } /^\*/ { if (cert) print }'
      '')
      (writeShellScriptBin "ecr_login" ''
        region=''${1:-us-east-1}
        aws ecr get-login-password --region ''${region} |
        docker login --username AWS \
            --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.''${region}.amazonaws.com
      '')
      (writeShellScriptBin "ecr_login_public" ''
        region=''${1:-us-east-1}
        aws ecr-public get-login-password --region ''${region} |
        docker login --username AWS \
            --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.''${region}.amazonaws.com
      '')
    ];
  };

  programs.bash = {
    enable = true;
    inherit (config.home) sessionVariables;
    historyFileSize = -1;
    historySize = -1;
    shellAliases = {
      l = "exa -alFT -L 1";
      ll = "ls -ahlFG";
      mkdir = "mkdir -pv";
      ncdu = "ncdu --color dark -ex";
      hm = "home-manager";
      wrun =
        "watchexec --debounce 50 --no-shell --clear --restart --signal SIGTERM -- ";

      # git
      g = "git";
      ga = "git add -A .";
      cm = "git commit -m ";

      # docker
      d = "docker";
      da = "docker ps -a";
      di = "docker images";
      de = "docker exec -it";
      dr = "docker run --rm -it";
      drma = "docker stop $(docker ps -aq) && docker rm -f $(docker ps -aq)";
      drmi = "di | grep none | awk '{print $3}' | sponge | xargs docker rmi";

      # k8s
      k = "kubectl";
      kx = "kubectx";
      ka = "kubectl get pods";
      kaw = "kubectl get pods -o wide";
      knuke = "kubectl delete pods --grace-period=0 --force";
      klist =
        "kubectl get pods --all-namespaces -o jsonpath='{..image}' | tr -s '[[:space:]]' '\\n' | sort | uniq -c";

      # aws stuff
      aws_id = "aws sts get-caller-identity --query Account --output text";

      # misc
      rot13 = "tr 'A-Za-z' 'N-ZA-Mn-za-m'";
      space = "du -Sh | sort -rh | head -10";
      now = "date +%s";

      # work
      local_ops = "nix-local-env run -d ~/hr/local_ops python dev.py";
      lo = "local_ops";
    };
    initExtra = ''
      HISTCONTROL=ignoreboth
      PROMPT_COMMAND='history -a;history -n'
      export PATH="$PATH:$HOME/.bin/"

      # asdf and base nix
    '' + (if isDarwin then ''
      source /usr/local/opt/asdf/asdf.sh
      source /usr/local/opt/asdf/etc/bash_completion.d/asdf.bash
    '' else ''
      source $HOME/.asdf/asdf.sh
      source $HOME/.asdf/completions/asdf.bash
    '') + ''
      source ~/.nix-profile/etc/profile.d/nix.sh

      # additional aliases
      [[ -e ~/.aliases ]] && source ~/.aliases

      # bash completions
      export XDG_DATA_DIRS="$HOME/.nix-profile/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
      source <(kubectl completion bash)
      source ~/.nix-profile/etc/profile.d/bash_completion.sh
      source ~/.nix-profile/etc/bash_completion.d/better-comma.sh
      complete -F __start_kubectl k
      source ~/.nix-profile/share/bash-completion/completions/git
      complete -o bashdefault -o default -o nospace -F __git_wrap__git_main g

      # starship
      eval "$(starship init bash)"
    '';
  };

  programs.direnv = {
    enable = true;
    enableNixDirenvIntegration = true;
  };

  programs.mcfly = {
    enable = true;
    enableBashIntegration = true;
  };

  home.file = {
    sqliterc = {
      target = ".sqliterc";
      text = ''
        .output /dev/null
        .headers on
        .mode column
        .prompt "> " ". "
        .separator ROW "\n"
        .nullvalue NULL
        .output stdout
      '';
    };
  };

  # starship config
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      character = {
        symbol = promptChar;
        success_symbol = "[${promptChar}](bright-green)";
        error_symbol = "[${promptChar}](bright-red)";
      };
      golang = {
        style = "fg:#00ADD8";
        symbol = "go ";
      };
      directory.style = "fg:#d442f5";
      nix_shell = {
        pure_msg = "";
        impure_msg = "";
        format = "via [$symbol$state]($style) ";
      };
      kubernetes = {
        disabled = false;
        style = "fg:#326ce5";
      };

      # disabled plugins
      aws.disabled = true;
      cmd_duration.disabled = true;
      gcloud.disabled = true;
      package.disabled = true;
    };
  };

  # gitconfig
  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;
    userName = "${firstName} ${lastName}";
    userEmail = if isDarwin then workEmail else personalEmail;
    aliases = {
      A = "add -A";
      pu = "pull";
      pur = "pull --rebase";
      cam = "commit -am";
      ca = "commit -a";
      cm = "commit -m";
      ci = "commit";
      co = "checkout";
      st = "status";
      br = "branch -v";
      hide = "update-index --skip-worktree";
      unhide = "update-index --no-skip-worktree";
      hidden = "! git ls-files -v | grep '^S' | cut -c3-";
      branch-name = "!git rev-parse --abbrev-ref HEAD";
      # Delete the remote version of the current branch
      unpublish = "!git push origin :$(git branch-name)";
      # Push current branch
      put = "!git push origin $(git branch-name)";
      # Pull without merging
      get = "!git pull origin $(git branch-name) --ff-only";
      # Pull Master without switching branches
      got =
        "!f() { CURRENT_BRANCH=$(git branch-name) && git checkout $1 && git pull origin $1 --ff-only && git checkout $CURRENT_BRANCH;  }; f";
      # Recreate your local branch based on the remote branch
      recreate = ''
        !f() { [[ -n $@ ]] && git checkout master && git branch -D "$@" && git pull origin "$@":"$@" && git checkout "$@"; }; f'';
      reset-submodule = "!git submodule update --init";
      sl = "!git --no-pager log -n 15 --oneline --decorate";
      sla = "log --oneline --decorate --graph --all";
      lol = "log --graph --decorate --pretty=oneline --abbrev-commit";
      lola = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
      shake = "remote prune origin";
    };
    extraConfig = {
      color.ui = true;
      push.default = "simple";
      pull.ff = "only";
      checkout.defaultRemote = "origin";
      core = {
        editor = if isDarwin then "code --wait" else "nano";
        pager = "delta --dark";
      };
      rebase.instructionFormat = "<%ae >%s";
    };
  };
  programs.git.${attrIf isDarwin "signing"} = {
    key = "03C0CBEA6EAB9258";
    gpgPath = "gpg";
    signByDefault = true;
  };
}
