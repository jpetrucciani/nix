let
  pkgs = import ./default.nix { };
  inherit (pkgs.hax) isDarwin isLinux isM1 isNixOs fetchFromGitHub chief_keef;

  firstName = "jacobi";
  lastName = "petrucciani";
  personalEmail = "j@cobi.dev";
  workEmail = "jacobi.petrucciani@medable.com";

  onAws = builtins.getEnv "USER" == "ubuntu";
  promptChar = if isDarwin then "ᛗ" else "ᛥ";

  # home-manager pin
  hm = with builtins; fromJSON (readFile ./sources/home-manager.json);
  home-manager = fetchFromGitHub {
    inherit (hm) rev sha256;
    owner = "nix-community";
    repo = "home-manager";
  };

  # nix-darwin pin
  nd = with builtins; fromJSON (readFile ./sources/darwin.json);
  nix-darwin = fetchFromGitHub {
    inherit (nd) rev sha256;
    owner = "LnL7";
    repo = "nix-darwin";
  };

  sessionVariables = {
    EDITOR = "nano";
    HISTCONTROL = "ignoreboth";
    PAGER = "less";
    LESS = "-iR";
    BASH_SILENCE_DEPRECATION_WARNING = "1";
  };

in
with pkgs.hax; {
  nixpkgs.overlays = import ./overlays.nix;
  nixpkgs.config = { allowUnfree = true; };

  programs.home-manager.enable = true;
  programs.home-manager.path = "${home-manager}";
  _module.args.pkgs = pkgs;

  programs.htop.enable = true;
  programs.dircolors.enable = true;

  home = {
    username =
      if isDarwin then
        firstName
      else
        (if onAws then "ubuntu" else firstName);
    homeDirectory =
      if isDarwin then
        "/Users/${firstName}"
      else
        (if onAws then "/home/ubuntu" else "/home/${firstName}");
    stateVersion = "21.11";
    inherit sessionVariables;

    packages = with pkgs;
      lib.flatten [
        awscli2
        atool
        bash-completion
        bashInteractive_5
        bat
        bc
        bzip2
        cacert
        cachix
        coreutils-full
        cowsay
        curl
        dasel
        diffutils
        docker-client
        dos2unix
        ed
        exa
        fd
        figlet
        file
        gawk
        gcc
        gitAndTools.delta
        gnugrep
        gnupg
        gnused
        gnumake
        gnutar
        google-cloud-sdk
        gron
        gzip
        hadolint
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
        manix
        moreutils
        nano
        ncdu
        neofetch
        netcat-gnu
        nix-info
        nix-prefetch-github
        nix-prefetch-scripts
        nix-tree
        nixpkgs-fmt
        nixpkgs-review
        nix_2_4
        nmap
        openssh
        p7zip
        patch
        pigz
        procps
        pssh
        pup
        ranger
        re2c
        ripgrep
        ripgrep-all
        rlwrap
        rnix-lsp
        rsync
        scc
        sd
        shellcheck
        shfmt
        sox
        statix
        swaks
        time
        tealdeer
        unzip
        up
        viu
        watch
        wget
        which
        xxd
        yank
        yq-go
        zip

        # python
        (python39.withPackages (pkgs: with pkgs; [
          # interactive
          (lib.optional isLinux bpython)

          # linting
          bandit
          black
          mypy
          flake8
          pylint

          # common use case
          gamble
          httpx
          requests

          # text
          anybadge
          tabulate
          beautifulsoup4

          # api
          fastapi
          uvicorn

          # data
          numpy
          pandas
          scipy

          # type annotations
          types-requests
          types-tabulate
        ]))

        # kubernetes
        kubectl
        kubectx

        # load in my custom checked bash scripts
        aws_bash_scripts
        general_bash_scripts
        docker_bash_scripts
        k8s_bash_scripts

        # my pkgs
        aliyun-cli
        cloudquery
        horcrux
        katafygio
        kube-linter
        pluto
        rare
        rbac-tool

        # overlays
        git-trim
        nix_hash_unstable
        nix_hash_jpetrucciani
        nix_hash_kwb
        nix_hash_hm
        nix_hash_darwin
        nixup
        foo

        # keef's stuff
        comma

        # sounds
        meme_sounds

        # mac specific
        (
          lib.optional isDarwin [
            lima
          ]
        )

        # linux specific
        (
          lib.optional isLinux [
            binutils
            keybase
            (
              writeBashBinChecked "u" ''
                sudo apt update
                sudo apt upgrade
              ''
            )
          ]
        )
      ];
  };

  programs.bash = {
    enable = true;
    inherit sessionVariables;
    historyFileSize = -1;
    historySize = -1;
    shellAliases = {
      ls = "ls --color=auto";
      l = "${pkgs.exa}/bin/exa -alFT -L 1";
      ll = "ls -ahlFG";
      mkdir = "mkdir -pv";
      hm = "home-manager";
      ncdu = "${pkgs.ncdu}/bin/ncdu --color dark -ex";
      fzfp = "${pkgs.fzf}/bin/fzf --preview 'bat --style=numbers --color=always {}'";
      strip = ''
        ${pkgs.gnused}/bin/sed -E 's#^\s+|\s+$##g'
      '';

      # git
      g = "git";
      ga = "git add -A .";
      cm = "git commit -m ";

      # nix memes
      kelby = "echo 'nix-env --tarball-ttl 0 -f https://github.com/jpetrucciani/nix/archive/main.tar.gz'";
      pynix = "nix shell -f https://github.com/cript0nauta/pynixify/archive/main.tar.gz";

      # misc
      space = "du -Sh | sort -rh | head -10";
      now = "date +%s";
      uneek = "awk '!a[$0]++'";
    } // docker_aliases // kubernetes_aliases;
    initExtra = ''
      HISTCONTROL=ignoreboth
      set +h
      export PATH="$PATH:$HOME/.bin/"
      export PATH="$PATH:$HOME/.npm/bin/"

      # asdf and base nix
    '' + (if isM1 then ''
      export CONFIGURE_OPTS="--build aarch64-apple-darwin20"
    ''
    else ""
    ) + (
      if isDarwin then ''
        # add brew to path
        brew_path="/opt/homebrew/bin/brew"
        if [ -f /usr/local/bin/brew ]; then
          brew_path="/usr/local/bin/brew"
        fi
        eval "$($brew_path shellenv)"

        # load asdf if its there
        asdf_dir="$(brew --prefix asdf)"
        [[ -e "$asdf_dir/asdf.sh" ]] && source "$asdf_dir/asdf.sh"
        [[ -e "$asdf_dir/etc/bash_completion.d/asdf.bash" ]] && source "$asdf_dir/etc/bash_completion.d/asdf.bash"
      '' else ''
        [[ -e $HOME/.asdf/asdf.sh ]] && source $HOME/.asdf/asdf.sh
        [[ -e $HOME/.asdf/completions/asdf.bash ]] && source $HOME/.asdf/completions/asdf.bash
      ''
    ) + ''
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
      source ~/.nix-profile/share/bash-completion/completions/docker
      source ~/.nix-profile/share/bash-completion/completions/git
      source ~/.nix-profile/share/bash-completion/completions/ssh
      complete -o bashdefault -o default -o nospace -F __git_wrap__git_main g
      complete -F _docker d
      complete -F __start_kubectl k
      complete -F _kube_contexts kubectx kx
      complete -F _kube_namespaces kubens kns
    '' + (if isNixOS then ''
      ${pkgs.figlet}/bin/figlet "$(hostname)" | ${pkgs.lolcat}/bin/lolcat
      echo
    '' else "");
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.readline = {
    enable = true;
    variables = {
      show-all-if-ambiguous = true;
      skip-completed-text = true;
      bell-style = false;
    };
    bindings = {
      "\\e[1;5D" = "backward-word";
      "\\e[1;5C" = "forward-word";
      "\\e[5D" = "backward-word";
      "\\e[5C" = "forward-word";
      "\\e\\e[D" = "backward-word";
      "\\e\\e[C" = "forward-word";
    };
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

  programs.nnn = {
    enable = true;
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
    prettierrc = {
      target = ".prettierrc.js";
      text = ''
        const config = {
          printWidth: 100,
          arrowParens: 'always',
          singleQuote: true,
          tabWidth: 2,
          useTabs: false,
          semi: true,
          bracketSpacing: false,
          jsxBracketSameLine: false,
          requirePragma: false,
          proseWrap: 'preserve',
          trailingComma: 'all',
        };
        module.exports = config;
      '';
    };
    ${attrIf isLinux "gpgconf"} = {
      target = ".gnupg/gpg.conf";
      text = ''
        use-agent
        pinentry-mode loopback
      '';
    };
    ${attrIf isLinux "gpgagentconf"} = {
      target = ".gnupg/gpg-agent.conf";
      text = ''
        allow-loopback-pinentry
      '';
    };
  };

  # starship config
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      character = {
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
        format = "via [$symbol$state($name)]($style) ";
      };
      kubernetes = {
        disabled = false;
        style = "fg:#326ce5";
      };
      terraform = {
        disabled = false;
        format = "via [$symbol $version]($style) ";
        symbol = "🌴";
      };
      nodejs = { symbol = "⬡ "; };
      hostname = {
        style = "bold fg:46";
      };
      username = {
        style_user = "bold fg:93";
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
      f = "fetch";
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
  programs.git.${attrIf (!isNixOS) "signing"} = {
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

  # fix vscode
  imports =
    if isNixOS then [
      "${fetchTarball "https://github.com/msteen/nixos-vscode-server/tarball/bc28cc2a7d866b32a8358c6ad61bea68a618a3f5"}/modules/vscode-server/home.nix"
    ] else [ ];

  ${attrIf isNixOS "services"}.vscode-server.enable = isNixOS;
}
