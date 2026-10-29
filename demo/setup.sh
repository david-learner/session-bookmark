# README 시연 GIF 용 가짜 환경. 대본(demo.*.tape)이 깨끗한 zsh 에서 `source demo/setup.sh <ko|en>` 으로 부른다.
# 실제 북마크·세션은 쓰지 않는다.
export SB_LANG=${1:-ko}
export HOME=/tmp/sb-demo
rm -rf /tmp/sb-demo && mkdir -p $HOME/bin $HOME/.local/share/session-bookmark
mkdir -p $HOME/projects/shop-app $HOME/projects/blog $HOME/notes

# 시연용 claude·codex: 세션을 여는 대신 안내 한 줄만 출력한다.
if [[ $SB_LANG == ko ]]; then note='(시연) 여기서 %s 가 이 세션을 이어서 엽니다: %s'; else note='(demo) %s would resume this session here: %s'; fi
for tool in claude codex; do
  cat > $HOME/bin/$tool <<STUB
#!/bin/sh
printf '\n  \033[2m$note\033[0m\n\n' "$tool" "\$*"
STUB
  chmod +x $HOME/bin/$tool
done

f=$HOME/.local/share/session-bookmark/bookmarks.jsonl
if [[ $SB_LANG == ko ]]; then
  cat > $f <<JSON
{"provider":"claude","name":"PROJ-123 결제 흐름 개선 아이디어","session_id":"5f0c2a9e-7d41-4b8e-9c3a-2e6f1b8d4a70","cwd":"$HOME/projects/shop-app","created_at":"2026-10-21 09:12","memo":"환불을 부분 환불까지 넓히는 안.\n정한 것: 주문 단위가 아니라 상품 단위로 환불.\n다음: 쿠폰이 걸린 주문의 환불 금액 계산부터."}
{"provider":"codex","name":"블로그 검색 기능 설계","session_id":"01a2b3c4-d5e6-7f80-9a1b-2c3d4e5f6a7b","cwd":"$HOME/projects/blog","created_at":"2026-10-24 22:40","memo":"태그 검색 먼저, 전문 검색은 나중에."}
{"provider":"claude","name":"주간 회고 정리","session_id":"9b8a7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d","cwd":"$HOME/notes","created_at":"2026-10-27 18:05","memo":""}
{"provider":"claude","name":"PROJ-131 주문 목록 느린 원인","session_id":"3c4d5e6f-7a8b-4c9d-0e1f-2a3b4c5d6e7f","cwd":"$HOME/projects/shop-app","created_at":"2026-10-28 15:30","memo":"인덱스 없는 정렬이 의심됨. 실행 계획 보기부터."}
JSON
else
  cat > $f <<JSON
{"provider":"claude","name":"PROJ-123 Payment flow ideas","session_id":"5f0c2a9e-7d41-4b8e-9c3a-2e6f1b8d4a70","cwd":"$HOME/projects/shop-app","created_at":"2026-10-21 09:12","memo":"Extend refunds to partial refunds.\nDecided: refund per item, not per order.\nNext: refund amount for orders with coupons."}
{"provider":"codex","name":"Blog search design","session_id":"01a2b3c4-d5e6-7f80-9a1b-2c3d4e5f6a7b","cwd":"$HOME/projects/blog","created_at":"2026-10-24 22:40","memo":"Tag search first, full-text search later."}
{"provider":"claude","name":"Weekly retro notes","session_id":"9b8a7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d","cwd":"$HOME/notes","created_at":"2026-10-27 18:05","memo":""}
{"provider":"claude","name":"PROJ-131 Slow order list","session_id":"3c4d5e6f-7a8b-4c9d-0e1f-2a3b4c5d6e7f","cwd":"$HOME/projects/shop-app","created_at":"2026-10-28 15:30","memo":"Suspect a sort without an index. Check the query plan first."}
JSON
fi

export PATH=$HOME/bin:$PWD/bin:/usr/bin:/bin:/opt/homebrew/bin
export SB_CONFIG=/nonexistent
export PS1=$'%F{green}%~%f $ '
cd $HOME
