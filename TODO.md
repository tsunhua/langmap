# TODO

## 詞典讀音資料修復

- [x] 修復本地 dev D1 的簡體中文同義詞典舊讀音污染。
  - 現象：`/mapping/12498` 的「浪费」除正確的 `lànɡfèi` 外，還錯掛
    `huīhuò`、`zāota`、`jiéyuē`、`àixī`。
  - 根因：舊版 exporter 曾把 `relations[].reading` 當成 headword
    `pronunciations`；dev D1 的 source 3 因此有 6,578／8,620 筆 relation
    reading 污染。
  - 處理：以目前 canonical JSONL 建立精確的 `(headword, reading)` 白名單，先備份
    D1，再刪除 6,578 筆不在白名單的 readings；expressions／edges 數量不變、外鍵檢查
    通過，「浪费」只剩 `lànɡfèi`。
  - 禁止方案：不要刪除 source 3 的全部 readings 後直接 `--force` 重匯；舊 dev 身分
    空間會額外建立 7,295 expressions。

- [x] 修復 Thai－English 詞典把泰文字母擬音誤標為 GB IPA。
  - 現象：`/mapping/142479` 的 `pronto` 顯示 `GB: [พรอน' โท] (ipa)`；
    `/mapping/78415` 的 `peg` 顯示 `GB: [เพก] (ipa)`。
  - 根因：Apple bundle 把供泰語讀者使用的泰文字母擬音標成 `d:prn="UK_IPA"`；
    exporter 原樣輸出，adapter 再映射為 `eng-Latn-GB / ipa`。
  - 語義判定：這是英語 headword 的 native-script respelling，不是泰語詞，也不是
    IPA；因此不建立 `tha-Thai` 或 `eng-Thai-TH` reading。現有資料模型沒有合適的
    respelling scheme，先安全丟棄，日後另行建模。
  - 處理：重新匯出 Thai JSONL（entry count 49,219 不變；保留泰語 equivalents），
    清理 dev source 7 的 20,344 筆 rows；以受管 production migration
    `007-remove-thai-english-respellings.sql` 清理 production source 13 的 20,344
    筆 rows。
  - production apply：operation
    `579df6132ac84fca87716b84803db5d7`，bookmark
    `000000b4-00000000-000050d7-e89982f114772d4af693a60af5a546bd`；遠端驗證 source
    13 與 `peg`／`pronto` 均無誤掛讀音。

- [x] 從 exporter、adapter 到 staging 建立讀音品質防線。
  - exporter 過濾「scheme 含 IPA 但值含明確非 IPA 文字系統」的節點（Thai、Bengali、
    Devanagari、Hangul、Han 等），不再把 native-script respelling 當 IPA；adapter
    另以 `reading_script_mismatch` 與 `relation_reading_as_headword` 防禦性隔離。
  - staging 將 reading errors 寫入 `quarantine_items`，`_prepare_staging` 在 clustering
    前以 blocking gate 失敗關閉；未通過品質 gate 不得發布 dictionary delta。
  - 已重新匯出並抽查 Korean－English、The Standard Dictionary、Traditional
    Chinese－English；entry count 維持不變，blocking reading errors 為 0。

- [ ] 完成其餘來源的重新匯出與發布前抽查。
  - 全 corpus raw scan（5,116,056 entries／4,542,553 readings）在上述三部重匯後，仍有
    215,898 筆「IPA 標籤＋非 IPA script」值：Bangla 19,887、Gujarati 53,830、Hindi
    21,292、Kannada 21,208、Kazakh 2、Korean 99,088、Punjabi 213、Tamil 5、Urdu 373。
  - 這些 JSONL 所指向的 CSV 目前不在 `dictionary` repo 的可用 export 目錄；不可手改
    JSONL 或在 LangMap 加例外。待原始 CSV 恢復後，使用同一 exporter 重新匯出，確認
    entry count 不變、raw scan 與 adapter gate 均為 0，再進行 mirror／production delta。
  - exporter 最後一輪擴充未知文字系統的 fail-closed heuristic 後，四部已存在來源也應
    在外部寫入權限恢復時重新匯出一次；本輪測試已驗證 parser 行為，但不把舊產物冒充為
    這一輪的新輸出。

