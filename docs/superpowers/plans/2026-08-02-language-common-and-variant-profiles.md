# 語言共通層與變體層實作計畫

> 對應規格：`docs/superpowers/specs/2026-08-02-language-common-and-variant-profiles.md`

1. 先新增資料生成與 schema 測試，鎖定基礎／變體 profile、潮州話
   `chao1238` 與 expression 分類 constraint，確認測試因功能缺失而失敗。
2. 新增 `0013_add_expression_variation_status.sql` 並同步 `backend/schema.sql`；更新
   expression mutation 型別、驗證與回應。
3. 更新 `language_seed_profiles.json`：補齊基礎 profile，保留有內容差異的
   region profile，將潮州話改為按 script 的 `chao1238` profiles。
4. 離線重建 language registry artifacts，驗證生成結果可重現且可載入完整 schema。
5. 重建本地 dev D1，執行 Python、backend、frontend build 及 `/languages` smoke test。
