# README 시연 GIF (en). 저장소 루트에서 실행한다: vhs demo/demo.en.tape
Output docs/demo.en.gif

Set Shell zsh
Set FontFamily "D2Coding"
Set FontSize 18
Set Width 1200
Set Height 640
Set Padding 24
Set Theme "Catppuccin Mocha"
Set TypingSpeed 90ms

# 사용자 셸 설정 없이 시연용 환경을 띄운다.
Hide
Type "exec env -i TERM=xterm-256color LANG=ko_KR.UTF-8 zsh -f" Enter
Sleep 500ms
Type "source demo/setup.sh en && clear" Enter
Sleep 500ms
Show

# 1. 목록 열기
Type "sb" Sleep 400ms Enter
Sleep 2.5s

# 2. 위아래로 옮기면 아래 상세가 바뀐다
Down Sleep 1.5s
Down Sleep 1.5s
Down Sleep 1.5s

# 3. 글자를 치면 걸러진다 (VHS 는 한글 입력을 못 보내 영문·숫자로 거른다)
Type "PROJ-123" Sleep 2.5s

# 4. enter 로 세션 진입
Enter
Sleep 3.5s
