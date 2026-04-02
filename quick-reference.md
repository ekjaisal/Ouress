# Quick Reference

This document outlines standard operational procedures and conventions for the primary utilities bundled within the Ouress environment. The provided examples demonstrate a few foundational workflows, structured data processing pipelines, and system management.

## System Management and Identity

### System Version Verification
Output the current execution context, build date, and release details of the environment:
```bash
ouress
```

### Host Filesystem Integration (WSL)
List all active Windows drive mounts currently accessible from within the Linux subsystem:
```bash
drives
```

### Time Zone Configuration
Symlink the desired geographical time zone to the system configuration. Available zones can be listed via `ls /usr/share/zoneinfo/`.
```bash
sudo ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
echo "Asia/Kolkata" | sudo tee /etc/timezone
```

### System Package Expansion
The `apt` package database is bundled within the root filesystem for installation of supplementary runtimes, compilers, or dependencies without breaking the core architecture.

Install the R statistical computing environment:
```bash
sudo apt update && sudo apt install r-base
```

Install the standard Java runtime:
```bash
sudo apt update && sudo apt install default-jre
```

## Network Fetching and Archival Operations

### Remote Dataset Acquisition
Utilise `curl` or `wget` to retrieve remote datasets, replication archives, or API payloads directly into the environment.

Download a file silently and follow redirects:
```bash
curl -fL -o dataset.csv https://example.com/data.csv
```

Recursively download an open directory of files:
```bash
wget -r -np -nH --cut-dirs=1 https://example.com/open-data/
```

### Archive Extraction and Compression
Manage compressed materials using the bundled extraction utilities.

Extract standard tarballs (`.tar.gz` / `.tgz`) and xz-compressed archives (`.tar.xz`):
```bash
tar -xzf archive.tar.gz
tar -xJf archive.tar.xz
```

Extract legacy ZIP archives:
```bash
unzip replication_materials.zip -d ./extracted_data/
```

Compress a corpus directory using multi-threaded Zstandard (`zstd`) for maximum speed:
```bash
tar -I 'zstd -T0' -cf corpus.tar.zst ./corpus_directory/
```

## Shell Ergonomics and Task Management

### Fuzzy Search and Directory Navigation
Improve terminal workflow by enabling interactive fuzzy-searching of command history or deep directory trees using `fzf`.

Pipe a file list to `fzf` to interactively locate and select a file:
```bash
find . -type f | fzf
```

Search through the contents of a file interactively:
```bash
cat data.csv | fzf
```

### Background Task Queueing
Manage and execute long-running extraction or processing scripts in the background using `task-spooler` (`tsp`), functioning as a lightweight, dependency-free background queue.

Queue tasks for sequential background execution:
```bash
tsp pdftotext massive_document.pdf output.txt
tsp mlr --csv stats1 -f score input.csv
```

Monitor the execution queue:
```bash
tsp -l
```

Follow the standard output of a currently running job:
```bash
tsp -t
```

### Multi-Core Batch Processing
Execute commands concurrently across multiple CPU cores using `rush`.

Process all CSV files in a directory concurrently, generating independent output files:
```bash
ls *.csv | rush 'mlr --csv stats1 -a mean -f score {} > {.}_stats.csv'
```

Download a list of URLs concurrently using exactly 4 worker threads:
```bash
cat urls.txt | rush -j 4 'wget -q {}'
```

## Extraction and Digitisation

### Layout-Aware Text Extraction from Portable Document Formats (PDF)
Extract raw text streams or preserve spatial document layout using `poppler-utils`.

Extract raw text streams:
```bash
pdftotext document.pdf output.txt
```

Preserve spatial layout (useful for extracting text from tables):
```bash
pdftotext -layout document.pdf output.txt
```

### Legacy Document Parsing
Extract plain text strings from proprietary binary formats without requiring heavy graphical word processors.

Parse legacy Microsoft Word (`.doc`) files:
```bash
antiword document.doc > output.txt
catdoc document.doc > output.txt
```

Parse OpenDocument (`.odt`) files:
```bash
odt2txt document.odt > output.txt
```

### HTML, XML, and XPath Extraction
Execute complex structural queries and extract specific nodes or attributes directly from remote or local markup files using `xidel`.

Extract specific HTML nodes via XPath:
```bash
xidel https://example.com --extract "//title"
```

Extract attribute targets via CSS selectors:
```bash
xidel page.html --extract "css('a.article-link')/@href"
```

Parse local XML datasets based on node values:
```bash
xidel dataset.xml --extract "//record[year>2010]/title"
```

### Web Page Conversion and Markdown Generation
Dump rendered text from web pages or convert HTML directly into semantic Markdown for analysis or archival.

Dump spatially-rendered text to standard output:
```bash
w3m -dump https://example.com > clean_text.txt
```

Convert raw HTML payload into semantic Markdown:
```bash
curl -s https://example.com | html2text -nobs > document.md
```

## Corpus Architecture and Interrogation

### Multilingual Corpus Search
Utilise the Unicode-aware `ugrep` engine to execute regular expressions across diverse human scripts without requiring manual encoding overrides.

Search across standard Latin scripts:
```bash
ugrep -r "discourse" /path/to/english-corpus/
```

Search natively across complex scripts (e.g. Malayalam, Devanagari):
```bash
ugrep -r "മലയാളം" /path/to/malayalam-corpus/
```

### Pipeline Profiling and Throughput Monitoring
Insert a progress bar, time estimate, and data throughput rate into standard Unix streams for long-running pipelines using `pv`.
```bash
cat massive_corpus.txt | pv | ugrep "keyword" > output.txt
```

