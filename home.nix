{ config, pkgs, ... }:
let
  inherit (pkgs.stdenv) isDarwin isLinux;
  promptChar = if pkgs.stdenv.isDarwin then "ᛗ" else "ᛥ";

  # name stuff
  firstName = "jacobi";
  lastName = "petrucciani";
  personalEmail = "j@cobi.dev";
  workEmail = "jacobi@hackerrank.com";
in {
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.username = if isDarwin then "${firstName}${lastName}" else firstName;
  home.homeDirectory =
    if isDarwin then "/Users/${firstName}${lastName}" else "/home/${firstName}";
  home.stateVersion = "21.03";

  home.packages = with pkgs; [
    atool
    bc
    bzip2
    cachix
    coreutils-full
    cowsay
    curl
    diffutils
    direnv
    dos2unix
    exa
    ed
    fd
    file
    figlet
    gawk
    git
    gitAndTools.delta
    gnugrep
    gnused
    gnutar
    gron
    gzip
    htop
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
    nix-direnv
    nix-bash-completions
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
    pssh
    procps
    pv
    ranger
    re2c
    ripgrep
    ripgrep-all
    rlwrap
    rsync
    scc
    sd
    socat
    starship
    swaks
    time
    unzip
    watch
    wget
    which
    xxd
    zip
    (with pkgs;
      writeShellScriptBin "," ''
        cmd=$1
        db=${path + "/programs.sqlite"}
        sql="select distinct package from Programs where name = '$cmd'"
        packages=$(${sqlite}/bin/sqlite3 -init /dev/null "$db" "$sql" 2>/dev/null)
        if [[ $(echo "$packages" | wc -l) = 1 ]];then
          if [[ -z $packages ]];then
            echo "$cmd": command not found
            exit 127
          else
            attr=$packages
          fi
        else
          attr=$(echo "$packages" | ${fzy}/bin/fzy)
        fi
        if [[ -n $attr ]];then
          exec ${nixUnstable}/bin/nix --experimental-features 'nix-command = nix-flakes' shell -f ${
            toString path
          } "$attr" --command "$@"
        fi
      '')
    (writeShellScriptBin "hms" ''
      git -C ~/.config/nixpkgs/ pull origin main
      home-manager switch
    '')
  ];

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
    };
    extraConfig = {
      color.ui = true;
      push.default = "simple";
      pull.ff = "only";
      core = {
        editor = if isDarwin then "code --wait" else "nano";
        pager = "delta --dark";
      };
      rebase.instructionFormat = "<%ae >%s";
    };
  };
  programs.git.${if isDarwin then "signing" else null} = {
    key = "03C0CBEA6EAB9258";
    gpgPath = "gpg";
    signByDefault = true;
  };
}