- [ ] 將修復後的簡體中文同義詞典 JSONL 按 production mirror 流程發布（若 production
  尚未包含該部的修正版）：import → `export_dictionary_delta.py` → managed plan/apply
  → replay delta 回 mirror，並在 apply 後刷新 `language_statistics`。

- [x] 優先導入中文與西班牙語詞典（2026-08-30）。
  - 已完成 mirror 合併：簡中／繁中 8 部、西語 2 部；繁中－英語使用最新重匯輸出，
    10 部均通過 reading gate。
  - 已產生待審 delta：`scripts/db/state/backup/delta/008-cn-es-priority.sql`，
    sha256 `1d9d4e1b8ce7d64849f10e9bacf02e525934f5686655b66e361c84133dbe4461`，約 253MB。
  - production apply 已完成：operation `14fad2e3f6cf44b592c75c53365d3aea`，bookmark
    `000000ba-00000000-000050d7-2d33b51bf078a5ae2a37b70c27dbd35d`；delta 已 replay 回 mirror。
  - `language_statistics` 已以 operation `069d15b302f44358a1770370a7129a7a` 刷新。

- [x] 修復詞頭尾逗號與漢語拼音誤建 expression。
  - `to leak out,` 應由 exporter canonicalize 為 `to leak out`；外部 exporter 已修正，production 已移除重複 punctuation row（保留 canonical id 181512）。
  - `kǎoguān`（expression 1847232）已移除，並折疊為 `考官` 的 `pinyin` reading；adapter 已擴大 pinyin reading folding。
  - production operation `196c1d3aaa47410ca9d73cf0b50fe30d` 已成功，bookmark `000000c0-00000000-000050d7-2562977cbc2b7e67d7b087a93e49ef70`；delta 已 replay 回 mirror。

- [x] 修復 mapping graph 在大量邊時回傳 500。
  - 根因是 D1 bind variable 上限；graph provenance 與邊查詢已分塊，避免 `/expressions/758326/graph?hops=1` 的 669 條邊觸發超限。

- [x] 清理 `/languages/rus` 與 `/languages/ell` 的混合文字誤分類。
  - 根因：中文／西文定義中的俄文、希臘字母符號被錯當成整句語言。
  - 已移除 source 23/24/25 產生的 41 筆錯誤 expression；production operation `0eceb5a265394caca754d6f05ef958a8` 已執行，遠端 rus／ell expression count 均為 0。

- [x] 導入 ChhoeTaigi 九部詞典（2026-08-30）。
  - source-side exporter 維護於 `/Users/lim/Documents/Code/tsunhua/dictionary`：使用 `.venv/bin/dictionary-chhoetaigi-export`（或 `bin/export-chhoetaigi-jsonl.py`）將 CSV 轉出 JSONL；`han` 作 nan headword，`poj` 作 nan 文字 equivalent（不是 reading），`tl` 作 `tailo` reading，`en` 作 eng mapping，`zh_TW` 作 cmn mapping。
  - `ChhoeTaigi_KamJitian`（《廈門音新字典》）使用 `nan-Hant-CN`；其餘八部使用 `nan-Hant-TW`。
  - mirror／production 新增 9 sources、192,946 nan expressions；readings 為 CN 27,848、TW 344,641。delta `012-chhoetaigi.sql` 約 79MB。
  - production operation `f8ae26ad99aa4439bfd50f1a9b7ac5e5` 已成功，bookmark `000000c4-00000000-000050d7-3108c50413f6034c004de3e788bc5a77`；statistics operation `cea227809bb34a948c53f46102575a68` 已刷新。
  - source 中沒有 `han` 的舊籍資料目前以 POJ fallback headword 保留，標記為 `fallback_poj_headword`；後續若補齊漢字欄位，應以 source re-export 與 repair delta 合併回漢字 expression。

