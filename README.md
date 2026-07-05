# New Mac Setup & Security Guide

A practical, battle-tested checklist to take a brand-new Mac (Apple Silicon)
from out-of-the-box to: organized, developer-ready, hardened against theft
and hacking, and sharing minimal data with Apple/Google.

Everything here was applied on a real machine (M-series MacBook, macOS 26
Tahoe). Adjust names/paths to taste. Sections marked with terminal commands
can be pasted directly; settings-app steps are written click-by-click.

Companion repo — one-command private local AI stack (Ollama + Gemma/Qwen +
VS Code): https://github.com/Naga15/mac-local-ai-setup

---

## 1. Folder structure — ✅ DONE

Created on :

```
~/Developer/            Apple-recognized dev folder
   ├── projects/        your own code
   ├── sandbox/         throwaway experiments
   └── clones/          other people's repos you're reading

~/AI/
   ├── projects/        AI projects
   ├── models/          local models
   ├── datasets/        training/eval data
   └── notes/           AI notes & research

~/Technology/
   ├── reference/       docs, manuals, cheatsheets
   ├── tools/           utilities, installers
   └── research/        tech research

~/Documents/
   ├── Personal/
   ├── Finance/
   └── Reference/       (this guide lives here)

~/Photos/
   ├── inbox/           unsorted imports
   ├── edited/          finished edits
   └── archive/         long-term storage

~/Screenshots/          all screenshots now save here
```

Screenshot location redirected via:

```bash
defaults write com.apple.screencapture location ~/Screenshots
killall SystemUIServer
```

To undo: `defaults delete com.apple.screencapture location && killall SystemUIServer`

---

## 2. Security status at first scan

| Setting                              | Found    | Action        |
|--------------------------------------|----------|---------------|
| FileVault (disk encryption)          | ❌ OFF   | Turn ON (§5)  |
| Firewall                             | ❌ OFF   | Turn ON (§3)  |
| Automatic updates                    | ❌ OFF   | Turn ON (§3)  |
| Gatekeeper (blocks unsigned apps)    | ✅ On    | none          |
| System Integrity Protection (SIP)    | ✅ On    | none          |
| Remote Login / SSH                   | ✅ Off   | keep off      |

---

## 3. Firewall + automatic updates — ⬜ RUN IN TERMINAL

Requires admin password. Paste the whole block into Terminal:

```bash
# --- Firewall + stealth mode ---
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

# --- Automatic updates ---
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool true
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool true
sudo defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool true

echo "✅ Firewall + auto-updates configured"
```

Notes:
- **Stealth mode** = Mac ignores ping/probe requests; invisible to network
  scans on public Wi-Fi.
- Verify firewall later with:
  `/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate`

---

## 4. Homebrew + apps — ⬜ RUN IN TERMINAL

### 4a. Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then wire it into the shell:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### 4b. App list — pick your tiers

**Tier 1 — for everyone:**

```bash
# CLI basics
brew install ripgrep fzf jq wget tree coreutils bat

# Apps
brew install --cask bitwarden      # password manager
brew install --cask lulu           # free outbound firewall — see what apps phone home
brew install --cask firefox        # privacy browser (+ uBlock Origin & Bitwarden extensions)
brew install --cask raycast        # launcher (Spotlight replacement)
brew install --cask rectangle      # window snapping
brew install --cask maccy          # clipboard history (⌘⇧C) — local-only, open source
brew install --cask stats          # menu-bar CPU/RAM/network monitor
brew install --cask the-unarchiver
brew install --cask vlc
```

**Tier 2 — developers:**

```bash
brew install git gh node pyenv lazygit
brew install --cask ghostty        # modern terminal
```

**Tier 3 — Kubernetes / containers (skip unless you do this work):**

```bash
brew install kubernetes-cli kind colima docker docker-compose docker-buildx
brew install helm k9s kubectx yq watch go
# Colima instead of Docker Desktop: nothing runs until `colima start`,
# no login agents, battery-friendly. kind works first-class against it.
# Usage:  colima start --cpu 2 --memory 4   → work →   colima stop
```

