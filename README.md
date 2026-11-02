# ᄉᆡ미 기픈 믈 — 수능 국어 개념서

개념 설명·예문·자주 틀리는 점에 평가원 기출을 붙인 수능 국어 개념서입니다.
**사이트: https://korean-exam-teacher.github.io/suneung-concept/** (GitHub Pages: main 브랜치 `/docs`)

같은 내용으로 **웹 사이트**(`docs/`)와 **한글 책**(`book/수능국어_개념서.hwpx`)을 함께 만듭니다.
이름은 용비어천가 2장 "ᄉᆡ미 기픈 므른 ᄀᆞᄆᆞ래 아니 그츨ᄊᆡ"에서 따왔습니다. 짝이 되는 기출 문제은행은 「불휘 기픈 남ᄀᆞᆫ」입니다.

## 폴더

| 폴더 | 내용 |
|---|---|
| `content/` | **고칠 곳.** 장마다 JSON 파일 하나. 쓰는 규칙은 `content/README.md` |
| `docs/` | 완성된 웹 사이트. GitHub Pages에 이 폴더를 그대로 올리면 됩니다 |
| `book/` | 한글 책과 PDF. `수능국어_개념서.hwpx`·`.pdf`(전체판, 738쪽: 개념 + 장마다 기출 풀어 보기 + 정답과 해설), `수능국어_개념서_가벼운판.hwpx`·`.pdf`(189쪽: 개념 + 기출은 출처·발문·정답만) |
| `tools/` | `build.ps1`(전체 빌드), `make_book.ps1`(한글로 열어 차례 쪽 번호를 채우고 PDF 저장), `make_hwpx.ps1`(책 짜기), `serve.ps1`(미리 보기 서버) |

## 다시 만들기

`content/`를 고친 뒤 PowerShell에서:

```
powershell -ExecutionPolicy Bypass -File "F:\국어의 모든 것\수능국어 개념서\tools\build.ps1"
```

- 기출은 `F:\평가원 기출 문제 모음\문제은행_저장소\docs`(문제은행 사이트)에서 읽습니다. 다른 곳이면 `-Bank "<경로>"`를 붙이세요.
- 개념마다 `kichul` 설정(유형 묶음 + 낱말)으로 기출을 자동으로 고릅니다. 특정 문항을 꼭 넣으려면 `kichul.items`에 `"2026-09||언어와 매체||35"` 같은 키를 적습니다.
- 미리 보기: `powershell -ExecutionPolicy Bypass -File tools\serve.ps1` 뒤 http://localhost:8765/

## 웹 사이트 기능

목차, 개념 찾기, 기출 바로 풀기·채점·해설, '이해했어요' 진도 표시(브라우저에 저장), 휴대폰 화면, 옛한글 글꼴.

## 저작권

기출 문항·지문·선택지·해설의 저작권은 한국교육과정평가원에 있습니다. 비영리 학습용으로만 씁니다.
