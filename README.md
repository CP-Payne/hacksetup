# hacksetup

A Kali bootstrap: i3 for windows, tmux for terminals, and the usual web, network and mobile tooling.

## Quick guide

Super is the Windows key.

### Opening apps

* Super+Enter opens a terminal.
* Super+W opens Firefox, or jumps to it if it's already open. It always lands on workspace 2.
* Super+B does the same for Burp, which goes to workspace 3.
* Super+D opens a launcher: type part of an app's name (e.g. "fire") and press Enter.
* Super+Q closes the focused window.

If Super+W does nothing, use Super+D for now. It usually means `~/.local/bin` wasn't on your PATH when i3 started, and logging out and back in normally fixes it.

### Moving around i3

* Super+1 to 9 go to a workspace. 1 is for terminals, 2 for the browser, 3 for Burp and 4 for notes.
* Super+` flips back to the last workspace you were on. It's handy for going back and forth between Burp and the terminal.
* Super+Tab lets you search all open windows by name.
* Super+H/J/K/L (or the arrow keys) move focus between windows on the same workspace, and adding Shift moves the window itself.
* Super+Shift+number sends the focused window to that workspace.
* Super+F makes a window fullscreen, and Super+G stacks the windows on a workspace as tabs. Super+E switches back to side-by-side.

Browser tabs are Firefox's own: Ctrl+T for a new tab, Ctrl+W to close, Ctrl+Tab to cycle and Alt+1 to 9 to jump to a tab.

### Terminal tabs with tmux

Terminal tabs are handled by tmux, not the terminal. A new terminal is not in tmux yet, so run this first:

```bash
eng test
```

That opens a session with four named windows: recon, web, exploit and shells. From there:

* Alt+1 to 4 switch between the windows.
* Ctrl+A, then `c` creates a new window, and Ctrl+A, then `,` renames it.
* Ctrl+A, then `|` splits the pane side by side, and Ctrl+A, then `-` splits it top and bottom.
* Ctrl+A, then `h`/`j`/`k`/`l` move between panes, or you can just click a pane.
* Ctrl+A, then `s` lists every session and window so you can pick one.
* Ctrl+A, then `d` detaches. Everything keeps running, and `eng test` brings it back.

Press Ctrl+A, let go, then press the second key. The letters are lowercase: capital `C`, for example, opens a different tmux screen.

A good first run is `eng htb-box`, then Super+W for Firefox, Super+B for Burp, and Super+` to flip back to the terminal. After a day of that the keys become automatic.

## Installing

Log in to Kali as your normal user, not root. The script uses sudo where it needs it.

```bash
git clone https://github.com/CP-Payne/hacksetup.git
```

```bash
cd hacksetup
```

```bash
bash setup.sh
```

Then log out and pick **i3** at the login screen.

Keep the repo where you cloned it. The config files are symlinks into the repo, so moving or deleting it breaks them. If you do move it, run `bash setup.sh dotfiles` from the new location.

The script is safe to re-run: installs skip or upgrade, git tools pull, and dotfiles re-link. Anything that fails to install is listed at the end of the run, and the rest carries on.

## Using the script

Run everything:

```bash
bash setup.sh
```

Run one or more sections:

```bash
bash setup.sh mobile_tools network_tools
```

| Section | What it does |
| --- | --- |
| `base_system` | Updates the system, installs build tools, Python, Go and Java, and creates `~/tools`, `~/.local/bin` and `~/engagements` |
| `desktop` | i3, rofi, kitty, a compositor, notifications and screenshots |
| `shell_tools` | tmux, fzf, ripgrep, fd, bat and others, plus PATH and the `t` alias in `~/.zshrc` |
| `dotfiles` | Links the configs and `bin/` scripts into place, then reloads any running tmux |
| `web_tools` | Burp Community, ffuf, feroxbuster, gobuster, sqlmap, nuclei, wordlists |
| `network_tools` | nmap, netexec, impacket, responder, evil-winrm, hashcat, john, chisel and others |
| `mobile_tools` | adb, apktool, jadx, frida-tools, objection |
| `burp_pro` | Burp Suite Pro installer. Optional, so a full run skips it |

To install Burp Pro, run `bash setup.sh burp_pro`. To skip a section on a machine, comment it out in `main()` at the bottom of `setup.sh`.

## Commands

