# UI 翻譯匯入

透過 Python 腳本將 JSON 翻譯檔轉換為 INSERT SQL，直接寫入 D1。

## 檔案結構

```
scripts/
├── generate-i18n-sql.py   # 翻譯 SQL 生成器
├── i18n/
│   ├── README.md           # 本文件
│   ├── zh-CN.json          # 簡體中文翻譯
│   └── zh-TW.json          # 繁體中文翻譯
└── v2/
```

## 翻譯 JSON 格式

每條 key 對應 `web/src/locales/en.ts` 的巢狀路徑：

```json
{
  "nav.home": "首页",
  "nav.languages": "语言",
  "nav.contribute": "贡献",
  "common.search": "搜索",
  "contribute.title": "批量贡献"
}
```

## 使用方式

```bash
# 1. 從專案根目錄執行，由 en.ts 自動取得英文原文及 SHA-256 ID
python3 scripts/generate-i18n-sql.py zh-CN scripts/i18n/zh-CN.json \
  > scripts/i18n/zh-CN-import.sql

# 2. 匯入本地 D1
npx wrangler d1 execute langmap-v2 --local \
  --file scripts/i18n/zh-CN-import.sql

# 3. 匯入遠端 D1
npx wrangler d1 execute langmap-v2 --remote \
  --file scripts/i18n/zh-CN-import.sql
```

## 簡繁體同時一次匯入

```bash
for locale in zh-CN zh-TW; do
  python3 scripts/generate-i18n-sql.py "$locale" "scripts/i18n/${locale}.json" \
    > "scripts/i18n/${locale}-import.sql"
  npx wrangler d1 execute langmap-v2 --local \
    --file "scripts/i18n/${locale}-import.sql"
done
```

## 原理

- `expression_id(lang, text)` 使用 SHA-256 計算固定 ID，與後端演算法一致（`backend/src/utils/ids.ts`）
- 同一英文 text + "en-US" 產生相同 ID，`INSERT OR IGNORE` 冪等執行
- 腳本自動處理：locale 註冊、`ui_messages` seed、翻譯 expression 建立、`expression_edges` 串接
- 未知 key 會跳過並顯示警告，不影響其他翻譯
