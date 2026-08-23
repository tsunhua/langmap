# Structured JSONL 詞典受管匯入設計

> 日期：2026-08-23
>
> 狀態：設計已確認，尚未實作

## 1. 摘要

LangMap 要把
`/Users/lim/Documents/Code/tsunhua/dictionary/export/structured-jsonl/`
中的 22 部詞典納入一套可更新、可重跑、可驗證及可回退的受管資料集。

匯入不能只按 `(lang_code, text)` 建立 Expression。相同文字可能有多個彼此獨立的語義鄰域；例如繁中英詞典把 `cod` 分成三個同形 entry，分別對應魚類、袋／莢／陰囊，以及愚弄／玩笑／虛假。三組對應若掛到同一個 `cod` Expression，圖譜會產生錯誤的間接關係。

本設計採用「離線義項層＋最小線上證據層」：完整抽取內容保存在本機 staging；AI 在發布前對齊同文義項；線上仍使用既有 Expression／edge 圖，不新增公開 sense entity。只有經評測校準、符合硬性規則的高信心候選可由 AI 自動合併，其餘保持分離。

## 2. 現況與問題

### 2.1 資料規模

目前 structured JSONL 共：

- 22 個檔案；
- 2,025,579 筆 entry；
- 873,875,683 bytes；
- 2,525,824 個已抽出的 sense；
- 4,736,563 個 equivalent 字串；
- 335,063 個 example；
- 2,094,917 個 pronunciation。

目前約 555,610 筆 entry 的 `senses=[]`。這不是「沒有語義」的可靠斷言，而是現行 exporter 只辨識部分 DOM 結構，漏掉大量定義節點。因此目前 JSONL 可供盤點與 fixture 使用，但不能直接成為第一個正式 release。

### 2.2 現行 exporter 的限制

現行程式為：

`/Users/lim/Documents/Code/tsunhua/dictionary/bin/export-dictionary-structured-jsonl.py`

已確認的限制包括：

- entry 沒有可靠的逐筆語言方向；雙向詞典不能只依檔名或 dictionary metadata 判斷。
- `headword` 會混入 homograph 顯示數字，例如 `cod 1`，但實際詞面應為 `cod`。
- `sense_id` 只是單一 entry 內的抽取順序，不能跨 entry 或跨詞典對齊。
- `entry_id` 含 CSV row number；前方列插入或刪除後可能漂移。
- 任何 CSV 第一欄以 `#` 開頭的記錄都可能被誤判為 metadata，導致真實詞頭遺失。
- `.se2`／`.semb` 之外的定義結構未完整處理。
- `equivalents` 可能混入拼音、性別、標點、用法或多個尚未拆開的詞句。
- `forms`、`pronunciations` 與 `pos` 可能收集到顯示文字或錯誤層級的內容。
- 輸出未記錄 exporter schema version、輸入 checksum 或足夠穩定的原生記錄定位。
- 寫出過程不是 atomic；失敗時可能留下不完整檔案。

### 2.3 現行 LangMap 模型的限制

現行 `expressions` identity 是 `(lang_code, canonical text, homograph_index)`；同文多義以 `.2`、`.3` 等 opaque 後綴表示。系統沒有 sense／meaning entity，且既有架構決策明確把語義放在 mapping 圖中。

相關現況：

- `backend/schema.sql` 的 `expressions` 已支援 `homograph_index`。
- 普通 Expression 建立 API 固定建立或重用 index `1`。
- index `2+` 目前只能由管理員 split 流程建立。
- `expression_edges` 是無向唯一 pair；同一 pair 只能有一條 edge。
- edge 目前不能分別記錄多筆詞典 claim。
- Expression 本身只有一組輸入描述欄位，不能表達同一節點被多筆輸入記錄支持。
- `expression_locale_attestations` 目前只允許一筆 `(expression_id, language_locale_code)`。
- `contribution` 不是持久化批次 entity，不能用來承載詞典 release 或 entry identity。

工作區中的實驗性 `scripts/dictionary/import_structured_jsonl.py` 雖會讀取 `sense_id`，仍把同文字的所有 equivalent 掛到 index `1`。它不能滿足本規格的多義隔離要求，也不能作為正式受管匯入器的資料模型基礎。

## 3. 目標