- [x] 修正 ChhoeTaigi POJ 誤作 reading（2026-08-31）。
  - 初次發布曾把 `poj` 與 `tl` 都輸出成 reading；已在 converter 根源修正為 POJ 文字 equivalent、TL reading。
  - production repair operation `927f4c46595c43c4836a717a61db092f` 已成功，bookmark `000000c8-00000000-000050d8-36d3f0b7909522dd2fb09e1f88fc78aa`；delta `013-chhoetaigi-poj-repair.sql` sha256 `d464d246c130247508f5e0366e6f67b2bcc7c88138f0bd975ef777f11ac17bdc`。
  - repair 移除九部來源的 226,811 筆錯誤 POJ readings，新增 82,634 nan expressions、145,192 edges；Tailo readings 保留 145,678 筆。statistics refresh operation `e07066153d7d4146947a3f6b1c75a1d2` 已成功。

- [x] 清理舊 Simplified Chinese－English source 28 的拼音 expression（以 `/mapping/1828256` 為例）。
  - 根因不是 ChhoeTaigi，而是 `com.apple.dictionary.zh_CN-en.OCD` 的 parser 將目標漢字後的 `<span class="trans ty_pinyin">…</span>` 當成普通 `trans`，把 76,010 個帶聲調拉丁拼音直接當成 `cmn` expression；`dēngjì xiàngmù`（1828256）因此只有 English edges，沒有 reading。
  - dictionary exporter 已修正並重新匯出；entry count 維持 136,120，fixed JSONL sha256 `3ebfee5e474757db037675e23fea2935a1a1c7a1354bac5286d799519b01605d`。修正 parser 的回歸測試通過（71 passed）。
  - production cleanup operation `f5278e506f5a4636924f731f43758608` 已成功，bookmark `000000c9-00000000-000050d8-6408b03faeeb9326e790fb7d3e9a21f4`；移除 76,010 個拼音 expressions 及其 115,189 條 source-28 edges。
  - production reading repair operation `d9f5c958ba374a80904256737f609778` 已成功，bookmark `000000cf-00000000-000050d9-9f0c7ebf44110925dda0c463c1994060`；從原始 HTML 配對 84,928 筆漢字／拼音，寫入 `cmn-Hans-CN / pinyin` readings，並清除舊錯誤 locale rows。statistics refresh operation `ee63b862fca54197ba0dc45612ea9800` 已重試成功，bookmark `000000ce-00000000-000050d9-7c48582a1e7377cd4375eb81ae628f88`。
  - 後續抽查發現首版配對包含例句／關係節點；首版 operation `d9f5c958ba374a80904256737f609778` 先寫入 84,928 筆，後續由 operation `bda5019097064ff9bb4e1973a4cb641f`（delta `018-ocd-pinyin-readings-correct.sql`）收斂為 80,975 筆真正目標漢字 readings（locale `cmn-Hans-CN`），bookmark `000000d1-00000000-000050d9-2ec5b988797f1157302abd2a7d5d0fa5`，並移除 3,953 筆誤配 rows。statistics refresh operation `e0e6b1bf190b45539d5dca9d68e366aa` 最終成功，bookmark `000000d3-000001fe-000050d9-b8517773453091a2bfc6436b40d63416`。`1828256` 已不存在，`登记项目` 現在顯示 `dēngjì xiàngmù` reading。

