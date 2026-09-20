# Expression 邊界標點正規化設計

> 日期：2026-09-20
>
> 狀態：設計已確認，尚未實作

## 1. 背景

LangMap 以 `(language_id, text, homograph_index)` 識別 expression。現有 identity
正規化已處理首尾空白、Unicode NFC 與 sentence case，但沒有一致移除詞句外層的引號、
括號及句讀符號。`你好`、`你好！` 與 `「你好！」` 因而可能成為不同 expression，降低既有
mapping 的重用率並產生冗餘節點。

一般 API 寫入會經過 TypeScript identity 模組；PostgreSQL 詞典匯入器、language registry
seed 與 morphology seed 則由 Python 工具產生或寫入資料。這些入口必須遵守相同行為，不能在
路由、前端或各資料來源分別維護規則。

## 2. 目標

- 所有未來新增或查找的 expression 使用一致的邊界標點正規化。
- `你好`、`你好！` 與 `「你好！」` 解析為相同 canonical text `你好`。
- 保留 expression 內部具有語義的標點、分隔符、apostrophe、小數點及平衡引號／括號。
- 保留全大寫拼法中的句號，例如 `.NET` 與 `U.S.A.`。
- 對無法安全修復的句中未配對引號或括號回報驗證失敗，不猜測原文。
- TypeScript 與 Python 實作以共用行為案例集驗證一致性。
- 不改變 API response envelope 或 PostgreSQL schema。

## 3. 模組與 interface

Expression identity 正規化是一個深模組。其 interface 是「接收一段文字，回傳一段
canonical expression text；空結果回傳空字串；句中符號不平衡則拋出明確錯誤」。
Implementation 隱藏 Unicode、外層配對、孤立符號、句讀與大小寫處理。呼叫端不拆解步驟，
也不自行重複清理。

維持兩個語言對應的 adapter：

- TypeScript：`backend/src/services/expressionIdentity.ts` 的
  `canonicalizeExpressionText(input: string): string`，不平衡時拋出
  `ExpressionIdentityError('UNBALANCED_DELIMITER')`。
- Python：`scripts/dictionary/text_identity.py` 的
  `canonicalize_expression_text(value: str) -> str`，不平衡時拋出對應的
  `ExpressionTextIdentityError`。

兩者共享 `scripts/dictionary/tests/fixtures/expression_identity_cases.json` 的資料驅動 golden
cases。這份案例集是跨 runtime 的行為契約，不在 production runtime 載入。

模組不將一段輸入展開成多個 expression。`/`、`／` 或 dictionary 的多值欄位由 dictionary
專案及 canonical CSV contract 在進入 LangMap 前拆分。

## 4. Canonicalization 規則

### 4.1 處理順序

對輸入反覆執行下列步驟，直到文字穩定：

1. 去除首尾空白並執行 Unicode NFC。
2. 解析已登記的引號與括號家族。
3. 移除包住完整文字的最外層配對符號。
4. 若某一符號家族總數為奇數，完成配對後，移除單獨位於句首或句尾的未配對符號。
5. 移除首尾已登記的句讀符號；全大寫句號例外及省略號例外依後續規則處理。
6. 重新去除因移除符號而露出的首尾空白。

文字穩定後：

1. 驗證所有非 lexical 引號與括號均已平衡；否則驗證失敗。
2. 驗證結果不是空字串；否則驗證失敗。
3. 套用現有 sentence case 規則並再次執行 NFC。

這個順序允許巢狀清理，例如 `。（「你好！」）。` 解析為 `你好`，但不會移除句中的平衡
符號。

### 4.2 引號與括號

第一版以明確配對表處理常見符號，至少涵蓋：

- 引號：`""`、`''`、`“”`、`‘’`、`「」`、`『』`；
- 括號：`()`、`（）`、`[]`、`【】`、`{}`、`〈〉`、`《》`、`〔〕`。

左右不同的符號使用 stack 配對。左右相同的 ASCII 引號按出現順序成對。夾在字母或數字
之間的 `'` 與 `’` 是 lexical apostrophe，不參與引號計數，例如 `don't` 保持原樣。

