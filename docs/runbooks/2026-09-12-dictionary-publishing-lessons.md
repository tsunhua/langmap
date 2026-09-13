# 詞典發布的教訓與經驗

> 整理截至 2026-09-12 的實際詞典與 Wikivoyage 發布經驗。本文是決策與檢查清單，
> 具體命令仍以 [Production Data Release Runbook](production-data-release.md) 與
> [Wikivoyage 會話手冊 Runbook](wikivoyage-phrasebook-release.md) 為準。

## 一句話結論

詞典發布的主要風險不在 D1 `INSERT`，而在「來源資料被錯誤解讀」以及「修正後沒有完整、可追溯地重跑」。
可靠流程應固定 `source commit + source artifact + checksum + staging quality report + delta + plan`，
先在本地驗證，再以受管的 source-scoped delta 發布；production apply 後必須按來源範圍驗證並刷新統計。

## 已確立的原則

1. **來源是唯一真相**：詞義、讀音、locale、例句與授權問題應回到 exporter／原始資料修正；不手改 JSONL，
   不在 LangMap 加單筆例外，也不直接手改 production。
2. **詞句、mapping、reading 分開建模**：reading 不是 expression；例句原句與譯句是獨立 expression，
   只建立兩者之間的 example edge，不把例句掛到主詞頭。
3. **身份以自然鍵與來源標記追蹤**：production 不依賴 staging 的整數 ID；同一來源的 homograph marker、
   source claim 與 edge claim 必須可重建。來源修正改變 identity 時，用 `--replace` 或來源範圍 repair delta。
4. **小批、可續跑、可回退**：每部或每批獨立 staging；state、before snapshot、plan、journal 與 bookmark 都要保留。
5. **資料發布與 Web deploy 分離**：D1 apply 成功不代表 Worker／前端已上線；兩者分別驗證、分別記錄。
6. **Production 只做定點取樣**：不下載全庫、不做全表 `COUNT(*)` 或 full mirror；以 source key、revision、row marker、expression ID 的小結果集驗證，超出定點範圍就停止並改用本地 artifact。

## 發布中反覆出現的問題

| 現象 | 根因 | 之後的防線 |
| --- | --- | --- |
| 漢語拼音被當成 `cmn` expression | exporter 把 pinyin span 當普通 equivalent | 在 exporter 將 pinyin／jyutping／tailo 寫入 reading；adapter 只接受明確 scheme；用 raw scan 與 blocking gate 攔截。 |
| 泰文擬音被標成英語 IPA | Apple bundle 的 `UK_IPA` 標記不代表真正 IPA | 對 native-script respelling fail closed；沒有正確資料模型時丟棄，不猜成另一種語言或 locale。 |
| POJ、臺羅、漢字被掛到錯誤 locale | 文字欄位與 reading 欄位混用，或 locale profile 不完整 | 來源欄位先定義 headword／equivalent／reading；為每種 orthography 建精確 locale；抽查雙表示法條目。 |
| 例句、例句讀音出現在主詞頭 | 舊 adapter 只會把 reading 綁到 headword，或把 example 當普通 mapping | example 使用獨立 expression；reading 帶 `target_claim_key` 路由到例句；檢查 edge relation 與 expression locale。 |
| Wikivoyage 出現 `[]`、說明文字、slash 或錯誤方向 | wikitext 結構漂移、括號備註／替代詞未按語境解析 | 固定 page revision；保留 page／row provenance；slash 只拆詞句替代，reading 內 slash 才拆 reading；placeholder、反向列表與語言說明進 quarantine。 |
| 同一詞因標點、大小寫或 packed gloss 產生重複 | canonicalization 在來源端不一致，或只做了局部清理 | 先在 exporter 統一 identity，再重匯整部來源；需要時用 source-scoped `--replace`，不要只刪一個 production row。 |
| 頁面／詞典被 `blocked` | language registry 或 exact locale 尚未存在 | 先更新 registry／locale seed，再重跑 export；不要在 importer 或前端猜語言。 |
| `/languages` 或語言列表數量滯後 | delta 只寫 expressions／edges／readings，沒有刷新 `language_statistics` | 每次 apply 把 statistics refresh 納入同一 operation，並在 postflight 讀回確認。 |
| 大 delta 超時或 bind variable 超限 | 單一 D1 execute 太大 | 產生 split SQL，限制每批語句／rows；apply 失敗後沿用同一 plan 和 journal resume，不重建另一份 delta。 |
| 修正後本地與 production 對不上 | 把 staging 當 production 全庫副本，或用不同基線產生 delta | mirror 只作 staging／replay；正式發布用 source-scoped natural-key delta。只有 restore、mirror drift 或 mirror 遺失才做 production export。 |
| 資料已上線但頁面仍是舊行為 | D1 apply 與 Web deploy 是兩條獨立流程，或瀏覽器保留舊 cache | 在發布紀錄中分開記錄 data operation 與 deploy；前端 cache 要有 schema／revision 版本，必要時清除舊 session cache。 |
| 資料可以技術發布但不能公開再分發 | 來源授權不明或限制性授權 | release gate 加入 license／attribution 審核；例如 `hk-cantowords`、`ts-english-dict` 在授權釐清前不得再鏡像或打包。 |