- [x] 導入 Jyutjyu 粵語辭典（2026-09-04，v15）。
  - source-side exporter 位於 `/Users/lim/Documents/Code/tsunhua/dictionary`，本輪輸出
    `/Volumes/DATA/langmap-structured-jsonl-jyutjyu-20260904-v15`，共 10 部、171,079
    筆 entries；包含使用者明確要求的 `hk-cantowords.csv` 與 `ts-english-dict.csv`。
  - locale 按辭典來源地區拆分，全部使用 `yue-Hans`：廣州 42／44／45／46／47／49，開平
    43，欽州 48，台山 58，香港 59；沒有把所有來源誤標為 HK，也沒有回到 Hant。
  - `hk-cantowords.csv` 的 Jyutping、英語義項與例句已解析；例句中的 `～`／`~` 會補成
    真正 headword。production 抽查到「佢个细路好百厌」（expression 2737802），未留下
    placeholder。
  - reading gate、source/locale/direction 抽查及 deterministic replay 通過；十部 reading
    均為 `jyutping`，production reading locale 與來源一致。v15 fail-closed 摘要為
    invalid 2,227、missing 101、skipped 2,313、filtered 9,950，未猜測無法安全判定的讀音。
  - `gz-modern` 的 `source_merged_row_truncated` diagnostic 保留；另保留 4 個非例句中的
    合法 `~` 記號（年代範圍、來源標記或約數），沒有把它們當作 placeholder。
  - production source rows 為 42–49、58–59；主 delta
    `scripts/db/state/backup/delta/021-jyutjyu-v15-20260904.sql`，sha256
    `d0c2094973cf3edc2d30dd92c4f64215180449a5dd00e81eb080065bc6ba158a`；cleanup 使用
    `scripts/db/state/backup/delta/021-jyutjyu-v15-20260904-cleanup-chunked.split.sql`，
    sha256 `24d1e7c110c9ee498e445c289238dd29a8439344063c1540643a5e79183513d1`。
  - cleanup operation `13304b6d9cf54e5891c8fb93538c7088` 已成功，bookmark
    `000000f2-00000000-000050dc-438a45832f1e12e129c50a4303e338f4`；主 delta operation
    `378bded6e5d64ef993cf78f150efcdb1` 已成功，bookmark
    `000000f2-00000387-000050dc-1905a943202cb9d434786d9bcd2f8264`。
  - `language_statistics` refresh operation `5e753cf2ea7749419c11ec5f238bccf8` 已成功，
    bookmark `000000f5-00000000-000050dc-33222957921444fe5ac2cedefd76a19f`；production yue
    統計為 205,475 expressions、6 locales。mirror 已 replay、同步 refresh，八張核心表
    計數一致且 `foreign_key_check=0`。
  - production inventory：sources 36、locales 28、expressions 2,740,525、edges 2,412,690、
    readings 796,699；十部 source 的 expression claims、reading claims 與 edge claims
    已逐部核對。

- [ ] 待確認 Jyutjyu 受限來源的公開再分發權。
  - 使用者已明確授權本輪導入 production；但 `hk-cantowords.csv` 原文仍標示
    `ALL RIGHTS RESERVED`，`ts-english-dict.csv` 授權仍未知。若 LangMap 要公開再分發，
    應先取得可核驗授權，否則不要再向外部鏡像或打包分發這兩部資料。