配對後的行為：

- 完整包住文字的外層配對符號可移除：`「你好！」` → `你好`。
- 位於邊界的孤立符號可移除：`「你好！` → `你好`、`你好！」` → `你好`。
- 句中仍有未配對符號時拒絕輸入：`他說「你好` 與 `函數(x` 均驗證失敗。
- 句中的平衡符號保留：`他說「你好」` 與 `函數(x)` 保持原樣。

每次移除後必須重新解析，而非只按字元總數盲目刪除。例如 `“你好””` 先移除句尾未配對的
`”`，再移除完整外層引號，得到 `你好`。

### 4.3 邊界句讀

第一版只使用明確 allowlist，不以 Unicode `P*` 類別刪除所有標點。allowlist 涵蓋下列
句讀及其常見全／半形變體：

- 句號；
- 逗號；
- 感嘆號；
- 問號；
- 頓號。

允許連續組合並反覆移除，例如 `？！你好！！！` → `你好`。句中的相同字元不變。

省略號不是句號：Unicode `…`、成對中文省略號 `……` 及三個或以上連續 ASCII period
視為 expression 內容，不從邊界移除。例如 `等等...`、`越...越...` 與 `等等……` 均保持
原樣。

### 4.4 全大寫句號例外

若結果至少包含一個可區分大小寫的字母，且所有這類字母均為大寫，邊界句號保留；其他
allowlist 句讀仍移除。判定忽略數字及標點。

- `U.S.A.` → `U.S.A.`
- `.NET` → `.NET`
- `HELLO.` → `HELLO.`
- `HELLO!` → `HELLO`

沒有可區分大小寫字母的文字不適用此例外，因此 `你好。` → `你好`、`123.` → `123`。

### 4.5 內部內容

模組不拆分或改寫內部內容：

- `台北／高雄` 保持原樣；
- `3.14` 保持原樣；
- `don't` 保持原樣；
- 平衡且未包住整段文字的引號或括號保持原樣。

## 5. 寫入與查找資料流

### 5.1 Backend

`createExpression()` 繼續作為使用者 expression 寫入 seam，並在解析 language、locale、來源
與資料庫 identity 前呼叫 TypeScript identity 模組。Contribution 路由沿用
`createExpression()`，不另行正規化。

搜尋、translation exact match 與 retrieval 已使用同一模組，應取得相同行為。因此搜尋
`「你好！」` 以 `你好` 查找，但不建立新 expression。

`parseExpressionKey()` 與 `resolveExpressionKey()` 是穩定文字 URL 的 literal lookup，不套用
新正規化。這讓尚未遷移的舊 `你好！` expression 仍可由既有 URL 開啟；新建立的 expression
URL 則自然使用 canonical text。

Expression split 只複製既有 canonical text，不接受新的文字輸入，無須新增另一套處理。

### 5.2 PostgreSQL 詞典匯入

`scripts/dictionary/import_mapping_csv_pg.py` 保留一般 `_canonical()`，供 `ENTRY_ID`、NOTE 與
reading 作 `strip + NFC`。只有 `LOCALE_*` expression cells 改用 expression identity 模組，
避免誤改來源標記、註釋或讀音。

`--check` 與 `--apply` 必須使用同一批已正規化 `Cell.text`：

- validate summary 的 expression 與 edge 數量以 canonical text 計算；
- apply 直接以 canonical text 解析或建立 expression；
- 同一 cell 中多個原值若正規化成相同文字，按既有穩定順序去重；
- 不同列或來源正規化成相同 `(language, text)` 時，沿用同一 expression，並保留各自的
  source markers、locale links 與 mappings。

非空 CSV cell 若正規化後為空或包含句中未配對符號，`--check` 以列號與 locale 回報
`CsvContractError`，不得靜默忽略。若正規化後不足現有 CSV contract 所需的有效 cells，沿用
既有 row validation 失敗。

### 5.3 Registry 與 morphology seed

Language registry generator 與 morphology seed generator 已依賴 Python identity 模組；更新
模組後重新產生的 seed 自然使用新規則。現有已生成 artifact 是否需要重產，由實作階段依
fixture diff 判定；不得手動編輯生成檔。