1. 讓 22 部詞典中的每筆輸入記錄都能被追蹤為「已發布」或具明確錯誤碼的 quarantine，禁止靜默遺失。
2. 正確保留同文多義；不同義項不得因文字相同而自動共用 Expression。
3. 讓 AI 自動合併經評測證明足夠可靠的同義 claims，同時優先避免錯誤合併。
4. 完整保留 exporter 已抽取的欄位，供重新處理、AI 對齊與品質稽核。
5. 線上 D1 只發布 LangMap 產品模型需要的 Expression、mapping、reading、例句 mapping、詞性與最小技術綁定。
6. 支援全量、增量、子集重跑、失敗續跑、dry run、驗證與 release 回退。
7. `homograph_index` 一旦發布便保持穩定；資料重排、加入新詞典或只跑子集都不能重新編號既有 Expression。
8. 所有轉換、排序、ID 與 artifact 必須 deterministic。

## 4. 非目標

- 不新增公開 `sense`、`meaning` 或 `concept` entity。
- 不把 definitions 或 labels 寫入線上 D1。
- 不為 definitions 新增 API 或 UI。
- 不新增 examples 專用資料表；例句只以普通 Expression／mapping 發布。
- 第一版不把 `forms` 發布為形態邊；原始 forms 完整保存在 staging，日後有可靠 adapter 時另立規格。
- 第一版不建立 AI 審核 Web UI；低信心候選保持分離，品質報告提供離線審閱入口。
- 不修改 `web/` 或 `apple/` 的一般詞典瀏覽流程；只有詞性若需展示時才做最小 API／前端增量。
- 不讓 importer 直接繞過驗證規則，把未知語言、locale、reading scheme 或詞性寫入 D1。
- 不承諾所有輸入記錄都能立即發布；無法可靠解析者必須進 quarantine。

## 5. 詞彙

- **Dataset release**：一組固定輸入 checksum、exporter／adapter／AI 配置與發布 artifact 的不可變版本。
- **Input entry**：詞典中的一筆原始 entry。
- **Input sense claim**：input entry 內明示的一個義項；只在離線 staging 中存在。
- **Lexical occurrence**：claim 中某一語言、某一詞面的具體出現，角色可為 headword、equivalent、example text 或 example translation。
- **Lexical cluster**：被判定為同一 `(lang_code, canonical text, semantic identity)` 的 lexical occurrences；每個 cluster 投影成一個 LangMap Expression。
- **Binding**：一個穩定 input claim／occurrence key 與線上 Expression 的版本化對應。
- **Evidence**：某一 input claim 支持一條線上 mapping 或詞性斷言的內部記錄。
- **Quarantine**：無法安全發布、但保留完整原始內容及錯誤碼的記錄集合。

## 6. 核心決策

### 6.1 採離線義項層，不改公開領域模型

Input sense、definition、label 與 AI cluster 都只存在 staging／artifact。線上仍以 Expression 表達可獨立擁有語義鄰域的詞句節點，以 `expression_edges` 表達直接關係。

此設計延續現有「意義由 mapping 圖承載」的方向，避免為一次匯入推翻搜尋、詳情頁、圖譜及貢獻 API。

### 6.2 預設分離，合併需要正面證據

處理順序是：

1. 每個 input sense claim 先保持獨立。
2. 同一個明示 homograph entry 下的多個細分 sense，預設共享該 entry 的 headword lexical cluster。
3. 沒有明示 homograph grouping 時，不因文字相同而自動共用 cluster。
4. AI 只在同語言、同 canonical text 的候選間判斷是否合併。
5. Equivalent 端也遵守相同規則；不能只拆 headword，卻讓另一端的同文多義重新把圖連通。

此策略容許暫時 over-split，因為漏合併只會讓圖較碎；錯誤合併則會製造虛假的語義路徑，風險更高。

### 6.3 AI 自動合併只作用於安全身份情境

AI 可以自動：

- 合併尚未發布的 lexical occurrences；
- 把新 input claim 綁定到一個既有 Expression；
- 合併同一明示 homograph entry 下、沒有衝突的細分 sense evidence。

第一版不能由 AI 自動把兩個已發布且各自有獨立 Expression ID 的節點破壞性合併。若一個新 release 推導出兩個既有 Expression 應合併，compiler 產生 `published_identity_conflict`，保持舊綁定並列入審閱。這避免自動搬移使用者 mappings、votes、handbook items 或其他引用。

### 6.4 全部欄位保存在 staging，線上只發布產品資料

| 欄位 | 離線 staging | 線上 D1 |
|---|---|---|
| headword | 完整保留 | Expression |
| homograph marker | 完整保留 | 轉成穩定 `homograph_index`，不顯示 marker |
| forms | 完整保留 | 第一版不發布 |
| pronunciations | 原始值與正規化值並存 | 合法 reading |
| sense definitions | 完整保留 | 不發布 |
| equivalents | 原始值與原子化結果並存 | Expression＋mapping |
| examples | 完整保留 | 成對者發布為 Expression＋mapping |
| labels | 完整保留 | 不發布 |
| POS | 原始值與正規化值並存 | 詞性佐證 |
| diagnostics | 完整保留 | release 摘要計數 |