## 現在採用的標準流程

### 1. 固定輸入

- 記錄來源 repo commit、原始檔案／頁面 revision、抓取時間、entry count、來源 license 與 checksum。
- Wikivoyage 另固定 `manifest.json`、wikitext snapshot、page catalog、section catalog 與 attribution。
- artifact 一旦進入 plan，不得原地修改；任何修正都建立新 artifact、新 checksum 與新 plan。

### 2. Export 與 staging

- 由來源 exporter 產生 Structured JSONL；entry count 應與來源報告一致。
- 先做 normalization，再做 explicit cluster／reconciliation；跨檔 AI 合併不是單檔增量發布的一部分。
- 以 incremental importer 分批匯入本地 SQLite；沿用 state，不刪成功紀錄強行重播。
- quality gate 至少包含：schema／foreign key、source／locale／direction、reading script、placeholder／markup、
  first／middle／last sample、quarantine 數量、deterministic replay。
- 所有不確定項目 fail closed：進 quarantine 或 `blocked`，不要以語言名稱、字形或上下文猜測。

### 3. 產生 delta

- 優先使用 `export_dictionary_source_delta.py`，以 source key、locale code、expression identity 及自然鍵產生可重跑 delta。
- 來源重匯後 identity 改變，使用 `--replace`；工具必須先檢查是否有其他 source 共用 owned expression。
- 大檔分割，並保存 delta manifest／SHA-256；不要把本地 staging 整數 ID 當成 production identity。
- 產生 delta 前使用 mirror 的 before snapshot；不要臨時猜測「上一次狀態」。

### 4. Production plan／apply

1. 先跑唯讀 `inventory`，確認 database identity、schema、source scope 與待變更範圍。
2. 建立 plan，鎖定 commit、artifact checksum、delta checksum、reference action、statistics refresh 與驗證條件。
3. operator 審核後才 apply；apply 先取得 D1 Time Travel bookmark，再按 migration／data／reference／verify stage 執行。
4. 暫時性失敗使用同一 plan 依 journal resume；不要產生新 plan、重建 delta 或手動重播已完成 stage。
5. 大型資料使用 split mode；不要繞過 plan 直接 `wrangler d1 execute --remote`。

### 5. Postflight 與記錄

- 按 source key 驗證 expression claims、edge claims、readings、locale links、source markers 與 representative samples。
- 驗證 `foreign_key_check`、orphan references、handbook items／sections，以及 `language_statistics`。
- apply 成功後把同一份 delta replay 回 mirror；確認 mirror 與 production 的來源範圍計數一致。
- 立刻在 [`TODO.md`](../../TODO.md) 記錄 source key、delta 路徑與 SHA-256、operation ID、bookmark、日期及 counts。
- 只有 data verify 與 Web deploy 都完成，才能對外宣稱「已發布」。

## 發布前最小檢查清單

### Source／staging

- [ ] source commit、artifact、revision、license、checksum 已固定
- [ ] entry count、page accounting、JSONL header 與實際行數一致
- [ ] language／locale／script／direction 逐批抽查
- [ ] reading 與 expression 分離；例句 edge 方向正確
- [ ] pinyin、POJ、Tailo、Jyutping、native-script respelling 沒有誤建 expression／IPA
- [ ] quarantine、invalid、missing、placeholder、markup diagnostics 已人工處理或明確保留
- [ ] local replay、`foreign_key_check`、quality report 通過

