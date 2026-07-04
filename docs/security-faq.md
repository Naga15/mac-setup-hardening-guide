# Security & Privacy FAQ

Plain-English answers to the questions that come up while hardening a Mac.

## Who can actually see my data?

| Party | CAN see | CANNOT see |
|---|---|---|
| **Your ISP** | Domains you visit (DNS lookups + the SNI field of HTTPS handshakes), when, how much data | Content — pages, messages, passwords. Nearly all web traffic is HTTPS: the ISP sees you connected to a site, not what you did there |
| **Tailscale** (if you use it) | Metadata: which devices are enrolled, their keys, connection times | Your traffic — ever. Connections are WireGuard-encrypted device-to-device; keys never leave your devices. Even its DERP relay servers only carry ciphertext |
| **Apple** (hardened per this guide) | Update check-ins; little else with analytics off and iCloud services off | FileVault contents; Find My location (end-to-end encrypted — Apple cannot read it) |
| **Websites & apps** | Everything you do *on them* — the biggest real-world collectors | Other tabs and apps (mostly) |
| **A laptop thief** | Nothing, if FileVault is on | Everything, if it isn't |

**Reduce the ISP's slice:** use encrypted DNS — System Settings → Wi-Fi →
Details → DNS → `9.9.9.9` (Quad9), or NextDNS for filtering. The ISP then
loses the DNS half of its visibility. Only a VPN hides the rest (SNI/IPs),
and that just moves trust to the VPN operator — choose accordingly.

## Can someone with admin/root access read my login password?

No — by design, from anyone. macOS never stores the password itself:

- It stores a **slow, salted hash** (PBKDF2, high iteration count) in a
  root-only database — a one-way fingerprint, not the password.
- The hash is entangled with the **Secure Enclave**, which rate-limits
  guessing *in hardware* and holds the FileVault keys in silicon that
  can't be extracted even by physically opening the chip.
- An admin can **reset** another user's password (loud, visible, and it
  doesn't decrypt their keychain) — but **read** it, never. Anyone claiming
  to "recover" a Mac password is describing a reset, or lying.

Practical upshot: the machine side is solved. Real password risk is human —
reuse across websites, phishing, weak passwords. Use a password manager and
unique passwords; that's where the attention belongs.

## Could quantum computers crack the password hash?

Mostly no. Quantum breaks cryptography unevenly:

- **Genuinely broken (eventually):** public-key crypto — RSA/elliptic curves
  fall to Shor's algorithm. This is why the industry is migrating to
  post-quantum algorithms (Apple's iMessage PQ3, TLS ML-KEM).
- **Merely dented:** hashes and symmetric encryption. Grover's algorithm
  gives only a quadratic speedup — effectively halving security bits.
  256-bit → "128-bit equivalent" — still billions of years.
- PBKDF2's deliberate slowness must be executed serially, erasing most of
  Grover's advantage; the attacker would also need the hash first (i.e.
  root on your machine — game over anyway); and Secure Enclave rate limits
  are physics, not math.

The honest caveat: a weak human password falls to a *classical* laptop
today. And the real quantum concern is "harvest now, decrypt later" —
recorded encrypted *traffic* being decrypted years from now. That threatens
communications, not your local login.

## How do corporate laptops verify passwords? And how do they work offline?

**Online (classic Active Directory/Kerberos):** your machine derives a key
from your password, encrypts a timestamp with it, and sends that to the
Domain Controller — which checks it against its stored verifier and issues
a ticket (TGT) for everything else. The password itself never crosses the
network, only proof you know it.

**Offline:** at each successful online login, the laptop stores a local
**cached credential verifier** — a re-hashed, salted, deliberately slow
derivative. With no network, it derives the same thing from what you type
and compares locally. That's why you can log in on a plane — and why a
password changed elsewhere doesn't work on a laptop that's been offline
(it still knows only the old one).

**The modern direction (Windows Hello, Platform SSO, passkeys):**
passwordless — a key pair is generated inside the TPM/Secure Enclave; your
PIN or fingerprint unlocks the private key, which signs a server challenge.
Nothing secret ever travels or is stored server-side. A personal Mac with
Touch ID works this way already: secrets that live in silicon and never move.

## Is Apple Intelligence / local AI safe to use?

- **Local models (Ollama etc.):** the most private option, full stop.
  After download, inference runs on your GPU; nothing leaves the machine;
  works in airplane mode.
- **Apple Intelligence:** most requests run on-device. Overflow goes to
  Private Cloud Compute — stateless, no retention, not used for training,
  and uniquely *verifiable* (published server images, hardware-enforced
  no-privileged-access, bug bounty). The one boundary to watch: the optional
  ChatGPT hand-off (off by default, prompts per request) — that's the only
  path to a third party.
- Either way, keep "Improve Siri & Dictation" and analytics sharing OFF —
  those settings, not the AI itself, are the data leaks.

## Find My: doesn't it share my location with Apple?

Find My location reports are **end-to-end encrypted** — only your devices
hold the decryption keys; Apple sees ciphertext. Meanwhile it enables
**Activation Lock** (a stolen Mac can't be wiped and resold — the strongest
theft deterrent that exists) and remote lock/erase from your phone or
icloud.com/find. It's the one place where "share nothing with Apple"
would cost you real security for negligible privacy gain.

## Why bother with a standard (non-admin) account for other users?

Containment. A standard user can run every app in /Applications but cannot
install system software, change security settings, or read your files. If
that account is ever phished or compromised, the blast radius stops at its
home folder — nothing system-wide gets touched without an admin password.
Never hand out admin to solve a one-time install; type your password at
that moment instead.
