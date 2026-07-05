#!/bin/zsh
# check-apps — what's running, what it costs, what you can safely close
# Usage:
#   check-apps           terminal report
#   check-apps html      generate + open HTML dashboard
#   check-apps notify    silent: write HTML report + macOS notification (used by LaunchAgent)
#   check-apps close     interactive: pick an open app to quit (graceful, like ⌘Q)

MODE="${1:-term}"

# ---------- close mode: interactive app quitter ----------
if [ "$MODE" = "close" ]; then
  APPS=("${(@f)$(osascript -e 'tell application "System Events" to get the name of every process whose background only is false' 2>/dev/null | tr ',' '\n' | sed 's/^ *//')}")
  [ ${#APPS[@]} -eq 0 ] && { echo "No GUI apps running."; exit 0; }

  echo "Open apps (RAM = all processes belonging to the app):"
  i=1
  for app in "${APPS[@]}"; do
    MB=$(ps -axo rss,command | grep -iF "$app" | grep -v grep | awk '{s+=$1} END {printf "%.1f", s/1048576}')
    printf "  %2d) %-24s %s GB\n" $i "$app" "${MB:-0.0}"
    ((i++))
  done
  echo "   q) cancel"
  printf "Quit which app? "
  read CHOICE
  [ "$CHOICE" = "q" ] || [ -z "$CHOICE" ] && { echo "Cancelled."; exit 0; }

  TARGET="${APPS[$CHOICE]}"
  [ -z "$TARGET" ] && { echo "Invalid choice."; exit 1; }
  if [ "$TARGET" = "Finder" ]; then
    echo "Finder just relaunches itself — skipping (that's macOS working as designed)."
    exit 0
  fi

  echo "Quitting $TARGET gracefully (unsaved-work prompts appear in that app)..."
  osascript -e "tell application \"$TARGET\" to quit" 2>/dev/null
  sleep 3
  if osascript -e 'tell application "System Events" to get the name of every process whose background only is false' 2>/dev/null | grep -qiF "$TARGET"; then
    printf "$TARGET is still running (unsaved dialog? frozen?). Force-quit? [y/N] "
    read FORCE
    if [ "$FORCE" = "y" ]; then
      pkill -9 -if "$TARGET" && echo "⚡ force-quit $TARGET (unsaved work lost)"
    else
      echo "Left running — check its window for a save dialog."
    fi
  else
    echo "✅ $TARGET closed."
  fi
  exit 0
fi
REPORT="$HOME/Technology/tools/last-report.html"
OLLAMA_BIN=/usr/local/bin/ollama
COLIMA_BIN=/opt/homebrew/bin/colima

# ---------- collect data ----------
PHYSMEM=$(top -l 1 | grep PhysMem)
FREEPCT=$(memory_pressure 2>/dev/null | tail -1 | grep -o '[0-9]*' | tail -1)

TOPMEM=$(ps -axo rss,pcpu,comm | sort -rn | head -10)
TOPCPU=$(ps -axo pcpu,rss,comm | sort -rn | head -5)
GUIAPPS=$(osascript -e 'tell application "System Events" to get the name of every process whose background only is false' 2>/dev/null)
LOGINITEMS=$(osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null)

OLLAMA_STATUS="not installed"
if [ -x "$OLLAMA_BIN" ]; then
  LOADED=$("$OLLAMA_BIN" ps 2>/dev/null | tail -n +2)
  [ -n "$LOADED" ] && OLLAMA_STATUS="⚠️ model in RAM: $(echo $LOADED | awk '{print $1, "("$3, $4")"}') — ollama stop <model>" \
                   || OLLAMA_STATUS="✅ idle (~0.1 GB)"
fi
COLIMA_STATUS="not installed"
if [ -x "$COLIMA_BIN" ]; then
  "$COLIMA_BIN" status 2>&1 | grep -q "colima is running" \
    && COLIMA_STATUS="⚠️ VM running — colima stop when done" \
    || COLIMA_STATUS="✅ stopped"
fi

# ---------- terminal mode ----------
if [ "$MODE" = "term" ]; then
  BOLD=$(tput bold 2>/dev/null); DIM=$(tput dim 2>/dev/null); RESET=$(tput sgr0 2>/dev/null)
  echo "${BOLD}══ Memory pressure ══${RESET}"; echo "$PHYSMEM"; echo "free: ${FREEPCT}%"
  echo; echo "${BOLD}══ Top 10 memory users ══${RESET}"
  echo "$TOPMEM" | awk '{m=$1/1048576;c=$2;$1="";$2="";n=split($0,p,"/");printf "  %5.1f GB  %5.1f%% CPU  %s\n",m,c,p[n]}'
  echo; echo "${BOLD}══ Top 5 CPU users ══${RESET}"
  echo "$TOPCPU" | awk '{c=$1;m=$2/1048576;$1="";$2="";n=split($0,p,"/");printf "  %5.1f%% CPU  %5.1f GB  %s\n",c,m,p[n]}'
  echo; echo "${BOLD}══ Open GUI apps ══${RESET}"; echo "  $GUIAPPS"
  echo; echo "${BOLD}══ Heavyweights ══${RESET}"
  echo "  Ollama: $OLLAMA_STATUS"; echo "  Colima: $COLIMA_STATUS"
  echo; echo "${BOLD}══ Login items ══${RESET}"; echo "  ${LOGINITEMS:-✅ none}"
  exit 0
fi

# ---------- HTML report (html + notify modes) ----------
MEMROWS=$(echo "$TOPMEM" | awk '{m=$1/1048576;c=$2;$1="";$2="";n=split($0,p,"/");
  flag=(m>1.0 && c<1.0)?" class=\"warn\"":"";
  printf "<tr%s><td>%.1f GB</td><td>%.1f%%</td><td>%s</td></tr>\n",flag,m,c,p[n]}')
CPUROWS=$(echo "$TOPCPU" | awk '{c=$1;m=$2/1048576;$1="";$2="";n=split($0,p,"/");
  printf "<tr><td>%.1f%%</td><td>%.1f GB</td><td>%s</td></tr>\n",c,m,p[n]}')
APPLIST=$(echo "$GUIAPPS" | tr ',' '\n' | sed 's/^ *//' | awk 'NF{printf "<span class=\"chip\">%s</span> ",$0}')

if [ "${FREEPCT:-100}" -ge 60 ]; then PCOLOR="#28a745"; PLABEL="Healthy"
elif [ "${FREEPCT:-100}" -ge 30 ]; then PCOLOR="#ffc107"; PLABEL="Getting busy"
else PCOLOR="#dc3545"; PLABEL="Under pressure — close something"; fi

cat > "$REPORT" <<HTML
<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Mac Health — $(date '+%b %d, %H:%M')</title>
<style>
  :root{color-scheme:light dark;font-family:-apple-system,sans-serif}
  body{max-width:780px;margin:2rem auto;padding:0 1rem;line-height:1.5}
  h1{font-size:1.4rem} h2{font-size:1.05rem;margin-top:1.6rem;border-bottom:1px solid #8884;padding-bottom:.3rem}
  .gauge{background:#8882;border-radius:10px;height:22px;overflow:hidden;margin:.4rem 0}
  .gauge>div{height:100%;border-radius:10px;background:$PCOLOR;width:${FREEPCT:-0}%}
  table{border-collapse:collapse;width:100%;font-size:.92rem}
  td,th{padding:.35rem .6rem;text-align:left;border-bottom:1px solid #8883}
  tr.warn td{color:#e67e22;font-weight:600}
  .chip{display:inline-block;background:#8882;border-radius:999px;padding:.15rem .7rem;margin:.15rem;font-size:.9rem}
  .ok{color:#28a745}.warn-t{color:#e67e22}
  .note{font-size:.85rem;opacity:.75;margin-top:1.5rem}
  .stamp{opacity:.6;font-size:.85rem}
</style></head><body>
<h1>🖥️ Mac Health Report</h1>
<p class="stamp">$(date '+%A, %b %d %Y — %H:%M') · generated by check-apps</p>

<h2>Memory pressure: <span style="color:$PCOLOR">${FREEPCT}% free — $PLABEL</span></h2>
<div class="gauge"><div></div></div>
<p class="stamp">$PHYSMEM</p>

<h2>Top memory users <span class="stamp">(orange = big + idle → safe to quit)</span></h2>
<table><tr><th>RAM</th><th>CPU</th><th>Process</th></tr>
$MEMROWS
</table>

<h2>Top CPU right now</h2>
<table><tr><th>CPU</th><th>RAM</th><th>Process</th></tr>
$CPUROWS
</table>

<h2>Open apps <span class="stamp">(⌘Q the ones you're done with)</span></h2>
<p>$APPLIST</p>

<h2>Heavyweights</h2>
<p>Ollama: $OLLAMA_STATUS<br>Colima: $COLIMA_STATUS</p>

<h2>Autostart / login items</h2>
<p>${LOGINITEMS:-<span class="ok">none ✅</span>}</p>

<p class="note">Rules: judge by <b>pressure</b>, not "used" (macOS caches on purpose).
Browser tabs are the usual RAM hogs. Never kill WindowServer / kernel_task / mds*.
Regenerate: <code>checkapps html</code></p>
</body></html>
HTML

if [ "$MODE" = "html" ]; then
  open "$REPORT"
elif [ "$MODE" = "notify" ]; then
  WARN=""
  echo "$OLLAMA_STATUS$COLIMA_STATUS" | grep -q "⚠️" && WARN=" · heavyweight running"
  osascript -e "display notification \"Memory ${FREEPCT}% free${WARN} — 'checkapps html' for details\" with title \"Mac Health (5-min startup check)\"" 2>/dev/null
fi
