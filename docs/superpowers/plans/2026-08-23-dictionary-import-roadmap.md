# Managed Dictionary Import Delivery Roadmap

> 本路線圖拆解已確認的
> [`2026-08-23-dictionary-structured-jsonl-import-design.md`](../specs/2026-08-23-dictionary-structured-jsonl-import-design.md)。
> 每份子計畫都要形成可獨立測試與審查的交付，不跨越尚未通過的驗收閘門。

## Goal

把 release manifest 掃描到的全部 structured JSONL 詞典建立成可更新、可重跑、可驗證及可回退的 LangMap 受管資料集，並以獨立 homograph Expression 正確保存 `cod` 等多義詞。檔案數量只在 export job 完成後由 release manifest 凍結，不寫死在程式或計畫中。

## Plan Order

| 順序 | 計畫 | 獨立交付 | 依賴 |
|---:|---|---|---|
| 1 | [Exporter v2 與 staging vertical slice](./2026-08-23-dictionary-export-staging.md) | JSONL v2、staging SQLite、繁中英 adapter、`cod` 三同形 preview artifact | 已確認 spec |
| 2 | [Release schema 與受管發布](./2026-08-23-dictionary-release-publishing.md) | D1 release/binding/evidence/POS、active eligibility、plan/apply/verify/rollback | Plan 1 artifact contract |
| 3 | [AI 義項對齊](./2026-08-23-dictionary-ai-reconciliation.md) | 候選生成、AI provider 契約、雙次判定、gold-set gate、compiler 整合 | Plan 1 staging；Plan 2 bindings |
| 4 | [全 corpus adapter 與 rollout](./2026-08-23-dictionary-corpus-rollout.md) | manifest 全詞典 coverage、全量 dry run、第一個 active release | Plans 1–3 |

## Cross-Repository Boundary

`/Users/lim/Documents/Code/tsunhua/dictionary` 負責忠實抽取：

- PyGlossary CSV reader；
- dictionary-specific DOM parser；
- Structured JSONL v2 schema、atomic writer 與 diagnostics；
- 不配置 LangMap Expression ID，不執行 AI 合併。

`/Users/lim/Documents/Code/tsunhua/langmap` 負責 LangMap 投影：

- staging、normalization、quarantine；
- lexical occurrence／cluster 與 AI reconciliation；
- Expression／edge／reading／POS compiler；
- D1 release lifecycle 與公開查詢 eligibility。

兩個 repository 只透過 JSONL v2 schema 與 release manifest 溝通。不得 import 對方的 Python package 或依賴相對 checkout 位置。

## Global Gates

每個 plan 完成前必須：

1. 跑該 plan 列出的自動測試。
2. 執行 `git diff --check`。
3. 確認沒有修改 `export/`、`.wrangler/`、`backend/public/` 或 `web/dist/` 生成內容。
4. 確認 LangMap 既有未提交改動未被覆寫或納入 commit。
5. 以 Conventional Commit 只提交該 task 的檔案。
6. 更新本路線圖的完成狀態時，只改 checklist，不改已確認的 spec 語義。

## Program Acceptance

- [ ] Plan 1：`cod 1/2/3` 產生三個文字皆為 `cod`、鄰域隔離的 preview clusters。
- [ ] Plan 2：fixture release 可重跑、切換與回退，既有一般 mapping／vote／handbook 引用不受影響。
- [ ] Plan 3：auto merge holdout precision 點估計至少 99.5%，Wilson 95% 下限至少 99.0%。
- [ ] Plan 4：所有 input record 均落入 published、quarantined 或 explicitly skipped，且全量 artifact 通過守恆與 D1 preflight。

## Execution Rule

嚴格依序執行。Plan 2 可以在 Plan 1 的 fixture artifact contract 固定後與 Plan 1 的全量 diagnostics 並行；Plan 3 不得在 staging schema 固定前開始；Plan 4 不得在 AI gate 與 release rollback 通過前 apply 全量資料。
