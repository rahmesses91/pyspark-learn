# Chewy final round — study material (Interview 1 alignment)

Reference profile: Senior Data Engineer background — Snowflake, dbt, **Medallion (Bronze / Silver / Gold)** and semantic modeling, Kafka streaming, quality-as-code, cost/performance optimization, small-team technical leadership.

Use these answers as **anchors**: adapt wording live; keep **2–3 minutes** for behavioral, **structured bullets** for technical whiteboards.

---

## 1. System architecture & platform design

### Q1.1 — Walk us through a scalable, cross-domain Snowflake architecture you’d recommend.

**Response (lead framing):**

- **Start from consumers**: who needs the data (finance close, product analytics, ops), latency tolerance, and blast radius if a domain breaks.
- **Layers (Medallion)**:
  - **Bronze**: source-faithful ingest (immutable or lightly typed); retain raw fidelity for replay/audit; partition or cluster by ingest date / source for cost and reprocessing.
  - **Silver**: cleansed, standardized, conformed keys; shared dimensions (customer, product, geography); business rules and deduplication applied once for reuse across domains.
  - **Gold**: domain-specific marts and curated outputs; optional **semantic layer** for governed metrics and self-serve BI; stable contracts for downstream consumers.
- **Cross-domain discipline**: **domain ownership** of pipelines and Gold products; **shared standards** for keys, naming, and PII; **contracts** at layer boundaries (schema + SLAs + tests).
- **Platform services**: orchestration (tasks/Airflow), RBAC, row access policies where needed, lineage and catalog, separate warehouses for ingest vs transform vs BI.
- **Why it scales**: new domains land in **Bronze**, conform in **Silver**, and publish **Gold** without rewriting other domains’ marts; regressions caught by tests and promotion gates.

*Personal hook:* At Disney I helped drive a Medallion ELT platform at scale (high daily volume), a governed semantic layer (150+ models), and standards across a large dbt catalog — same **Bronze → Silver → Gold** pattern, with heavy emphasis on trust and reuse.

---

### Q1.2 — How do you prevent one team’s changes from breaking downstream domains?

**Response:**

- **Technical**: dbt tests (uniqueness, relationships, not-null on critical fields), CI on PRs, environment promotion (dev → staging → prod), **data contracts** or agreed schemas at handoff points.
- **Operational**: critical assets tagged; **lineage** so blast radius is visible; canaries or shadow runs for high-risk changes where feasible.
- **Process**: design reviews for cross-cutting models; **versioning** and communication for breaking changes; ownership per domain with a clear escalation path.
- **Culture**: “fix forward” with postmortems that improve tests, not just manual vigilance.

---

### Q1.3 — Where do you put business logic: ETL, dbt, BI, or the semantic layer?

**Response:**

- **Prefer**: encode **reusable, auditable** logic once in the **warehouse layer** (dbt) or a **semantic layer** if you use one — so metrics are consistent everywhere.
- **BI** should visualize and filter, not redefine revenue or active user definitions.
- **Exceptions**: light formatting for presentation; real-time aggregates that must live close to the app might sit outside classic batch dbt — but then document the metric owner and reconciliation to batch.

---

## 2. Snowflake — performance, cost, and operations

### Q2.1 — How have you approached Snowflake cost and performance optimization?

**Response (STAR skeleton):**

- **Situation**: Large models and heavy BI consumption; costs and runtimes creeping up as data and users grew.
- **Task**: Reduce spend and job duration without sacrificing trust or freshness.
- **Actions**:
  - **Profile** slow queries and credits; separate workloads (transform vs ad hoc) with right-sized warehouses.
  - **Model design**: narrow incremental strategies, reduce full scans, prune wide joins, push filters early.
  - **Clustering / pruning** where tables are large and query patterns are predictable.
  - **Materialization choices**: table vs incremental vs dynamic tables — match refresh needs to cost.
  - **Governance**: discourage “always full refresh” on huge assets without review.
- **Result**: Tie to outcomes you can cite (e.g., material compute savings and runtime reduction on large datasets over time).

*Principle:* Optimization without observability is guessing — measure, change one lever, re-measure.

---

### Q2.2 — How do you decide warehouse size and concurrency?

**Response:**

- Match **peak burst** for ELT windows vs **steady** BI load; use **multi-cluster** or queues when concurrency spikes.
- Avoid oversized warehouses for small, frequent tasks; **right-size** and scale up for known heavy batches.
- **Separate** transformation warehouses from exploratory workloads so analysts don’t starve pipelines.

---

## 3. Real-time vs batch

### Q3.1 — When would you choose streaming vs batch?

**Response (narrative):** Choose **streaming** when latency, continuity, or operational reactivity drive the requirement and you can own the complexity. Choose **batch** when correctness, reconciliation, and simpler operations matter more than sub-hour freshness. **Hybrid** is common: stream into **Bronze**, then **batch Silver/Gold** for tests, joins, and stable analytics — e.g. Kafka → landing with orchestrated promotion to trusted layers.

