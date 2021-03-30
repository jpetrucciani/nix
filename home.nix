{ config, pkgs, ... }:
let
  inherit (pkgs.hax) isDarwin fetchFromGitHub;

  # name stuff
  firstName = "jacobi";
  lastName = "petrucciani";
  personalEmail = "j@cobi.dev";
  workEmail = "jacobi@hackerrank.com";

  onAws = builtins.getEnv "USER" == "ubuntu";
  promptChar = if isDarwin then "ᛗ" else "ᛥ";
  # chief keefs stuff
  kwbauson-cfg = import (fetchFromGitHub {
    owner = "kwbauson";
    repo = "cfg";
    rev = "2da560982596354d8dca5a9fd1aec699723657b9";
    sha256 = "1q8m9cy3n8yppvvbzsrgcdjmzs3d5cv2ppl859amh6kffbfqvmhd";
  });

  coinSound = pkgs.fetchurl {
    url = "https://cobi.dev/sounds/coin.wav";
    sha256 = "18c7dfhkaz9ybp3m52n1is9nmmkq18b1i82g6vgzy7cbr2y07h93";
  };
  guhSound = pkgs.fetchurl {
    url = "https://cobi.dev/sounds/guh.wav";
    sha256 = "1chr6fagj6sgwqphrgbg1bpmyfmcd94p39d34imq5n9ik674z9sa";
  };
  bruhSound = pkgs.fetchurl {
    url = "https://cobi.dev/sounds/bruh.mp3";
    sha256 = "11n1a20a7fj80xgynfwiq3jaq1bhmpsdxyzbnmnvlsqfnsa30vy3";
  };

