<div align="center">
<img src="assets/logos/Ouress.svg" alt="Ouress Logo" width="128">
<h1>Ouress</h1>
<p><i>An Opinionated Underlabouring Research Environment for the Social Sciences</i></p>
</div>
<p align="center">
<a href="https://github.com/ekjaisal/Ouress/releases"><img height="20" alt="GitHub Release" src="https://img.shields.io/github/v/release/ekjaisal/Ouress?color=66023C&label=Release&labelColor=141414&style=flat-square&logo=github&logoColor=F5F3EF&logoWidth=11"></a>
<a href="https://github.com/ekjaisal/Ouress/blob/main/LICENSE"><img height="20" alt="License: BSD-3-Clause" src="https://img.shields.io/badge/License-BSD_3--Clause-66023C?style=flat-square&labelColor=141414&logoColor=F5F3EF&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0iI0Y1RjNFRiI+PHBhdGggZD0iTTE0IDJINmMtMS4xIDAtMiAuOS0yIDJ2MTZjMCAxLjEuOSAyIDIgMmgxMmMxLjEgMCAyLS45IDItMlY4bC02LTZ6bTQgMThINlY0aDd2NWg1djExeiIvPjwvc3ZnPg=="></a>
<a href="https://github.com/ekjaisal/Ouress/releases"><img height="20" alt="GitHub Downloads" src="https://img.shields.io/github/downloads/ekjaisal/Ouress/total?color=66023C&label=Downloads&labelColor=141414&style=flat-square&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0iI0Y1RjNFRiI+PHBhdGggZD0iTTEyIDIwbC03LTcgMS40MS0xLjQxTDExIDE2LjE3VjRoMnYxMi4xN2w0LjU5LTQuNThMMTkgMTNsLTcgN3oiLz48L3N2Zz4=&logoColor=F5F3EF"></a>
<a href="https://github.com/ekjaisal/Ouress/stargazers"><img height="20" alt="GitHub Stars" src="https://img.shields.io/github/stars/ekjaisal/Ouress?color=66023C&style=flat-square&labelColor=141414&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0iI0Y1RjNFRiI+PHBhdGggZD0iTTEyIDJsMy4wOSA2LjI2TDIyIDkuMjdsLTUgNC44N2wxLjE4IDYuODhMMTIgMTcuNzdsLTYuMTggMy4yNUw3IDE0LjE0IDIgOS4yN2w2LjkxLTEuMDFMMTIgMnoiLz48L3N2Zz4=&logoColor=F5F3EF&label=Stars"></a>
</p>

The computational turn in the social sciences offers the promise of scalability and, to an extent, reproducibility in the study of politics, society, media, discourse, and several other domains, in ways unimaginable through traditional means. But enterprising social scientists, foraying into this terrain to harvest its vast potential, often encounter several friction points that deter many and offer a smooth passage only to the already initiated.

It is not rare for research projects in the social sciences to span very long, continuous or even disjunct periods. Studies often demand multiple iterations, deep engagements, deeper re-engagements, and reflexive refinements. Keeping data, analysis pipelines, and workflows frozen in time and returning to them with a high degree of confidence that things are exactly as they were, even years later, is crucial to avoid concerns about reliability. Fighting with environment variables, package managers, and dependency conflicts against this backdrop on a routine basis to get things done often forces a shift in focus from the rigour of the work itself to assuming the role of a systems administrator. Minimum-friction, pre-configured but extensible, end-to-end setups, if carefully implemented, could thus clear the ground to a large extent, making it possible to reclaim the research’s ingenuity as the primary focus.

While reproducible environments have existed for a long time, with Docker-like containers as the industry standard, it is a stretch to assume that what works well for development operations pipelines is equally viable for all use cases. For a social science researcher with perhaps the primary goal of parsing datasets, building a corpus, or analysing text, cloud-native containerisation introduces significant bottlenecks and knowledge gaps that underserve such a demographic. Cloud-native containers are engineered for statelessness and isolated execution, rather than serving as persistent, stateful workbenches. Conversely, language-specific virtual environments excel at package isolation but lack the capacity to encapsulate system-level dependencies and pre-compiled native binaries. The technical underlabouring for social science-oriented end-to-end workflows, therefore, calls not for custom-built containerisation or virtual environments, but for a curated appliance with minimal-friction ergonomics. Thus, Ouress exists!