**Optional:**

```bash
brew install --cask tailscale      # private mesh VPN — install when you have a use case
# Backstage is not a brew package — scaffold per-project with Node:
#   npx @backstage/create-app@latest
```


Maintenance: `brew update && brew upgrade` periodically; `brew list` to see
what's installed.

---

## 5. FileVault (disk encryption) — ⬜ DO IN SYSTEM SETTINGS — **#1 PRIORITY**

Why: without it, anyone with physical access to the laptop can read the disk.
No performance cost on Apple Silicon.

Steps:
1. **System Settings → Privacy & Security → FileVault → Turn On…**
2. When asked how to unlock if you forget your password, choose
   **"Create a recovery key"** (do NOT use iCloud unlock if minimizing Apple
   data sharing).
3. **Write the recovery key down on paper** and store it somewhere safe
   (not on this laptop). Losing both your password and the key = data gone
   forever.

Verify with: `fdesetup status` → should say "FileVault is On."

---

## 6. Privacy hardening — ⬜ DO IN SYSTEM SETTINGS

### Apple data sharing — turn OFF
System Settings → **Privacy & Security → Analytics & Improvements**:
- [ ] Share Mac Analytics → OFF
- [ ] Share with App Developers → OFF
- [ ] Improve Siri & Dictation → OFF

System Settings → **Privacy & Security → Apple Advertising**:
- [ ] Personalized Ads → OFF

### iCloud — Advanced Data Protection
System Settings → **[your name] → iCloud → Advanced Data Protection → Turn On**
- End-to-end encrypts iCloud data so even Apple cannot read it.
- Requires setting a recovery contact or recovery key first.

### Siri & Spotlight
- System Settings → **Siri** → disable "Learn from this App" for sensitive apps;
  turn Siri off entirely if unused.
- System Settings → **Spotlight** → uncheck "Help Apple Improve Search."

### Google data minimization
- Use **Firefox** or **Brave** instead of Chrome.
- Default search engine → **DuckDuckGo** (browser settings).
- Don't sign into Google in the browser except when needed; use a separate
  browser profile for Google services.
- **LuLu** (installed in §4b) shows every outbound connection and lets you
  block apps that phone home.

### Lock screen basics
System Settings → **Lock Screen**:
- [ ] Require password "immediately" after sleep/screensaver.
System Settings → **Touch ID & Password**: enroll fingerprint(s).

---

## 7. Optional extras (not yet done, worth considering)

- **DNS-level ad/tracker blocking:** recommended approach is Tailscale global
  DNS → AdGuard (`94.140.14.14` / `94.140.15.15`), or the same IPs directly in
  Wi-Fi DNS — see §8m for the full two-layer setup.
- **Find My Mac:** trade-off — helps recover a stolen laptop but shares
  location with Apple. Your call.
- **Time Machine backups:** plug in an external drive, System Settings →
  General → Time Machine. Encrypt the backup disk when prompted.
- **Firmware password / Recovery lock:** extra theft protection,
  System Settings → Privacy & Security.

---

## 8. Additional recommendations (added after follow-up review)

Verified already safe on this machine: guest account off, no sharing services
(SMB/screen sharing/remote desktop) running, Terminal Secure Keyboard Entry ✅
enabled .

### 8a. Backups — 3-2-1 rule (biggest remaining gap after FileVault)
- **3** copies of your data, **2** different media, **1** offsite.
- Local: Time Machine on an external SSD (~$70/1TB). Encrypt when prompted.
- Offsite: Backblaze, or an encrypted cloud folder for critical files only.

### 8b. Two-factor authentication
- Enable 2FA on **Apple ID, Google, GitHub** — they're the master keys.
- Store TOTP codes in Bitwarden. Optional: 2× YubiKeys for phishing-proof auth.

### 8c. Touch ID for sudo (dev quality-of-life)
```bash
sudo sh -c 'echo "auth sufficient pam_tid.so" > /etc/pam.d/sudo_local'
```
Survives OS updates (unlike editing /etc/pam.d/sudo directly).