## 7. 整體架構

```text
原始 CSV
  → Structured JSONL v2
  → 離線 staging SQLite
  → 詞典 adapters
  → lexical occurrence graph
  → AI reconciliation
  → deterministic compiler
  → versioned release artifact
  → LangMap D1 publisher
```

### 7.1 Exporter v2

Exporter v2 位於 dictionary 專案，負責忠實抽取，不負責 LangMap identity 或 AI 合併。

必要改動：

- JSONL header 加入 `schema_version`、`dictionary_key`、輸入 fingerprint 與 entry count。
- entry 同時保留 `raw_headword`、`canonical_headword` 與 `homograph_marker`。
- 保留可用的原生 entry／sense 定位，例如 HTML `lexid`、element ID 或其他穩定屬性。
- 保留逐筆語言方向提示；不得只寫詞典層級的單一方向。
- definitions、equivalents、examples、labels、POS、forms 與 pronunciations 保留原始節點順序和原始文字。
- `sense_key` 優先使用原生穩定定位；沒有時使用 record fingerprint 加局部 ordinal，並標記為 fallback identity。
- metadata 只在明確的前導 metadata 區段、且 key 符合 allowlist 時解析；`#` 與 `#9110` 等真實詞頭不得被吞掉。
- sense traversal 按 DOM 文件順序，不先收集所有 `.se2` 再收集 `.semb`。
- 寫到同目錄臨時檔；完成計數與 checksum 後才原子替換目標檔。
- 任一檔案失敗時回傳非零狀態，不保留看似完整的目標檔。

Exporter v2 不把顯示數字硬編碼為語言文字，也不在不知道語義時拆分 equivalent。

### 7.2 離線 staging

Staging 使用本機 SQLite，而不是把 800 MiB 以上 JSONL 全部載入記憶體。Loader 逐行驗證 JSON schema 並寫入下列邏輯表：

- `dataset_releases`
- `input_entries`
- `input_senses`
- `input_equivalents`
- `input_examples`
- `input_pronunciations`
- `input_forms`
- `input_pos`
- `input_labels`
- `lexical_occurrences`
- `reconciliation_candidates`
- `reconciliation_decisions`
- `lexical_clusters`
- `quarantine_items`

每張正規化表都保留：

- 穩定輸入鍵；
- 原始 JSON；
- 正規化欄位；
- record fingerprint；
- adapter 版本；
- 狀態與錯誤碼。

Staging schema 是 pipeline 的內部契約，不是 LangMap 公開資料模型。Schema migration 跟隨 importer 版本，舊 release 不就地改寫；需要重算時建立新 staging release。

### 7.3 詞典 adapters

每部詞典必須在 manifest 中指定 adapter。共用基礎 adapter 只處理無語言爭議的結構；個別詞典的方向、標點、縮寫與文法格式由專用規則處理。

Adapter 負責：

1. **語言方向**：優先使用 entry／HTML 結構中的方向屬性；人工驗證的記錄區段規則可作次選。不能只靠 Unicode script 猜測共用拉丁字母的語言。
2. **詞頭**：把顯示用 homograph marker 與 canonical text 分離；canonical text 仍只做 `trim`＋Unicode NFC。
3. **Equivalent 原子化**：把多詞列舉、讀音、性別、用法和標點拆成結構化欄位；原字串永遠保留。
4. **Reading**：把原始 scheme 映射成 LangMap grammar 接受的 code；例如 IPA 類型歸一為 `ipa`，dialect／locale 另行解析。未知 scheme 不得直接寫 SQL。
5. **POS**：把原始 POS 映射到受控碼；未知值只保存在 staging。
6. **Examples**：只在原句、譯句及兩端語言可可靠成對時建立 mapping candidate。數量不一致時不得做未經規則確認的笛卡兒積。
7. **Diagnostics**：輸出逐錯誤碼計數、範例與 entry 定位。

同一 adapter 的規則、映射表與測試 fixtures 必須一併版本化；release manifest 記錄整個 adapter bundle checksum。

### 7.4 Reconciliation engine

Reconciliation 分成候選生成與 AI 判定兩階段。

#### 候選生成

候選只在以下基本條件成立時產生：

- `lang_code` 相同；
- canonical text 相同；
- 兩筆都不是 quarantine；
- 沒有 deterministic blocker。