- [x] 修復 `hk-cantowords.csv` 例句污染與 HK 例句 locale（2026-09-04）。
  - 根因：來源例句把完整 Jyutping 放在句末括號內；句末 `.`、`!`、`?` 或引號會令舊
    parser 無法判定為發音提示，整個括號因而進入 yue expression。另因 adapter 只讀
    `examples[].language`，忽略 JSONL 的 `language_hint`，明確繁體例句被錯落到
    `yue-Hans-HK`。
  - source-side exporter commit `ca52c23`：完整 Jyutping 括號（含句內標點）會被移除；
    具明確繁體字形的 HK 例句使用 `yue-Hant-HK`。重匯 entry count 仍為 58,105，JSONL
    sha256 `f7fc4bb3cf06e32879cbb2b5e1a424690a2a074b0e41eacfccb30f22fe74acaa`。
  - adapter 已補上 `yue-Hant-HK` profile 及 `language_hint` 支援；mirror repair 已原地
    修正 16,334 個 expression、合併 67 個重複 expression、重接 68 條 edge；
    `/mapping/2993892` 保留原 ID，內容為「純粹發泄下工作嘅苦悶咋」，locale 為
    `yue-Hant-HK`，英文關係保留。repair SQL：
    `scripts/db/state/backup/delta/022-jyutjyu-hk-example-repair-20260904.split.sql`，
    208 個受管語句、1,371,882 bytes，sha256
    `3a7d1c80a835becad816c049246ee4af73a9a32612ffcdcb34865da46e78cc04`。
  - production repair operation `ed28ddc5fa4a4f22a0ef99dd8c3f2ebb` 已成功，bookmark
    `000000fb-000000ca-000050dc-5e548d38e70c12fe4f8672435aa9a01b`；
    `language_statistics` refresh operation `481bc20b918547ecaa1d61f009be7cf0` 亦已成功，
    bookmark `000000fb-00000702-000050dc-aabebefe8ff52fd947ce5539a42cc619`。
    mirror 已 replay repair／stats delta；核心表計數與 production 一致，mirror
    `foreign_key_check=0`。
- [ ] 回源裁定 `hk-cantowords` 仍有 105 條未清理的括號內容；它們含缺調號、非 Jyutping
  token 或不完整音節，不能安全猜測為 canonical reading。完整 Jyutping 例句已改為
  例句層級 reading；這 105 條歷史清單仍只代表尚未能安全正規化的候選，逐條清單見
  `docs/2026-09-05-hk-cantowords-uncertain-parentheticals.md`；待人工確認後才可另行
  修正與發布。
- [ ] 回源核對 v15 的 invalid／missing reading 與 `source_merged_row_truncated` diagnostics；
  需在 dictionary exporter 修正後重新匯出並重新抽查，不要直接手改 JSONL 或 production。

- [x] 補入 `hk-cantowords.csv` 例句層級 Jyutping reading（2026-09-05）。
  - 根因：舊版 `ExampleV2` 沒有 `readings` 欄位；清理例句末尾括號時只保留乾淨句子，
    adapter／compiler 也只會把 reading 綁到 headword，因此完整粵拼沒有落到例句 expression。
  - dictionary source commit `6cfd1ce` 新增例句 reading schema／解析與完整 Jyutping 判定；
    LangMap commit `cab4ba23` 新增 `target_claim_key`，將 reading 路由到例句 expression。
    相關測試為 dictionary `89 passed`、LangMap `180 passed`。
  - 重新匯出仍為 58,105 entries；新 JSONL sha256
    `e47ea8a33f4449089c1766cd76e56184fc7d82ef6c16c9862a114114ef08dcdd`，已備份舊 artifact
    為 `hk-cantowords.jsonl.pre-example-readings-20260905`。
  - production delta `024-jyutjyu-example-readings-20260905.sql` sha256
    `f11ac2ff1569a6ffff60cbce295920ab9602a6bd052350387accfc2a6818497b`；主要 apply operation
    `54633edb8ff34fa8b313edfb94c580a3` 已成功，stats refresh operation
    `9201e64408ce40d18db658ac1c6e6f19` 已成功，delta 已 replay 回 mirror。
  - `/mapping/2993892` 現在是乾淨句子「純粹發泄下工作嘅苦悶咋」，locale 為
    `yue-Hant-HK`，並有 `jyutping` reading
    `seon4 seoi5 faat3 sit3 haa5 gung1 zok3 ge3 fu2 mun6 zaa3`；英文關係保留。
  - 發布後 mirror／production 核心計數一致：expressions 2,740,541、readings 849,426、
    edges 2,412,766；yue statistics 為 205,491 expressions、6 locales。缺調號或混入非
    Jyutping token 的括號不自動補猜，繼續保留在上方 TODO。