### 8d. Lock-screen hygiene (System Settings)
- Notifications → Show Previews → **When Unlocked**.
- Lock Screen → add message: "If found: you@example.com".

### 8e. AirDrop
- General → AirDrop & Handoff → AirDrop: **Contacts Only** (or No One).

### 8f. Browser
- Install **uBlock Origin** in Firefox/Brave — blocks the #1 real-world Mac
  infection vector (malvertising, fake download buttons).

### 8g. Git identity + SSH key (after Homebrew)
```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
ssh-keygen -t ed25519 -C "you@example.com"
gh auth login    # then add the key to GitHub
```

### 8h. The "don't" list — most Mac malware is invited in
- Never install "cleaner" apps (MacKeeper, CleanMyMac popup ads, etc.).
- Never bypass a Gatekeeper warning (right-click → Open) unless 100% sure.
- Only install from Homebrew, the App Store, or the developer's official site.

### 8i. Why we did NOT partition the disk
Windows-style partitioning is unnecessary on macOS: APFS already separates the
OS (sealed, read-only `Macintosh HD` volume) from your files (`Data` volume),
and all APFS volumes share free space dynamically — a fixed partition would
only waste space. Partitioning also never protected against drive failure or
theft (same physical disk) — backups (§8a) are the real answer.

### 8j. Second user + guest access

**Permanent standard account for seconduser** (second user of this Mac):
```bash
sudo sysadminctl -addUser seconduser -fullName "seconduser" -password -
```
- Standard (non-admin) — full use of all /Applications apps, but cannot
  change system settings, install system software, or read your home dir.
  Only `youruser` stays admin.