候選排序使用穩定 tie-breaker；大群組分批但不得依載入順序改變結果。候選特徵包括：

- 正規化 POS 集合；
- definitions 的語義表示；
- labels；
- example 語義；
- equivalent 鄰域及語言分布；
- 明示 homograph marker 與 entry grouping；
- 已發布 binding；
- 解析完整度與 adapter 信任等級。

#### Deterministic blockers

以下任一條成立即禁止自動合併：

- 語言或 canonical text 不同；
- 明示 homograph marker 在同一詞典內互異，且沒有人工 override；
- 受控 POS、專名狀態或語用標記存在已定義的互斥衝突；
- 任一 identity 使用 fallback 且跨 release 對應含糊；
- 候選會把兩個已發布 Expression ID 合成一個；
- 任一輸入缺少最低所需語義證據；
- 候選群超過配置上限且未能安全分解；
- 模型、embedding 或配置版本未通過目前 gold set 驗收。

#### AI 輸出契約

AI 必須回傳符合 JSON schema 的結構：

```json
{
  "decision": "merge | keep_separate | abstain",
  "confidence": 0.0,
  "evidence_codes": [],
  "conflict_codes": [],
  "summary": ""
}
```

自由文字 `summary` 只供稽核，不參與程式控制。程式只使用列舉值、分數及 evidence／conflict codes。

自動合併必須同時滿足：

- 所有 deterministic blockers 均為 false；
- 至少兩類獨立語義證據一致；
- 兩次獨立、輸入排序不同的模型判定皆為 `merge`；
- 兩次信心分數都高於版本化 `auto_merge_threshold`；
- 使用中的模型、prompt、embedding、feature schema 與 threshold 組合已通過 gold set。

任一 AI 呼叫超時、格式錯誤、結果不一致或回傳 `abstain` 時，候選保持分離。不得以重試多數決逐步降低門檻。

### 7.5 Deterministic compiler

Compiler 讀取已完成 reconciliation 的 staging release 和目前 D1 inventory，產生不可變發布 artifact。

#### Expression 配置

對每個 lexical cluster：

1. 若所有既有 bindings 指向同一 Expression，重用該 ID。
2. 若沒有既有 binding，依 `(lang_code, canonical text)` 查找目前最大 `homograph_index`，在固定排序的 cluster keys 上依序追加。
3. 若同一 cluster 含兩個不同的已發布 Expression bindings，產生 `published_identity_conflict`，不得自行選 winner。
4. 配置結果寫入 artifact；apply 與子集重跑不得再次計算不同 index。
5. 已退役 index 永不回收，數字後綴不表示語義或重要順序。

Compiler 必須在 inventory fingerprint 一致時才能 apply。Inventory 在 plan 後改變，整個 apply 失敗並要求重新 plan，避免併發配置相同 index。

#### Mapping 配置

每個可發布 input sense claim 建立：

- headword lexical cluster 到每個 equivalent lexical cluster 的直接 edge；
- example text cluster 到對應 example translation cluster 的直接 edge。

不得：

- 把同一 sense 的所有節點做 clique；
- 因多個 equivalents 並列便推論它們彼此同義；
- 把 example 與 headword 建立輸入未明示的關係；
- 跨義項按文字去重 target Expression。

同一 pair 若已存在 edge，重用 edge 並新增 evidence。Edge pair 一律按 ID 字典序 canonicalize。

#### Readings 與 POS

- Entry-level reading 掛到該 entry 投影出的所有適用 headword clusters。
- Reading 必須有合法 locale、scheme 與非空 value。
- 相同 reading 依現有唯一語義去重；artifact 仍保留對應的輸入 claim。
- 一個 Expression 可有多個 POS；每個 POS 都是具 claim 與 release 綁定的 attestation。
- 原始 POS 無法映射時，不建立線上詞性，但不阻止其他已驗證欄位發布。

### 7.6 Publisher

Publisher 是 `scripts/dictionary/` 下的可重用工具，不是一次性腳本。它提供：

```text
inspect → stage → reconcile → plan → apply → verify → rollback
```

所有命令支援 JSON 輸出、明確輸入／輸出路徑、非零錯誤碼及 dry run。正式 apply 必須透過現有 `scripts/db` 受管操作記錄與 inventory lock，不提供繞過 guard 的簡寫。

大型 SQL 按 D1 寫入限制分塊。每塊有序號、checksum 與完成 journal；重跑只跳過 checksum 相同且已驗證的 chunk。只有所有 chunks 與全量驗證通過後，release 才能設為 active。

## 8. 線上資料模型

