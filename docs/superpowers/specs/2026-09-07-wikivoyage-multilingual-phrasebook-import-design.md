# Wikivoyage 多語會話手冊匯入設計

> 日期：2026-09-07
>
> 狀態：設計對話已確認，書面規格待覆核；尚未實作

## 1. 摘要

LangMap 將以英文 Wikivoyage 的
[Category:Phrasebooks](https://en.wikivoyage.org/wiki/Category:Phrasebooks)
作為全集入口，下載各語言會話手冊的固定 revision 原始 wikitext，只抽取英文詞句、
非英文目標詞句及目標詞句的 reading。英文與目標詞句分別建立或重用 Expression，兩端以
普通 direct edge 連接；reading 只附著在目標 Expression，不建立羅馬字 Expression。

所有可發布資料最後匯入同一本系統維護的公開 Handbook。Handbook 本身只保存英文
Expression，使用者在閱讀頁選擇精確 `language_locale` 後，前端以批次 API 顯示該 locale
的一跳 direct mapping 與 reading。這使 Handbook 保持單一英文骨架，而翻譯隨 LangMap
圖資料持續成長，不需要為每種語言複製一本手冊。

來源取得採「不可變 wikitext 快照 → Structured JSONL v2 → staging／quarantine →
自然鍵 production delta」流程。下載全集，但按頁面批次審閱及發布；全部資料完成後才首次
發布 Handbook。後續只重新處理發生變化的頁面；新增內容可增量發布，來源移除或內容刪減先
進入刪除審閱，再重建受管 Handbook 的 sections／items。

2026-09-07 盤點時，分類直接包含 326 個成員，其中 317 個是主命名空間頁面、9 個是地區
子分類。此數字只作首批基準；程式必須以每次固定下來的 category manifest 為準，不把 317
寫成長期條件。

## 2. 背景與問題

英文 Wikivoyage 會話手冊通常以 wikitext definition list 表達雙語列：

```text
; Where is the toilet? : トイレはどこですか？ ''Toire wa doko desu ka?''
```

部分頁面另有括號內的英語式發音提示、IPA、多種正字法或多個地域變體。頁面完整度差異
很大：有些內容完整，有些仍保留大量空白範本；Wu 等頁面可在同一列同時列出多個 locale。
直接抽取渲染後 HTML 會弱化「目標文字、羅馬字、英語式發音提示」之間的界線，直接把
API 結果寫入 D1 則缺少可重跑、審閱及回退的中間層。

LangMap 現有模型已具備本功能的大部分能力：

- `expressions` 保存單一語言的詞或句；
- `expression_edges` 保存兩個 Expression 的直接關係；
- `expression_locale_links` 保存精確 locale；
- `expression_readings` 保存指定 locale 與 scheme 的 reading；
- `expression_sources`／`expression_edge_sources` 保存來源聲明；
- `handbooks`、`handbook_sections`、`handbook_section_items` 保存由 Expression 組成的手冊。

現行 Handbook 閱讀頁只列出 item Expression，點擊後才取得一般 mapping graph。若一本英文
Handbook 的同一 item 連到數百種語言，逐 item 請求會形成 N+1；不帶精確 locale 的一般
一跳圖也不適合作為整頁翻譯 API。因此需要一個按 target locale 批次解析 Handbook items
的專用讀取契約。

## 3. 目標

1. 以英文 Wikivoyage Phrasebooks 分類的主命名空間頁面作為可重跑的全集入口。
2. 只匯入可靠成對的英文詞句、非英文目標詞句及目標 reading。
3. 所有發布的目標詞句都以普通 direct edge 連回英文，不經中文或第三種語言推導。
4. 每個發現的頁面及每個解析候選都有明確狀態，禁止靜默遺失。
5. 來源快照、轉換產物、排序、checksum 與 production delta 可重現。
6. 使用既有 Structured JSONL staging、preview、quarantine、自然鍵匯入及受管發布流程。
7. 建立一本系統維護的英文 Handbook，讓使用者選擇精確 locale 後閱讀雙語詞句與 reading。
8. Handbook 翻譯切換採常數次批次查詢，不做逐 item API 請求或線上覆蓋率聚合。
9. 支援頁面級變更偵測、非破壞性增量更新、刪除審閱、批次發布、驗證與回退。
10. 提供足以履行 CC BY-SA 4.0 的來源、revision、授權與頁面歷史入口。

## 4. 非目標

- 不匯入發音教學、文法說明、圖片、旅行敘事、導航文字或長篇正文。
- 不匯入只有英文而沒有非英文目標詞句的列。
- 不使用機器翻譯補齊缺失目標詞句。
- 不以中文 Wikivoyage 作為資料來源或中間 pivot。
- 不透過第三種語言、多跳 graph 或語義相似度推導 direct edge。
- 不把羅馬字、IPA、拼音或英語式發音提示建立為 Expression。
- 不為每種語言建立獨立 Handbook。
- 不新增公開 sense／concept entity。
- 不承諾每個分類頁面都有可發布資料；空白、未知或不可靠資料必須明確列入報告。
- 不在線上 API 計算或顯示每個 locale 的 Handbook 覆蓋率。
- 不修改 `apple/` 客戶端。

## 5. 核心產品模型

### 5.1 單一英文 Handbook

系統建立一本公開 Handbook：

```text
Wikivoyage Multilingual Phrasebook
├─ Basics
│  ├─ Hello.
│  ├─ Thank you.
│  └─ Where is the toilet?
├─ Problems
├─ Numbers
├─ Transportation
├─ Lodging
├─ Eating
├─ Shopping
├─ Driving
└─ Authority
```

Handbook section item 只引用英文 Expression。目標詞句與 reading 不複製進 Handbook 資料表，
而是在讀取時按精確 target locale 由 direct edge 解析：

```text
Hello. (eng)
├─ こんにちは。 (jpn-Jpan-JP)
├─ 你好。 (cmn-Hans-CN)
└─ Bonjour. (fra-Latn-FR)
```

這本 Handbook 使用 nullable `handbooks.managed_key` 作為跨環境自然鍵：

```text
managed_key = enwikivoyage-phrasebooks
```

`managed_key` 需要新增 migration 並同步 `backend/schema.sql`，同欄建立 unique index。一般
Handbook 的值為 `NULL`，行為不變。公開建立／更新 API 不接受此欄；`managed_key` 非空的
Handbook 不可經一般 PUT／DELETE 修改，更新只能由受管資料發布流程執行。GET 回傳
`managed: true` 與 `can_edit: false`，前端不顯示編輯入口。

首次發布以系統帳號 `langmap` 持有；production preflight 若找不到該帳號即停止。後續更新
只替換該 Handbook 的 sections／items，不刪除 Handbook row，因而保留 production ID、URL、
投票、建立時間與其他外部引用。`language_locale_id` 指向 canonical `eng-Latn-US`；該 locale
缺失時 preflight 失敗，不以其他英語 locale 猜測替代。

### 5.2 顯示模型

選擇 target locale 後，每個 item 顯示：

```text
Hello.
こんにちは。
Konnichiwa.
```

- 第一層是 Handbook 保存的英文 Expression。
- 第二層是所選 locale 的零至多個 direct mappings。
- 第三層是各目標 Expression 在同一精確 locale 下的 readings。
- 多個有效目標詞句全部顯示，不任意壓成一筆。
- 沒有 direct mapping 時顯示「暫無翻譯」，不作跨 locale 或多跳回退。

## 6. 整體架構

```text
English Wikivoyage Category:Phrasebooks
  → category discovery manifest
  → pinned revision wikitext snapshots
  → page catalog + deterministic parser
  → per-page Structured JSONL v2
  → existing dictionary staging SQLite
  → WikivoyagePhrasebookAdapter
  → preview / quarantine / quality report
  → canonical local mirror
  → checksum-locked natural-key delta
  → managed production plan/apply
  → generated English Handbook
  → locale-filtered batch translation API
```

新程式集中在 `scripts/wikivoyage/`，只負責 discovery、下載、page profile、解析與 Handbook
artifact 產生。正規化與 canonical 匯入沿用 `scripts/dictionary/langmap_dictionary/`，新增
一個範圍明確的 Wikivoyage adapter，不另建第二套 staging 或 production publisher。

建議目錄：

```text
scripts/wikivoyage/
  README.md
  download.py
  export_phrasebooks.py
  build_handbook.py
  page-catalog.json
  section-catalog.json
  tests/
    fixtures/
scripts/dictionary/langmap_dictionary/adapters/
  wikivoyage_phrasebook.py
```

原始快照與大量 JSONL 預設寫到呼叫者指定的外部 artifact 目錄，例如
`/Volumes/DATA/langmap-wikivoyage/`，不提交進 Git。程式、catalog、小型測試 fixture、規格與
最終受管 SQL／manifest 依現行 repository 規則版本化。

## 7. 下載與不可變快照

### 7.1 Discovery

Downloader 透過英文 Wikivoyage MediaWiki API 枚舉 `Category:Phrasebooks`，只取 namespace
`0` 頁面。地區子分類不遞迴作為另一份來源，避免同一頁因直接分類與子分類重複出現。

每次 discovery 產生排序穩定的 manifest。頂層至少包含 `schema_version = 1`、
`site = enwikivoyage`、`category = Category:Phrasebooks`、`license = CC BY-SA 4.0`、
`discovered_at` 與 `pages`。每個 page descriptor 至少包含：

- 整數 `pageid`；
- `title` 與 `canonical_url`；
- 整數 `revision` 與 ISO 8601 `revision_timestamp`；
- 由 pageid 與 revision 組成的 `snapshot_file`，例如
  `pages/16153-5332510.wikitext`；
- 符合 `^[0-9a-f]{64}$` 的 `snapshot_sha256`。

Manifest 的 `discovered_at` 反映該次真實下載，不參與內容 identity。頁面依 `pageid` 排序；
序列化使用固定 UTF-8、key 順序與換行。所有頁面完成下載及 checksum 後才原子替換 manifest，
失敗不得留下看似完整的快照。

### 7.2 HTTP 行為

- 使用描述 LangMap 與聯絡入口的明確 User-Agent。
- 支援 MediaWiki continuation，不假設單頁回應包含全集。
- 對 `429`、可重試 `5xx` 及暫時網路錯誤採有上限的 exponential backoff，遵守 `Retry-After`。
- 設定連線與讀取 timeout；永久錯誤回傳非零狀態。
- 限制並行請求數，不對 Wikimedia API 造成突發負載。
- 已存在且 checksum 正確的 pinned snapshot 可重用；不得以新 revision 內容覆寫舊檔。
- 下載只取得公開資料，不需要登入、cookie 或 API token。

### 7.3 頁面狀態完整性

每個 discovery 頁面在 export report 中必須恰好屬於一種狀態：

- `included`：至少產生一筆有效候選；個別列仍可另有 row-level quarantine；
- `empty`：頁面存在，但沒有完整雙語列；
- `excluded`：不是具體的非英語語言會話手冊；
- `blocked`：language／locale 尚未在 LangMap registry 中完成建模；
- `quarantined`：頁面級結構有歧義，無法安全發布任何候選。

`Hitchhiking phrasebook`、`Learning Devanagari` 等非目標語言手冊可列為 `excluded`；排除原因
必須在 `page-catalog.json` 明示。任何頁面不得因 parser 沒有命中而靜默消失。

## 8. Page catalog 與 Registry

### 8.1 明確 identity

`page-catalog.json` 以 `pageid` 為穩定鍵，明確記錄：

- canonical title；
- `language.code`；
- 一至多個 `language_locale.code`；
- 預設 writing system；
- reading scheme 規則；
- 單頁多 locale 的拆分規則；
- include／exclude 狀態及原因。

標題只用於顯示與 drift 報告，不能用字串截去 `phrasebook` 後直接猜 ISO code。Wikidata、
頁面 `Lang` template 或標題可協助產生 catalog 候選，但正式匯出只能使用已審閱的 catalog。

### 8.2 Registry gate

目標 language 必須已存在於 `languages`；目標 locale 必須已存在於 `language_locales`，且
language、script、orthography、region 與 place identity 正確。Importer 不因 Wikivoyage 頁面
標題而自動建立名稱僅等於 code 的臨時 locale。

缺失 identity 時把整頁標為 `blocked`。需要新增 registry 資料時，另依 language reference
流程更新 seed／migration 並驗證後，才重新執行該頁匯出。

## 9. Parser 與 Structured JSONL

### 9.1 解析範圍

Parser 讀取 pinned raw wikitext，以結構化 wikitext parser／AST 處理 template、link、italic、
括號與 definition list；不以單一跨全文 regex 解析巢狀 wikitext。只接受會話列表章節中的
definition list 或 page profile 明確允許的等價表格。

候選列必須同時具有：

1. 非空英文提示；
2. 非空且非純占位符的目標文字；
3. catalog 能唯一確定的 target language 與 locale；
4. 可還原到 page、revision、section 與 row 的定位。

Parser 移除顯示 markup，但保留語言文字本身的標點、大小寫與 placeholder。Expression
canonicalization 沿用現有 `trim`＋Unicode normalization 契約，不做模糊標點合併或同義改寫。

### 9.2 穩定鍵

每頁輸出一份 Structured JSONL v2；以下以變數名稱描述穩定鍵的組成：

```text
dictionary_key = "enwikivoyage:" + decimal_pageid
entry_key      = join(":", decimal_pageid, section_key, sha256(english_text), occurrence)
```

`english-text-hash` 由 canonical English text 計算；`occurrence` 只區分同頁同章節中的完全相同
英文提示。Revision 不進入 `dictionary_key` 或 `entry_key`，以免上游編輯後把所有資料視為新
identity；revision 保存在 header、raw metadata、fingerprint 與 provenance marker。

一筆有效候選的語義形狀是「目標詞句作 headword、英文作 equivalent」。以下只展示與本功能
有關的核心欄位；`record_fingerprint`、`forms`、`diagnostics` 等共同必要欄位仍須完整遵守既有
Structured JSONL v2 契約：

```json
{
  "record_type": "entry",
  "schema_version": 2,
  "dictionary_key": "enwikivoyage:16153",
  "entry_key": "16153:basics:10c0accd59fdc72c62ac403b30d94ddc058db54f2f319a970c18fec4b9e490d6:1",
  "raw_headword": "トイレはどこですか？",
  "canonical_headword": "トイレはどこですか？",
  "direction_hint": "jpn-to-eng",
  "pronunciations": [
    {
      "value": "Toire wa doko desu ka?",
      "scheme": "hepburn",
      "locale": "jpn-Jpan-JP"
    }
  ],
  "senses": [
    {
      "sense_key": "16153:basics:10c0accd59fdc72c62ac403b30d94ddc058db54f2f319a970c18fec4b9e490d6:1:sense:1",
      "ordinal": 1,
      "equivalents": [
        { "value": "Where is the toilet?", "language": "eng" }
      ]
    }
  ],
  "raw": {
    "pageid": 16153,
    "revision": 5332510,
    "section_key": "basics",
    "section_title": "Basics",
    "row": 24,
    "source_wikitext": "; Where is the toilet? : ..."
  }
}
```

Header 的 `dictionary_key`、input checksum、entry count 與 exporter version 遵守既有 Structured
JSONL v2 契約。Loader 相容欄位 `csv_row_number` 使用該頁會話候選的 1-based 文件順序；真正
來源位置另由 `raw.section_key`、`raw.row` 與原始 wikitext 保存。每筆 `record_fingerprint` 涵蓋
所有會影響發布結果的正規化資料。

### 9.3 多目標與多 locale

- 同列有多個明確可分的目標詞句時，每個目標詞句各產生一筆 entry，映射到同一英文詞句。
- 同列有 Suzhou／Shanghai 等明確標籤時，依 page catalog 拆成各自 locale、文字及 reading。
- 同一文字可連到多個經明示的 locale，沿用單一 Expression 並建立多個 locale links。
- 無法判斷某段文字屬於哪個 locale 時，整個歧義單元進 quarantine，不以字元集猜測。
- 同一語言多個有效譯法全部保留；不得只取第一筆。

### 9.4 Reading 規則

Reading 只附著在目標 Expression，且必須帶精確 locale：

- 明示 IPA template 或可靠 IPA 欄位正規化為 `ipa`；
- page profile 明示 Pinyin、Jyutping、Hepburn、Tailo 等標準時使用既有標準 scheme code；
- 結構明確為羅馬字但無法可靠命名標準時使用 `wikivoyage-romanization`；
- 括號內明確為英語式音節發音提示時使用 `wikivoyage-respelling`，不得標為 IPA；
- 目標文字本身使用 Latin script 時，不因字母外觀自動把相鄰文字當 reading；
- 空字串、純標點、目標文字重複、註解及同音字提示不得進 reading；
- CJK 字元出現在 romanization／IPA 候選時，該 reading 進 quarantine；
- reading 無法可靠分類時，只隔離 reading；若雙語詞句仍可靠，expression 與 edge 可繼續成為候選。

## 10. Canonical 投影與來源

### 10.1 Wikivoyage adapter

新增 `WikivoyagePhrasebookAdapter`，只接受 `dictionary_key` 前綴
`enwikivoyage:`。Adapter 負責：

- 以 catalog 指定 language／locale，不重做語言猜測；
- 把 target headword、English equivalent 與 readings 投影成現有 normalized occurrence；
- 驗證每條 mapping 恰好連接 `eng` 與一個非英語 language；
- 禁止 definitions、labels、forms 或正文誤投影為線上資料；
- 為每個失敗單元輸出固定 error code 與 raw location。

既有 normalize 入口依 `dictionary_key` 明確 dispatch adapter；非 Wikivoyage 詞典繼續使用原
adapter，不因新增規則而改變輸出。

Canonical 寫入沿用現有 identity：同一 `(language_id, text)` 重用
`homograph_index = 1` 的 Expression；不依 Wikivoyage page 或 revision 增量建立同形詞。Edge 端點
依整數 ID 排序並使用普通 direct mapping relation mask。相同 edge 可由多個 Wikivoyage 頁面或
其他來源共同聲明。

### 10.2 Source 與 provenance

每個 Wikivoyage 頁面是一個穩定 URL source：

```text
type = url
name = https://en.wikivoyage.org/wiki/Japanese_phrasebook
```

Expression／edge marker 保存 revision 與原始位置：

```text
oldid:5332510#basics/24
```

`expression_readings` 現有模型只有 `source_id`，因此 reading 連到該頁的 canonical URL；精確
revision 由 checksum-locked snapshot manifest 保留。這項限制可滿足可重現與頁面歷史歸因，
不為單一資料集新增 reading claim 表。

Handbook 頁底顯示資料經 LangMap 抽取及正規化、改編自 English Wikivoyage，並提供
CC BY-SA 4.0 授權及分類入口。譯文詳情提供 canonical page URL；expression／edge provenance
能進一步定位 revision 與列。來源顯示不得把 Wikivoyage 描述為 LangMap 原創內容。

Repository 程式碼維持 Apache-2.0；Wikivoyage 衍生的快照、JSONL、資料庫內容與 Handbook
內容保留 CC BY-SA 4.0。實作需新增清楚的第三方內容授權／attribution notice，並在可下載的
資料 artifact 與 API 文件中指出這項內容授權邊界，不能只依 repository 根目錄的程式碼
`LICENSE`。頁面 URL／history、固定 revision、改編說明與授權連結共同構成 attribution 資訊。

## 11. Handbook 生成

### 11.1 Section catalog

`section-catalog.json` 保存 canonical section key、英文顯示名稱、固定順序與已審閱 aliases。
例如 `Basic`、`Basics`、`Basic phrases` 可映射至 `basics`，但不以任意 substring 合併。

標準 section 依 catalog order 排列。無法映射但確實含有效會話列的自訂 section 仍保留，依
canonical English title、pageid 排在標準 section 後；同名自訂 section 使用同一 section。

### 11.2 Item union

- 以所有 `included` 頁面已發布的英文 equivalent 建立 item union。
- 同一 canonical section 內完全相同的英文 Expression 只出現一次。
- 相同英文 Expression 可在不同 section 重複引用，因為章節提供使用情境。
- 標準模板詞句依 section catalog 的顯式順序排列。
- 額外詞句依 canonical English text 穩定排序；position 不依環境特有的 Expression ID。
- 不使用模糊相似度合併 `Where is the toilet?` 與 `Where's the toilet?`。

Builder 產生自然鍵 SQL／artifact，以 `managed_key = enwikivoyage-phrasebooks` 解析 Handbook，
先重建其 sections／items，再做 foreign key 與 count 驗證。任何失敗必須整體回滾，不留下半本
Handbook。

## 12. API 設計

### 12.1 既有 detail 相容

`GET /api/v2/handbooks/:id` 保持現有 sections／items 契約，增量加入：

```json
{
  "managed": true,
  "can_edit": false
}
```

一般 Handbook 依目前登入者與權限計算 `can_edit`。前端只依 `can_edit` 顯示編輯入口，不以
username 或固定 ID 猜測。

### 12.2 批次翻譯 API

新增：

```http
GET /api/v2/handbooks/:id/translations?target_locale=jpn-Jpan-JP
```

Endpoint 同時接受既有 `ui_locale` 與 `secondary_ui_locale` 顯示偏好，供共用名稱解析器產生
`language_name`；兩者不影響 target identity 或 mapping 選擇。

成功回應沿用 `{ success, data }` envelope：

```json
{
  "success": true,
  "data": {
    "target_locale": "jpn-Jpan-JP",
    "items": [
      {
        "source_expression_id": "123",
        "translations": [
          {
            "id": "456",
            "text": "こんにちは。",
            "lang_code": "jpn",
            "language_locale_code": "jpn-Jpan-JP",
            "language_name": "Japanese",
            "readings": [
              { "scheme": "hepburn", "value": "Konnichiwa." }
            ]
          }
        ]
      }
    ]
  }
}
```

查詢規則：

1. 驗證 Handbook 存在且呼叫者可見。
2. 精確解析 `target_locale`；未知、空白或不合法值回傳 `400 INVALID_LANGUAGE_LOCALE_CODE`。
3. 只處理該 Handbook 中 `eng` items 的一跳 direct edges。
4. 目標 Expression 必須具有所選 locale link，edge relation mask 必須包含 mapping 且
   `score >= 0`。
5. Reading 必須屬於同一精確 locale，不跨 locale 回退。
6. 沒有翻譯的 source item 不出現在 `items`；前端由缺席狀態顯示「暫無翻譯」。
7. 不限制為 Wikivoyage source。社群或其他詞典建立的合格 direct mapping 會自動補充 Handbook。
8. 多個譯文依 Wikivoyage source 優先、edge score 降冪、target text、target ID 排序；reading
   依 scheme、value 排序。

不新增 `/handbooks/:id/locales` 或 coverage API。目標選擇器直接使用既有
`/language-locales` 搜尋；選到沒有翻譯的 locale 是合法狀態。

### 12.3 效能形狀

翻譯查詢不得以每個 Handbook item 執行一次 SQL。Edge 的兩個方向使用兩個定向查詢
`UNION ALL`，分別利用 `(expression_a_id, expression_b_id)` unique index 與
`idx_expression_edges_b_id`，避免 `OR` adjacency 掃描。查詢由 Handbook sections／items 與
精確 target locale 限定，只回傳實際命中的 translation 和 reading。

Route 最多使用固定數量的批次查詢：可見性／locale 驗證、translation rows、reading／顯示名稱
補充；不得隨 item 數量線性增加 query count。實作完成後以 `EXPLAIN QUERY PLAN` 驗證兩個 edge
方向及 locale link 使用既有索引；只有實測顯示缺少索引時才新增 migration。

公開回應可按 Handbook ID、target locale、內容 revision 快取。第一版不建 coverage table、
translation cache table 或其他衍生資料表。

## 13. 前端互動

### 13.1 Locale selector

Handbook 頂部增加可搜尋的 locale combobox，沿用現有 `LanguageLocalePicker` 的鍵盤操作、可見
focus、accessible name 與 localized display name。選擇器允許所有已註冊 locale，不承諾每個
locale 已有翻譯。

URL 參數固定為：

```text
?target_locale=jpn-Jpan-JP
```

初始選擇順序：

1. 有效 URL query；
2. 此瀏覽器上次選擇的 Handbook target locale；
3. 未選擇，僅顯示英文。

無效 URL query 不觸發模糊 prefix 猜測；顯示可理解的選擇錯誤並保留英文內容。

### 13.2 載入與競態

- 首次 detail 請求取得英文 sections／items。
- 選擇 locale 後只呼叫 translations API，不重新下載 Handbook detail。
- 英文內容在翻譯載入期間保持可讀，目標區顯示 skeleton。
- 快速連續切換會 abort 舊請求，並以 request token 防止遲到回應覆蓋新 locale。
- 成功結果按 `Handbook ID + target locale + content revision` 在前端 session cache 重用。
- 翻譯請求失敗不使 Handbook 整頁失敗；目標區顯示可重試錯誤。

### 13.3 Item 與 Inspector

每個 item 顯示英文、零至多個目標詞句與各自 readings。目標詞句是可聚焦按鈕；點擊後以
現有 expression detail／inspector 顯示 locale、reading、來源及關係，再由完整連結前往
`/mapping/:id`。英文 item 仍可開啟其完整 graph。

Managed Handbook 不顯示編輯按鈕。頁底顯示 Wikivoyage attribution 與 CC BY-SA 4.0 link。

桌面版保持目錄、內容與 inspector 三欄；行動版使用單欄雙語列及既有 inspector drawer。
英文、目標詞句與 reading 必須允許換行及 `overflow-wrap`，不可被長詞句撐破；觸控目標至少
44px。雙語內容使用實際文字而非只靠顏色區分，screen reader 能按英文、譯文、reading 順序
朗讀。

## 14. 錯誤與 Quarantine

### 14.1 下載錯誤

- Category continuation 中斷、頁面 revision 不存在、checksum 不符或部分檔案缺失：整次
  snapshot 失敗，不替換既有 manifest。
- 頁面在 discovery 後被刪除或移動：依 pageid 重新解析 canonical title；無法取得 pinned
  revision 時標記明確錯誤，不偷偷抓最新版。
- Rate limit 或暫時服務錯誤超過重試上限：回傳非零狀態並保留可續跑進度。

### 14.2 解析錯誤碼

至少使用下列固定錯誤碼：

- `unknown_page_profile`
- `unknown_language`
- `unknown_locale`
- `unsupported_page_kind`
- `empty_english`
- `empty_target`
- `template_placeholder`
- `ambiguous_target_boundary`
- `ambiguous_locale`
- `unknown_reading_scheme`
- `invalid_reading_script`
- `duplicate_entry_key`
- `source_revision_drift`

Quarantine 保存 error code、pageid、revision、section、row、原始 wikitext 與 parser version。
修正 catalog 或 parser 後重新產生整頁 JSONL，不手工修改已生成 artifact。

### 14.3 API 錯誤

- Handbook 不存在或私人 Handbook 不可見：沿用現有 `404` 行為。
- `target_locale` 缺失或無效：`400 INVALID_LANGUAGE_LOCALE_CODE`。
- locale 合法但沒有 mapping：`200` 且 `items=[]`。
- 個別 reading 資料異常：略過該 reading 並記錄可觀測錯誤，不丟棄其他譯文。
- D1 查詢失敗：使用標準 API error envelope；前端保留英文並提供重試。

## 15. 品質門檻

### 15.1 自動 gate

- Discovery 的每個 namespace 0 頁面在 report 中恰好出現一次。
- 每個 `included` 頁面至少有一筆有效 entry。
- 每筆 entry 的 language／locale 均存在於 canonical registry 且彼此一致。
- 每條發布 edge 恰好連接 `eng` 與一個非英語 language。
- 每筆 reading 有非空 value、允許的 scheme、精確 locale 與目標 Expression。
- 空目標、純標點、模板 placeholder 與正文不得發布。
- Romanization／IPA reading 不得包含被對應規則禁止的 script。
- 相同已固定的 snapshot manifest、catalog 與 parser version 必須產生 byte-identical JSONL、
  report 與衍生 release manifest。
- JSONL header entry count、實際 entry count、preview count 與 report count 相符。
- Staging、local mirror 與 production delta 均通過 foreign key check。
- Production source-scoped postflight counts 與 approved manifest 相符。

### 15.2 人工抽查

每個頁面至少抽查第一筆、中間一筆與最後一筆有效資料，核對：

- 英文提示未混入說明或 markup；
- target language、locale、文字邊界正確；
- direct edge 方向與內容合理；
- reading 沒有被建立成 Expression；
- reading scheme 與 locale 合理；
- 原始列能由 provenance 還原。

所有 multi-locale、multiple-target、unknown scheme、script mismatch 與 quarantine 列逐筆審閱。
抽查異常回到 parser、page catalog 或 registry 修正，重新匯出整頁後再抽查；不得在 production
delta 中硬編單列例外。

## 16. 發布與回退

### 16.1 分批發布

完整 snapshot 一次固定，但 target pages 以約 20–30 頁為一批進行 staging、抽查及發布。批次
大小可依資料量縮小，不能以頁面數繞過 D1 CPU 或 SQL 大小限制。

每批流程：

1. 鎖定 snapshot、page catalog、parser 與 JSONL checksum。
2. 匯入 disposable staging SQLite。
3. 產生 preview、quality report、quarantine 與來源摘要。
4. 匯入 canonical local mirror，執行 source-scoped verify。
5. 產生 checksum-locked natural-key delta 與 manifest。
6. 以產出的 delta 路徑執行 `manage.sh production plan --approved-data-migration DELTA_PATH`。
7. 確認 bookmark 後執行 production apply。
8. 對 production 執行 source-scoped postflight。
9. 刷新 `language_statistics`。

首次必須等所有可發布頁面完成後，才產生並發布
`managed_key = enwikivoyage-phrasebooks` Handbook，避免先發布大量明知沒有對應資料的英文 item。
被標為 `empty`、`excluded`、`blocked` 或 `quarantined` 的頁面仍列在最終 corpus report，不被
假裝成已完成。

### 16.2 更新

更新先產生新 discovery manifest，依 pageid 比較 revision 與 snapshot checksum，只重新處理
變更、新增或已移除的頁面。由於 canonical Expression／edge 可被多個頁面、其他詞典及社群
共同使用，而 `expression_readings` 目前又只有單一 `source_id`，第一版不自動執行破壞性的
source replace。

更新流程把新舊頁面 artifact 依自然鍵分成：

- `added`：可沿用正常品質 gate 與受管 delta 增量發布；
- `unchanged`：不產生 SQL；
- `removed`／`changed-away`：產生 deletion review artifact，列出 expression claim、edge claim、
  reading、Handbook item 及所有其他來源／使用者引用，不自動刪除；
- `identity-changed`：舊、新 identity 並列進人工審閱，不能只新增新列後把舊列視為已清理。

經人工確認的移除另產生最小受管 delta：先移除該頁的 provenance；只有在沒有其他來源聲明、
沒有使用者建立者／投票、沒有 Handbook 或 registry 引用，且 foreign-key preflight 通過時，
才可刪除 canonical edge／Expression。Reading 若由該頁持有但可能有未能表達的共用支持，預設
保留並列入報告，不自動刪除。若未來新增多來源 reading claim 模型，再另立規格放寬此限制。

所有核准的新增與移除發布完成後重新生成 Handbook item union；未核准移除之前，既有
Handbook item 與 graph 資料保持可用。

### 16.3 回退

每次 production apply 前保留 bookmark。失敗批次不繼續後續批次。回退以 bookmark 或反向
受管 delta 恢復該批 source claims；不得使用未經 inventory／checksum 驗證的直接 remote
migration apply。

Handbook 更新只替換 sections／items；回退恢復上一版結構，不刪除 Handbook row，投票與 URL
保持不變。

## 17. 驗證與測試

### 17.1 Downloader

- MediaWiki continuation 能完整合併多頁結果並按 pageid 排序。
- Namespace 14 子分類不進入 page snapshot。
- 429／Retry-After、可重試 5xx、timeout 與永久 4xx 行為正確。
- Pinned revision 已存在且 checksum 相同時重用；不同內容不得覆寫舊檔。
- 任一頁下載失敗時不原子替換 manifest。
- 測試只使用錄製 fixture／mock HTTP，不依賴即時網路。

### 17.2 Parser 與 adapter

Fixtures 至少涵蓋：

- Japanese：目標文字、標準羅馬字與括號 respelling；
- Wu：同列 Suzhou／Shanghai 多 locale；
- Arabic 或 Hebrew：RTL 文字；
- Cantonese／Mandarin：CJK 目標與 Jyutping／Pinyin；
- Latin-script target：不得把目標文字誤判為 reading；
- IPA template；
- 多個 target variants；
- 空白範本、註解、infobox 與正文排除；
- 未知 heading 與 custom section；
- 不合法 reading script 進 quarantine；
- 同一輸入重跑 byte-identical。

Adapter 測試驗證 target headword、English equivalent、locale、reading、source marker 與 error
code。不得建立 reading Expression，不得建立 target-target 或 English-English edge。

### 17.3 Canonical import

- 相同 `(language, text)` 重用既有 Expression。
- 同一英文詞句由多頁支持時只保留一個 Expression，edge source claims 可多筆共存。
- 相同 target reading 重跑不重複。
- 更新差異能穩定分成 added、unchanged、removed／changed-away 與 identity-changed。
- 未經 deletion review 核准不得刪除既有 claim、reading 或 canonical data。
- 自然鍵 delta 可在 mirror 重播且 counts 不變。
- 每批發布後 `language_statistics` 與 canonical tables 一致。

### 17.4 Handbook API

- Managed Handbook 不能經一般 PUT／DELETE 修改，且 `can_edit = false`。
- translations API 同時涵蓋 edge 的 A、B 兩種端點方向。
- 只回傳一跳 direct edge、`score >= 0` 且具有精確 target locale link 的 Expression。
- 同 language 不同 locale 不交叉回退。
- Reading 只回傳所選精確 locale。
- 多譯文與多 reading 排序穩定。
- 合法但零命中 locale 回傳 `200 items=[]`。
- 私人 Handbook 可見性與既有權限不退化。
- SQL query count 不隨 Handbook item 數量線性成長。
- `EXPLAIN QUERY PLAN` 證明兩個 edge 方向與 locale lookup 使用索引。

### 17.5 Web

- 未選 locale 時只顯示英文。
- URL `target_locale`、上次選擇與空狀態優先順序正確。
- 選擇 locale 只請求 translations，不重新請求 Handbook detail。
- 快速切換時舊回應不得覆蓋新 locale。
- 多譯文、多 reading、零譯文與 API error 狀態可讀。
- Managed Handbook 不顯示編輯入口。
- 目標譯文可開啟 Inspector 及 `/mapping/:id`。
- Desktop 與 mobile viewport 不被長詞句、RTL 或多 reading 撐破。
- Combobox、雙語 item、retry 與 Inspector 支援鍵盤、可見 focus 及 accessible name。
- `prefers-reduced-motion` 下不加入非必要切換動效。

### 17.6 全流程驗收

1. 使用固定 fixture snapshot 產生 manifest、JSONL、report 與 Handbook artifact。
2. 在乾淨 local D1 匯入至少 Japanese、Wu、Cantonese 與一個 RTL page。
3. 執行相關 pytest、backend Vitest 與 Web component tests。
4. 啟動本地 Worker，驗證 Handbook 英文骨架與至少四個 target locales。
5. 驗證來源連結、revision marker 與 CC BY-SA 4.0 說明。
6. 執行 `cd web && npm run build`、相關後端測試、`./build.sh` 與 `git diff --check`。
7. 在 production plan 階段核對 checksum、bookmark、source-scoped counts 與統計刷新，不以測試
   結果宣稱 production 已發布。

## 18. 實作順序與依賴

後續 implementation plan 應按下列依賴拆解：

1. Downloader、snapshot manifest 與 fixtures。
2. Page／section catalog 及 registry 缺口報告。
3. Wikitext parser 與 Structured JSONL exporter。
4. Wikivoyage adapter、staging preview 與 quality gates。
5. `handbooks.managed_key` migration、schema contract 與受管 Handbook builder。
6. Batch translations API、query plan 與後端測試。
7. Handbook locale selector、雙語 item、來源顯示與前端測試。
8. 全 corpus 下載、逐頁抽查、分批 local mirror 匯入。
9. Production data plan/apply、統計刷新與 Handbook 首次發布。

Registry 缺口必須在任何受影響頁面匯入前完成；資料匯入必須在首次 Handbook materialization
之前完成；API 契約可使用 fixture Handbook 並行開發，但 production Handbook 不得先於資料
發布。

## 19. 成功標準

- Category manifest 中每個主命名空間頁面都有明確最終狀態。
- 所有 `included` 頁面的有效英文—目標詞句及合法 readings 通過品質 gate 並可由來源還原。
- LangMap 中每個已發布目標詞句以 direct edge 連到英文，reading 不形成獨立 Expression。
- 單一 Managed Handbook 穩定保存英文詞句骨架。
- 使用者可用精確 locale 切換譯文，無 N+1、無線上覆蓋率聚合、無多跳推導。
- 更新與重跑不製造重複資料，刪除審閱不破壞其他來源或使用者共用內容。
- Handbook URL、投票與建立時間在更新後保持穩定。
- CC BY-SA 4.0 授權與可追溯來源在產品及 release artifact 中均可取得。
