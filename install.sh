#!/usr/bin/env bash
# session-bookmark 설치 스크립트 (macOS)
#
#   ./install.sh                  저장소를 받은 폴더에서 설치
#   curl -fsSL https://raw.githubusercontent.com/david-learner/session-bookmark/main/install.sh | bash
#
# 옵션
#   --prefix DIR   sb 를 설치할 폴더 (기본: ~/.local/bin)
#   --no-skills    Claude Code·Codex 스킬은 설치하지 않음
#   --uninstall    sb 와 스킬을 지움 (북마크·설정은 남김)

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

info() { printf '  %s\n' "$*"; }
ok()   { printf '✓ %s\n' "$*"; }
warn() { printf '! %s\n' "$*" >&2; }
die()  { printf '✗ %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --prefix)    [ $# -ge 2 ] || die "--prefix 다음에 폴더를 주세요"; PREFIX="$2"; shift 2 ;;
    --prefix=*)  PREFIX="${1#*=}"; shift ;;
    --no-skills) WITH_SKILLS=0; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help)   sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)           die "알 수 없는 옵션: $1" ;;
  esac
done

# ── 지우기 ─────────────────────────────────────────────

if [ $UNINSTALL -eq 1 ]; then
  rm -f "$PREFIX/sb" && ok "지움: $PREFIX/sb"
  for d in "$CLAUDE_DIR/skills/session-bookmark" "$CODEX_DIR/skills/session-bookmark"; do
    [ -d "$d" ] && rm -rf "$d" && ok "지움: $d"
  done
  info "북마크와 설정은 남겼습니다. 필요 없으면 직접 지우세요."
  info "  $DATA_FILE"
  info "  $CONFIG_DIR/config"
  exit 0
fi

# ── 사전 점검 ─────────────────────────────────────────────

[ "$(uname -s)" = Darwin ] || warn "macOS 용으로 만들었습니다. 다른 OS 에서는 동작을 보장하지 않습니다."
command -v zsh >/dev/null || die "zsh 가 필요합니다."

missing=""
for c in jq fzf; do command -v "$c" >/dev/null || missing="$missing $c"; done
if [ -n "$missing" ]; then
  warn "필요한 도구가 없습니다:$missing"
  command -v brew >/dev/null && info "설치: brew install$missing" || info "Homebrew(https://brew.sh)를 설치한 뒤 brew install$missing 을 실행하세요."
  exit 1
fi

# ── 소스 준비: 저장소 폴더에서 실행했으면 그 파일을, 아니면 GitHub 에서 받는다 ──

SRC=""
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ -n "$script_dir" ] && [ -f "$script_dir/bin/sb" ]; then
  SRC="$script_dir"
else
  case "$REPO" in OWNER/*) die "SB_REPO 가 정해지지 않았습니다. 저장소를 받은 폴더에서 ./install.sh 를 실행하세요." ;; esac
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  info "내려받는 중: github.com/$REPO ($BRANCH)"
  curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" | tar -xz -C "$tmp" --strip-components 1 \
    || die "내려받지 못했습니다: github.com/$REPO"
  SRC="$tmp"
fi

# 덮어쓸 파일이 새 파일과 다르면 날짜를 붙여 백업한다.
backup_if_changed() {
  local target="$1" new="$2"
  if [ -f "$target" ] && ! cmp -s "$target" "$new"; then
    cp -p "$target" "$target.bak-$(date +%Y%m%d%H%M%S)"
    info "기존 파일을 백업했습니다: $target.bak-…"
  fi
}

# ── sb ─────────────────────────────────────────────

mkdir -p "$PREFIX"
backup_if_changed "$PREFIX/sb" "$SRC/bin/sb"
install -m 755 "$SRC/bin/sb" "$PREFIX/sb"
ok "설치: $PREFIX/sb"

# ── 스킬 ─────────────────────────────────────────────

install_skill() { # 이름 도구폴더 소스
  local name="$1" home="$2" src="$3"
  if [ ! -d "$home" ]; then
    info "$name 폴더가 없어 스킬을 건너뜁니다: $home"
    return
  fi
  mkdir -p "$home/skills/session-bookmark"
  backup_if_changed "$home/skills/session-bookmark/SKILL.md" "$src/SKILL.md"
  cp "$src/SKILL.md" "$home/skills/session-bookmark/SKILL.md"
  ok "스킬 설치: $home/skills/session-bookmark"
}

if [ $WITH_SKILLS -eq 1 ]; then
  install_skill "Claude Code" "$CLAUDE_DIR" "$SRC/skills/claude/session-bookmark"
  install_skill "Codex" "$CODEX_DIR" "$SRC/skills/codex/session-bookmark"
fi

# ── 설정 파일: 없을 때만 예시를 만든다 ─────────────────────

if [ ! -f "$CONFIG_DIR/config" ]; then
  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG_DIR/config" <<'EOF'
# sb(session bookmark) 설정
# 세션에 들어갈 때 쓸 명령입니다. 비워 두면 claude / codex 를 그대로 씁니다.
# 셸 별칭은 풀리지 않습니다. 별칭 이름 대신 별칭의 내용을 적으세요.
#
# SB_CLAUDE_CMD="claude --dangerously-skip-permissions"
# SB_CODEX_CMD="codex -s workspace-write -a on-request"
EOF
  ok "설정 파일 예시: $CONFIG_DIR/config"
else
  info "설정 파일은 그대로 두었습니다: $CONFIG_DIR/config"
fi

# ── PATH 확인 ─────────────────────────────────────────────

case ":$PATH:" in
  *":$PREFIX:"*) ;;
  *)
    warn "설치 폴더가 PATH 에 없습니다: $PREFIX"
    info "~/.zshrc 에 아래 줄을 더하고 새 터미널을 여세요."
    info "export PATH=\"$PREFIX:\$PATH\""
    ;;
esac

echo
ok "끝났습니다. 터미널에서 sb 를 실행해 보세요."