本設計不改 `expressions` 的 identity，也不改 `expression_edges` 的 pairwise 語義。新增下列最小表。

### 8.1 `dictionary_dataset_releases`

記錄不可變 release 與 active 狀態：

```text
id
dataset_key
parent_release_id
input_manifest_hash
exporter_schema_version
adapter_bundle_hash
reconciliation_config_hash
artifact_hash
status: planned | applying | validated | active | failed | rolled_back
created_at
activated_at
```

同一 `dataset_key` 最多一個 active release。相同完整配置與 artifact hash 重跑是 no-op。

### 8.2 `dictionary_expression_bindings`

保存 release 內 input occurrence／cluster 到 Expression 的穩定對應：

```text
release_id
claim_key
cluster_key
role
expression_id
binding_kind: allocated | reused | ai_merged | explicit_group
```

主鍵至少涵蓋 `(release_id, claim_key, role)`。`expression_id` 是外鍵。Compiler 讀取父 release bindings 以維持 identity；不能只靠 `MAX(homograph_index)` 和當次輸入順序重算。

### 8.3 `expression_edge_evidence`

讓同一 edge 可以保留多筆 input claim evidence：

```text
release_id
edge_id
claim_key
evidence_kind: equivalent | example
```

主鍵為 `(release_id, edge_id, claim_key, evidence_kind)`。Edge 本身仍全域唯一；evidence 不影響 score 或 votes。

### 8.4 `dictionary_release_objects`

記錄某一 release 使用的線上物件，以及該物件是本版建立或重用，供 active-release eligibility、verify、rollback 與安全清理：

```text
release_id
object_kind: expression | edge | reading | locale_attestation | pos_attestation
object_id
claim_key
object_action: created | reused
```

這是內部 membership／ownership journal。每個 active release 使用的 reading、locale attestation 與 POS attestation 都必須有 membership，不能只記錄首次建立的 object。它不取代各實體的外鍵或唯一約束；publisher 在寫入前後都必須驗證 object 實際存在且 identity 一致。

### 8.5 `parts_of_speech`

受控詞性 registry：

```text
code
name_en
sort_order
```

第一版只 seed adapters 已能可靠映射的常見詞性。新增 code 需 migration；不得把任意原始 POS 字串臨時寫成 code。

### 8.6 `expression_pos_attestations`

```text
id
expression_id
part_of_speech_code
release_id
claim_key
created_at
```

唯一語義為 `(expression_id, part_of_speech_code, release_id, claim_key)`。Expression 詳情 API 聚合後按 `parts_of_speech.sort_order, code` 穩定回傳；原始 POS 文字不進此表。

### 8.7 Schema 生命週期

以上資料表必須：

- 以當時下一個連續 migration 新增；
- 同步更新 `backend/schema.sql`；
- 更新 schema contract tests 與 migration lock；
- 明確配置 lookup、release activation、edge evidence 與 rollback 所需索引；
- 不在 `schema.sql` 內 seed 大型詞典內容。

## 9. Release 可見性、更新與回退

### 9.1 可見性

Managed mapping 若只由本 pipeline 建立，只有在其 evidence 屬於 active release 時才參與公開 mapping 查詢。Managed reading、locale attestation 與 POS attestation 同樣只有在 active release 具有 membership 時才出現在公開詳情。若同一物件同時有一般使用者或系統建立的關係，release 切換不得隱藏它。

第一版 rollback 的產品保證是「恢復 active release 的 mapping、reading、locale attestation 與 POS 投影」，不是強制刪除所有曾建立的 Expression row。未被 active release 使用的 dictionary-only Expression 可由 verify 報告列為 cleanup candidate；已有其他引用的節點必須保留。

### 9.2 增量更新

新 release 以目前 active release 為 parent：

- 相同 claim key＋相同 fingerprint：直接重用 binding 與決策。
- 相同 claim key＋內容改變：重新 normalize／reconcile，但優先保留既有 Expression identity。
- 新 claim：生成候選並按規則配置。
- 消失 claim：在新 release 中不再 active，但不直接刪除歷史 binding。
- fallback identity 漂移：進 `identity_remap_required`，不得自動視為刪除＋新增。

### 9.3 回退

Rollback 按以下順序：

1. 驗證目標 parent release 仍完整且 artifact checksum 相符。
2. 把目前 release 標為 `rolled_back`。
3. 原子切換 active release 指標。
4. 驗證公開 mapping、reading、locale attestation 與 POS 計數符合 parent manifest。
5. 產生不再被 active release 使用的 object 清單。
6. 只清理沒有任何其他引用、且 identity 與 ownership journal 完全吻合的物件。

