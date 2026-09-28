# 詞句翻譯重構 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 更快取得指定 locale 的譯文，完成後點選譯詞才顯示相關參考。

**Architecture:** 完整精確匹配先行；已指定來源採本地有界分詞／短語抽取，以批次 SQL 檢索並在候選不足時才補 trigram。locale 排名先於 LIMIT；上游生成真串流，前端單一原文／譯文工作區與按詞查閱。

**Tech Stack:** Vue 3、TypeScript、Hono、PostgreSQL、Workers AI OpenAI 相容 API。

**Spec:** [重構設計](../specs/2026-09-28-translation-refactor-design.md)

## Global Constraints

- 保留既有未提交變更，不改 `apple/`；新增中文使用傳承體。
- 生成結果暫態，登入、取消、500 grapheme、8192 text bytes、16384 body bytes 邊界維持。
- 檢索最多 8 個片段、24 個 evidence、每 root 3 條路徑；trigram 僅補不足候選，片段至少 3 字元、最多 64 字元、similarity 至少 0.55，最多補 3 個 roots。
- 沿用 GIN trigram，不新增索引或供應商；首輪保持 2 秒檢索預算和 30 秒生成上限。
- 無可用的 superpowers execution 子技能時，依本計畫在本次工作中逐項執行；前後端獨立部分可由 worker 分工，整體接入與驗收由主代理負責。

## Task 1：串流與本地規劃

Files: `backend/src/services/translation/generation.ts`, `planner.ts`, `orchestrator.ts`, 對應 tests。

Interfaces: `planTranslation` 明確來源不呼叫 AI；`streamTranslation` 逐次傳出 content delta，最後回傳拼接譯文。

- [x] 先以可控制的 async iterator 測試生成未完成即發出 delta、忽略 reasoning、truncation／中途失敗不成功。
- [x] 本地 planner 建立 word spans 與相鄰短語，codepoint offsets、穩定去重；自動來源僅 AI detector。
- [x] SDK `stream: true`；只累加 `choice.delta.content`，驗證 finish reason 與取消，assisted alternatives 為空。
- [x] 執行 `cd backend && npm test -- translationGeneration.test.ts translationPlanner.test.ts translationOrchestrator.test.ts`。

核心回歸：
```ts
const pending = streamTranslation(ai, { ...request, onDelta: chunk => deltas.push(chunk) });
await firstChunk;
expect(deltas).toEqual(['Hello']);
expect(completed).toBe(false);
releaseFinalChunk();
expect((await pending).translation).toBe('Hello world');
```

## Task 2：locale 排名與有界批次檢索

Files: `localeMetadata.ts`, `exactMatch.ts`, `retrieval.ts`, translation types 與 tests。

Interfaces: SQL `locale_rank` 為 0=完整 locale、1=同 script／orthography／region、2=同 script／orthography、3=fallback；JS 同步保留該排名，完整 locale 才可免 AI。

- [x] 回歸低 score 指定 locale 優先、高 score 跨 locale fallback，以及未知 metadata 不免 AI。
- [x] roots／候選／對照用批次查詢，未命中 roots 才走短片段 trigram；保留 edge 品質、pivot、去重與穩定排序。
- [x] metadata 批次讀取，檢索 deadline 到達立即返回並安全收尾晚到查詢。
- [x] 以隔離 PostgreSQL 驗證真 SQL、locale 在 LIMIT 前排名、trigram query plan 與候選相關性。

核心回歸：
```ts
expect(result.evidence[0].target_text).toBe('requested-locale-term');
expect(result.locale_compatible).toBe(true);
expect(databaseCalls).toBeLessThanOrEqual(6);
```

## Task 3：單一工作區與點詞參考

Files: `ExpressionTranslation.vue`, translation components、按詞 composable／utility、i18n 與前端 tests。

Interfaces: `TranslationResult` 接收當次 evidence；完成後才分詞，選詞用 occurrence start／end；參考先用已有 evidence，其他使用 `getExpression`／一跳 `getMappingGraph`。

- [x] 回歸只有一份譯文、初始無參考列表、點詞才顯示、連續換詞不被舊回應覆蓋。
- [x] 桌面左右／行動上下、進度一行、保留 copy／retry／contribute，生成可編輯並取消舊請求。
- [x] 詞界、最長短語、emoji／換行／RTL、keyboard／Escape／focus；按次頁面 cache 與 in-flight 去重。
- [x] 執行相關前端測試並在桌面／行動 viewport 實際操作。

核心回歸：
```ts
expect(wrapper.find('.reference-panel').exists()).toBe(false);
await wrapper.get('[data-term="車站"]').trigger('click');
expect(wrapper.get('.reference-panel').text()).toContain('車站');
expect(wrapper.findAll('.translation')).toHaveLength(1);
```

## Task 4：接入與驗收

Files: translate route、前後端契約與原／新 spec；必要的測試環境調整限於基線問題。

- [x] 將 pipeline promise 綁定 Worker response 生命週期；同步 frontend fuzzy match type。
- [x] 排除本機 Node localStorage 與 Vite CSV allow 問題，先讓既有基線正常執行。
- [x] 執行相關後端／前端 tests、`cd web && npm run build`、`./build.sh`、`git diff --check`。
- [x] 真實公開句子量測首內容 delta／總耗時／AI calls／DB calls，抽查 locale 與按詞參考。
- [x] 更新 spec 為實作結果，註明已驗證與未能驗證的範圍，不以 mocked tests 代替交付。

實際驗證結果與剩餘品質範圍見[新版規格實作結果](../specs/2026-09-28-translation-refactor-design.md#實作結果)。本次完成本機驗收，未部署或提交 Git commit。
