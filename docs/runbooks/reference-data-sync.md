# Reference Data Sync Runbook

## 前置條件

- language registry 與 system UI bundle 由版本控制來源 deterministic 生成。
- ownership scope 明確；缺少 ownership 的 remote row 不可猜測或刪除。
- 先完成 production inventory 與 plan。

## Plan / Apply / Verify

```bash
python3 scripts/i18n/generate-bundle.py
./scripts/db/manage.sh production inventory
./scripts/db/manage.sh production plan
```

plan 必須列出 insert/update/unchanged/manual-review counts；artifact 缺少的 remote
row 不列為 delete。審核後由受保護 apply 載入 registry 與 system UI bundle，再執行
完整 inventory/baseline verify。

## 失敗處理

若 key ownership、translation coverage、schema 或 orphan check 不一致，標記
manual review 並停止。修正來源 generator 或建立 migration，不在前端寫例外。

## 禁止事項

- 不直接對 production 執行 `import-all.sh --remote`。
- 不刪除 artifact 未包含的 production reference row。
- 不把 translation JSON 當成可直接執行的 remote SQL 入口。