清理不是 activation rollback 的前置條件；切換必須先恢復正確可見性，再做可安全重跑的垃圾清理。

## 10. Quarantine 與錯誤處理

標準錯誤碼至少包括：

| 錯誤碼 | 意義 | 發布行為 |
|---|---|---|
| `empty_headword` | canonical headword 為空 | entry quarantine |
| `unknown_direction` | 無法確認語言方向 | claim quarantine |
| `unknown_language` | 不能映射到既有 `lang_code` | occurrence quarantine |
| `unknown_locale` | reading 所需 locale 不存在 | reading quarantine |
| `ambiguous_equivalent` | equivalent 無法可靠原子化 | 該 equivalent quarantine |
| `invalid_reading_scheme` | scheme 未映射或不合法 | reading quarantine |
| `missing_sense_content` | sense 沒有 definition、equivalent、example、POS 或 reading 可供區分／驗證 | sense 關係 quarantine；合法 entry 詞頭仍可獨立發布 |
| `unsupported_pos` | 原始 POS 無可靠 code | 只略過線上 POS |
| `identity_collision` | 同一 key 對應不同 identity | 整個 release 失敗 |
| `identity_remap_required` | fallback key 跨 release 漂移 | 需要人工 mapping |
| `ai_conflict` | AI 判定不一致或違反 blocker | 保持分離 |
| `published_identity_conflict` | cluster 含兩個既有 Expression | 保持舊 binding，阻止該 cluster 更新 |
| `artifact_mismatch` | plan 後 inventory 或檔案改變 | apply 失敗 |

Quarantine item 必須保存原始 JSON、input key、entry／sense 定位、adapter 版本、錯誤碼與結構化 detail。修正 adapter 後可以按 dictionary、錯誤碼或 claim keys 子集重跑。

單一普通資料錯誤不必阻止其他安全記錄進入 artifact；identity collision、artifact mismatch、schema mismatch、計數不守恆或 active-release invariant 破壞屬 release 級錯誤，必須整體阻止 apply／activation。

## 11. AI 評測與門檻

### 11.1 Gold set

Gold set 必須分層涵蓋：

- 22 部詞典各自的 adapter；
- 各語言與雙向區段；
- 同文同義、同文近義、同文異義；
- 詞性衝突、專名、縮寫、語用差異；
- definitions／examples 缺失或互相矛盾；
- equivalent 鄰域重疊但語義不同；
- 明示 homograph marker；
- 已發布 binding 與新增 claim 的對齊。

Gold set 與 holdout 都以穩定 claim keys 保存；訓練／調參資料與最終 holdout 不得重疊。

### 11.2 啟用條件

自動合併功能只有在以下條件全部成立時啟用：

- holdout 中至少有 1,000 個會落入 auto-merge 路徑的已標註候選；
- auto-merge precision 點估計至少 99.5%；
- Wilson 95% confidence interval 下限至少 99.0%；
- deterministic blocker 測試零違反；
- 每個啟用 auto-merge 的 adapter 都有代表性樣本；樣本不足的 adapter 只能 `keep_separate` 或 `abstain`；
- 兩次判定一致率符合 release manifest 設定，且所有實際自動合併個案均為雙次 `merge`。

Recall 只報告，不設為放寬 precision 的理由。任何模型、prompt、embedding、feature schema 或 threshold 變更都形成新的 reconciliation config hash，必須重新通過評測。

### 11.3 稽核與重現

每筆 decision 保存：

- candidate keys；
- features fingerprint；
- 模型與配置版本；
- 兩次結構化輸出；
- deterministic blockers；
- 最終 decision 與理由碼；
- 是否被人工 override。

完整 prompt 及 definitions 等內容只存在離線 artifact；線上只保存 release config hash、binding kind 與摘要計數。

## 12. `cod` 必要驗收案例

繁中英 fixture 必須包含原始三筆 `cod` entry：

| 顯示詞頭 | canonical text | 預期鄰域 |
|---|---|---|
| `cod 1` | `cod` | 魚類義項 |
| `cod 2` | `cod` | 袋、包、莢、殼、陰囊義項 |
| `cod 3` | `cod` | 愚弄、戲弄、玩笑、欺騙、虛假義項 |

驗收必須證明：

