# 語言實體以 Glottolog 識別，詞句以 BCP 47 content tag 綁定

LangMap 不再接受任意自造的 `language_code`。全站把「語言／方言實體」與「一段內容使用的語言標籤」分開：

1. 語言實體優先使用 namespaced Glottocode，例如 `glotto:chao1238`。
2. `languages.code` 與 `expressions.language_code` 保存 canonical BCP 47 content tag。
3. BCP 47 無法唯一表示 Glottolog 方言時，以 private-use 尾段帶入 Glottocode，例如 `nan-Hant-x-chao1238`。
4. API 另外回傳 `languoid_id`；不把 `x-` 私用約定宣稱為 IANA 標準。
5. Glottolog 未收錄時不在 LangMap 建立語言；先向 Glottolog 提交，等待正式 release。
6. Glottolog classification 以 pinned release 的 `parent_id` 原樣匯入，不建立本地分類 relations。
7. 舊 code 只透過一次性 migration manifest 轉換；runtime 不保留 alias，且不重算 expression id。

這個決定同時適用於詞句、映射、搜尋、handbook、匯入腳本、地圖與本站 UI locale。保留 `expressions.language_code` 的字串契約，是為了降低現有 v2 API 和前端的遷移成本；新增 `languoids` registry 解決 BCP 47 無法覆蓋大量方言 identity 的限制。

考慮過但否決：

- 只用 BCP 47／ISO 639：無法穩定識別大量方言。
- 只把 Glottocode 寫進 `language_code`：不適合 HTML `lang`、HTTP 及既有 i18n 工具。
- 自行設計全球方言代碼或 provisional ID：重複外部標準、難以互通及長期維護。
- 永久 alias table：一次性 migration 完成後只會增加 runtime 複雜度。
- 本地多來源分類圖：現階段沒有需求，直接跟隨 pinned Glottolog release。

詳細 schema、canonicalization、匯入與遷移規則見 `docs/superpowers/specs/2026-07-26-language-codes-and-community-ui-i18n.md`。
