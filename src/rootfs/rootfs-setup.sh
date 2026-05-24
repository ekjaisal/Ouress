#!/bin/bash

# BSD 3-Clause License
# ____________________
# 
# Copyright © 2026, Jaisal E. K.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

cat > /usr/sbin/policy-rc.d << 'EOF'
#!/bin/sh
exit 101
EOF
chmod +x /usr/sbin/policy-rc.d

echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99snapshot
echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/99translations

echo "==> Refreshing package index..."
apt-get update

echo "==> Installing system dependencies..."
apt-get install -y --no-install-recommends \
    bash coreutils findutils grep sed gawk diffutils less util-linux nano \
    ca-certificates curl wget rsync openssh-client fish ugrep moreutils \
    jq sqlite3 poppler-utils antiword catdoc odt2txt xz-utils git sudo \
    gzip bzip2 zip unzip 7zip tar zstd unrar-free tmux htop tree \
    file bc man-db w3m html2text bat locales binutils python3-venv python3-pip \
    visidata fzf pv dos2unix task-spooler

echo "==> Generating system locales..."
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
update-locale LANG=C.UTF-8 LC_ALL=C.UTF-8

echo "==> Retrieving external binaries..."

if [ -f /tmp/packages.list ]; then
    while IFS=$' \t' read -r bin_name file_type url expected_hash || [ -n "$bin_name" ]; do
        [[ -z "$bin_name" || "$bin_name" == \#* ]] && continue
        
        echo "  :: Validating $bin_name..."
        dest="/tmp/${bin_name}.${file_type}"
        [ "$file_type" = "raw" ] && dest="/usr/local/bin/${bin_name}"
        
        curl -fsSL "$url" -o "$dest" || true
        
        if [ ! -f "$dest" ]; then
            echo "Error: Download failed or returned 404 for $url" >&2
            exit 1
        fi
        
        actual_hash=$(sha256sum "$dest" | awk '{print $1}')
        
        if [ "$actual_hash" != "$expected_hash" ]; then
            echo "Error: SHA256 mismatch for $bin_name." >&2
            echo "Expected: $expected_hash" >&2
            echo "Actual:   $actual_hash" >&2
            exit 1
        fi
        echo "     [OK] Checksum verified."
        
        if [[ "$file_type" == "tar.gz" || "$file_type" == "tgz" ]]; then
            tar -xzf "$dest" -C /tmp
            find /tmp -maxdepth 2 -type f -name "$bin_name" -exec cp -f {} "/usr/local/bin/$bin_name" \;
            chmod +x "/usr/local/bin/$bin_name"
        elif [[ "$file_type" == "tar.xz" ]]; then
            tar -xJf "$dest" -C /tmp
            find /tmp -maxdepth 2 -type f -name "$bin_name" -exec cp -f {} "/usr/local/bin/$bin_name" \;
            chmod +x "/usr/local/bin/$bin_name"
        elif [[ "$file_type" == "zip" ]]; then
            unzip -q "$dest" -d /tmp
            find /tmp -maxdepth 2 -type f -name "$bin_name" -exec cp -f {} "/usr/local/bin/$bin_name" \;
            chmod +x "/usr/local/bin/$bin_name"
        elif [[ "$file_type" == "raw" ]]; then
            chmod +x "/usr/local/bin/$bin_name"
        fi
    done < /tmp/packages.list
else
    echo "  :: Warning: packages.list not found. Skipping external binary retrieval."
fi

echo "  :: Installing xq wrapper..."
cat > /usr/local/bin/xq << 'XQEOF'
#!/bin/sh
yq -p xml "$@"
XQEOF
chmod +x /usr/local/bin/xq

echo "==> Configuring SSL certificates..."
cat > /usr/local/bin/ouress-fix-ssl << 'EOF'
#!/bin/sh
SSL_LIB=$(ls /usr/lib/x86_64-linux-gnu/libssl.so.* 2>/dev/null | head -n 1)
CRYPTO_LIB=$(ls /usr/lib/x86_64-linux-gnu/libcrypto.so.* 2>/dev/null | head -n 1)
[ -n "$SSL_LIB" ] && ln -sf "$SSL_LIB" /usr/lib/x86_64-linux-gnu/libssl.so
[ -n "$CRYPTO_LIB" ] && ln -sf "$CRYPTO_LIB" /usr/lib/x86_64-linux-gnu/libcrypto.so
EOF

chmod +x /usr/local/bin/ouress-fix-ssl
/usr/local/bin/ouress-fix-ssl

cat > /etc/apt/apt.conf.d/99ouress-ssl-symlinks << 'EOF'
DPkg::Post-Invoke { "if [ -x /usr/local/bin/ouress-fix-ssl ]; then /usr/local/bin/ouress-fix-ssl; fi"; };
EOF

echo "==> Patching VisiData namespace collision..."
cat > /usr/bin/vd << 'EOF'
#!/usr/bin/python3
import sys
from visidata.main import vd_cli
sys.exit(vd_cli())
EOF
chmod +x /usr/bin/vd

echo "==> Optimising filesystem..."
find /usr/local/bin -type f -executable -exec sh -c 'file "$1" | grep -q "ELF" && strip --strip-unneeded "$1"' _ {} \;
apt-get purge -y binutils
apt-get autoremove --purge -y
dpkg -l | grep '^rc' | awk '{print $2}' | xargs -r dpkg --purge || true

rm -f /usr/bin/scalar /usr/lib/git-core/scalar
rm -f /usr/bin/git-shell /usr/lib/git-core/git-shell
rm -f /usr/lib/git-core/git-daemon /usr/lib/git-core/git-imap-send
rm -f /usr/lib/git-core/git-http-backend /usr/lib/git-core/git-http-push

rm -rf /usr/share/info/*
rm -f /usr/bin/parallel /usr/share/man/man1/parallel.1*
rm -rf /usr/share/man/?? /usr/share/man/??_*
find /usr/share/doc -type f ! -name "copyright" -delete 2>/dev/null || true
find /usr/share/doc -type d -empty -delete 2>/dev/null || true
find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en' ! -name 'en_US' -exec rm -rf {} + 2>/dev/null || true

rm -rf /usr/share/i18n/locales/*
rm -rf /usr/share/i18n/charmaps/*

find /usr/lib/python3* -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
find /usr/lib/python3* -name "*.pyc" -delete 2>/dev/null || true
find /usr/lib/python3* -type d -name "test" -exec rm -rf {} + 2>/dev/null || true
find /usr/lib/python3* -type d -name "idlelib" -exec rm -rf {} + 2>/dev/null || true
find /usr/lib/python3* -type d -name "pydoc_data" -exec rm -rf {} + 2>/dev/null || true

find /usr/lib /usr/local/lib -name "*.a" -delete 2>/dev/null || true
find /usr/share/perl5 -name "*.pod" -delete 2>/dev/null || true
rm -rf /usr/share/fonts /usr/share/X11 /usr/share/color /usr/share/ghostscript
rm -rf /usr/lib/x86_64-linux-gnu/perl/5.40.1/auto/Encode/{JP,KR,CN,TW}
find /usr/lib/x86_64-linux-gnu/perl -name "*.h" -delete 2>/dev/null || true
rm -rf /usr/share/lintian /usr/share/gdb /usr/share/gcc /usr/share/bug

rm -rf /usr/lib/udev/hwdb.d/*
rm -f /etc/udev/hwdb.bin
rm -rf /var/lib/systemd/hwdb/*

mkdir -p /tmp/terminfo_keep/{a,c,l,s,t,v,x}
cp /usr/share/terminfo/a/ansi /tmp/terminfo_keep/a/ 2>/dev/null || true
cp /usr/share/terminfo/c/cygwin /tmp/terminfo_keep/c/ 2>/dev/null || true
cp /usr/share/terminfo/l/linux /tmp/terminfo_keep/l/ 2>/dev/null || true
cp /usr/share/terminfo/s/screen* /tmp/terminfo_keep/s/ 2>/dev/null || true
cp /usr/share/terminfo/t/tmux* /tmp/terminfo_keep/t/ 2>/dev/null || true
cp /usr/share/terminfo/v/vt100 /tmp/terminfo_keep/v/ 2>/dev/null || true
cp /usr/share/terminfo/x/xterm* /tmp/terminfo_keep/x/ 2>/dev/null || true
rm -rf /usr/share/terminfo/*
cp -r /tmp/terminfo_keep/* /usr/share/terminfo/ 2>/dev/null || true
rm -rf /tmp/terminfo_keep

find /usr/lib/x86_64-linux-gnu/gconv/ -name "*.so" \
    ! -name "UTF*" ! -name "ISO8859*" ! -name "CP*" ! -name "KOI*" \
    ! -name "EUC*" ! -name "BIG5*" ! -name "GB*" ! -name "SHIFT*" \
    -delete 2>/dev/null || true

echo "==> Applying system defaults..."
passwd -d root
useradd -m -s /usr/bin/fish ouress
echo "ouress ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ouress
chmod 0440 /etc/sudoers.d/ouress
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
echo "UTC" > /etc/timezone

cat > /etc/wsl.conf << 'EOF'
[automount]
enabled = true
root = /mnt/
options = "metadata,umask=22,fmask=11"

[user]
default = ouress
EOF

echo "==> Configuring fish interactive shell..."
cat > /etc/fish/conf.d/ouress.fish << 'EOF'

set -gx LANG C.UTF-8
set -gx LC_ALL C.UTF-8

function ouress
    if test -f /etc/ouress/release
        set -l host "Native/Chroot"
        if test -f /proc/version
            if grep -qi microsoft /proc/version 2>/dev/null
                set host "WSL2"
            end
        end

        while read -l line
            echo $line
            if string match -q "TARGET_ARCHITECTURE=*" $line
                echo "EXECUTION_CONTEXT=\"$host\""
            end
        end < /etc/ouress/release
    else
        echo "ouress: release file not found at /etc/ouress/release"
    end
end

function fish_greeting
    if test -f /etc/ouress/release
        set -l ver (grep ^VERSION= /etc/ouress/release | cut -d'"' -f2)
        set -l name (grep ^NAME= /etc/ouress/release | cut -d'"' -f2)
        echo "$name $ver"
    end
end

function fish_prompt
    set -l last_status $status
    set -l yellow (set_color yellow)
    set -l red    (set_color red)
    set -l reset  (set_color normal)

    set -l cwd (pwd)
    set -l display_path

    if string match -q '/mnt/*' $cwd; or string match -q '/Volumes/*' $cwd
        set display_path "[$cwd]"
    else
        set display_path $cwd
    end

    set -l prompt_char
    if test $last_status -ne 0
        set prompt_char $red" ~>"$reset
    else
        set prompt_char " ~>"
    end

    echo -n $yellow$display_path$reset$prompt_char" "
end

function fish_title
    if set -q WSL_DISTRO_NAME
        echo $WSL_DISTRO_NAME
    else
        echo "Ouress"
    end
end

alias ..='cd ..'
alias ...='cd ../..'

alias ls='ls --color=auto'
alias ll='ls -lh --color=auto'
alias la='ls -lah --color=auto'

function drives
    ls /mnt/ 2>/dev/null | grep -E '^[a-z]$'
end

alias grep='grep --color=auto'

function __ouress_startup_cd
    set -l cwd (pwd)

    if test $cwd != "/" -a $cwd != "/root" -a $cwd != "/home/ouress"
        return
    end

    set -l host "linux"
    if test -f /proc/version
        if grep -qi microsoft /proc/version 2>/dev/null
            set host "wsl"
        end
    end

    if test $host = "wsl"
        if not test -d /mnt/c
            echo "ouress: Windows drives not mounted. Type 'cd /mnt/c' when ready."
            return
        end

        if set -q USERPROFILE
            set -l wsl_user_dir (wslpath -u "$USERPROFILE" 2>/dev/null)
            if test -n "$wsl_user_dir" -a -d "$wsl_user_dir"
                cd "$wsl_user_dir"
                return
            end
        end

        cd /mnt/c/Users 2>/dev/null; or cd /mnt/c
    end
end

if status is-interactive
    __ouress_startup_cd
end

EOF

chsh -s /usr/bin/fish root

echo "==> Finalising image..."
apt-get clean
rm -f /etc/apt/apt.conf.d/99snapshot
rm -rf /var/lib/apt/lists/* /var/cache/man/*
rm -rf /var/log/* /tmp/*
rm -f /usr/sbin/policy-rc.d
rm -f /root/.bash_history /root/.local/share/fish/fish_history /root/.wget-hsts /root/.lesshst 2>/dev/null || true
rm -f /home/ouress/.bash_history /home/ouress/.local/share/fish/fish_history /home/ouress/.wget-hsts /home/ouress/.lesshst 2>/dev/null || true

echo "==> rootfs configuration complete."