| Command | What it does |
| --- | --- |
| `eng <name>` | Creates or reattaches the tmux session for an engagement, with its folder at `~/engagements/<name>` |
| `tmux ls` | Lists running sessions |
| `t` | Attaches to the last tmux session, or starts one called `main` |
| `raise <class> <command>` | Focuses a window by its class, or launches the command if it isn't open. The Super+W and Super+B keys use it |

Each engagement folder has `scans`, `loot`, `exploits` and `screenshots` inside. A session's windows all start in that folder.

## More keys

### i3

| Keys | Action |
| --- | --- |
| Super+T | Jump to the terminal, or open one |
| Super+V / Super+S | Open the next window below / beside the current one |
| Super+Shift+Space | Toggle floating for a window |
| Super+Space | Switch focus between floating and tiled windows |
| Super+R | Resize mode: `h`/`j`/`k`/`l` to resize, Esc to leave |
| Print | Take a screenshot with flameshot |
| Super+Shift+C | Reload the i3 config |
| Super+Shift+R | Restart i3 in place |
| Super+Shift+E | Exit i3 |

### tmux

All of these come after Ctrl+A.

| Key | Action |
| --- | --- |
| `w` | List windows |
| `[` | Scroll and copy with vim keys, `q` to leave |
| `P` | Turn logging of the current pane to `~/tmux-logs` on or off |
| `r` | Reload the tmux config |
| Ctrl+A | Send a real Ctrl+A to the program in the pane |

The bar at the top of tmux shows the session, the windows, your `tun0` VPN address when connected, and the time.

## Extending it

### Add a tool

Find the right section in `setup.sh`, add one line, then run only that section.

```bash
apt_install bloodhound
pipx_install git+https://github.com/someone/smbthing
go_install github.com/projectdiscovery/katana/cmd/katana
git_tool https://github.com/someone/repo
```

```bash
bash setup.sh network_tools
```

`git_tool` clones into `~/tools`, and pulls on later runs. Go tools land in `~/go/bin`, which is already on your PATH.

### Add a section

Write a function above the `main` section of `setup.sh`, and add its name to `main()` so full runs include it:

```bash
cloud_tools() {
  log "Cloud tools"
  apt_install awscli
}
```

The script stops on errors, so don't end a section with `[[ test ]] && command`. When the test is false, the section counts as failed and the script stops there. Use `if` instead, or add `|| true`.

### Add a script to your PATH

Put it in `bin/`, then link it. Any file in `bin/` is made executable and linked into `~/.local/bin`:

```bash
bash setup.sh dotfiles
```

### Change a key or setting

The files in `dotfiles/` are live, so edit them in the repo and reload:

| File | Apply with |
| --- | --- |
| `dotfiles/tmux.conf` | Ctrl+A, then `r` |
| `dotfiles/i3/config` | Super+Shift+C |
| `dotfiles/kitty.conf` | Open a new terminal |
| `dotfiles/xprofile` | Log out and back in |

To add a new config file, put it in `dotfiles/` and add a `link` line to the `dotfiles()` function in `setup.sh`:

```bash
link "$REPO/dotfiles/foo.conf" "$HOME/.config/foo/foo.conf"
```

If a real file already exists at that location, it's renamed to `<file>.bak.<timestamp>` first.

To send an app to its own workspace, add an `assign` line to the i3 config:

```i3
assign [class="(?i)obsidian"] $ws4
```

## Troubleshooting

**Ctrl+A does nothing.** Check these in order:

1. Make sure you're in tmux, which has a bar at the top showing the session and windows. In a plain terminal, Ctrl+A just moves the cursor to the start of the line, so run `eng test` first.
2. Check that `~/.tmux.conf` is a link into this repo with `ls -l ~/.tmux.conf`. If it isn't, run `bash setup.sh dotfiles`.
3. Run `tmux show -g prefix`. If it prints `prefix C-b`, tmux started before the config was linked. Run `tmux source-file ~/.tmux.conf` to fix it.

**`eng` or `raise` is not found.** Run `bash setup.sh dotfiles`, then log out and back in.

**The script stopped before "Done".** A step hit an error. Read the last few lines of output, fix the cause, and run the script again. It's safe to re-run.

**Burp is grey or blank.** Log out and back in so `~/.xprofile` applies, then open Burp again.
