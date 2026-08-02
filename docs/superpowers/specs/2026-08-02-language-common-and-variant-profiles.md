# 語言共通層與變體層設計

> 狀態：已確認，待實作。
>
> 更新：本文件「`/languages` 繼續逐 profile 顯示」的決策，已由 [2026-08-03-language-variety-profile-model-design.md](./2026-08-03-language-variety-profile-model-design.md) 取代；`variation_status` 與共通／地方變體內容的其餘決策仍有效。

## 1. 決策

內容語言採「共通層 → 變體層」。基礎 BCP 47 profile（例如 `en`、`ko`、
`yue-Hant`）承載已確認共通或尚未分類的詞句；帶 region 或 private-use
身份的 profile（例如 `en-US`、`ko-KP`、`nan-Hant-x-chao1238`）只承載已確認的
變體內容。

UI locale 是另一個概念，但第一方英文介面沒有使用美國特有規則，因此來源 locale
採 `en`。其他確有 script／locale 需求的 UI locale 可保留更完整的 tag。

## 2. Expression 分類

`expressions.variation_status` 有三種值：

- `unclassified`：尚未判定是否存在變體差異；這是既有及新建內容的安全預設。
- `shared`：已確認可在該基礎／script profile 所涵蓋的相關變體間共用。
- `variant`：已確認屬於 `language_code` 指定的具體變體。

服務層約束：

- 基礎 profile 可使用 `unclassified` 或 `shared`。
- 具體變體 profile 使用 `variant`；不以 `shared` 聲稱它跨其他變體通用。
- 既有資料不因代碼外觀而自動判定為 `shared`；遷移一律先標為
  `unclassified`，後續由人工或具來源的流程重新分類。
- 重新分類保留 expression ID、版本、mapping 與 contribution 關聯。

## 3. Profile 與地理分布

- `en`、`pt`、`ko` 是共通／待分類內容入口；`en-US`、`en-GB`、`pt-BR`、
  `ko-KR`、`ko-KP` 繼續存在以記錄已確認差異。
- `yue-Hant` 不代表廣州預設，而是未綁定地方變體的繁體粵語。
- 城市只放在 `language_locations`，不因使用地而加入 language code。
- Glottolog 能精確識別、BCP 47 無專用 subtag 的變體，以 private-use
  Glottocode 表示。

潮州話的 canonical profiles 為：

- `nan-Hant-x-chao1238`
- `nan-Hans-x-chao1238`
- `nan-Latn-x-chao1238`

三者共用 `variety_key = glotto:chao1238` 與 `glottocode = chao1238`。較上層的
`chao1239` 不作為具體潮州話內容 profile。

## 4. 資料與 API

- `backend/schema.sql` 新增有 CHECK constraint 的 `variation_status`。
- production 以 forward-only migration 新增欄位，既有 row 預設
  `unclassified`，不做猜測式內容搬移。
- expression 建立與列表 API 讀寫 `variation_status`；省略時使用
  `unclassified`。
- registry seed 同時包含基礎與確有需要的變體 profile。
- `/languages` 繼續逐 profile 顯示，不把 UI locale 當成內容語言來源。

## 5. 非目標

- 本階段不建立 expression 與多個地理區域的多對多關係。
- 不自動判斷兩個拼寫是否共通或特有。
- 不按每座城市建立 language profile。
- 不把內容 profile `en-US` 刪除；它仍可承載美國英語特有詞句。

## 6. 驗收

- registry 同時含 `en`／`en-US`／`en-GB`、`pt`／`pt-BR`、
  `ko`／`ko-KR`／`ko-KP`。
- registry 含三個 `chao1238` script profiles，不含 `nan-x-chao1239`。
- 新建 expression 預設為 `unclassified`，可明確提交三種狀態。
- schema 拒絕未知狀態。
- dev bootstrap 後 `/languages` 回傳新的共通與變體 profiles，UI source locale 為
  `en`。
