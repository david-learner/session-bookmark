---
name: session-bookmark
description: Add the current Claude Code session to the session bookmarks (sb). The agent names the bookmark after the conversation. Use for requests like "bookmark this session", "save this session for later", "I'll continue this later", "/session-bookmark", or in Korean "이 세션 북마크해줘", "북마크 추가", "세션 저장해 둬", "나중에 이어서 할게". Listing, resuming and deleting bookmarks are done by the user with `sb` in a terminal.
---

# Bookmark the current session

Add the current session to the bookmarks with the `sb` command. Later, the user picks it from the `sb` list and comes back to this session.

## Steps

1. Get the session ID from `$CLAUDE_CODE_SESSION_ID`. If it is empty, stop and tell the user. Do not use any other session ID instead.
2. Name the bookmark. Describe the conversation topic in about 30 characters, in the language of the conversation. If there is a ticket key, put it first. Example: `PROJ-123 payment flow discussion`
3. Decide the memo. **The skill argument is the memo.**
   - If there is an argument, use it as the memo **exactly as written**. Do not summarize or add to it.
   - If there is no argument, do not write a memo. Leave out `-m` entirely in the command below.
4. Run the command below. Do not leave out `</dev/null`. Without it, `sb` asks for the name and memo again and waits.
   - With an argument:
     ```bash
     sb add -p claude -n "<name>" -m "$(cat <<'MEMO'
     <the argument, unchanged>
     MEMO
     )" "$CLAUDE_CODE_SESSION_ID" </dev/null
     ```
   - Without an argument:
     ```bash
     sb add -p claude -n "<name>" "$CLAUDE_CODE_SESSION_ID" </dev/null
     ```
   - Do not pass a folder (`-d`). `sb` reads the folder the session was started in from the session record.
5. Show the user the `Added:` or `Updated:` line (`추가:` or `갱신:` in Korean), with the saved name and memo. If the session was already bookmarked, `sb` prints `Updated:` and replaces the name. The memo changes only when a new one is given. An empty memo keeps the old one.

## If it fails

- `no folder found in the session record` (`세션 기록에서 작업 경로를 찾지 못해`): `sb` could not find the session record, so it saved the current folder. The bookmark is still added. Tell the user that the saved folder may not be where the session started.
- If `sb` is not found, stop and tell the user. session-bookmark is not installed, or its install folder is not on PATH.
