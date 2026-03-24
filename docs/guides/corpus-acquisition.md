下面是可操作的建議與具體資源，便於你在初期快速獲得高質量開源語料並開始構建數據管道。

**主要獲取渠道（優先級與說明）**
- **Tatoeba（句子庫）**：大量例句、多語言、社區驅動，通常標註語言和來源，許可友好（部分爲 CC）。適合快速建立平行句對。  
- **OPUS（並行語料集合）**：集合了 OpenSubtitles、TED Talks、WikiMatrix、GlobalVoices 等多源並行語料，適合跨語對照與翻譯。可用 `opus-tools` 或官方 API 下載。  
- **Mozilla Common Voice（音頻 + 文本）**：高質量社區錄音，按 locale（語言-地區）標註，適合發音/朗讀需求。許可爲 CC0/CC-BY（請檢查具體版本）。  
- **Wikipedia Dumps（單語語料）**：大規模、可公開抓取（用於語言模型與詞頻統計），語言覆蓋廣。  
- **Universal Dependencies / treebanks（句法、標註語料）**：結構化、質量高，適合語言學研究或構建規範化表達。  
- **OpenSLR / MLS / LibriVox / M-AILABS（語音語料）**：多個開源語音數據集，適合訓練或對齊 TTS/ASR。  
- **OPUS 中的 OpenSubtitles / ParaCrawl / Europarl / MultiUN**：分別覆蓋口語、網頁爬取並行語料、歐洲議會語料、聯合國文稿（多語、正規文本）。  
- **Wiktionary / Wikidata / Glottolog / WALS**：用作詞表、語言元數據、分類與語種信息（對地域化與元數據尤爲重要）。  
- **項目/教會/聖經翻譯（Bible corpora）**：許多語言的聖經翻譯爲公共領域或可再分發，適合低資源語言的並行句對（注意許可）。  
- **公共領域書籍（Project Gutenberg 等）**：適合富文本語料（主要用於語料擴充、語言模型訓練）。

許可注意：大規模抓取（尤其網頁抓取得到的 CC/版權不明確語料）存在法律風險。優先使用明確標註爲可再分發的語料（CC0/CC-BY/PD）。對於影視/音樂等有版權的資源，必須獲得許可或只保留引用/摘要信息。

**關於地域（到鄉鎮級別）的現實限制**
- 絕大多數現成公開語料只標註語言或國家/地區（如 `zh-CN`、`pt-BR`），很少包含精確到鄉鎮的地理標籤。要達到鄉鎮粒度常見做法：  
  - 從帶 geotag 的數據源（比如某些社交媒體或新聞稿）提取位置元數據（注意隱私與合規）。  
  - 與地方性研究機構、田野調查人員或社區合作，收集帶有地理標籤的樣本。  
  - 允許用戶在提交時選擇或點選地圖（前端地域選擇器），並記錄該元數據以供後續聚合。  
- 建議初期以「國家/省/市」爲主，逐步通過社區/合作方補充鄉鎮級數據並在 UI 中標註來源與可信度。

**實操優先級（建議的入門語料清單）**
1. `Tatoeba`（句子對） — 快速建立多語句庫。  
2. `OPUS`（OpenSubtitles、TED、WikiMatrix 等） — 並行語料，用於跨語言映射。  
3. `Common Voice`（音頻 + 文本） — 發音樣例與音頻 URL。  
4. `Wikipedia` dumps — 單語大語料（清洗後做檢索/示例庫）。  
5. `Universal Dependencies` — 結構化、高質量句子。  
6. `OpenSLR / MLS / M-AILABS` — 補充語音資料。  
7. `Glottolog / WALS / Wikidata` — 語言與地區元數據。

**下載與使用示例命令（zsh）**
- 使用 Hugging Face `datasets` 快速加載（Python）：
```bash
pip install datasets
```
Python 示例：
```python
from datasets import load_dataset
# Tatoeba
tatoeba = load_dataset("tatoeba", "eng-por")  # 示例
# Common Voice
cv = load_dataset("mozilla-foundation/common_voice_14", "zh-CN")
```

