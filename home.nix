{ pkgs ? import ./default.nix { }, flake ? null, machine-name ? "void", isBarebones ? false }:
let
  inherit (pkgs.hax) isDarwin isLinux isM1 isX86Mac;
  inherit (pkgs.hax) docker_aliases kubernetes_aliases;
  inherit (pkgs.hax) attrIf words;
  inherit (pkgs.lib) mkForce;

  constants = import ./hosts/constants.nix;

  firstName = "jacobi";
  lastName = "petrucciani";
  personalEmail = "j@cobi.dev";
  workEmail = "jpetrucciani@blackedge.com";
  medableEmail = "jacobi.petrucciani@medable.com";
  gitUser = {
    name = "${firstName} ${lastName}";
    email =
      if machine-name == "m1max" then medableEmail
      else if machine-name == "edge" then workEmail
      else personalEmail;
  };

  onAws = builtins.getEnv "USER" == "ubuntu";
  promptChar = if isDarwin then "ᛗ" else "ᛥ";

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

  sessionVariables = {
    BASH_SILENCE_DEPRECATION_WARNING = "1";
    EDITOR = "nano";
    GIT_SSH_COMMAND = "${pkgs.openssh}/bin/ssh";
    PAGER = "less";

    # thanks google
    USE_GKE_GCLOUD_AUTH_PLUGIN = "True";
  };

  optList = conditional: list: if conditional then list else [ ];