### Delta／production

- [ ] before snapshot 與 delta manifest checksum 鎖定
- [ ] source-scoped natural-key delta；identity 變更已評估 `--replace`
- [ ] plan 已通過 database identity、schema、ownership、bookmark 與 source-scope preflight
- [ ] 大檔已 split；未使用直接 remote SQL
- [ ] operator 已審核 plan，並保留 operation journal

### Postflight

- [ ] source-scoped counts／samples 與 staging 對得上
- [ ] locale links、readings、edges、handbook references 與 orphan checks 通過
- [ ] `language_statistics` 已刷新
- [ ] delta 已 replay 回 mirror
- [ ] `TODO.md` 已記錄 operation、bookmark、checksum 與結果
- [ ] Web deploy、API／前端版本與 cache invalidation 另行驗證

## 發生問題時的處置順序

1. **來源內容錯**：停止發布；回 source exporter 修正，重新匯出、重新抽查、重新產生 delta。保留舊 artifact 備份，
   不直接編輯 JSONL。
2. **staging gate 失敗**：保留 quarantine 與 report；先修 parser、registry 或 source fixture，不把錯誤資料送進 mirror。
3. **production apply 中斷**：讀 `operations.jsonl` 與 plan report；若 identity 和 plan 未變，沿同一 plan resume。
4. **postflight 不一致**：停止後續發布，使用已記錄 bookmark 評估回復；不要刪除共享 expression、reading 或 edge。
5. **mirror 漂移**：先做 source-scoped inventory；只有確認 restore、drift 或 mirror 遺失，才重新建立 production snapshot。
6. **授權不清**：標記 release blocked，不以「資料已在本地」作為公開發布理由。

## 目前仍需持續改善

- 將 cache schema／artifact revision 納入所有前端資料快取 key，避免部署後沿用舊 payload。
- 逐部清理尚未完成的 reading script mismatch、legacy example edges 與不確定括號資料；不得用一次性全刪代替來源修正。
- 把 license／attribution 欄位納入 release manifest 的必填 gate，而不是只在 TODO 備註。
- 維持 source-scoped sampling 報告，讓接力 session 可以只讀 ledger 和 manifest，不依賴聊天記錄推斷發布狀態。

## 2026-09-12 source surface sweep

本輪先以來源檔的固定 head／middle／tail 抽樣排序，不讀取 production 全庫。可重跑的審計入口為：

```bash
PYTHONPATH=scripts python3 scripts/dictionary/audit_expression_surfaces.py \
  /Volumes/DATA/langmap-structured-jsonl \
  --sample-entries 120 --sample-limit 8 \
  --output /tmp/langmap-source-surface-sample.json
```

`--sample-entries` 是每個 JSONL 的 bounded byte-seek 抽樣，不是逐行全掃；只有抽樣命中高置信問題時，才對該來源做完整重匯與 source-scoped 驗證。本輪優先修正並重新匯出：

1. `zhs-ja.Crown`：巢狀全形句號、CJK 例句內聯 pinyin，後者改存 example reading，不再混進 expression。
2. `zh_CN-en.OCD`：混合括號、`cf []` 交叉引用殘留與不平衡尾端。
3. `ko-en.NewAce`：不平衡大括號、定義型括號與 `cf []` 殘留。
4. `ja-en.WISDOM`：usage label、`〘…〙` 說明與日語詞句後附英文 gloss；英文 gloss 不再成為日語 expression。
5. Spanish DGLEV：`.hw` 缺失時使用 CSV headword fallback，避免整行匯入中止。

這些修正均保持 entry count 不變並通過 exporter 回歸測試。Portuguese、Gujarati 抽樣各命中一個不平衡的說明型 equivalent；因目前沒有可重匯的原始 CSV，兩者列為 release blocked，不能以猜測或手改 JSONL 修復。production 尚未因本輪 sweep 被改動；後續須在取得原始來源後，按本 runbook 的 staging／delta／plan／apply 流程發布。
