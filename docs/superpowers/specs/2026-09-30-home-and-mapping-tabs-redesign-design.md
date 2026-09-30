# LangMap 首頁與詞句頁 Tab 重整規格

> 日期：2026-09-30
> 狀態：主要改動已部署並通過桌面／行動驗收；首頁主副標文案待定稿
> 範圍：Web 首頁、全站導覽、詞句 mapping 頁

## 目標

讓搜尋與翻譯成為最清楚的首頁入口，區分全站導覽、首頁任務切換與詞句頁檢視切換，減少重複入口和行動版導覽負擔。整體沿用 LangMap 現有的暖紙張背景、陶土色主色、藍色關係線與低圓角，呈現時尚、寬鬆而克制的層級。

## 已核對的現況

- `HomeView.vue` 已提供 Search／Translate 兩種首頁模式，Search 為預設；搜尋表單使用 `ExpressionSearchControls`，翻譯模式使用 `TranslationWorkbench`，動態內容只在 Search 模式載入。
- `TopNav.vue` 已承載全站導覽、搜尋入口與 `LangSwitcher`；首頁本身不顯示另一份頁首搜尋表單。
- `MappingDetail.vue` 已組合 mapping 圖譜、階層列表、語言篩選與圖譜資訊面板；現有圖譜 API 支援 1 至 3 跳。
- expression detail 已回傳 readings 的 locale code、reading scheme 與標音值；不同 locale 的標音可在前端區分，不需新增資料欄位。
- 已核對的既有規格：[首頁整合詞句翻譯工作台](2026-09-29-home-translation-workbench-design.md) 定義搜尋／翻譯流程。本規格只調整資訊層級與呈現，不替換其操作契約。

## 設計決策

### 1. 三種切換各自表達不同層級

| 層級 | 內容 | 呈現方式與範圍 |
|---|---|---|
| 全站導覽 | Home、Languages、Handbooks、Contribute；帳戶與網站介面語言控制沿用現況 | 導向全站目的地，不與頁內工作模式共用同一組 Tab 樣式 |
| 首頁任務 | Search、Translate | 留在首頁工作區切換，預設 Search；不新增獨立 Translate 導覽項目 |
| 詞句頁檢視 | Graph、List | 只放在 mapping 區域，切換同一組關係資料的視圖，不改變詞句頁路由 |

首頁以置中的單一任務工作區呈現 Search／Translate。膠囊式任務切換緊接在目前任務卡片上方，兩者共用寬度與水平錨點；任務卡只放當前表單。Search 表單清楚標示 Language、Search expressions；提示文字說明可輸入詞語、短語或句子，搜尋按鈕使用卡片全寬。以已選桌面參考稿的 1487×1058 viewport 為視覺基準，工作卡寬度約 822px；「Recent activity」在卡片下方作為次要內容，切換到 Translate 時不顯示。首頁不再放置第二份完整搜尋表單。

### 2. 全站導覽與行動版

- 保留現有 Home、Languages、Handbooks 名稱、目的地和網站介面語言選項。網站介面語言只控制 UI 文案，不代表詞句的語言或 reading locale。
- Handbooks 在桌面和行動版都是通往 `/handbooks` 的單一導覽入口。行動版選單不展開或列舉 handbook 內容，讓內容規模增長時導覽仍精簡。
- Languages 沿用現有目的地與選取方式；Contribute、登入／帳戶入口及權限行為不變。
- 首頁以 Search／Translate 工作區作為搜尋與翻譯的主要入口。其他頁面沿用全站搜尋入口；`/search` 隱藏全站頁首搜尋，由頁面內表單承載主要搜尋，避免同頁出現第二份完整表單。行動版內容頁的搜尋按鈕展開獨立的行內搜尋列並將焦點放進搜尋欄；它與導覽選單分開開合。
- 當前目的地在導覽中有明確 active state。選單可由鍵盤操作，開合狀態與控制項名稱可被輔助科技辨識。

### 3. Mapping 圖譜與列表

- Graph 是預設視圖；Graph／List 控制固定在 mapping 區域，並在桌面與行動版位置一致、可見且可操作。
- Graph 保留多跳探索、既有語言篩選、節點選取及資訊檢視能力。跳數選擇沿用 API 支援的 1、2、3 跳，預設為 2 跳；不要把間接節點壓平成根節點的一跳關係。
- mapping 標題下方先顯示簡短說明；語言篩選與 Graph／List 位於同一控制列，Hops 另置一列，避免控制項浮在節點上。
- 行動版圖譜保持在頁面正常內容流；畫布只呈現最多 8 個彼此連通的代表節點，優先保留目前選取節點的路徑與不同語言的直接對照。畫布下方清楚標示預覽數與已載入總數，並提供切換至 List 的操作；List 仍顯示 API 已載入的完整節點集合，既有 API 截斷提示另外保留。
- 所選節點詳情接在圖譜下方，使用透明背景與分隔線融入頁面，不使用固定底部抽屜、覆蓋圖譜的彈出面板或獨立白底卡片。
- 詞句頁主要動作列顯示 Share 與 Contribute；新增詞句、地圖、詞形及管理員拆分等次要操作收在 More actions。
- List 提供相同 mapping 關係的可讀文字替代，保留語言、詞句與層級資訊；從任一視圖切換時不丟失當前詞句頁上下文。
- 不論目前選取哪個視圖，使用者都能回到另一視圖；圖譜在小螢幕上可讀、可操作，不以縮小桌面圖譜取代行動版資訊層級。
- 不新增收藏按鈕或收藏狀態。詞句與關係的既有貢獻、來源及檢視操作維持原有契約。