| Approach | Tools used in AWS | Tradeoffs | Things to consider |
|----------|-------------------|-----------|---------------------|
| **Streaming** | **MSK** or self-managed Kafka; **Kinesis Data Streams** / **Data Firehose**; **Lambda** or **Kinesis Analytics** for light transforms; **Glue** streaming jobs; **EMR** (Spark Structured Streaming); **DMS** for CDC into a stream or staging sink; often **S3** as durable buffer or lake landing | **Pros:** low latency, continuous ingest, fits event-driven and CDC patterns. **Cons:** ordering, late/out-of-order data, duplicate handling, higher operational load; cost can climb at sustained throughput; debugging is harder than batch | End-to-end **SLOs**; **at-least-once vs effectively-once** semantics; **schema evolution** and contract with producers; **replay** and backfill strategy; **reconciliation** to batch or source-of-truth for critical metrics |
| **Batch** | **Glue** (ETL, crawlers), **EMR** (Spark), **MWAA** (Airflow) or **Step Functions** for orchestration; **Athena** / **Redshift** / **S3** for query and serve; **Batch** on **EC2/EKS**; **DMS** full/load-optimized extracts; **Lambda** for small scheduled jobs | **Pros:** simpler reasoning, easier full reprocessing, often better **$/TB** for heavy transforms and big joins; fits finance close and large SCD patterns. **Cons:** higher **latency**; large batch failures can miss SLA windows; needs strong **idempotent** loads | **SLA windows** and dependencies; **partitioning** (S3/Hive-style) and **incremental** vs full refresh; **idempotency** and late-arriving files; cost of **over-provisioned** always-on clusters vs serverless |
| **Hybrid** | Combine above: e.g. **Kinesis/MSK → S3** (Bronze) via Firehose or custom consumers; **Glue/EMR/MWAA** scheduled jobs promote to **Silver/Gold**; **Lambda** for alerts or lightweight routing | **Pros:** near-real-time landing with **governed** downstream batch quality. **Cons:** two paths to operate; must define **handoff** contract and avoid dual sources of truth without reconciliation | Clear **Bronze** cutover rules; **watermarks** or “closed window” for Silver runs; **monitoring** lag from stream tip to Gold freshness; same **metric definitions** in stream summaries vs batch marts |

*Personal hook:* High-volume Kafka-style events into Snowflake with native orchestration for landing/processing; **Silver/Gold** and trusted analytics still behave like batch or micro-batch with tests and SLAs.

---

### Q3.2 — How do you handle late or duplicate events in a streaming path?

**Response:**

- **Idempotency**: natural or surrogate keys; **merge** semantics; watermarks or **as-of** rules documented with the business.
- **Dedup** in **Silver** (or at the Bronze→Silver boundary) with windowing or latest-wins where agreed.
- **Reconciliation**: periodic batch jobs comparing stream aggregates to source or batch totals for critical metrics.
- **Alert** on lag and volume anomalies.

---

## 4. Observability, data quality, and regressions

### Q4.1 — How do you detect and prevent data regressions?

**Response:**

- **Pre-production**: dbt tests in CI, builds on representative data, PR review for logic and fan-out.
- **Production**: monitors on **critical data elements** — row counts, freshness, null rates, distribution shifts, key referential integrity.
- **Evolution**: started with **quality-as-code** (e.g., PyTest for developer workflows) and extended to **enterprise monitoring** (e.g., Anomalo, Datadog) for 24/7 coverage.
- **Process**: severity tiers, on-call or rotation, runbooks, **post-incident** test additions.

*Result anchor:* Reduced manual triage while keeping production assets reliable (use your resume figures if asked).

---

### Q4.2 — How do you define SLAs and freshness for datasets?

**Response:**

- **Tier assets**: Tier 1 (exec, regulatory, customer-facing) vs Tier 2/3 with looser targets.
- **Define**: **freshness** (max lag vs source), **completeness** (expected volume bands), **accuracy** checks against golden sources or reconciliations.
- **Measure**: orchestration metadata + monitoring; **alert** before consumer SLA breach where possible.
- **Ownership**: named owner per dataset; escalation path; document **dependencies** upstream.

---

## 5. dbt — modeling principles and practice

### Q5.1 — What are your dbt modeling principles?

**Response:**