1. 線上只有文字為 `cod` 的 Expression，不建立 `cod 1`、`cod 2`、`cod 3` 文字。
2. 三個 entry 投影為三個穩定 homograph Expression IDs。
3. 三個 Expression 的直接鄰域互不混線。
4. `cod 2`／`cod 3` 的細分 senses 完整保存在 staging，但依明示 entry grouping 共用各自 headword cluster。
5. 其他詞典的 `cod` claims 預設分離；只有通過 AI auto-merge 門檻的 claims 才綁到上述既有節點。
6. 其他詞典的 homograph 數字不得被當成與繁中英 `1/2/3` 相同的全域 identity。
7. Equivalent 端若有同文異義，也要配置不同 homograph Expression，不能從另一端重連三組鄰域。
8. 同一 release 重跑、打亂輸入順序及子集重跑後，三個 Expression IDs 與 bindings 不變。

## 13. API 與產品行為

### 13.1 Expression 詳情

`GET /api/v2/expressions/:id` 增加穩定排序的 `parts_of_speech`：

```json
{
  "parts_of_speech": [
    { "code": "noun", "name_en": "noun" }
  ]
}
```

同一 code 的多筆 attestations 聚合成一個顯示項；原始 POS、definitions、labels、AI 分數及 claim keys 不透過公開 API 回傳。

### 13.2 Mapping 查詢

所有讀取 mapping 的 service 必須套用同一個 active-release eligibility helper，不能在各 route 複製條件。Graph、詳情、搜尋 mapping count、feed 與 localization 等消費者必須保持一致。

查詢仍按既有 score、created time 與 ID 規則穩定排序，並保持既有數量上限。Dataset release 切換不能讓同一端點在不同 query path 看見不一致的 managed edges。

Expression 詳情中的 readings、locale attestations 與 POS 使用同一 active-release membership helper；既有一般使用者或系統資料不受 release 過濾。不得只在 mapping 查詢實作 activation，卻讓已回退 release 的 reading 或 POS 繼續顯示。

### 13.3 內部操作介面

第一版不新增公開 release API。操作入口是 `scripts/dictionary/` CLI 與現有 `scripts/db` 管理流程。品質報告、AI decision 與 quarantine 使用 JSON／SQLite 查詢，不新增管理頁。

## 14. Artifact 內容

每個 release artifact 目錄至少包含：

```text
manifest.json
quality-report.json
bindings.jsonl
reconciliation-decisions.jsonl
quarantine.jsonl
sql/
  0001-....sql
  0002-....sql
rollback/
  manifest.json
```

`manifest.json` 至少記錄：

- release ID 與 parent release ID；
- input files 的相對識別、大小與 checksum；
- exporter schema version；
- adapter bundle checksum；
- AI reconciliation config hash；
- D1 inventory fingerprint；
- 各 object 類型預期新增、重用、停用與 evidence 數量；
- quarantine 分類計數；
- 每個 SQL chunk 的順序、大小與 checksum；
- artifact 整體 checksum。

Artifact 路徑由 CLI 明確指定。臨時 SQL 可在 apply／verify 完成後刪除，但 manifest、quality report、bindings 與 reconciliation decisions 必須保留，因為它們具有重現、稽核與回退價值。

## 15. 驗證

### 15.1 Exporter 與 adapter tests

- 每部詞典至少一組 golden fixture；特殊結構各有針對性 fixture。
- 驗證語言方向、headword／marker 分離、DOM sense 順序、equivalent 原子化、reading scheme、locale 與 POS。
- 驗證 `#`、`#9110`、空詞頭、重複詞頭與 fallback identity。
- 相同輸入重跑得到 byte-stable JSONL 與 manifest。
- Exporter 失敗不留下可被誤認為完整輸出的目標檔。

### 15.2 Pipeline unit tests

- canonical text 與 expression hash 對齊現有 TypeScript identity service。
- lexical occurrence grouping 不跨 sense 誤合併。
- equivalent mapping 採星形而非 clique。
- example 只建立明示 pair。
- homograph allocator 只追加、不回收、不受輸入順序影響。
- AI schema、blockers、雙次判定與 threshold 邏輯。
- 所有 quarantine 錯誤碼及 release 級錯誤。

### 15.3 SQL／D1 tests

- migration 與 `backend/schema.sql` 契約一致。
- 以開啟 foreign keys 的 SQLite 載入等價 schema，執行真實 artifact SQL。
- 同一 artifact 執行兩次，各表計數不變。
- 所有 edge 端點存在、`a < b`、沒有 self-edge 或重複 pair。
- 每個已發布 claim 有 binding；每條 managed mapping 有 active evidence。
- activate、apply 中斷續跑、inventory mismatch、verify failure 與 rollback 都有整合測試。
- 一般使用者建立的 mapping、votes 與 handbook 引用不因 release rollback 消失。

### 15.4 全量 dry run

