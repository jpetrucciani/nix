# jet status for bash: sends where you are (OSC 7) and user variables
# (OSC 1337 SetUserVar) for `{var.NAME}` status segments. A copy of jet's
# docs/jet-status.bash; home.nix sources it in every bashrc.
#
# It runs before every prompt, so it never starts a process: no
# subshells, no git, no kubectl, no base64. About 0.2 ms a prompt, plus
# up to 0.5 ms for a big kubeconfig (kubectl alone takes 50). Bash 4.4+;
# on older ones (macOS's /bin/bash) it does nothing.
#
#   git    branch, or the short commit when detached
#   gitop  rebase 2/5, merge, cherry-pick, revert, bisect, am
#   k8s    current context, `:namespace` when not default
#   nix    the nix-shell / nix develop name
#   venv   the Python virtualenv's project
#   jobs   background jobs, when any
#   took   how long the last command took, when 2s or more
#   rc     the last command's exit status when it failed, with the signal
#
# Every variable goes out on every prompt, empty ones too: jet keeps a
# pane's variables until they're set again. The values also stay in the
# JET_STATUS array for the rest of your prompt to use.

if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4))); then
  __jet_status() { :; }
  return 0
fi

# base64 in bash; $1 -> REPLY. Values rarely change between prompts,
# so each one is encoded once and remembered.
declare -gA __jet_b64s=()
__jet_b64() {
  REPLY=''
  [[ $1 ]] || return 0
  REPLY=${__jet_b64s[$1]-}
  [[ $REPLY ]] && return
  ((${#__jet_b64s[@]} > 512)) && __jet_b64s=()
  local LC_ALL=C s=$1 t=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/
  local i n=${#1} a b c out=
  for ((i = 0; i < n; i += 3)); do
    printf -v a %d "'${s:i:1}"
    b=0 c=0
    ((i + 1 < n)) && printf -v b %d "'${s:i+1:1}"
    ((i + 2 < n)) && printf -v c %d "'${s:i+2:1}"
    out+=${t:a>>2:1}${t:((a & 3) << 4)|(b >> 4):1}
    if ((i + 1 < n)); then out+=${t:((b & 15) << 2)|(c >> 6):1}; else out+='='; fi
    if ((i + 2 < n)); then out+=${t:c&63:1}; else out+='='; fi
  done
  __jet_b64s[$1]=$out
  REPLY=$out
}

# branch -> JET_STATUS[git], operation in progress -> JET_STATUS[gitop]
__jet_git() {
  local d=$PWD g='' head n m
  JET_STATUS[git]='' JET_STATUS[gitop]=''
  while :; do
    if [[ -d $d/.git ]]; then
      g=$d/.git
      break
    elif [[ -f $d/.git ]]; then # worktree or submodule: "gitdir: path"
      read -r g <"$d/.git"
      g=${g#gitdir: }
      [[ $g == /* ]] || g=$d/$g
      break
    fi
    [[ -z $d ]] && return
    d=${d%/*}
  done
  read -r head <"$g/HEAD" 2>/dev/null || return
  case $head in
  "ref: refs/heads/"*) JET_STATUS[git]=${head#ref: refs/heads/} ;;
  *) JET_STATUS[git]=${head:0:7} ;;
  esac
  if [[ -d $g/rebase-merge ]]; then
    read -r n <"$g/rebase-merge/msgnum" && read -r m <"$g/rebase-merge/end"
    JET_STATUS[gitop]="rebase${n:+ $n/$m}"
  elif [[ -d $g/rebase-apply ]]; then
    if [[ -f $g/rebase-apply/applying ]]; then JET_STATUS[gitop]=am; else JET_STATUS[gitop]=rebase; fi
  elif [[ -f $g/MERGE_HEAD ]]; then
    JET_STATUS[gitop]=merge
  elif [[ -f $g/CHERRY_PICK_HEAD ]]; then
    JET_STATUS[gitop]=cherry-pick
  elif [[ -f $g/REVERT_HEAD ]]; then
    JET_STATUS[gitop]=revert
  elif [[ -f $g/BISECT_LOG ]]; then
    JET_STATUS[gitop]=bisect
  fi
}

# current context[:namespace] -> JET_STATUS[k8s], read from the
# kubeconfig the way kubectl finds it: the first file with a
# current-context wins, and so does the first definition of a context.
# One pass over the lines; certificates are one line each, so even a
# big kubeconfig is a few dozen.
__jet_k8s() {
  local LC_ALL=C f i l k v ctx='' in='' name='' ns=''
  local -a files lines
  local -A nsof=()
  IFS=: read -ra files <<<"${KUBECONFIG:-$HOME/.kube/config}"
  JET_STATUS[k8s]=''
  for f in "${files[@]}"; do
    [[ -r $f ]] || continue
    mapfile -t lines <"$f"
    lines+=(.) # closes the last item
    for ((i = 0; i < ${#lines[@]}; i++)); do
      # outside contexts: only top-level keys matter, and certificates are
      # long lines, so look at one character before copying any
      l=${lines[i]:0:1}
      [[ $in || ($l && $l != [[:space:]-]) ]] || continue
      l=${lines[i]:0:256}
      [[ -z $l ]] && continue
      # "  - name: 'x'  # y" -> k=name v=x
      k=${l#"${l%%[![:space:]-]*}"} v=${l#*:}
      k=${k%%:*} v=${v#"${v%%[![:space:]]*}"}
      v=${v%%[[:space:]]*} v=${v//[\"\']/}
      if [[ $l == [![:space:]-]* ]]; then # a top-level key
        [[ $in && $name && ! -v nsof[$name] ]] && nsof[$name]=$ns
        in='' name='' ns=''
        [[ $k == contexts ]] && in=1
        [[ $k == current-context && -z $ctx ]] && ctx=$v
        continue
      fi
      [[ $in ]] || continue
      if [[ $l == *([[:space:]])-[[:space:]]* ]]; then # a new context
        [[ $name && ! -v nsof[$name] ]] && nsof[$name]=$ns
        name='' ns=''
      fi
      case $k in
      name) name=$v ;;
      namespace) ns=$v ;;
      esac
    done
  done
  [[ $ctx ]] || return
  ns=${nsof[$ctx]-}
  JET_STATUS[k8s]=$ctx
  [[ $ns && $ns != default ]] && JET_STATUS[k8s]=$ctx:$ns
}

__jet_status() {
  local rc=${STARSHIP_CMD_STATUS:-$?}
  local jobs='\j' out v url
  declare -gA JET_STATUS

  __jet_git
  __jet_k8s
  JET_STATUS[nix]=${IN_NIX_SHELL:+${name:-nix}}
  if [[ $VIRTUAL_ENV ]]; then
    JET_STATUS[venv]=${VIRTUAL_ENV##*/}
    # uv and python -m venv name it .venv or venv: show the project
    if [[ ${JET_STATUS[venv]} == ?(.)venv ]]; then
      v=${VIRTUAL_ENV%/*}
      JET_STATUS[venv]=${v##*/}
    fi
  else
    JET_STATUS[venv]=''
  fi
  jobs=${jobs@P}
  JET_STATUS[jobs]=${jobs#0}

  # duration: starship's timer when it's there, else ours
  local now=${EPOCHREALTIME//[!0-9]/} ms=''
  if [[ ${STARSHIP_START_TIME-} ]]; then
    ms=$((now / 1000 - STARSHIP_START_TIME))
  elif [[ ${__jet_t0-} ]]; then
    ms=$(((now - __jet_t0) / 1000))
  fi
  __jet_t0='' JET_STATUS[took]=''
  if [[ $ms ]] && ((ms >= 2000)); then
    local s=$((ms / 1000))
    if ((s >= 3600)); then
      JET_STATUS[took]="$((s / 3600))h$((s % 3600 / 60))m"
    elif ((s >= 60)); then
      JET_STATUS[took]="$((s / 60))m$((s % 60))s"
    else
      JET_STATUS[took]="${s}s"
    fi
  fi

  case $rc in
  0) rc='' ;;
  130) rc="130 INT" ;;
  131) rc="131 QUIT" ;;
  134) rc="134 ABRT" ;;
  137) rc="137 KILL" ;;
  139) rc="139 SEGV" ;;
  141) rc="141 PIPE" ;;
  143) rc="143 TERM" ;;
  esac
  JET_STATUS[rc]=$rc

  # one write for everything
  url=${PWD//%/%25}
  out=$'\e]7;file://'"$HOSTNAME${url// /%20}"$'\e\\'
  for v in git gitop k8s nix venv jobs took rc; do
    __jet_b64 "${JET_STATUS[$v]}"
    out+=$'\e]1337;SetUserVar='"$v=$REPLY"$'\a'
  done
  # inside tmux, wrapped so they pass through (needs allow-passthrough on)
  [[ ${TMUX-} ]] && out=$'\ePtmux;'"${out//$'\e'/$'\e\e'}"$'\e\\'
  printf '%s' "$out"
}

# Time each command: PS0 is expanded as a command starts, and the
# arithmetic in this array index sets __jet_t0 in the shell itself (no
# fork). Bash 5 for EPOCHREALTIME; without it, no {var.took}.
# shellcheck disable=SC2016 # expanded by PS0, not here
if ((BASH_VERSINFO[0] >= 5)) && [[ $PS0 != *__jet_t0* ]]; then
  PS0+='${__jet_x[__jet_t0=${EPOCHREALTIME//[!0-9]/}]:0:0}'
fi
