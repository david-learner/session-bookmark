#!/usr/bin/env bash
# session-bookmark installer (macOS) / 설치 스크립트
#
#   ./install.sh
#   curl -fsSL https://raw.githubusercontent.com/david-learner/session-bookmark/main/install.sh | bash
#
#   --prefix DIR   where to install sb (default: ~/.local/bin)
#   --no-skills    do not install the Claude Code / Codex skills
#   --uninstall    remove sb and the skills (bookmarks and config are kept)
#
# 안내 언어는 SB_LANG(ko|en)으로 정한다. 없으면 로캘이 한국어일 때만 한국어로 보인다.

set -euo pipefail

REPO="${SB_REPO:-david-learner/session-bookmark}"
BRANCH="${SB_BRANCH:-main}"
PREFIX="${HOME}/.local/bin"
WITH_SKILLS=1
UNINSTALL=0

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/session-bookmark"
DATA_FILE="$HOME/.local/share/session-bookmark/bookmarks.jsonl"

case "${SB_LANG:-}" in
  ko|en) ;;
  *) case "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" in ko*) SB_LANG=ko ;; *) SB_LANG=en ;; esac ;;
esac

# 언어별 문구: m '한국어' 'English'
m() { if [ "$SB_LANG" = ko ]; then printf '%s' "$1"; else printf '%s' "$2"; fi; }

info() { printf '  %s\n' "$*"; }
ok()   { printf '✓ %s\n' "$*"; }
warn() { printf '! %s\n' "$*" >&2; }
die()  { printf '✗ %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --prefix)    [ $# -ge 2 ] || die "$(m '--prefix 다음에 폴더를 주세요' '--prefix needs a folder')"; PREFIX="$2"; shift 2 ;;
    --prefix=*)  PREFIX="${1#*=}"; shift ;;
    --no-skills) WITH_SKILLS=0; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help)   sed -n '4,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)           die "$(m '알 수 없는 옵션' 'unknown option'): $1" ;;
  esac
done

# ── 지우기 ─────────────────────────────────────────────

if [ $UNINSTALL -eq 1 ]; then
  rm -f "$PREFIX/sb" && ok "$(m '지움' 'Removed'): $PREFIX/sb"
  for d in "$CLAUDE_DIR/skills/session-bookmark" "$CODEX_DIR/skills/session-bookmark"; do
    [ -d "$d" ] && rm -rf "$d" && ok "$(m '지움' 'Removed'): $d"
  done
  info "$(m '북마크와 설정은 남겼습니다. 필요 없으면 직접 지우세요.' 'Bookmarks and config were kept. Delete them yourself if you no longer need them.')"
  info "  $DATA_FILE"
  info "  $CONFIG_DIR/config"
  exit 0
fi

# ── 사전 점검 ─────────────────────────────────────────────

[ "$(uname -s)" = Darwin ] || warn "$(m 'macOS 용으로 만들었습니다. 다른 OS 에서는 동작을 보장하지 않습니다.' 'Built for macOS. Other systems are not supported.')"
command -v zsh >/dev/null || die "$(m 'zsh 가 필요합니다.' 'zsh is required.')"

missing=""
for c in jq fzf; do command -v "$c" >/dev/null || missing="$missing $c"; done
if [ -n "$missing" ]; then
  warn "$(m '필요한 도구가 없습니다' 'Missing required tools'):$missing"
  if command -v brew >/dev/null; then
    info "$(m '설치' 'Install'): brew install$missing"
  else
    info "$(m "Homebrew(https://brew.sh)를 설치한 뒤 brew install$missing 을 실행하세요." "Install Homebrew (https://brew.sh), then run: brew install$missing")"
  fi
  exit 1
fi

# ── 소스 준비: 저장소 폴더에서 실행했으면 그 파일을, 아니면 GitHub 에서 받는다 ──

SRC=""
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ -n "$script_dir" ] && [ -f "$script_dir/bin/sb" ]; then
  SRC="$script_dir"
else
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  info "$(m '내려받는 중' 'Downloading'): github.com/$REPO ($BRANCH)"
  curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" | tar -xz -C "$tmp" --strip-components 1 \
    || die "$(m '내려받지 못했습니다' 'Download failed'): github.com/$REPO"
  SRC="$tmp"
