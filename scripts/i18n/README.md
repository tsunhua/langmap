# UI 翻譯匯入

將 JSON 翻譯檔轉成 SQL，再匯入 Cloudflare D1。翻譯鍵需對應
`web/src/locales/en.ts` 的巢狀路徑。

## 翻譯檔

- `zh-Hans-CN.json`：簡體中文（中國）
- `zh-Hant-TW.json`：繁體中文（台灣）
- `es-ES.json`：西班牙文（西班牙）
- `ja-JP.json`：日文（日本）

格式為扁平 JSON：

```json
{
  "nav.home": "首頁",
  "common.search": "搜尋"
}
```

## 一鍵生成與匯入

批次腳本會生成全部四個語言的 SQL 至暫存目錄，依序匯入後自動清理。

```bash
scripts/i18n/import-all.sh --local
```

遠端模式會列出目標語言，輸入 `yes` 後才會寫入：

```bash
scripts/i18n/import-all.sh --remote
```

如只需生成單一語言：

```bash
python3 scripts/i18n/generate-i18n-sql.py \
  zh-Hant-TW scripts/i18n/zh-Hant-TW.json \
  > /tmp/langmap-zh-Hant-TW-import.sql
```

生成器會建立 locale、UI message、翻譯詞句與語義關係；重複執行時使用
`INSERT OR IGNORE`。找不到英文原文的未知鍵會略過並在 stderr 顯示警告。

`scripts/i18n/*-import.sql` 已加入 `.gitignore`。若曾建立在專案內，可用
`git check-ignore scripts/i18n/<locale>-import.sql` 確認不會被 Git 追蹤。
