# ss-ext — `screensaver-extend`

**Extend a too-short, MDM-enforced screen-saver / auto-lock timeout on macOS — without touching the managed profile.**

Many corporate-managed Macs ship a configuration profile that forces the screen saver (and password lock) to engage after just a few minutes of inactivity. Because it's a *managed preference*, you can't change it in **System Settings**, and `defaults write com.apple.screensaver idleTime …` is silently overridden.

`ss-ext` gives you back a sane idle timeout (default **30 minutes**) **without removing or weakening the profile**. It still locks when you're actually away — it only changes *how long* "away" has to be, exactly like playing a video or running a presentation does.

```bash
git clone https://github.com/dendenxu/ss-ext.git
cd ss-ext
./install.sh
screensaver-extend on        # default 30 min; auto-starts at login
screensaver-extend set 45    # ...or pick your own
```

## What it is / isn't

- ✅ Extends the *idle* time before the screen saver + lock engage.
- ✅ Still locks when you're genuinely idle past your timeout — the password policy is untouched.
- ✅ Leaves the MDM configuration profile **completely unmodified**.
- ❌ Does **not** disable the lock, remove the password requirement, or delete/alter any profile.
- ❌ Not a way to defeat a security policy — it's the macOS-sanctioned "I'm using this machine" signal, held only while you're inside your chosen window.

## How it works

macOS fires the screen saver after `com.apple.screensaver idleTime` seconds of **HID inactivity** (no keyboard/trackpad). Any app may hold a `PreventUserIdleDisplaySleep` power assertion to suppress that — which is why a playing video keeps your screen awake.

`ss-ext` runs a small LaunchAgent daemon that:

1. Polls your **real** idle time (`ioreg -c IOHIDSystem` → `HIDIdleTime`).
2. While idle **<** your timeout, holds a `PreventUserIdleDisplaySleep` assertion (via `caffeinate -d`) → the short screen saver never triggers.
3. Once idle **≥** your timeout, **releases** the assertion → macOS immediately runs the screen saver + lock per the existing policy.

The assertion never resets the idle counter, so the OS locks promptly once you cross your timeout. Net effect: effective idle-to-lock = your timeout; profile untouched.

## Battery & lid behavior

- **On battery, the override pauses by default** (`AC_ONLY=1`). When you're not plugged in, the daemon releases the assertion and your machine reverts to the MDM-enforced timeout — so an unplugged laptop in your bag locks promptly and saves power. Plug back in and the 30-minute override resumes within one poll. Want it on battery too? `screensaver-extend ac-only off`.
- **Closing the lid always sleeps.** The daemon holds *only* `PreventUserIdleDisplaySleep` — the weakest assertion. It suppresses the idle screen saver but does **not** touch clamshell (lid-close) sleep, which is a separate path. Shut the lid and the Mac sleeps normally, override or not.

## Requirements

- macOS. Uses only built-in `caffeinate`, `ioreg`, `launchctl`, `defaults`, `bash`.
- No admin rights, no Homebrew, nothing to compile.

## Install

```bash
git clone https://github.com/dendenxu/ss-ext.git
cd ss-ext
./install.sh                 # copies to ~/.local/bin/screensaver-extend
screensaver-extend on        # start now + auto-start at login (default 30 min)
```

If `~/.local/bin` isn't on your `PATH`, add this to `~/.zshrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

> Prefer a custom location? `PREFIX=/usr/local/bin ./install.sh`.

## Usage

```bash
screensaver-extend on             # install + load the LaunchAgent (auto-start at login)
screensaver-extend off            # unload — revert to the MDM-enforced timeout
screensaver-extend set 45         # change the idle timeout to 45 minutes (hot-reloads)
screensaver-extend ac-only off    # also override on battery (default: on = AC only)
screensaver-extend config         # print all settings (or: config KEY VALUE to set one)
screensaver-extend status         # show config + live state
screensaver-extend restart        # restart the daemon
```

Configuration lives in `~/.config/screensaver-extend.conf`:

```bash
TIMEOUT_MIN=30   # lock after this many minutes of real inactivity
POLL_SEC=15      # how often (seconds) to sample idle time and power source
AC_ONLY=1        # 1 = only override on AC power; on battery, fall back to the MDM timeout
```

Every key is toggleable from the CLI — `screensaver-extend config TIMEOUT_MIN 45`,
`screensaver-extend ac-only off`, etc. — or edit the file and `screensaver-extend restart`.
Changes hot-reload the running agent.

### `status` example

```
config   : /Users/you/.config/screensaver-extend.conf
timeout  : 30 min    poll: 15s    ac-only: on
agent    : loaded
power    : AC
idle now : 124s
assertion: HELD (screensaver suppressed)
MDM force: idleTime=300s, askForPassword=1
```

## Verify it's working

```bash
# Prints 1 while you're active (assertion held), 0 when released:
pmset -g assertions | awk '$1=="PreventUserIdleDisplaySleep"{print $2}'

# Your real idle time in seconds:
ioreg -c IOHIDSystem | awk '/HIDIdleTime/{print int($NF/1000000000)" s"; exit}'
```

If your MDM forces, say, 5 minutes (`idleTime=300`) and you stay idle **past 300 s** with the assertion still `1` and no `ScreenSaverEngine` process running, the override is working.

## How auto-start works

`screensaver-extend on` writes `~/Library/LaunchAgents/com.local.screensaver-extend.plist` (`RunAtLoad` + `KeepAlive`) pointing at the installed script, and bootstraps it into your GUI session. It restarts on logout/login and if it ever exits.

> Implementation note: `on` uses `launchctl kickstart -k` when the agent is already loaded and only `bootstrap`s when it isn't — never `bootout` immediately followed by `bootstrap`, because `bootout` is asynchronous and the immediate `bootstrap` would lose the teardown race (a silent-failure footgun).

## Uninstall

```bash
./uninstall.sh   # removes the binary, LaunchAgent, config and state; reverts to MDM timeout
```

## Notes & caveats

- **Manual lock still works** — hot corners and `Ctrl-Cmd-Q` are unaffected; the assertion only suppresses *idle-triggered* sleep. (Lid close and battery behavior are covered above.)
- **Corporate policy**: this changes only *your* local idle window and keeps the password lock intact. Make sure that's consistent with your organization's acceptable-use policy. It only touches power assertions and a user LaunchAgent — it never edits `/Library/Managed Preferences` or the profile.
- **Testing**: set `SSEXT_FORCE_POWER=ac|battery` to override power-source detection (used to exercise the `AC_ONLY` path without unplugging).

## License

MIT © 2026 Zhen Xu