in
{
  nixpkgs.overlays = import ./overlays.nix;

  programs = {
    htop.enable = true;
    dircolors.enable = true;
  };

  home = {
    inherit username homeDirectory sessionVariables;
    stateVersion = "22.11";
    packages = with pkgs;
      lib.flatten [
        _nix
        aq
        bat
        bzip2
        cacert
        cachix
        clolcat
        coreutils-full
        cowsay
        curl
        delta
        diffutils
        doggo
        dos2unix
        duckdb
        dyff
        ed
        erdtree
        fd
        figlet
        file
        fq
        gawk
        genpass
        glow
        gnugrep
        gnumake
        gnupg
        gnused
        gron
        gum
        gzip
        hgrep
        html-to-markdown
        htmlq
        ivy
        jq
        just
        kyanite
        libarchive
        libnotify
        lsof
        manix
        mods
        moreutils
        nano
        nanorc
        netcat-gnu
        nil
        nix-info
        nix-output-monitor
        nix-prefetch-github
        nix-prefetch-scripts
        nix-sweep
        nix-top
        nix-tree
        nix-update
        nixd
        nixfmt
        nixpkgs-fmt
        nixpkgs-review
        p7zip
        patch
        pigz
        prism
        procps
        pssh
        re2c
        rlwrap
        rsync
        ruff
        scc
        scrypt
        shfmt
        spacer
        statix
        time
        unzip
        uv
        vale
        watch
        wget
        which
        xh
        yank
        yq-go
        zip

        # kubernetes
        kubectl
        kubectx
        ## thanks google
        gke-gcloud-auth-plugin

        # secrets
        flake.inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default

        # load in my custom checked pog scripts
        (
          writeShellScriptBin "machine-name" ''
            echo "${machine-name}"
          ''
        )
        hms
        aws_pog_scripts
        curl_pog_scripts
        docker_pog_scripts
        ffmpeg_pog_scripts
        gcp_pog_scripts
        general_pog_scripts
        github_pog_scripts
        hax_pog_scripts
        helm_pog_scripts
        k8s_pog_scripts
        nix_pog_scripts
        ssh_pog_scripts

        discord_webhook

        (optList (!isBarebones) [
          docker-client
          google-cloud-sdk
          ripgrep
          shellcheck
          terraform-ls

          # python
          (python314.withPackages pkgs.hax.basePythonPackages)

          # sounds
          meme_sounds
          # all except old mac
          (
            optList (!isX86Mac) [
              git-trim
            ]
          )

          # linux specific
          (
            optList isLinux [
              gnutar # this breaks vscode server?
              nixos-generators
              binutils
              man-pages
              ncdu
              sampler
              vtm
            ]
          )
        ])

        (
          optList (machine-name == "voyager") [
            go
          ]
        )
        # overlays
        nix_hash_unstable
        nix_hash_jpetrucciani
        nix_hash_magicschool
        nix_hash_medable
        nix_hash_hex
        nix_hash_pog
        nix_hash_rust-overlay
        nixup
      ];
  };

  programs.less = {
    enable = true;
    options = [ "-iR" ];
  };
  programs.lesspipe.enable = true;
  programs.lsd.enable = true;

  programs.yt-dlp = {
    enable = isLinux;
    extraConfig = ''
      --embed-thumbnail
      --embed-metadata
      --embed-subs
      --sub-langs all
      --downloader aria2c
      --downloader-args aria2c:'-c -x8 -s8 -k1M'
    '';
  };

  programs.bash = {
    enable = true;
    historyControl = [ "ignoreboth" ];
    historyFileSize = -1;
    historySize = -1;
    shellAliases = {
      ls = mkForce "ls --color=auto";
      l = "lsd -lA --permission octal";
      ll = mkForce "ls -ahlFG";
      mkdir = "mkdir -pv";
      fzfp = "${pkgs.fzf}/bin/fzf --preview 'bat --style=numbers --color=always {}'";
      strip = ''${pkgs.gnused}/bin/sed -E 's#^\s+|\s+$##g' '';

      # git
      g = "git";
      ga = "git add -A .";
      cm = "git commit -m ";

      # misc
      space = "du -Sh | sort -rh | head -10";
      now = "date +%s";
      uneek = "awk '!a[$0]++'";
    } // docker_aliases // kubernetes_aliases;
    bashrcExtra =
      if isDarwin then ''
        export PATH="$PATH:${homeDirectory}/.nix-profile/bin"
      '' else "";
    initExtra = ''
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
      ${constants.bash_funcs.wezterm_title}

      _kube_contexts() {
        local curr_arg;
        curr_arg=''${COMP_WORDS[COMP_CWORD]}
        COMPREPLY=( $(compgen -W "- $(${pkgs.kubectl}/bin/kubectl config get-contexts --output='name')" -- $curr_arg ) );
      }

      _kube_namespaces() {
        local curr_arg;
        curr_arg=''${COMP_WORDS[COMP_CWORD]}
        COMPREPLY=( $(compgen -W "- $(${pkgs.kubectl}/bin/kubectl get namespaces -o=jsonpath='{range .items[*].metadata.name}{@}{"\n"}{end}')" -- $curr_arg ) );
      }

      # additional aliases
      [[ -e ~/.aliases ]] && source ~/.aliases

      # bash completions
      source "${pkgs.kubectl}/share/bash-completion/completions/kubectl.bash"
      source "${pkgs.gitFull}/share/bash-completion/completions/git"
      complete -o bashdefault -o default -o nospace -F __git_wrap__git_main g
      complete -F __start_kubectl k
      complete -F _kube_contexts kubectx kx
      complete -F _kube_namespaces kubens kns
    '' + (if (!isBarebones) then ''
      source "${pkgs.docker-client}/share/bash-completion/completions/docker.bash"
      complete -F _docker d
    '' else "") +
    ''
      # there are often duplicate path entries on non-nixos; remove them
      NEWPATH=
      OLDIFS=$IFS
      IFS=:
      for entry in $PATH;do
        if [[ ! :$NEWPATH: == *:$entry:* ]];then
          if [[ -z $NEWPATH ]];then
            NEWPATH=$entry
          else
            NEWPATH=$NEWPATH:$entry
          fi
        fi
      done

      IFS=$OLDIFS
      export PATH="$NEWPATH"
      unset OLDIFS NEWPATH
    '' + (if isLinux then ''
      ${pkgs.figlet}/bin/figlet "$(hostname)" | ${pkgs.clolcat}/bin/clolcat
      echo
    '' else "");
  };

  programs.broot = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.zoxide = {
    enable = true;
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
      completion-query-items = -1;
      expand-tilde = false;
      bell-style = false;
      revert-all-at-newline = true;
    };
    bindings = {
      "\\e[1;5D" = "backward-word";
      "\\e[1;5C" = "forward-word";
      "\\e[5D" = "backward-word";
      "\\e[5C" = "forward-word";
      "\\e\\e[D" = "backward-word";
      "\\e\\e[C" = "forward-word";
      "\\C-k" = "kill-whole-line";
      "\\C-p" = "history-search-backward";
      "\\C-l" = "complete";
      "\\C-f" = "complete-filename";
    };
  };

  programs.helix = {
    enable = true;
    settings = {
      editor = {
        lsp.display-messages = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
      };
      keys.normal = {
        space = {
          space = "file_picker";
          w = ":w";
          q = ":q";
        };
      };
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

  programs.ssh = {
    enable = true;
    includes = [ "config.d/*" ];
    enableDefaultConfig = false;
    settings."*" = {
      User = "jacobi";
      Compression = true;
      IdentitiesOnly = true;
      PasswordAuthentication = false;
      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
        "aes128-gcm@openssh.com"
        "aes256-ctr"
        "aes192-ctr"
        "aes128-ctr"
      ];
      KexAlgorithms = [
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
        "diffie-hellman-group16-sha512"
        "diffie-hellman-group18-sha512"
        "diffie-hellman-group-exchange-sha256"
      ];
      MACs = [
        "hmac-sha2-256-etm@openssh.com"
        "hmac-sha2-512-etm@openssh.com"
        "umac-128-etm@openssh.com"
      ];
      HostKeyAlgorithms = [
        "ssh-ed25519"
        "rsa-sha2-256"
        "rsa-sha2-512"
      ];
    };
  };

  home.file = {
    ssh_config_github = {
      target = ".ssh/config.d/github";
      text = pkgs.hax.ssh.github;
    };
    curlrc = {
      target = ".curlrc";
      text = ''
        --netrc-optional
      '';
    };
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
    prettier_config = {
      target = "prettier.config.js";
      text = builtins.readFile ./prettier.config.js;
    };
    oxfmt_config = {
      target = ".oxfmtrc.json";
      text = builtins.toJSON pkgs._oxfmt;
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
    ${attrIf isDarwin "gpgagentconf"} = {
      target = ".gnupg/gpg-agent.conf";
      text = ''
        pinentry-program ${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac
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
      battery.disabled = true;
      gcloud.disabled = true;
      package.disabled = true;
    };
  };

  # gitconfig
  programs.jujutsu = {
    enable = true;
    settings.user = gitUser;
  };
  programs.git =
    let
      gs = text:
        let
          script = pkgs.writers.writeBash "git-script" ''
            set -eo pipefail
            cd -- ''${GIT_PREFIX:-.}
            ${text}
          '';
        in
        "! ${script}";
    in
    {
      enable = true;
      package = pkgs.gitFull;
      settings = {
        user = gitUser;
        alias = {
          A = "add -A";
          pu = "pull";
          pur = "pull --rebase";
          cam = "commit -am";
          ca = "commit -a";
          cm = "commit -m";
          ci = "commit";
          co = "checkout";
          cod = gs ''git co $(git default) "$@"'';
          st = "status";
          br = gs ''
            esc=$'\e'
            reset=$esc[0m
            red=$esc[31m
            yellow=$esc[33m
            green=$esc[32m
            git -c color.ui=always branch -vv "$@" | ${pkgs.gnused}/bin/sed -E \
              -e "s/: (gone)]/: $red\1$reset]/" \
              -e "s/[:,] (ahead [0-9]*)([],])/: $green\1$reset\2/g" \
              -e "s/[:,] (behind [0-9]*)([],])/: $yellow\1$reset\2/g"
            git --no-pager stash list
          '';
          brf = gs "git f --quiet && git br";
          f = "fetch --all";
          hide = "update-index --skip-worktree";
          unhide = "update-index --no-skip-worktree";
          hidden = "! git ls-files -v | grep '^S' | cut -c3-";
          branch-name = "!git rev-parse --abbrev-ref HEAD";
          default = gs "git symbolic-ref refs/remotes/origin/HEAD | sed s@refs/remotes/origin/@@";
          # Delete the remote version of the current branch
          unpublish = "!git push origin :$(git branch-name)";
          # Push current branch
          put = gs ''git push "$@"'';
          # Pull without merging
          get = "!git pull origin $(git branch-name) --ff-only";
          # update a branch without checkout
          gd = gs "git fetch origin $(git default):$(git default)";
          # Pull Master without switching branches
          got =
            "!f() { CURRENT_BRANCH=$(git branch-name) && git checkout $1 && git pull origin $1 --ff-only && git checkout $CURRENT_BRANCH;  }; f";
          gone = gs ''git branch -vv | ${pkgs.gnused}/bin/sed -En "/: gone]/s/^..([^[:space:]]*)\s.*/\1/p"'';
          # Recreate your local branch based on the remote branch
          recreate = gs ''
            if [[ $# -ne 1 ]]; then
              echo "usage: git recreate <branch>" >&2
              exit 2
            fi
            branch=$1
            git checkout "$(git default)"
            git branch -D "$branch"
            git fetch origin "$branch:$branch"
            git checkout "$branch"
          '';
          reset-submodule = "!git submodule update --init";
          s = gs "git br && git -c color.status=always status | grep -E --color=never '^\\s\\S|:$' || true";
          sl = "!git --no-pager log -n 15 --oneline --decorate";
          sla = "log --oneline --decorate --graph --all";
          lol = "log --graph --decorate --pretty=oneline --abbrev-commit";
          lola = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
          shake = "remote prune origin";
          pop = "reset HEAD~1";
        };
        checkout.defaultRemote = "origin";
        color.ui = true;
        fetch.prune = true;
        init.defaultBranch = "main";
        pull.ff = "only";
        push.default = "simple";
        rebase.instructionFormat = "<%ae >%s";
        core = {
          editor = if isDarwin then "code --wait" else "nano";
          pager = "delta --dark";
          autocrlf = "input";
        };
        push = {
          autoSetupRemote = true;
        };
        trim.bases = "main,master";
        delta = {
          navigate = true;
          line-numbers = true;
          side-by-side = true;
          line-numbers-left-format = "";
          line-numbers-right-format = "│ ";
        };
      };
      lfs.enable = true;
      signing.format = null;
      ignores = [
        "*.pcap"
        "*.swp"
        "*~"
        ".cursor"
        ".codex"
        "AGENTS.md"
        "SPEC.md"
        "TODO.md"
        "result*"
      ];
    };

  programs.tmux = {
    enable = true;
    historyLimit = 500000;
    shortcut = "a";
    extraConfig = ''
      set -g base-index 1
      set -g pane-base-index 1

      set -g status-keys vi
      setw -g mode-keys vi
      setw -g mouse on

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

      setw -g monitor-activity on
      set-option -g bell-action none
    '';
  };

  # fix vscode
  imports =
    if isLinux then [
      "${flake.inputs.vscode-server}/modules/vscode-server/home.nix"
    ] else [ ];

  ${attrIf isLinux "services"}.vscode-server.enable = true;

  wayland.windowManager.hyprland.systemd.enable = false; # disable in general
}