**Built-in Guest User** (lending the Mac to anyone else — no password,
wiped on logout, cannot see other users' files):
```bash
sudo sysadminctl -guestAccount on    # currently OFF; enable when wanted
```
Keep "Allow guests to connect to shared folders" OFF in
System Settings → Users & Groups.

**Touch ID for seconduser:** fingerprints are per-user in the Secure
Enclave — her finger only ever unlocks her account. Enroll from *her*
account: System Settings → Touch ID & Password → Add Fingerprint (needs her
password). Limits: 3 prints/user, 5 total. Touch ID also does user switching
at the lock screen. After any restart, first login per account needs the
password (FileVault keychain unlock) — Touch ID works from then on.
The wipe-on-logout Guest user cannot use Touch ID.

**FileVault + new accounts:** new users can't unlock the disk at cold boot by
default (you unlock, they log in after). To let her boot the Mac herself:
```bash
sudo fdesetup add -usertoadd seconduser
```

**Time limits (Screen Time — optional, guest/kid-oriented):** log in as the
target account, then:
1. System Settings → Screen Time → turn on, enable App & Website Activity
2. App Limits → Add Limit → **All Apps & Categories** → e.g. 3 hours/day
   → enable **Block at End of Limit**
3. Optional: Downtime → schedule allowed hours (locks everything outside them)
4. **Lock Screen Time Settings → set a 4-digit passcode only YOU know** —
   without this the guest can simply disable the limit. When time runs out,
   "Ask For More Time" requires your passcode (+15 min / 1 hr grants).

Screen Time cannot attach to the wipe-on-logout Guest user — for that one,
toggle it on only when needed:
```bash
sudo sysadminctl -guestAccount on    # before handing over
sudo sysadminctl -guestAccount off   # when done
```

### 8k. Find My / theft protection
Decision: sign in with your ONE main Apple ID (same as iPhone if any), enable
**only Find My Mac**, disable all other iCloud services. Reasons: Activation
Lock makes a stolen Mac unsellable; Find My location is end-to-end encrypted
(Apple can't read it); a separate/throwaway Apple ID risks self-bricking via
Activation Lock if you lose its credentials.
- Secure the Apple ID: strong unique password, 2FA, recovery contact/key.
- **Remote control when lost/stolen** — from the iPhone Find My app or
  icloud.com/find in any browser: locate (E2E encrypted), play sound,
  **Mark As Lost** (remote-locks the Mac with a passcode + message you set),
  or **Erase** (with FileVault on = instant crypto-wipe; Activation Lock
  persists even after erase). Commands execute when the Mac next goes online;
  location still updates offline via the Bluetooth Find My network.
- **Machine identifiers (also keep a copy OFF this laptop — email/paper):**
  - Model: find in Apple menu → About This Mac
  - Serial: `YOUR-SERIAL-HERE`

### 8l. Local AI — Ollama + Gemma — ✅ INSTALLED 

100% local inference: after download, nothing ever leaves the Mac (works
offline). The most private way to use AI.

- **App:** `/Applications/Ollama.app` (v0.31.1, shared with all user
  accounts), server at `localhost:11434`, CLI at `/usr/local/bin/ollama`

**Recommended models:**

| Model              | Size   | Use for                                      |
|--------------------|--------|----------------------------------------------|
| `qwen3:14b`        | 9.3 GB | Roo Code agent mode (tool-calling capable)   |
| `gemma3:12b`       | 8.1 GB | Continue chat / general questions            |
| `qwen2.5-coder:7b` | 4.7 GB | Continue tab-autocomplete                    |
| `gemma3:4b`        | 3.3 GB | Quick one-liners: `ollama run gemma3:4b "…"` |

Only one big model loads at a time on 24 GB RAM — Ollama swaps automatically.
27B-class models would swap heavily; 12–14B is the right ceiling.

```bash
ollama run gemma3:12b   # chat
ollama list             # installed models
ollama rm <model>       # remove one
```

**VS Code extensions (installed ):**
- **Roo Code** — agentic coding. Settings → API Provider: Ollama →
  model `qwen3:14b`. (Gemma 3 lacks tool-calling; use qwen3 here.)
- **Continue** — chat model `gemma3:12b`, autocomplete `qwen2.5-coder:7b`.
- `code` CLI added to PATH via ~/.zprofile.

**Sharing models with a second account (optional):** models live per-user
in `~/.ollama/models`; another account would re-download them. To share:
```bash
mkdir -p /Users/Shared/ollama-models
mv ~/.ollama/models/* /Users/Shared/ollama-models/
chmod -R a+rX,u+w /Users/Shared/ollama-models
# then ONCE IN EACH account:
launchctl setenv OLLAMA_MODELS /Users/Shared/ollama-models
echo 'export OLLAMA_MODELS=/Users/Shared/ollama-models' >> ~/.zprofile
```
Quit/reopen Ollama afterwards. Apps in /Applications are already usable by
all accounts (browsers installed via Homebrew casks land there too).

### 8m. Network-wide ad/tracker blocking

Block ads and trackers the legitimate way — at the DNS layer for every device,
plus an on-device app for in-page filtering. No account required.

**Layer 1 — DNS filtering via Tailscale + AdGuard DNS (network-wide):**

If you run Tailscale, point its **global nameservers** at AdGuard's public
ad-blocking resolvers. Every device on the tailnet then filters ads with zero
per-device config and no signup.

- Tailscale admin → **DNS** tab → Global nameservers:
  - `94.140.14.14` and `94.140.15.15`  (AdGuard, blocks ads + trackers)
  - **Override DNS servers: ON**
  - Leave MagicDNS (`100.100.100.100`) in place — tailnet names keep working
    and everything else forwards to AdGuard.
- Verify: `dig +short doubleclick.net` should return `0.0.0.0` (blocked) while
  a normal site like `example.com` resolves as usual.
- Why AdGuard rather than Mullvad here: Tailscale's global-nameserver field
  forwards over **plain** DNS; AdGuard answers on plain IPs, whereas Mullvad is
  DoH/DoT-only and can't be used as a plain Tailscale nameserver.
- No Tailscale? Set the same two AdGuard IPs directly in
  System Settings → Wi-Fi → Details → DNS (per-network, not tailnet-wide).

**Layer 2 — AdGuard for Mac app (on-device, in-page filtering):**

```bash
brew install --cask adguard
```
- Catches what DNS can't: cosmetic ads, element hiding, social widgets.
- Content Blocking: enable social-widget / Like-Share blocking; leave
  "online assistants / callback pop-ups" OFF (it also kills legit live-chat).
- **Privacy protection level: Standard, not High.** High enables aggressive
  Stealth Mode (strips Referer, blocks third-party cookies/auth) which silently
  breaks OAuth/SSO logins — a headache for dev work. Raise individual Stealth
  toggles later, one at a time, if you want more.
- Runs as a menu-bar app (one-click access). First launch asks to approve a
  system network extension in System Settings → click Allow.

**A note on the Wi-Fi DNS fallback:** don't hardcode public DNS in your Wi-Fi
settings on a laptop you travel with — it can break hotel/airport
**captive-portal** login pages. Leave Wi-Fi DNS automatic; the AdGuard app
covers on-device blocking regardless of which network you're on.

**NextDNS** is a good alternative if you want per-device stats and custom
blocklists, but it requires a free account (for a profile ID). AdGuard covers
the "just block ads, no signup" case, which is why this guide uses it.

---

## 9. Progress checklist

- [ ] Folder structure created
- [ ] Screenshots redirected to ~/Screenshots
- [ ] Firewall + stealth mode ON            (§3)
- [ ] Automatic updates ON                  (§3)
- [ ] Homebrew installed (6.0.6)            (§4a)
- [ ] CLI tools: git gh node pyenv kubectl kind ripgrep fzf jq wget tree coreutils (§4b)
- [ ] Apps: Bitwarden Firefox Ghostty LuLu Raycast Rectangle The-Unarchiver VLC (§4b)
- [ ] Containers: colima + docker CLI + buildx + kind — verified  (§4b)
- [ ] Tailscale — install if you want a private mesh + tailnet-wide ad blocking via AdGuard DNS (§8m)
- [ ] Git identity configured (Your Name / you@example.com, main, )
- [ ] FileVault ON, encryption finished, recovery key stored
- [ ] Firewall ON + stealth mode ON
- [ ] Auto-updates ON — check/download/install incl. macOS
- [ ] Apple analytics/ads OFF, location services pruned
- [ ] iCloud services disabled except Find My
- [ ] Advanced Data Protection — N/A while iCloud services are off
- [ ] Firefox/Brave default browser + DuckDuckGo search
- [ ] Lock screen: immediate password       (§6)
- [ ] Terminal Secure Keyboard Entry        (§8)
- [ ] External SSD + Time Machine backup    (§8a)  ← biggest remaining gap
- [ ] 2FA on Apple ID / Google / GitHub     (§8b)
- [ ] Touch ID for sudo        (§8c)
- [ ] Notification previews "When Unlocked" (§8d)
- [ ] AirDrop → Contacts Only               (§8e)
- [ ] uBlock Origin in browser              (§8f)
- [ ] GitHub auth via gh CLI; SSH key optional (§8g)
- [ ] Guest User enabled (when wanted)      (§8j)
- [ ] Permanent `seconduser` account + her Touch ID (§8j)
- [ ] FileVault "Enable Users" for seconduser done (§8j)
- [ ] Apple ID signed in, Find My-focused   (§8k)
- [ ] Serial number stored off-device (email YOUR-SERIAL-HERE to yourself) (§8k)
- [ ] Ollama + 6 models local AI installed  (§8l)
- [ ] Ollama.app opened, menu bar + CLI installed (§8l)
- [ ] VS Code: Roo Code + Continue wired to local models (§8l)
- [ ] Public repo published: github.com/Naga15/mac-local-ai-setup
- [ ] Network-wide ad/tracker blocking: Tailscale global DNS → AdGuard + AdGuard for Mac app (§8m)

---

*Generated with Claude Code on . Update the checklist as items are completed.*

---

## Further reading

- [docs/security-faq.md](docs/security-faq.md) — who can see your data (ISP,
  Tailscale, Apple), how password verification really works, quantum vs
  hashes, corporate login internals, local AI privacy.
