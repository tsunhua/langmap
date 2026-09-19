> Historical record: this SQLite/D1/JSONL handbook pipeline is retired and is not a current import entrypoint. It remains only until the scripts inventory receives explicit deletion approval.

# 英文 Wikivoyage 會話手冊匯入

這個目錄提供一條可重跑的離線流程：下載英文 Wikivoyage
`Category:Phrasebooks` 的固定 revision，解析英文詞句、目標詞句與 reading，輸出
Structured JSONL v2，再交給既有 dictionary staging／local-import。最後可在本地 SQLite
建立唯一的 `enwikivoyage-phrasebooks` managed handbook。

解析時會移除詞句末尾的句號，並把詞句中的 `/` 替代展開成獨立詞句；讀音中的 `/` 也會
展開為多個 reading。括號內的備註與 IPA 記號中的斜線不視為詞句替代；固定快照的來源
標記仍以每個展開後的輸出列遞增，便於 handbook 重新建立與來源範圍驗證。

原始快照與 JSONL 都是外部 artifact，不提交 Git。建議把它們放在
`/Volumes/DATA/langmap-wikivoyage/` 或其他具備備份與 checksum 的目錄。

## 最小流程

```bash
# 1. 下載固定 revision 快照（公開 API，不需要 token）
python3 scripts/wikivoyage/download.py \
  --output-dir /Volumes/DATA/langmap-wikivoyage

# 2. 解析已固定的快照；每頁一個 JSONL，並產生 source-catalog.json
python3 -m scripts.wikivoyage.export_phrasebooks \
  --snapshot-dir /Volumes/DATA/langmap-wikivoyage \
  --output-dir /Volumes/DATA/langmap-wikivoyage-jsonl \
  --page-catalog scripts/wikivoyage/page-catalog.json \
  --section-catalog scripts/wikivoyage/section-catalog.json \
  --report /Volumes/DATA/langmap-wikivoyage-jsonl/export-report.json

# 3. 在不寫入 D1 的情況下驗證 page accounting、checksum、抽樣列與 review counts
python3 -m scripts.wikivoyage.quality \
  --snapshot-dir /Volumes/DATA/langmap-wikivoyage \
  --export-dir /Volumes/DATA/langmap-wikivoyage-jsonl \
  --report /Volumes/DATA/langmap-wikivoyage-jsonl/export-report.json \
  --output /Volumes/DATA/langmap-wikivoyage-jsonl/quality-report.json
```

同樣的三個階段可由安全的 orchestration CLI 執行：

```bash
python3 -m scripts.wikivoyage.pipeline \
  --snapshot-dir /Volumes/DATA/langmap-wikivoyage \
  --export-dir /Volumes/DATA/langmap-wikivoyage-jsonl
```

加入 `--download` 才會呼叫 Wikimedia API。`--d1-database`、`--state` 與
`--staging-root` 可選擇接上既有 local SQLite importer；這個 CLI 不接受 production
Wrangler 參數，也不會執行 migration 或 production apply。大型匯入請以
`--batch-pages 20` 至 `--batch-pages 30` 分批，或重複使用 importer 的 `--only`。

## Catalog 與狀態

`page-catalog.json` 以 pageid 明確保存語言、精確 locale、reading scheme 及 include／
exclude 狀態。不能從頁面標題猜 ISO code；未完成審閱的頁面會在 export report 標為
`blocked`，不會靜默消失。`section-catalog.json` 只接受列出的章節標題或 alias。

每個成功輸出的 JSONL 都包含 dictionary header、輸入 checksum、revision 及
`oldid:<revision>#<section>/<row>` provenance marker。`review/quarantine.jsonl` 保存
被拒絕的 row-level 候選；`review/removals.jsonl` 是保留給 operator 審核的增量移除入口，
目前首次匯出為空檔。Quality gate 要求 manifest 與 report 一一對應，且 included page
必須恰好有一個非空 JSONL。

## Staging、local import 與 Handbook

通過 quality gate 後，把 JSONL 交給既有流程。`source-catalog.json` 會讓來源列以每個
英文 Wikivoyage page URL 建立 `url` source；不要手動改 source name 或 source marker。

```bash
python3 scripts/dictionary/incremental_import.py \
  --input-dir /Volumes/DATA/langmap-wikivoyage-jsonl \
  --d1-database <local-canonical.sqlite> \
  --state <state-dir>/wikivoyage.json \
  --staging-root /tmp/langmap-wikivoyage-staging \
  --snapshot-root <state-dir>/snapshots \
  --batch-size 5000 --commit-every 50000 --stop-on-error
```

確認 registry 已有目標 language／locale、`eng-Latn-US` 與 system user `langmap` 後，才可
執行：

```bash
python3 -m scripts.wikivoyage.build_handbook \
  --database <local-canonical.sqlite> \
  --section-catalog scripts/wikivoyage/section-catalog.json
```

這本 handbook 只儲存英文 expression；翻譯由 `/api/v2/handbooks/:id/translations` 按
精確 `target_locale` 一次批量讀取 direct edge 與 readings。production 發布仍須依
`docs/runbooks/wikivoyage-phrasebook-release.md` 的人工審核、delta、plan／apply／verify
流程，本文與上述命令都不會替你套用 production migration。

## 來源與授權

資料來源是英文 Wikivoyage，頁面內容依 Wikimedia 的 CC BY-SA 4.0 條款使用。發布包必須
保留 page URL、revision、抓取時間、checksum 與 row marker；使用者介面在 managed
handbook 底部顯示 Wikivoyage attribution。若頁面內容改變，應重新下載新 revision，不能
覆寫既有 pinned snapshot。