fi

# 덮어쓸 파일이 새 파일과 다르면 날짜를 붙여 백업한다.
backup_if_changed() {
  local target="$1" new="$2"
  if [ -f "$target" ] && ! cmp -s "$target" "$new"; then
    cp -p "$target" "$target.bak-$(date +%Y%m%d%H%M%S)"
    info "$(m '기존 파일을 백업했습니다' 'Backed up the existing file'): $target.bak-…"
  fi
}

# ── sb ─────────────────────────────────────────────

mkdir -p "$PREFIX"
backup_if_changed "$PREFIX/sb" "$SRC/bin/sb"
install -m 755 "$SRC/bin/sb" "$PREFIX/sb"
ok "$(m '설치' 'Installed'): $PREFIX/sb"

# ── 스킬 ─────────────────────────────────────────────

install_skill() { # 이름 도구폴더 소스
  local name="$1" home="$2" src="$3"
  if [ ! -d "$home" ]; then
    info "$(m "$name 폴더가 없어 스킬을 건너뜁니다" "$name not found, skipping its skill"): $home"
    return
  fi
  mkdir -p "$home/skills/session-bookmark"
  backup_if_changed "$home/skills/session-bookmark/SKILL.md" "$src/SKILL.md"
  cp "$src/SKILL.md" "$home/skills/session-bookmark/SKILL.md"
  ok "$(m '스킬 설치' 'Installed skill'): $home/skills/session-bookmark"
}

if [ $WITH_SKILLS -eq 1 ]; then
  install_skill "Claude Code" "$CLAUDE_DIR" "$SRC/skills/claude/session-bookmark"
  install_skill "Codex" "$CODEX_DIR" "$SRC/skills/codex/session-bookmark"
fi

# ── 설정 파일: 없을 때만 예시를 만든다 ─────────────────────

if [ ! -f "$CONFIG_DIR/config" ]; then
  mkdir -p "$CONFIG_DIR"
  if [ "$SB_LANG" = ko ]; then
    cat > "$CONFIG_DIR/config" <<'EOF'
# sb(session bookmark) 설정
# 세션에 들어갈 때 쓸 명령입니다. 비워 두면 claude / codex 를 그대로 씁니다.
# 셸 별칭은 풀리지 않습니다. 별칭 이름 대신 별칭의 내용을 적으세요.
#
# SB_CLAUDE_CMD="claude --permission-mode acceptEdits"
# SB_CODEX_CMD="codex --search"
#
# 화면 언어(ko|en). 비워 두면 로캘이 한국어일 때만 한국어로 보입니다.
SB_LANG=ko
EOF
  else
    cat > "$CONFIG_DIR/config" <<'EOF'
# sb (session bookmark) config
# Commands used to resume a session. Leave empty to use claude / codex as is.
# Shell aliases are not expanded. Write what the alias expands to, not its name.
#
# SB_CLAUDE_CMD="claude --permission-mode acceptEdits"
# SB_CODEX_CMD="codex --search"
#
# Screen language (ko|en). If empty, Korean is used only for a Korean locale.
SB_LANG=en
EOF
  fi
  ok "$(m '설정 파일 예시' 'Example config'): $CONFIG_DIR/config"
else
  info "$(m '설정 파일은 그대로 두었습니다' 'Kept the existing config'): $CONFIG_DIR/config"
fi

# ── PATH 확인 ─────────────────────────────────────────────

case ":$PATH:" in
  *":$PREFIX:"*) ;;
  *)
    warn "$(m '설치 폴더가 PATH 에 없습니다' 'The install folder is not on your PATH'): $PREFIX"
    info "$(m '~/.zshrc 에 아래 줄을 더하고 새 터미널을 여세요.' 'Add this line to ~/.zshrc and open a new terminal:')"
    info "export PATH=\"$PREFIX:\$PATH\""
    ;;
esac

echo
ok "$(m '끝났습니다. 터미널에서 sb 를 실행해 보세요.' 'Done. Run sb in your terminal.')"
