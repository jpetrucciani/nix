{ config, pkgs, ... }:
let
  inherit (pkgs.stdenv) isDarwin isLinux;
  promptChar = if pkgs.stdenv.isDarwin then "ᛗ" else "ᛥ";
in {
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.username = if isDarwin then "jacobipetrucciani" else "jacobi";
  home.homeDirectory =
    if isDarwin then "/Users/jacobipetrucciani" else "/home/jacobi";
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
    ed
    fd
    file
    figlet
    gawk
    gnugrep
    gnused
    gnutar
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
  ];

  programs.starship.enable = true;
  programs.starship.settings = {
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
}
