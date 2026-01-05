// import { DurableObject } from "cloudflare:workers"; // REMOVED
import JSZip from "jszip";
import { D1DatabaseService } from "../server/db/d1";
import { D1Database, R2Bucket, DurableObjectNamespace, DurableObjectState } from "@cloudflare/workers-types";

// Environment bindings definition
export interface Env {
    DB: D1Database;
    EXPORT_BUCKET: R2Bucket;
    EXPORT_DO: DurableObjectNamespace;
}

// Data Models
export interface ExportOptions {
    collectionId: string;
    format: "json" | "csv";
}

export interface ExportJob {
    jobId: string;
    status: "pending" | "running" | "done" | "error";
    progress: number;
    createdAt: number;
    finishedAt?: number;
    options: ExportOptions;
    result?: {
        r2Key: string;
        downloadUrl?: string;
        sizeBytes?: number;
    };
    error?: string;
}

export class ExportDO {
    state: DurableObjectState;
    env: Env;
    db: D1DatabaseService;

    constructor(state: DurableObjectState, env: Env) {
        this.state = state;
        this.env = env;
        this.db = new D1DatabaseService(env.DB);
    }

    async fetch(req: Request): Promise<Response> {
        console.log("ExportDO received request:", req.url, req.method);
        const url = new URL(req.url);

        try {
            if (url.pathname === "/start") {
                if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });
                const body = await req.json() as any;
                console.log("Starting export job:", body);
                return await this.startExport(body);
            }

            if (url.pathname === "/health") {
                return new Response("OK", { status: 200 });
            }

            if (url.pathname === "/status") {
                return await this.getStatus();
            }

            return new Response("Not found", { status: 404 });
        } catch (err: any) {
            console.error("ExportDO error:", err);
            return new Response(`Internal DO Error: ${err.message}\nStack: ${err.stack}`, { status: 500 });
        }
    }

    async getStatus(): Promise<Response> {
        try {
            const job = await this.state.storage.get<ExportJob>("job");
            if (!job) {
                return new Response(JSON.stringify({ error: "Job not found in storage" }), { status: 404 });
            }
            return new Response(JSON.stringify(job), {
                headers: { "Content-Type": "application/json" }
            });
        } catch (e: any) {
            return new Response(`Storage Get Error: ${e.message}`, { status: 500 });
        }
    }

    async startExport(data: { jobId: string } & ExportOptions): Promise<Response> {
        const existingJob = await this.state.storage.get<ExportJob>("job");
        if (existingJob && (existingJob.status === "running" || existingJob.status === "pending")) {
            return new Response(JSON.stringify({ message: "Job already running", jobId: existingJob.jobId }), { status: 200 });
        }

        const job: ExportJob = {
            jobId: data.jobId,
            status: "pending",
            progress: 0,
            createdAt: Date.now(),
            options: {
                collectionId: data.collectionId,
                format: data.format
            }
        };

        await this.state.storage.put("job", job);

        this.state.waitUntil(this.runExport(job));

        return new Response(JSON.stringify({
            jobId: job.jobId,
            status: job.status
        }), {
            headers: { "Content-Type": "application/json" }
        });
    }

    async runExport(job: ExportJob) {
        try {
            job.status = "running";
            await this.state.storage.put("job", job);

            const collectionIdStr = job.options.collectionId;
            const collectionId = parseInt(collectionIdStr.replace("col_", ""), 10);

            if (isNaN(collectionId)) {
                throw new Error(`Invalid collection ID: ${collectionIdStr}`);
            }

            const zip = new JSZip();

            // Fetch data (full content)
            // Note: we fetch everything into memory for now. 
            // For truly large datasets, we would need to stream strictly or paginated write to zip.
            // But JSZip `generateAsync` pulls all into memory unless piped.
            // Given constraints, this MVP works for reasonable collection sizes (< 50MB).

            const fullData = await this.getCollectionData(collectionId);

            const filename = `collection_${collectionId}.${job.options.format}`;
            let content = "";

            if (job.options.format === "csv") {
                const header = "id,text,meaning_id,audio_url,language_code,region_code,region_name,region_latitude,region_longitude,tags,source_type,source_ref\n";
                const body = fullData.map((item: any) => {
                    const escape = (val: any) => {
                        if (val === null || val === undefined) return "";
                        return `"${String(val).replace(/"/g, '""')}"`;
                    };

                    return [
                        item.id,
                        escape(item.text),
                        item.meaning_id || "",
                        escape(item.audio_url),
                        escape(item.language_code),
                        escape(item.region_code),
                        escape(item.region_name),
                        item.region_latitude || "",
                        item.region_longitude || "",
                        escape(item.tags),
                        escape(item.source_type),
                        escape(item.source_ref)
                    ].join(",");
                }).join("\n");
                content = header + body;
            } else {
                content = JSON.stringify(fullData, null, 2);
            }

            zip.file(filename, content);

            zip.file("manifest.json", JSON.stringify({
                collectionId: collectionId,
                generatedAt: new Date().toISOString(),
                count: fullData.length,
                format: job.options.format
            }, null, 2));

            // Use generateAsync with uint8array as it is standard compatible
            const zipContent = await zip.generateAsync({ type: "uint8array" }, (metadata) => {
                this.updateProgress(metadata.percent / 100).catch(console.error);
            });

            const r2Key = `exports/${job.jobId}.zip`;
            await this.env.EXPORT_BUCKET.put(r2Key, zipContent);

            job.result = {
                r2Key: r2Key,
                sizeBytes: zipContent.byteLength
            };
            job.status = "done";
            job.progress = 1.0;
            job.finishedAt = Date.now();

            await this.state.storage.put("job", job);

        } catch (err: any) {
            console.error("Export failed:", err);
            job.status = "error";
            job.error = err.message || "Unknown error";
            await this.state.storage.put("job", job);
        }
    }

    async updateProgress(progress: number) {
        const job = await this.state.storage.get<ExportJob>("job");
        if (job) {
            job.progress = progress;
            await this.state.storage.put("job", job);
        }
    }

    async getCollectionData(collectionId: number) {
        const query = `
        SELECT e.*, ci.note 
        FROM expressions e
        JOIN collection_items ci ON e.id = ci.expression_id
        WHERE ci.collection_id = ?
        ORDER BY ci.created_at DESC
      `;
        const { results } = await this.env.DB.prepare(query).bind(collectionId).all<any>();
        return results;
    }
}