- **Layers (Medallion + dbt)**: **Bronze** = source-faithful ingest (often outside or minimal dbt). **Silver** = dbt **staging** (1:1 cleanup per source) + **intermediate** (conformed, reusable entities). **Gold** = dbt **marts** (domain-facing, stable contracts) plus optional semantic/metric layer.
- **DRY with discipline**: **macros and templates** for repeated incremental patterns — but avoid macro soup; keep business logic readable.
- **Tests**: not-null, unique, relationships on keys; optional custom tests for business rules on critical models.
- **Materializations**: default **view** for exploration; **table/incremental** for heavy or wide models; document **why** incremental keys and merge strategy.
- **Documentation & lineage**: first-class; helps onboarding and incident response.
- **Governance**: naming conventions, project structure, promotion process, and design review for shared models.

*Scale anchor:* Standards across hundreds of assets; reusable patterns for incremental processing and versioning.

---

### Q5.2 — When would you not use an incremental model?

**Response:**

- Small tables where incremental overhead isn’t worth it.
- Logic that **requires full history** re-evaluation every run (some slowly changing or complex restatements) — unless you snapshot or use a pattern that supports it.
- Early prototyping — promote to incremental once stable and heavy.

---

## 6. Python & SQL (hands-on depth)

### Q6.1 — How do you use Python in a data engineering role?

**Response:**

- **Orchestration glue**: Lambdas or small services for lightweight transforms, API pulls, or Snowflake procedure orchestration where appropriate.
- **Quality & tooling**: test harnesses, data diff helpers, codegen or scaffolding for repetitive dbt patterns.
- **Streaming / batch**: historically PySpark for volume; at Snowflake-centric shops, Python often complements SQL/dbt rather than replacing it.
- **Principle**: Python where it **reduces toil** or handles **non-SQL** I/O; keep **core business transformations** in SQL/dbt for transparency and analyst alignment.

---

### Q6.2 — Example SQL strength they might probe — running totals or sessionization (conceptual).

**Response pattern:**

- Acknowledge **window functions** (`sum() over`, `rows between`, `lag`/`lead`) for running metrics and gap detection.
- For **sessions**: partition by user, order by time, flag gaps > threshold, cumulative sum of flags to get session id.
- Mention **testing** on edge cases: duplicates, clock skew, null timestamps.

---

## 7. Leadership, influence, and Chewy Operating Principles

### Q7.1 — Tell me about a time you improved how a team shipped reliable data products.

**Response (STAR — adapt):**

- **S**: Platform growing; inconsistent modeling and firefighting.
- **T**: Raise reliability and velocity without blocking teams.
- **A**: Introduced **modeling standards**, **design reviews**, **shared macros/templates**, and **quality gates**; partnered with Finance/Product on semantic layer and metrics.
- **R**: Higher trust (e.g., BI/adoption metrics you cite), less ad hoc work, measurable maintenance reduction.

*OPs:* execution pays for ideation; live in details/metrics; Chewy Time = clear scope + fast iteration with guardrails.

---

### Q7.2 — #OperateAtDepth — Describe using data to drive a decision.

**Response:**

- Pick **cost/performance** or **quality incident** narrative: baseline metrics (credits, runtime, failure rate), hypothesis, change, before/after dashboard or report.
- Emphasize **you** owned analysis and recommendation; stakeholders agreed because numbers were clear.

---

### Q7.3 — #AccelerateTime — Deliver faster without sacrificing quality.

**Response:**

- **Templates/macros** and **standards** so teams don’t reinvent pipelines.
- **CI/CD** and **automated tests** so speed doesn’t mean fragile deploys.
- **Thin vertical slices**: ship smallest valuable data product, iterate; **reversible** decisions favored when safe.

---

### Q7.4 — Why Chewy? (go beyond “I love pets”)

**Response:**

- **Mission**: trusted, convenient experience at scale — data platforms directly support that through **reliable** product, supply, and customer analytics.
- **Fit**: depth in **Snowflake/dbt**, **streaming + batch**, **quality and cost discipline**, and **cross-functional** partnership matches enterprise retail/e-commerce data needs.
- **Growth**: interest in how Chewy evolves **platform patterns**, **governance**, and **analytics/AI enablement** responsibly.

---

## 8. Questions you can ask them

- How is **data platform ownership** split between central platform and domain teams?
- What are the top **1–2 platform bets** for the next 12–18 months (e.g., real-time, semantic layer, AI features)?
- How do you **define and enforce** data quality SLAs today, and where do you want that to go?
- What does **success** look like for this role in the first 90 days?
- How does the team **balance** innovation (new tech) with operational load?

---

## Quick checklist before Interview 1

- [ ] One **whiteboard-ready** **Bronze → Silver → Gold** architecture (batch + optional stream ingest) in under 5 minutes.
- [ ] Three **OperateAtDepth** stories with metrics.
- [ ] Two **AccelerateTime** stories (standards, automation, fast iteration).
- [ ] Clear **dbt** stance: layers, tests, incremental rules, when to review design.
- [ ] **Regression + SLA** answers that name tools and process, not only tools.
- [ ] **Why Chewy** + **2–3 questions** for the manager.