*Ouress* is an **O**pinionated **U**nderlabouring **R**esearch **E**nvironment for the **S**ocial **S**ciences. It is a portable, zero-configuration Unix-like environment tailored to serve the priorities of social science research (such as the text-as-data approach). It aims to deliver a carefully curated, yet extensible toolkit in a single compressed filesystem that runs on Linux<sup>®</sup> via [chroot](https://www.gnu.org/software/coreutils/manual/html_node/chroot-invocation.html) and on Windows<sup>®</sup> via the [Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/about) (WSL2). It is put together (i) with intentional choices about which components to include and exclude, hence, *opinionated*; (ii) as an effort to clear the ground for social science research using computational tools; hence, *underlabouring*.

## The Ouress Manifesto

* **Minimal-Friction Ergonomics:** Ouress will not prompt for account creation, passwords, or path management. The environment provides an intuitive, out-of-the-box functional shell executing as a standard unprivileged user (`ouress`) with pre-configured passwordless `sudo`. This structure provides a cognitive safety net against accidental destructive actions without introducing the friction of constant password prompts. The environment will integrate seamlessly with the host filesystem, retaining write access to the Windows filesystem via `/mnt/`.
* **Reproducibility:** An analysis pipeline locked-in today must execute deterministically on any other machine years into the future. Ouress anchors the internal package manager to fixed-timestamp [*Debian* snapshot repositories](https://snapshot.debian.org). This guarantees temporal stability across three deployment scenarios:
  * **“As is” Release Base:** Pipelines executing on an unmodified release base image.
  * **Scripted Extension:** Pipelines executing on a release base image where all system modifications (e.g. supplementary `apt` installations) are explicitly codified within the pipeline itself.
  * **Stateful Snapshot:** Pipelines executing from a distributed, fully configured custom `.ress` archive that captures the exact frozen state of the workbench.
* **Minimum Bloat:** Ouress will be a lean, yet stable, versatile, and sufficiently-equipped distribution artifact with [Just Enough Operating System](https://www.suse.com/topics/definition/jeos-just-enough-operating-system) (JeOS) required to run on WSL2 or Linux `chroot`. The [kernel](https://www.techtarget.com/searchdatacenter/definition/kernel)-less appliance will only package strictly required tools and aggressively remove heavyweight graphical frameworks, legacy hardware databases, and redundant translation scaffolding. Components such as the Python 3 core will be bundled strictly with `pip` and `venv` to support [PEP-668](https://peps.python.org/pep-0668) isolated environments, ensuring minimal data retention on the disk.
* **Architectural Portability:** The primary distribution artifact (the `.ress` archive) will be a unified, structurally identical [root filesystem](https://www.linfo.org/root_filesystem.html). Whether deployed natively via `chroot` on a Linux system or launched through the Windows Subsystem for Linux (WSL2), the internal environment will execute identically without requiring platform-specific branching.
* **Reliability & Graceful Degradation:** Customisations, shell aliases, and convenience functions must never introduce critical points of failure. Every environmental enhancement should be designed to degrade gracefully, ensuring the underlying *Debian* core and POSIX utilities remain fully operational and resilient against unexpected usage patterns.
* **Binary Durability:** Core utilities must survive routine `apt upgrade` operations with bloat-reduction and without succumbing to dependency conflicts. Defensive mechanisms, such as dynamic APT post-invoke hooks for SSL library symlinking, ensure that network-dependent binaries maintain continuous HTTPS connectivity even after development header packages are removed.
* **Version Pinning:** Pre-compiled static binaries fetched outside the default package ecosystem must be strictly version-pinned to specific upstream releases and validated against hardcoded SHA256 checksums. This secures the build process against upstream fragility, link rot, and supply-chain tampering.
* **Unified Lockstep Versioning Plan:** To eliminate ambiguity regarding pipeline compatibility, the management utility and the Linux root filesystem will be versioned as a single, indivisible artifact using [semantic versioning](https://semver.org) (`MAJOR.MINOR.PATCH`). This ensures exact matching between pipeline requirements and environment states:
  - **The MAJOR Epoch (e.g. v1.0.0 to v2.0.0):** Indicates a foundational shift that may break backwards compatibility. This will be strictly triggered by upstream *Debian* stable generation upgrades (e.g. *Debian* 13 to 14), major interpreter shifts (e.g. Python 3.13 to 3.14), or the deprecation and removal of core tools. Pipelines developed on a previous major version may require modification to execute on a newer major version.
  - **The MINOR Workbench (e.g. v1.0.0 to v1.1.0):** Signifies a shift in the internal reproducibility state that remains functionally backwards-compatible. This will be triggered when updating the frozen *Debian* snapshot timestamp (to ingest upstream point releases and security patches), updating pinned external binaries, or adding new tools. While older pipelines will most likely execute deterministically without errors, strict bit-by-bit replication requires anchoring to the exact Minor version.
  - **The Chassis PATCH (e.g. v1.0.0 to v1.0.1):** Denotes ergonomic updates to the management utility, installer, or documentation. The underlying *Debian* snapshot timestamp and curated binaries remain entirely frozen but the version number in the artifact will be bumped for synchronisation. Pipelines will be mostly compatible across all patch versions within the same minor release sequence.

## Architecture

Ouress is built on Linux, with its foundational make-up derived from the *[Debian](https://www.debian.org)* distribution. It is constructed using `debootstrap --variant=minbase`, then subsequently reduced to a JeOS by intentionally removing packages, hardware databases, and translation metadata that do not suit its purpose. The primary interactive shell in Ouress is `fish`, the [Friendly Interactive Shell](https://fishshell.com) (`/bin/fish`), for a smooth and intuitive experience out of the box. The default system shell (`/bin/sh`) is `dash` ([Debian Almquist Shell](https://packages.debian.org/sid/dash), providing strict POSIX compliance and speed for system scripts and `apt` internals. `bash`, the universal [GNU Bourne Again Shell](https://www.gnu.org/software/bash), is maintained for robust, widely compatible scripting (`/bin/bash`).

The Ouress-specific metadata resides under `/etc/ouress/`, keeping the upstream `/etc/os-release` unaltered to avoid interfering with system behaviour that relies on it. The `release.vars` file contains release metadata applied to the root filesystem during the build process. The base image, i.e., the customised *Debian* root filesystem distributed as `ouress-vx.x.x.ress` is structurally a standard `xz`-compressed tar archive, with the `.ress` extension identifying it as an Ouress image or snapshot. A fully configured snapshot, containing installed tools, datasets, scripts, and analytical pipelines, can be exported, shared, and imported as a reproducible state (e.g. `research-snapshot.ress`).

The architectural essence of Ouress can thus be summarised as a research appliance composed of a root filesystem that shares the host’s kernel and is derived by reducing *Debian* to JeOS and preconfiguring it with a curated selection of packages. The foundational architectural choices, tool curation logic, and defensive mechanisms are recorded in the [key decisions log](key-decisions-log.md).

**Note:** Ouress currently supports only the `amd64` (`x86_64`) architecture.

## The Curated Bundle

### Extraction and Digitisation Tools

| Utility | Function |
| :--- | :--- |
| `poppler-utils` (`pdftotext`, `pdfinfo`, `pdfimages`) | Tools for layout-aware text extraction from PDFs. |
| `antiword`, `catdoc`, `odt2txt` | Tools for text extraction from legacy Word, Excel, and OpenDocument files. |
| `xidel` | Tool for HTML, XML, XPath, and CSS selector extraction with built-in network fetching. |
| `w3m`, `html2text` | Tools for converting web pages to plain text or markdown. |

### Exploration, Wrangling and Productivity Tools

| Utility | Function |
| :--- | :--- |
| `ugrep` | RegEx engine for handling Unicode across Latin, CJK, Malayalam, Devanagari, Arabic, and other human scripts. |
| `sed`, `gawk` | Stream editors for cleaning and reshaping text. |
| `miller` | Tool for filtering, reshaping, aggregating, and joining CSV, TSV, and JSON data. |
| `jq`, `gron`, `jqp` | Toolchain for JSON querying, flattening, and interactive visual filtering. |
| `xq` | Wrapper tool for XML querying and transformation. |
| `sqlite3` | Database engine for handling local `.db` files. |
| `xsv` | Tool for CSV slicing, statistical analysis, and table joins. |
| `visidata` | Interactive terminal-based spreadsheet for visually exploring, filtering, and pivoting massive CSV and JSON datasets. |
| `sponge` | Utility for absorbing standard input before writing, enabling safe in-place file editing. |
| `dos2unix` | Utility for cleaning and standardising Windows line endings in collaborative datasets to prevent pipeline breakages. |

### Network, Fetch, and Version Control Tools

| Utility | Function |
| :--- | :--- |
| `curl`, `wget` | Utilities for HTTP requests, API calls, and recursive web downloads. |
| `rsync` | Utility for data synchronisation and remote transfer. |
| `ssh`, `scp` | Utilities for remote login and secure file copy. |
| `git` | Version control system for cloning replication archives and managing analysis scripts. |

### Compression and Archiving Tools

| Utility | Function |
| :--- | :--- |
| `7zip`, `xz`, `gzip`, `bzip2`,  `zstd`, `tar`, `unrar`,  `zip`, `unzip` | Suite of utilities for handling major compression and archiving formats. |

### Shell Productivity Tools

| Utility | Function |
| :--- | :--- |
| `fish` | Interactive shell featuring history autosuggestions, syntax highlighting, and code completion. |
| `bash` | Universal shell for widely compatible scripting and automation. |
| `fzf` | Command-line fuzzy finder for interactive history search and directory navigation. |
| `tmux` | Terminal multiplexer for managing background jobs, splitting panes, and persisting sessions. |
| `task-spooler` (`tsp`)       | Tool for queueing, managing, and executing long-running shell tasks in the background. |
| `rush`                       | Tool for executing jobs in parallel. |
| `nano` | Terminal text editor. |
| `htop`, `tree`, `file`, `bc` | System utilities for process monitoring, directory inspection, file identification, and arithmetic. |
| `pv` | Utility for inserting progress bars, time estimates, and throughput monitoring into standard Unix text pipelines. |
| `ts` | Utility for appending timestamps to standard input lines for logging and profiling. |
| `batcat` | Utility for syntax highlighting and paginated reading of raw structured data. |

## Installation & Usage

### Windows

Ouress provides a zero-friction command-line utility for Windows, eliminating the need for manual WSL configuration or PowerShell scripting.

1. Download the installer from the [Releases](https://github.com/ekjaisal/Ouress/releases/latest) page or from [https://ouress.jaisal.in](https://ouress.jaisal.in).

2. Run the installer to deploy the command-line utility alongside the base `.ress` image.

   **Note:** Windows SmartScreen may flag the installer as an unrecognised application. Provided the installer is sourced from the locations specified in step 1, bypass the prompt by clicking **More info** → **Run anyway**. For added assurance, [verify](#verification) the `SHA256SUMS`.

3. Launch Ouress from the Start Menu.

4. Use the interactive command-line utility to manage the entire environment lifecycle:

   - **[1] Register New Environment:** Deploy and register a fresh instance from the bundled base image.

   - **[2] Import Environment:** Restore and register a shared or backed-up `.ress` snapshot.

   - **[3] Export Environment:** Compress a registered environment into a portable `.ress` snapshot.

   - **[4] Unregister Environment:** Permanently unregister an environment and remove its virtual disk.

5. **Launching Environments:** Windows Terminal and the Windows Start Menu natively integrates with WSL. Once an environment is registered via the Ouress command-line utility, launch it directly by searching for its name (assigned during registration) in the Windows Start Menu or by selecting it from the Windows Terminal dropdown. The system automatically handles launching, suspending, and terminating the virtual machine in the background.

### Linux

Ouress works with `chroot` on Linux. Please note that it requires root privileges (`sudo`) and manual bind mounts for external directories.

```bash
mkdir -p ~/ouress-project
sudo tar -xJf ouress-vx.x.x.ress -C ~/ouress-project
```
Optionally, mount the host directories into the environment’s `/mnt/` directory.

```bash
sudo mkdir -p ~/ouress-project/mnt
sudo mount --bind ~/Documents ~/ouress-project/mnt
```
Bind-mount the host’s DNS configuration (for network).
```bash
sudo mount --bind /etc/resolv.conf ~/ouress-project/etc/resolv.conf
```
Enter the environment.

```bash
sudo chroot ~/ouress-project /usr/bin/fish
```

Upon exit, unmount host directories and DNS configuration (required, if mount opted, to prevent accidental data loss or lock scenarios).

```bash
sudo umount ~/ouress-project/mnt
sudo umount ~/ouress-project/etc/resolv.conf
```

**Note:** See the accompanying [quick reference](quick-reference.md) file to familiarise with a few standard operational procedures.

## Environment Snapshots (.ress)

### Exporting & Importing on Windows

Use the **Ouress** management utility to handle snapshot operations securely.

When exporting (`[3] Export Environment`), the utility will ask for the preferred compression level, launch a native file dialog and prompt for a destination and filename, and execute a pipeline that instructs the Linux subsystem to compress its own filesystem. The pipeline bypasses the Windows-Linux I/O bridge, eliminating the need for manual disk compaction or zeroing.

**Note:** Exercise caution while attempting to export non-Ouress environments using the utility. Exporting with the utility works only if the environment has `xz-utils` (name can vary) installed. Incorrect usage may result in locks or errors in WSL.

When importing (`[2] Import Environment`), the utility will prompt for a destination name and launch a native file dialog to select any valid `.ress` snapshot. The environment will be instantly restored and registered with the operating system.

**Important Security Note:** A `.ress` snapshot is a complete, executable Linux filesystem. By default, importing and launching a snapshot grants it the exact same privileges as the current Windows user account, including full read/write access to files via `/mnt/c/`. Treat a `.ress` file with the **exact degree of caution** as with an executable `.exe` file and import environments only from **trusted sources**.

### Importing on Linux

```bash
mkdir -p ~/ouress-received
sudo tar -xJf research-snapshot.ress -C ~/ouress-received
```

Optionally, mount the host directories into the environment’s `/mnt/` directory.

```bash
sudo mkdir -p ~/ouress-received/mnt
sudo mount --bind ~/Documents ~/ouress-received/mnt
```

Bind-mount the host’s DNS configuration (for network).

```bash
sudo mount --bind /etc/resolv.conf ~/ouress-received/etc/resolv.conf
```

Enter the restored environment.

```bash
sudo chroot ~/ouress-received /usr/bin/fish
```

Upon exit, unmount host directories and DNS configuration (required, if mount opted, to prevent accidental data loss or lock scenarios).

```bash
sudo umount ~/ouress-received/mnt
sudo umount ~/ouress-received/etc/resolv.conf
```

### Exporting on Linux

```bash
sudo env XZ_OPT="-6 -T0" tar -cJf research-snapshot.ress -C ~/ouress-project . 
```

**Note:** Change `-6` to `-0` for the fastest export but with larger file size or to `-9` or even `-9e` (extreme) for the slowest export with smallest file size.

## Verification

A PGP signed `SHA256SUMS` file is included with the release artifacts for verifying integrity.

**Fingerprint:** `C4A8 E4F9 1650 7DD9 49D4 5DF8 B4ED 8851 B020 2101`
**Key Server:** [keys.openpgp.org](https://keys.openpgp.org)

## Building from Source (if required)

The Ouress base image, i.e. the customised root filesystem, is readily distributed as `ouress-vx.x.x.ress` and the WSL command-line utility (along with the root filesystem) as `Ouress-vx.x.x-x64-Setup.exe`. If required, they can be rebuilt exactly (or with modifications) through the following steps:

### Building the Base Image (Root Filesystem)

#### Build Prerequisites

The build process requires a *Debian* Linux environment with internet access. On Windows, WSL2 with a *Debian* distribution serves as the build machine. On Linux, the build runs natively.

Required tools on the build machine:

- `debootstrap`
- `xz-utils`

#### Prepare the Build Machine

##### On Windows (WSL2)

Open PowerShell as Administrator

```powershell
wsl --install -d Debian
```

Follow the prompts to create the build environment and inside install the prerequisites.

```bash
sudo apt update && sudo apt install -y debootstrap xz-utils
```

##### On Linux

```bash
sudo apt update && sudo apt install -y debootstrap xz-utils
```

#### Execute the Build

1. Clone or download the Ouress repository to the build machine.

2. Navigate to the `rootfs` directory.

3. Execute the orchestrator script as root.

   ```bash
   sudo ./build.sh
   ```

### Building the WSL Command-line Utility

#### Build Prerequisites

* [Lazarus](https://www.lazarus-ide.org) IDE v4.4
* [Free Pascal Compiler](https://www.freepascal.org) v3.2.2 (included with Lazarus IDE v4.4)

#### Build Instructions

1. Clone or download the Ouress repository to the build machine.
2. Navigate to the `cli` directory.
3. Open the `Ouress.lpi` in the Lazarus IDE.
4. Build using **Run** → **Build** or `Shift` + `F9`.

### Build Notes

* The version number must be synchronised in `Ouress.lpi` and `release.vars` to avoid ambiguities. An entry for the corresponding version should be made to the [key decisions log](key-decisions-log.md), if necessary.
* Shell scripts and associated files for building the `rootfs` must be encoded in UTF-8 (strictly without BOM) to ensure that UTF-8 characters are rendered correctly in the shell of the built artifact.
* Pascal source code must be encoded in UTF-8 with BOM for UTF-8 characters to be rendered correctly on the terminal by the Windows command-line utility.
* The `.nsi` script must be encoded in UTF-8 with a BOM to avoid incorrect metadata recording for UTF-8 characters in the installer’s properties.

## Acknowledgements

Ouress is built on [*Debian* GNU/Linux](https://www.debian.org), leveraging the project’s proven stability and extensive package ecosystem. The Ouress project is not affiliated with *Debian*. [*Debian*](https://www.debian.org/trademark)<sup>®</sup> is a registered trademark owned by [Software in the Public Interest, Inc.](https://www.spi-inc.org/projects/debian); [GNU](https://www.gnu.org) is a trademark of the [Free Software Foundation](https://www.fsf.org); and [Linux](https://www.linuxmark.org)<sup>®</sup> is a registered trademark of [Linus Torvalds](https://github.com/torvalds) in the US and other countries.

The command-line management utility for the [Windows Subsystem for Linux (WSL2)](https://github.com/microsoft/WSL) is built using the [Lazarus IDE](https://www.lazarus-ide.org/) and the [Free Pascal Compiler](https://www.freepascal.org).

A huge thanks to the thousands of volunteer developers who make the *Debian* GNU/Linux operating system, the Lazarus IDE, and the Free Pascal Compiler possible, as well as the engineering teams behind the Windows Subsystem for Linux.

The project has benefited significantly from the assistance of Anthropic’s [Claude Sonnet 4.6](https://anthropic.com/claude-sonnet-4-6-system-card) and Google’s [Gemini 3.1 Pro](https://deepmind.google/models/model-cards/gemini-3-1-pro) for ideation, code generation, refactoring, and debugging.

## License

The Ouress build scripts, Windows command-line management utility, and environment configurations are under the BSD 3-Clause License. The full project is provided “as-is”, without any warranties. Please see the [LICENSE](LICENSE) file for details.

The project bundles and distributes several third-party open-source libraries, binaries, and resources. These components are governed entirely by their respective licenses, and the Ouress project claims no copyright over them. System tools and utilities installed via the *Debian* package manager (`apt`) retain their original license texts within the root filesystem at `/usr/share/doc/*/copyright`. Please see the accompanying [NOTICE](NOTICE) file for details.