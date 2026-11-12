# Small commands: aliases to modern tools, `reload` and `reap`.
# Sourced from ~/.zshrc by install.sh, after everything else, so the grep and
# find aliases below can't break scripts that are sourced earlier.

# File listings through eza. lt shows 2 levels; `lt -L 4` goes deeper.
alias ls="eza --group-directories-first"
alias ll="eza -la --group-directories-first"
alias lt="eza --tree --level=2"

# Modern replacements, all installed by the Brewfile.
alias cat="bat --paging=never"
alias grep="rg"
alias find="fd"

# Restart the shell. exec zsh, not `source ~/.zshrc`: re-sourcing runs init
# scripts twice (compinit doesn't like it) and with any aliases already active,
# whereas a fresh exec parses everything in the same order as a new terminal.
alias reload="exec zsh"

# reap: pick processes to stop from an interactive list (needs fzf).
# The list has every TCP port your own processes are listening on, then your
# orphaned processes that hold no port. Type to filter, Tab to mark several,
# Enter to stop the marked ones (SIGTERM, then SIGKILL for survivors), Esc to
# leave. When the output is piped, it prints the list instead.

# Prints one "PORT PID COMMAND PARENT" row per entry, no header.
_reap_rows() {
  # PARENT: who started each process. A process whose parent died is adopted by
  # launchd (PID 1) — but so is everything launchd starts itself (apps, system
  # agents). `launchctl list` gives the PIDs launchd manages as jobs, so
  # parent 1 and *not* in that list means a real orphan.
  local -A managed shown
  local p port pid ppid parent comm
  for p in ${(f)"$(launchctl list 2>/dev/null | awk 'NR>1 && $1 ~ /^[0-9]+$/ {print $1}')"}; do
    managed[$p]=1
  done

  # Listening sockets owned by the current user.
  # -a: AND the selectors (lsof ORs them by default, which would list every process).
  # -P -n: raw port numbers and IPs, no DNS/service-name lookups (fast).
  while read -r port pid; do
    [[ -n $pid ]] || continue
    ppid=${$(ps -o ppid= -p $pid 2>/dev/null)// /}
    if [[ -z $ppid ]]; then
      parent="?"
    elif [[ $ppid != 1 ]]; then
      parent="${$(ps -o comm= -p $ppid 2>/dev/null):t} ($ppid)"
    elif (( $+managed[$pid] )); then
      parent="launchd"
    else
      parent="ORPHANED"
    fi
    shown[$pid]=1
    comm=${${$(ps -o comm= -p $pid 2>/dev/null):t}// /_}
    printf "%-6s %-8s %-16.16s %s\n" $port $pid ${comm:-?} $parent
  done < <(lsof -nP -a -u "$USER" -iTCP -sTCP:LISTEN 2>/dev/null | awk 'NR>1 {
    split($9, a, ":"); port=a[length(a)]
    key=$2 FS port
    if (!(key in seen)) { seen[key]=1; print port, $2 }
  }' | sort -n)

  # Orphans that are not listening on any port: same test, over all your
  # processes. Skipped as noise: macOS helper services (.xpc / .appex), which
  # launchd runs on demand without listing them, and browser crash reporters,
  # which detach from their parent on purpose.
  while read -r pid ppid comm; do
    [[ $ppid == 1 ]] || continue
    (( $+managed[$pid] || $+shown[$pid] )) && continue
    [[ $comm == *.xpc/* || $comm == *.appex/* || $comm == *crashpad_handler ]] && continue
    printf "%-6s %-8s %-16.16s %s\n" - $pid ${${comm:t}// /_} "ORPHANED (no port)"
  done < <(ps -u "$USER" -o pid=,ppid=,comm=)
}

reap() {
  if (( $# )); then
    print -u2 "reap takes no arguments: run it and pick from the list."
    return 2
  fi

  local rows header
  rows=$(_reap_rows)
  if [[ -z $rows ]]; then
    print "Nothing is listening on a port, and there are no orphaned processes."
    return 0
  fi
  header=$(printf "%-6s %-8s %-16s %s" PORT PID COMMAND PARENT)

  # Piped or redirected: just print the list.
  if [[ ! -t 1 ]]; then
    print -r -- $header
    print -r -- $rows
    return 0
  fi

  # {2} is the PID column; the preview shows how long it has run and its full command.
  # --exact: typed text must appear literally in a row. Fuzzy matching is too
  # loose for a list where Enter stops whatever is highlighted.
  local picked
  picked=$(print -r -- $header$'\n'$rows | fzf --multi --header-lines=1 \
    --height=60% --layout=reverse --border --no-sort --exact \
    --prompt='stop> ' \
    --header='Type to filter · Tab marks several · Enter stops · Esc leaves' \
    --preview='ps -p {2} -o etime=,args=' \
    --preview-window='down,3,wrap' --preview-label=' running for · command ') || return 0

  # (f) splits on newlines, ${=line} on spaces; -U keeps each PID once (a
  # process listening on two ports has two rows).
  local -aU pids
  local line
  for line in ${(f)picked}; do pids+=(${${=line}[2]}); done
  (( $#pids )) || return 0

  kill $pids 2>/dev/null
  sleep 0.5
  # Escalate only for survivors.
  local -a alive
  for pid in $pids; do kill -0 $pid 2>/dev/null && alive+=($pid); done
  if (( $#alive )); then
    kill -9 $alive 2>/dev/null
    sleep 0.2
  fi

  local pid still=() stopped=()
  for pid in $pids; do
    if kill -0 $pid 2>/dev/null; then still+=($pid); else stopped+=($pid); fi
  done
  (( $#stopped )) && print "Stopped $#stopped process(es): ${(j:, :)stopped}"
  (( $#still )) && { print -u2 "Could not stop: ${(j:, :)still}"; return 1 }
  return 0
}
