{ config, pkgs, ... }:

{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  home.username = if pkgs.stdenv.isDarwin then "jacobipetrucciani" else "jacobi";
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/jacobipetrucciani" else "/home/jacobi";
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
          exec ${nixUnstable}/bin/nix --experimental-features 'nix-command = nix-flakes' shell -f ${toString path} "$attr" --command "$@"
        fi
      '')
  ];
}