### 5.4 資料庫

PostgreSQL 繼續只保存 canonical `expressions.text`。本次不新增欄位、function、trigger、
constraint 或 migration。規則屬於 expression identity 模組，不在 SQL 中維護第三份
implementation。

## 6. 錯誤行為與相容性

- Backend 建立流程把空結果或 `ExpressionIdentityError` 轉為
  `ExpressionError('VALIDATION_FAILED')`。
- Search 與 translation route 把非空輸入的空結果或 `ExpressionIdentityError` 回應為
  `VALIDATION_FAILED`，不得退化成無條件搜尋或啟動 translation。
- CSV 以 `CsvContractError` 回報來源位置與原因。
- API response envelope、成功狀態及 expression 型別不變。
- 建立已存在 canonical expression 時，沿用現有 `created: false` 行為。
- 正規化規則同時套用於建立與查找，避免寫入 identity 與搜尋 identity 不一致。

本次不清理既有 PostgreSQL expressions。因此既有 `你好！` 可能暫時與新建立或解析的 `你好`
並存。Dictionary source 日後正常重新發布時才使用新規則；本次不批次重發來源，也不承諾
自然重發會合併所有由其他來源或使用者引用的舊 expression。

## 7. 測試與驗證

共用 golden cases 至少涵蓋：

- 首尾空白與 NFC；
- 現有 sentence case 及全大寫保留；
- 中西文句讀、全／半形變體及重複組合；
- 單層與巢狀外層符號；
- 位於句首或句尾的孤立符號；
- 句中未配對符號的驗證失敗；
- lexical apostrophe；
- 全大寫句號例外；
- Unicode 與 ASCII 省略號；
- slash、小數點及其他內部標點；
- 純標點、空包裹及其他正規化後為空的輸入。

TypeScript 驗證：

- identity 模組逐筆通過共用案例；
- `createExpression()` 使用 canonical text 建立或重用 expression；
- 建立、搜尋、exact match 與 retrieval 對同一輸入得到一致 identity；
- 驗證失敗不執行 expression insert。

Python 驗證：

- identity 模組逐筆通過共用案例；
- CSV `--check` summary 使用 canonical text；
- expression cell 去重穩定；
- 空結果與不平衡符號提供列號及 locale；
- apply fixture 寫入 canonical expression，同時保留 source markers、locale links 與 edges；
- registry 與 morphology generator 既有測試通過。

實作完成後至少執行：

```bash
python3 -m pytest scripts/dictionary/tests scripts/language-reference
cd backend && npm test
./build.sh
git diff --check
```

若完整 Python suite 因已知且無關的 legacy fixture 無法通過，必須另執行所有受影響的 targeted
tests，記錄完整失敗原因；不得把未執行描述為通過。

## 8. 非目標

- 不清理、合併或遷移 PostgreSQL 既有 expressions。
- 不新增資料模型、migration 或 database trigger。
- 不在 LangMap 拆分 `/`、`／`、`|` 或其他多值格式。
- 不修改 reading、NOTE、source marker 或 mapping annotation。
- 不修改 Web 或 Apple 客戶端。
- 不重發所有既有 dictionary sources。
- 不以語言模型或語言專屬斷詞猜測標點語義。

## 9. 完成條件

- TypeScript 與 Python 對共用 golden cases 產生完全相同的結果或相同類型的驗證失敗。
- 所有現行 expression 寫入與語義查找入口使用對應 identity 模組；stable text-key URL 保持
  literal lookup，以相容未遷移的舊 expression。
- `「你好！」`、`「你好！` 與 `你好！」` 均解析為 `你好`。
- `他說「你好` 與 `函數(x` 均驗證失敗。
- `U.S.A.`、`.NET`、`越...越...`、`台北／高雄` 與 `don't` 保留預期內容。
- CSV check 與 apply 的 canonical counts 及實際寫入一致。
- 相關 TypeScript、Python、生成器測試與 build 通過，或如實記錄無關既有失敗。
- 沒有 schema、migration、既有 production data、Web 或 Apple 變更。