### 4. Locale-specific readings

- 詞句頁的 reading 依精確 `language_locale_code` 分組或標示 locale；同一 language 的不同地區／書寫系統 profile 不得共用一個未標明的 reading。
- 每筆標音同時呈現其 reading scheme 與值；同一 locale 有多種 scheme 時保留各筆資料。
- locale 顯示名稱沿用現有 API 的本地化名稱；必要時一併顯示穩定 locale code，以免名稱相近時混淆。
- 網站介面語言切換不改寫 reading 的 locale 身分，也不把網站語言選項當作詞句 locale 篩選器。

## 互動與狀態

- Search／Translate 切換只改變首頁工作模式；Search 延用現有語言選擇、搜尋結果路徑與 URL 契約，Translate 延用既有翻譯請求、結果、錯誤、取消及重試行為。
- 搜尋或翻譯載入、失敗、無結果時，使用既有的 loading、error、empty state；輸入與語言選擇不因切換模式或請求失敗而意外遺失。
- Graph／List 切換不得重設詞句頁。圖譜跳數或語言篩選更新時，維持目前詞句為根節點並使用既有穩定排序、循環處理和數量上限。
- 動作按鈕、選單、Tab 與圖譜操作提供可見 focus、accessible name 和鍵盤操作；觸控目標至少 44px，並遵守 `prefers-reduced-motion`。
- 窄螢幕不得出現水平溢出；長詞句允許換行或在容器內處理，不得撐破頁面。

## 視覺規範

- 使用 `web/src/assets/atlas.css` 現有 tokens、字級與間距慣例；不新增顏色、陰影或圓角系統。
- Search／Translate 表達「要做哪種任務」，Graph／List 表達「如何檢視目前關係」；兩組控制須有不同的區域標題或容器脈絡，避免看起來是同一層級的全站 Tab。
- 首屏優先呈現品牌導覽、置中的首頁主標題、緊貼主表單卡的 Search／Translate 膠囊切換和單一任務卡；欄位標籤與全寬搜尋按鈕清楚可見。活動動態、mapping 細節和次要操作保持清楚但不競爭主入口。
- 桌面可用較寬的工作區；行動版採單欄與明確分段，不將桌面多欄直接等比例縮小。

## 範圍與非目標

### 範圍

- Web 的首頁工作區視覺層級、全站導覽呈現、行動版導覽、mapping 圖譜／列表切換與 locale-specific readings 呈現。
- 以現有前端 API、路由、翻譯和圖譜資料為基礎完成整合。

### 非目標

- 不修改搜尋或翻譯 API 契約、登入門檻、翻譯資料生命週期及既有頁面路由。
- 不更改 expression、mapping、locale 或 reading 的 schema，不新增 favorite／bookmark 能力。
- 不重設 Handbooks 內容頁、Languages 資料模型或 Contribute 流程。
- 不修改 `apple/` 客戶端，不引入新的設計 token、圖譜供應商或外部服務。

## 驗收準則

1. 首頁初次載入時 Search 已選取；膠囊式 Search／Translate 切換緊接在單一當前任務卡上方，Search expressions 欄位標籤清楚、提示文字涵蓋詞語至句子且按鈕全寬；Recent activity 在卡片下方且只於 Search 模式顯示；Translate 不改變既有翻譯流程。
2. Search／Translate 只作首頁任務切換；Graph／List 只作 mapping 檢視切換，兩者不共用造成層級混淆的視覺表現。
3. 桌面與行動版都有 Home、Languages、Handbooks 的清楚導覽；行動選單中的 Handbooks 是單一直接入口，不列出 handbook 項目。現有網站介面語言選項仍可使用。
4. 首頁沒有重複的完整搜尋表單；`/search` 只呈現頁面內搜尋表單，不顯示全站頁首搜尋；其他內容頁的行動搜尋按鈕展開獨立行內搜尋列，不會打開導覽選單。
5. Mapping 預設顯示 Graph、預設深度為 2 跳，語言篩選與 Graph／List 同列，Hops 控制獨立成列；間接關係仍保留其正確層級。行動圖譜顯示不超過 8 個連通節點並標出預覽／已載入數，切換至 List 可查看完整已載入集合。
6. 行動版選取節點後，詳情自然接在圖譜下方，沒有固定定位、覆蓋層或白底卡片外框；詳情內容與關閉選取操作仍可用。
7. 同一詞句若有多個 locale readings，每一筆都能辨認對應 locale 與 scheme；切換網站 UI 語言不會混淆或合併這些 reading。
8. 頁面不提供不存在的收藏操作；既有來源、貢獻與登入功能仍依原契約運作。
9. 鍵盤、輔助科技與觸控均可操作主要導覽、工作區切換、mapping 視圖和圖譜控制；遵守 44px 觸控目標及 reduced motion，桌面和行動版沒有水平溢出。
10. 前端變更完成後，以桌面與行動 viewport 回讀首頁、導覽、詞句 Graph/List、不同 locale readings 狀態；前端建置通過。

## 參考

- [首頁整合詞句翻譯工作台規格](2026-09-29-home-translation-workbench-design.md)
- [詞句詳情頁與對照圖譜優化規格](2026-07-26-mapping-detail-graph-optimization.md)
