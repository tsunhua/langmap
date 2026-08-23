# Reconciliation gold JSONL

每行是一個候選的人工判定，欄位固定如下：

```json
{
  "candidate_key": {
    "left_claim_key": "claim-a",
    "right_claim_key": "claim-b"
  },
  "label": "merge",
  "adapter_id": "traditional-chinese-english",
  "split": "holdout",
  "annotator_id": "reviewer-1",
  "annotation_version": "v1"
}
```

`label` 只能是 `merge` 或 `keep_separate`；`split` 只能是 `tuning` 或
`holdout`。候選鍵必須保持字典序，且同一候選不可同時出現在兩個 split。
只有 `holdout` 中實際走過自動合併路徑的候選會計入 precision gate。每個啟用
adapter 至少需要 50 個自動路徑候選，總數至少 1,000 個；gate 使用 point
precision 99.5% 與 Wilson 95% 下界 99.0%。

definitions、labels、examples 可作為審閱上下文，但不是線上資料庫欄位。
