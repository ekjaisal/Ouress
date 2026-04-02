# Log of Key Decisions

This document serves as the ledger recording the key decisions taken concerning Ouress. It records the foundational architectural choices, curation logic for tools, and defensive mechanisms implemented for long-term stability, reproducibility, and minimal-friction ergonomics.

## Ouress v1.0.0

| **#** | **Decision** | **Rationale** |
| ----- | -------------------------------------------- | ------------------------------------------------------------ |
| 1     | *Debian* GNU/Linux as the base   | Battle-tested stable and reliable operating system base for long-term durability. |
| 2     | Debian snapshot repository                   | Locks the `apt` package ecosystem to a specific timestamp via `snapshot.debian.org` to guarantee bit-for-bit reproducibility across builds. |
| 3     | `.ress` artifact extension                   | Identifies the custom compressed `tar` format, distinguishing it from generic archives while maintaining cross-platform structural consistency. |
| 4     | `fish` as interactive shell                  | Provides syntax highlighting and autosuggestions by default. Configuration is isolated in `/etc/fish/conf.d/` to survive upgrades. |
| 5     | `bash` retained                              | Included as a reliable fallback for scripting and automation. |
| 6     | Unprivileged execution (Passwordless `sudo`) | Executes as the `ouress` user to provide a cognitive safety net against accidental system destruction, while passwordless `sudo` eliminates friction for deliberate administrative actions. |
| 7     | Hardware database (`hwdb`) purge             | Completely removes `udev` and `systemd` hardware databases, as virtualised WSL/chroot environments rely on the host OS for physical PCI/USB device management. |
| 8     | Terminfo consolidation                       | Purges thousands of legacy hardware terminal mappings from `/usr/share/terminfo`, retaining only modern software emulators (`xterm`, `tmux`, `linux`, `screen`, `ansi`, `cygwin`, `vt100`). |
| 9     | APT strictness & translation exclusion       | Applies `APT::Install-Recommends "false"` and `Acquire::Languages "none"` to prevent the package manager from pulling in bloated graphical dependencies or foreign language package descriptions during future user installations. |
| 10    | Strict UTF-8 enforcement                     | `C.UTF-8` locale is explicitly generated and globally exported to `LANG` and `LC_ALL` to prevent cross-platform encoding mismatches. |
| 11    | APT list cache purge (Container Standard)    | Clears the `/var/lib/apt/lists/*` index to eliminate weight. Requires users to execute `apt update` before installing supplementary packages, aligning with standard container practices. |
| 12    | Post-install deletion over `dpkg` filters    | Executes aggressive `rm -rf` sweeps after installation rather than intercepting files with `dpkg --path-exclude`. This preserves contiguous byte alignment on disk, optimising the final `xz` compression. |
| 13    | Python core bundled                          | Includes the standard library, `pip`, and `venv`. Omits the full installation to prevent compiler bloat while supporting PEP-668 isolated environments. |
| 14    | `git` included (server and legacy binaries removed)          | Required for version control and repository management. Server-side executables (e.g., `git-daemon`, `git-shell`, `scalar`) are purged to eliminate weight. |
| 15    | `ugrep`                                      | Provides native Unicode support across scripts without requiring additional command-line flags. |
| 16    | `miller` and `xsv`                           | Pre-compiled binaries for data processing. `xsv` is used for fast CSV statistics and slicing; `miller` provides complex transformations. |
| 17    | `gron`, `jq`, and `jqp`                      | Toolchain for JSON. `gron` flattens structures, `jq` queries data, and `jqp` provides interactive filtering. |
| 18    | `xidel` and `xq`                             | Tools for HTML, XML, and XPath extraction. `xq` is implemented as a wrapper around `yq` to provide functionality absent from default repositories. |
| 19    | `w3m` and `html2text`                        | `w3m` converts web pages while preserving spatial layout; `html2text` generates semantic Markdown. |
| 20    | `batcat` included                            | Provides syntax highlighting and pagination for reading raw structured data on the terminal. |
| 21    | `moreutils` (`sponge`, `ts`)                 | `sponge` enables safe, in-place pipeline editing; `ts` allows timestamping of standard input lines. |
| 22    | Static binary version pinning                | External binaries are hard-coded to specific release URLs to prevent upstream fragility and guarantee absolute reproducibility of the build artifact. |
| 23    | SHA256 checksum verification                 | Cryptographically verifies all downloaded external binaries against hard-coded hashes to prevent supply-chain tampering and ensure artifact integrity. |
| 24    | Automated SSL symlinking (APT Hook)          | A `DPkg::Post-Invoke` hook links required `libssl` base names to dynamically versioned libraries, maintaining HTTPS support without `-dev` packages across `apt upgrade` operations. |
| 25    | Safe ELF binary stripping                    | Stripping is restricted to validated ELF files using `file` to remove dead weight while protecting shell wrapper scripts and hooks from corruption. |
| 26    | Static `.a` libraries removed                | Pure build artifacts providing no runtime utility.           |
| 27    | Man pages and copyrights retained            | Required for offline manual access and open-source license compliance. |
| 28    | Obscure `gconv` encodings removed            | Unnecessary encodings purged to reduce size, retaining only standard and major global encodings (UTF, ISO-8859, Windows codepages, KOI, CJK). |
| 29    | `cron` daemon excluded                       | Ouress is an on-demand appliance, not a 24/7 server. Task scheduling should be delegated to the host OS. |
| 30    | `/etc/ouress/` configuration namespace       | Isolates custom configuration from standard system paths for independent management. |
| 31    | Zero-latency WSL start-up directory          | Parses the natively applied `$USERPROFILE` environment variable via `wslpath`, eliminating subprocess interop latency during shell initialisation. |
| 32    | `wsl.conf` baked into rootfs                 | Enforces an automount configuration to standardise file permissions between the Windows host and the Linux subsystem natively. |
| 33    | `ouress` command                             | Prints release manifest information conforming to standard release conventions. |
| 34    | `task-spooler` (`tsp`) and `rush`                            | `tsp` provides tiny, system-native background queueing, while `rush` provides a single-binary, high-performance drop-in for multi-core batch processing, without GNU `parallel` which requires the heavy dependencies. |
| 35    | Shell ergonomics expansion (`visidata`, `fzf`, `pv`, `dos2unix`) | Integrated to provide functional multipliers for interactive data exploration, fuzzy searching, and pipeline monitoring. |
| 36    | Strict exclusion of `ffmpeg` and media scrapers | Modern DASH media scraping (e.g. via `yt-dlp` or `lux`) relies on `ffmpeg` for multiplexing, which would introduce codec bloat. |