正式 apply 前必須滿足：

```text
input records = staged records
staged claims = published claims + quarantined claims + explicitly skipped claims
```

並驗證：

- 沒有空 Expression；
- 沒有未知 `lang_code`；
- 沒有非法 locale 或 reading scheme；
- 沒有未解析的 published identity conflict；
- 排序、ID、SQL 與 manifest checksum 可重現；
- artifact 與 D1 預估大小不超過當前環境配置；
- 每批寫入量不超過 importer 的安全配置；
- 品質報告按詞典、語言、錯誤碼、POS、AI decision 與 object kind 彙總。

### 15.5 效能驗收

- JSONL、staging 讀取與 artifact 生成全部採串流或有界批次。
- 全量 pipeline 不得把所有 entries、equivalents 或 edges 同時放入記憶體。
- 大型 join／candidate generation 依 staging 索引執行，並有 query plan 測試。
- Candidate group、圖遍歷與 SQL chunk 都有明確上限及穩定分頁。
- 失敗續跑從 journal checkpoint 恢復，不重做已驗證 chunk。

## 16. 本地與正式環境生命週期

詞典資料不寫入 `backend/schema.sql`，也不作普通 schema seed。

本地開發：

- 一般 `local rebuild` 保持輕量，不預設載入兩百萬筆完整 corpus。
- `scripts/dictionary` 提供小型 fixture release，供 schema、API 與 `cod` 整合測試。
- 需要完整 corpus 時，以明確 CLI 套用指定 release artifact。
- 本地 inventory／fingerprint 在套用 corpus 後記錄 active dictionary release。

正式環境：

- 先 `plan` 產生 immutable artifact 與 inventory fingerprint。
- 透過 `scripts/db` 的受管資料操作執行 `apply`。
- apply 完成後執行 counts、FK、identity、edge eligibility 與抽樣查詢。
- 所有驗證通過才 activation；失敗保持舊 release active。

## 17. 分階段交付

### Phase 1：Exporter v2 與資料稽核

- 修正 exporter schema 與已知抽取問題。
- 重新輸出 22 個 JSONL。
- 建立全量 coverage／diagnostics 報告。

驗收：每筆輸入記錄都有 v2 entry 或明確 exporter error；同一輸入重跑 byte-stable。

### Phase 2：Staging、adapters 與 `cod` vertical slice

- 建立 staging schema、loader、manifest 與 quarantine。
- 先完成繁中英 adapter。
- 走通 `cod` 三個 homograph 的 Expression／mapping／reading／POS artifact。

驗收：通過第 12 節全部條件，artifact SQL 可重跑。

### Phase 3：線上最小資料層與 release publisher

- 新增 release、binding、edge evidence、ownership、POS tables。
- 接入 active-release mapping eligibility。
- 完成 plan／apply／verify／rollback。

驗收：fixture release 可安全切換與回退，不影響一般使用者資料。

### Phase 4：AI reconciliation

- 建立 candidate features、gold set、雙次判定與決策 artifact。
- 達到第 11 節門檻後，逐 adapter 啟用 auto merge。
- 未達門檻的 adapter 保持分離。

驗收：holdout 指標、blocker 測試與 decision 重現全部通過。

### Phase 5：全量 release

- 完成其餘 adapters。
- 執行全量 stage、reconcile、compile 與 dry run。
- 修正 release 級錯誤；一般 quarantine 依報告保留。
- 套用並驗證第一個全量 active release。

驗收：第 15.4 節守恆式與全部全量檢查通過。

## 18. 成功標準

設計完成實作後，必須能證明：

1. `cod` 等同文多義詞擁有彼此隔離、可穩定重現的 Expression 鄰域。
2. 跨詞典同義 claims 可由達標 AI 自動綁定到同一 Expression；低信心資料不會被強行合併。
3. Definitions、labels、raw POS 與完整 examples 留在離線 staging；線上沒有新增 definitions／labels 模型。
4. 可成對例句成為普通詞句 mapping，沒有建立未明示的例句—詞頭關係。
5. 線上 POS 是受控、可追蹤且穩定排序的多值資料。
6. 相同 release 重跑是 no-op；子集重跑、輸入重排和新增詞典不改變既有 homograph IDs。
7. 每筆輸入 claim 都可對應到發布 binding、quarantine 或明確 skip reason。
8. Release apply 可驗證、可續跑；activation 失敗時舊 release 仍有效。
9. Rollback 恢復上一版可見 mapping／reading／POS，且不破壞一般使用者資料。
10. 全量處理使用串流／有界批次，排序、ID 與 artifact 均 deterministic。