- 使用 OPUS 提取器（示例，通過 `opus-tools` 或 OPUS 網站 API）：
```bash
# 使用 opus-tools 或手動腳本，從 OPUS 下載並行語料（示例爲僞命令，具體參見 OPUS 文檔）
# 也可直接從 https://opus.nlpl.eu/ 下載壓縮包並解壓
```

- 下載 Wikipedia dump 並提取純文本（示例工具 `wikiextractor`）：
```bash
# 下載
wget https://dumps.wikimedia.org/zhwiki/latest/zhwiki-latest-pages-articles.xml.bz2
# 解壓並提取
git clone https://github.com/attardi/wikiextractor.git
python wikiextractor/WikiExtractor.py -b 100M --no-templates zwiki-latest-pages-articles.xml.bz2 -o extracted
```

- 下載 Common Voice release（來自 Mozilla 官網）：
```bash
# 在 Common Voice 網站下載對應語言包（通常爲壓縮包），或用 datasets 加載
```

**預處理要點（保證質量的關鍵）**
- 記錄並保存**來源元數據**（source_type, source_ref, license, url, crawl_date, confidence）。這是你設計裏重要的一環。  
- 語言識別與清洗：用 `fastText` / `langid.py` 做語言檢測，剔除語言不匹配的句子。  
- 正則化與 Unicode 規範化（NFC/NFKC），處理不同書寫體系與拼寫變體。  
- 去重：句子級去重（哈希或 MinHash），多輪去重以降低噪聲。  
- 對齊（並行語料）：用現有對齊工具（例如 `hunalign`, `fast_align`）對並行句對進行精排。  
- 質量過濾策略：長度、字符覆蓋、語言檢測置信度、重複率、詞典覆蓋率（低覆蓋表示可能噪聲）。  
- 對音頻：統一採樣率（16k/22k/48k），生成或保存 `audio_url`、時長、說話人標籤；需要做強制對齊可用 `Montreal Forced Aligner` 等工具。

**地域標註與映射策略**
- 使用 `Common Voice` 的 `locale` 或 OPUS/metadata 的 `language-region` 字段作爲初始 region 標籤。  
- 若沒有細粒度信息，採用「最近行政區」或用戶地理選擇器補充（並把它當作「用戶提供的地域元數據」）。  
- 節點對齊：把 `regions` 表與公開地理數據庫（GADM / OpenStreetMap）聯通，用 PostGIS 做點到區域映射。

**治理、許可與倫理流程**
- 對每條語料保留 `license` 字段，明確是否可公開/商用。  
- 對 AI 補全或爬取來源做單獨標記並在 UI 中顯式展示。  
- 爲用戶貢獻設計同意書與版權聲明；對上傳音頻要求上傳者確認版權/授權。  
- 敏感內容（人名、私人信息等）需過濾或脫敏，遵守 GDPR/本地隱私法規。

**自動化與管道（建議）**
- 建議建立 ETL 管道：抓取 → 清洗 → 語言檢測 → 去重 → 元數據入庫 → 索引（Typesense/ES）→ 審核隊列。  
- 使用 `Airflow` / `Prefect` / 簡單的 `cron + Celery` 管理任務。  
- 將所有原始文件與處理日誌保存在對象存儲（S3），以便回溯與再處理。

**低資源/方言策略**
- 主動建立「社區採集」通道：在前端加入貢獻工具（錄音 + 位置信息 + 示例），並通過聲望系統或人工審核保證質量。  
- 與大學/田野語言學團隊、文化機構或 NGO 建立合作，交換/採集帶地理標籤的語料。  
- 利用「受控語料」（聖經、政府公告、地方新聞）作爲替代或補充。

如果你希望，我可以做下面任一項（你選其一或多個）：  
- **生成用於下載與預處理的腳本**（Python + `datasets` / `wikiextractor` / 處理流水線），按你優先的語言集合打包；  
- **爲 `OPUS` / `Common Voice` 等生成具體的下載命令與示例**（按語言）；  
- **搭建一個最小 ETL 示例**：下載 Tatoeba + Common Voice 的片段，做語言檢測、去重並導入 `expressions` 表的示例記錄。  