### In-Place Pipeline Editing
Absorb standard input fully before writing to the output file, eliminating the need for temporary intermediary files during stream editing via `sponge`.
```bash
sed 's/old_term/new_term/g' corpus.txt | sponge corpus.txt
```

### Pipeline Output Timestamping
Append system timestamps to standard input lines via `ts`, providing temporal tracking for extended corpus generation pipelines.
```bash
pdftotext massive.pdf - | grep "keyword" | ts
```

### Line Ending Standardisation
Convert Windows-style carriage returns (`\r\n`) to Unix line feeds (`\n`) using `dos2unix` to prevent pipeline breakages when processing collaborative datasets.

Standardise a single file:
```bash
dos2unix dataset.csv
```

Apply standardisation recursively across an entire directory:
```bash
find . -name "*.txt" -exec dos2unix {} +
```

## Structured Data Processing

### Interactive Tabular Exploration
Launch an interactive terminal spreadsheet interface via `visidata` (`vd`) for visually exploring, filtering, and pivoting massive tabular or JSON datasets natively in the shell.
```bash
vd dataset.csv
vd records.json
```

### CSV Transformation and Aggregation
Leverage `miller` (`mlr`) for complex tabular data operations without invoking Python, Pandas, or external scripts.

Compute summary statistics on specific columns:
```bash
mlr --csv stats1 -a mean,stddev,min,max -f score input.csv
```

Filter records based on conditional logic:
```bash
mlr --csv filter '$year > 2010 && $status == "active"' input.csv
```

Convert a CSV file entirely into an array of JSON objects:
```bash
mlr --csv --ojson cat input.csv > output.json
```

### High-Performance CSV Slicing
Execute rapid filtering and indexing on extremely large tabular datasets using `xsv`.

Generate immediate statistical profiles of all columns:
```bash
xsv stats input.csv | vd
```

Select specific columns and search for exact string matches:
```bash
xsv select author,year,title input.csv | xsv search -s author "Smith"
```

### JSON Querying and Visual Filtering
Parse, filter, and shape hierarchical JSON structures (such as API payloads) via the `jq` toolchain.

Query data arrays and extract specific key values natively:
```bash
curl -s "https://api.crossref.org/works?query=politics" | jq '.message.items[] | .title[0]'
```

Flatten deeply nested JSON into greppable paths via `gron`:
```bash
gron data.json | grep "author.name"
```

Launch the interactive `jq` construction playground to build complex queries visually:
```bash
jqp -f data.json
```

### Relational Database Interrogation
Execute SQL queries directly against standalone `.db` or `.sqlite` datasets without requiring server orchestration.
```bash
sqlite3 dataset.db ".tables"
sqlite3 dataset.db "SELECT title, year FROM articles WHERE year = 2024 LIMIT 10;"
```

### Raw Data Inspection
Provide syntax-highlighted pagination for structural review of datasets or raw code.

View syntax-highlighted data files:
```bash
batcat raw_data.json
```

Disable line numbers and Git integration for pure data review:
```bash
batcat --plain table.csv
```

## Network and Version Control

### Repository Management
Clone replication archives and maintain strict version control over analysis scripts via `git`.
```bash
git clone https://github.com/example/replication-data.git
cd replication-data
git status
```

## Python Workflows & Package Management

Ouress bundles a minimal Python 3 core adhering strictly to PEP-668. To ensure host system stability, global `pip install` commands are intentionally blocked by the operating system.

### Standard Package Installation (Virtual Environments)
Dependencies must be isolated within distinct virtual environments to prevent systemic conflicts.

Instantiate a lightweight, isolated environment:
```bash
python3 -m venv research-env
```

Activate the environment within the Fish shell:
```bash
source research-env/bin/activate.fish
```

Install required scientific packages:
```bash
pip install tqdm pandas beautifulsoup4 spacy
```

Terminate the virtual environment session:
```bash
deactivate
```

### Advanced Packages and C-Extensions
Ouress is intentionally stripped of heavyweight C-compilers to minimise bloat. Most modern Python packages provide pre-compiled binaries (wheels) that install instantly out of the box. However, if a package lacks a pre-compiled wheel and strictly requires building from source, it will fail with compiler errors (e.g. missing `gcc` or `Python.h`).

To resolve this and allow the package to build natively, install the requisite compilers and Python development headers before retrying the `pip install` command:
```bash
sudo apt update && sudo apt install build-essential python3-dev
```

### Compiling Custom Python Runtimes (pyenv)
When a specific legacy version of Python is required for a replication archive rather than the bundled system interpreter, the best approach is to rely on `pyenv`. This utility compiles target Python versions entirely from source without interfering with the base operating system.

Install necessary C compilers and build dependencies:
```bash
sudo apt update && sudo apt install git build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
```

Download and execute the pyenv bootstrap script:
```bash
curl https://pyenv.run | bash
```

Configure the Fish shell to initialise pyenv automatically:
```bash
set -Ux PYENV_ROOT $HOME/.pyenv
fish_add_path $PYENV_ROOT/bin
echo 'pyenv init - | source' >> /etc/fish/conf.d/ouress.fish
source /etc/fish/conf.d/ouress.fish
```

Compile and install the specific target version:
```bash
pyenv install 3.11.15
```

Establish the compiled version as the global default for the active user:
```bash
pyenv global 3.11.15
```

Verify the correct execution path:
```bash
python --version
```