in with pkgs.hax; {
  nixpkgs.overlays = import ./overlays.nix;
  nixpkgs.config = { allowUnfree = true; };
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.htop.enable = true;
  programs.dircolors.enable = true;

  home = {
    username = if isDarwin then
      "${firstName}${lastName}"
    else
      (if onAws then "ubuntu" else firstName);
    homeDirectory = if isDarwin then
      "/Users/${firstName}${lastName}"
    else
      (if onAws then "/home/ubuntu" else "/home/${firstName}");
    stateVersion = "21.03";

    sessionVariables = {
      EDITOR = "nano";
      HISTCONTROL = "ignoreboth";
      PAGER = "less";
      LESS = "-iR";
      BASH_SILENCE_DEPRECATION_WARNING = "1";
    };

    packages = with pkgs;
      lib.flatten [
        amazon-ecr-credential-helper
        atool
        bash-completion
        bashInteractive
        bat
        bc
        bzip2
        cacert
        cachix
        cloudquery
        coreutils-full
        cowsay
        curl
        dasel
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
        just
        kubectx
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
        nixUnstable
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
        procps
        pssh
        pup
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
        sox
        swaks
        time
        tealdeer
        unzip
        watch
        watchexec
        wget
        which
        xxd
        yq-go
        zip
        kwbauson-cfg.better-comma
        kwbauson-cfg.nle
        kwbauson-cfg.git-trim
        (writeBashBinChecked "hms" ''
          git -C ~/.config/nixpkgs/ pull origin main
          home-manager switch
        '')
        (writeBashBinChecked "get_cert" ''
          curl --insecure -I -vvv "$1" 2>&1 |
            awk 'BEGIN { cert=0 } /^\* SSL connection/ { cert=1 } /^\*/ { if (cert) print }'
        '')
        (writeBashBinChecked "ecr_login" ''
          region="''${1:-us-east-1}"
          aws ecr get-login-password --region "''${region}" |
          docker login --username AWS \
              --password-stdin "$(aws sts get-caller-identity --query Account --output text).dkr.ecr.''${region}.amazonaws.com"
        '')
        (writeBashBinChecked "ecr_login_public" ''
          region="''${1:-us-east-1}"
          aws ecr-public get-login-password --region "''${region}" |
          docker login --username AWS \
              --password-stdin public.ecr.aws
        '')
        (writeBashBinChecked "u" ''
          sudo apt update
          sudo apt upgrade
        '')
        (writeBashBinChecked "slack_meme" ''
          word="$1"
          fg="$2"
          bg="$3"
          figlet -f banner "$word" | sed 's/#/:'"$fg"':/g;s/ /:'"$bg"':/g' | awk '{print ":'"$bg"':" $1}'
        '')
        (soundScript "coin" coinSound)
        (soundScript "guh" guhSound)
        (soundScript "bruh" bruhSound)
      ];
  };

  programs.bash = {
    enable = true;
    inherit (config.home) sessionVariables;
    historyFileSize = -1;
    historySize = -1;
    shellAliases = {
      ",," = "nix run github:kwbauson/cfg#better-comma -- ";
      ls = "ls --color=auto";
      l = "exa -alFT -L 1";
      ll = "ls -ahlFG";
      mkdir = "mkdir -pv";
      ncdu = "ncdu --color dark -ex";
      hm = "home-manager";
      wrun =
        "watchexec --debounce 50 --no-shell --clear --restart --signal SIGTERM -- ";
      fzfp = "fzf --preview 'bat --style=numbers --color=always {}'";
      strip = ''
        sed -E 's#^\s+|\s+$##g'
      '';

      # nix
      nix_hash = "nix-prefetch-url";
      nix_hash_git = "nix-prefetch-git";
      nix_hash_kwb = "nix-prefetch-git https://github.com/kwbauson/cfg.git";

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
      local_ops = "nix-local-env -d ~/hr/local_ops run python dev.py";
      lo = "local_ops";
    };
    initExtra = ''
      HISTCONTROL=ignoreboth
      set +h
      export PATH="$PATH:$HOME/.bin/"

      # asdf and base nix
    '' + (if isDarwin then ''
      [[ -e /usr/local/opt/asdf/asdf.sh ]] && source /usr/local/opt/asdf/asdf.sh
      [[ -e /usr/local/opt/asdf/etc/bash_completion.d/asdf.bash ]] && source /usr/local/opt/asdf/etc/bash_completion.d/asdf.bash
    '' else ''
      [[ -e $HOME/.asdf/asdf.sh ]] && source $HOME/.asdf/asdf.sh
      [[ -e $HOME/.asdf/completions/asdf.bash ]] && source $HOME/.asdf/completions/asdf.bash
    '') + ''
      [[ -e ~/.nix-profile/etc/profile.d/nix.sh ]] && source ~/.nix-profile/etc/profile.d/nix.sh

      _kube_contexts() {
        local curr_arg;
        curr_arg=''${COMP_WORDS[COMP_CWORD]}
        COMPREPLY=( $(compgen -W "- $(kubectl config get-contexts --output='name')" -- $curr_arg ) );
      }

      _kube_namespaces() {
        local curr_arg;
        curr_arg=''${COMP_WORDS[COMP_CWORD]}
        COMPREPLY=( $(compgen -W "- $(kubectl get namespaces -o=jsonpath='{range .items[*].metadata.name}{@}{"\n"}{end}')" -- $curr_arg ) );
      }

      # additional aliases
      [[ -e ~/.aliases ]] && source ~/.aliases

      # bash completions
      export XDG_DATA_DIRS="$HOME/.nix-profile/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
      source <(kubectl completion bash)
      source <(just --completions bash)
      source ~/.nix-profile/etc/profile.d/bash_completion.sh
      complete -F __start_kubectl k
      source ~/.nix-profile/share/bash-completion/completions/git
      source ~/.nix-profile/share/bash-completion/completions/ssh
      complete -o bashdefault -o default -o nospace -F __git_wrap__git_main g
      complete -F _kube_contexts kubectx kx
      complete -F _kube_namespaces kubens kns

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

  programs.fzf = {
    enable = true;
    enableBashIntegration = false;
    defaultCommand = "fd -tf -c always -H --ignore-file ${./ignore} -E .git";
    defaultOptions = words "--ansi --reverse --multi --filepath-word";
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

  programs.tmux = {
    enable = true;
    tmuxp.enable = true;
    historyLimit = 500000;
    extraConfig = ''
      set -g base-index 1
      set -g pane-base-index 1
      # Setting the prefix from `C-b` to `C-a`.
      # By remapping the `CapsLock` key to `Ctrl`,
      # you can make triggering commands more comfottable!
      set -g prefix C-a

      set -g status-keys vi
      setw -g mode-keys vi
      setw -g mouse on
      setw -g monitor-activity on

      # Moving between windows.
      unbind [
      unbind ]
      bind -r [ select-window -t :-
      bind -r ] select-window -t :+

      # Pane resizing.
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Maximize and restore a pane.
      unbind Up
      bind Up new-window -d -n tmp \; swap-pane -s tmp.1 \; select-window -t tmp
      unbind Down
      bind Down last-window \; swap-pane -s tmp.1 \; kill-window -t tmp

      # Log output to a text file on demand.
      bind P pipe-pane -o "cat >>~/#W.log" \; display "Toggled logging to ~/#W.log"


      # -- display -------------------------------------------------------------------
      # tabs
      set -g window-status-current-format "#[fg=black]#[bg=red] #I #[bg=brightblack]#[fg=brightwhite] #W#[fg=brightblack]#[bg=black]"
      set -g window-status-format "#[fg=black]#[bg=yellow] #I #[bg=brightblack]#[fg=brightwhite] #W#[fg=brightblack]#[bg=black]"

      # status bar
      set-option -g status-position bottom
      set-option -g status-justify left
      set -g status-fg colour1
      set -g status-bg colour0
      set -g status-left ' '
      set -g status-right '#(date +"%_I:%M")'
      set-option -g set-titles on
      #256 colors
      set -g default-terminal "xterm-256color"
      set -ga terminal-overrides ",xterm-256color:Tc"
      #Don't auto remane windows
      set-option -g allow-rename off
      # Source config
      unbind r
      bind r source-file ~/.tmux.conf \; display "Finished sourcing ~/.tmux.conf ."


      # Use Alt-arrow keys without prefix key to switch panes
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # Shift arrow to switch windows
      bind -n S-Left  previous-window
      bind -n S-Right next-window


      # allow fn+left/right
      bind-key -n Home send Escape "OH"
      bind-key -n End send Escape "OF"

      setw -g monitor-activity off
      setw -g monitor-activity on
      set-option -g bell-action none
    '';
  };
}
