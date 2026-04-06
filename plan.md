# 完整上下文合集：LLM 驱动个人知识库项目（Doom Emacs + Org-mode 版 v2.0）【最终无截断版】

**作者**：bufrr（你的 GitHub）  
**日期**：2026 年 4 月 5 日  
**版本**：已修复所有格式问题 + 完整无截断（所有代码块均正确闭合，所有分割线正常显示）  
**目的**：把本对话**全部上下文**打包成一个独立、可直接复制粘贴的 Markdown 文件，供你丢给其他 AI（Claude / GPT / Grok 等）进行分析、优化、生成代码或 PR diff。

---

## 0. 项目背景与用户仓库

- **原始触发**：你让我 review 这条 X（Twitter）帖子：  
  https://x.com/yanhua1010/status/2039966047378583815  
  （Yanhua 2026-04-03 发布的 Obsidian + LLM 个人知识库完整实现，基于 Andrej Karpathy 2026-04-02 的 "LLM Knowledge Bases" 理念）

- **你的现有配置**：
  - Emacs 配置仓库：https://github.com/bufrr/emacs-config （Doom Emacs + Org-mode + GTD 系统）
  - 博客仓库：https://github.com/bufrr/bufrr.github.io （Org-mode 驱动，`posts/` 目录全部是 `.org` 文件，通过 `build.el` + `org-publish` 发布到 GitHub Pages）
  - 你已有 `CLAUDE.md` 文件，可直接复用

- **核心参考文献**：
  - Karpathy 的 [llm-wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — 权威架构定义
  - [VentureBeat 报道](https://venturebeat.com/data/karpathy-shares-llm-knowledge-base-architecture-that-bypasses-rag-with-an) — 背景解读

**核心诉求**：用 **Doom Emacs + Org-mode** 复刻并优化 Karpathy 的「Raw → Compile → Wiki」知识库系统，同时把博客无缝纳入，实现「第二大脑 + 自动博客工厂」。

---

## 1. 原始 Review（Yanhua X 帖子的英文深度评测）—— article.md 完整内容

> **Review of Yanhua's X post (April 3, 2026) on building an LLM-powered personal knowledge base in Obsidian**
>
> This is a superb, highly practical deep-dive that takes Andrej Karpathy's recent tweet about "LLM Knowledge Bases" and turns it into a ready-to-implement system. Yanhua doesn't just summarize Karpathy's idea — they live it, debug it, and ship a complete workflow that anyone with Obsidian + an LLM (Claude in their case) can copy in a weekend. It's one of the best "here's exactly how I did it" threads I've seen on personal knowledge management (PKM) in the AI era.
>
> ### What the article actually delivers
>
> Karpathy's original post (April 2) outlined the high-level vision:
> - Raw sources → LLM "compiles" a clean wiki of Markdown files
> - Obsidian as the IDE/frontend
> - LLM handles summarization, concept extraction, indexing, Q&A, and "linting"/health checks
> - Keep everything as files (no black-box RAG at small scale)
>
> Yanhua's post is the **implementation manual**:
> - **Directory structure** (raw/ → wiki/ → outputs/) with clear separation of concerns
> - **Ingestion pipeline**: Web Clipper for articles, Podwise for podcasts, custom Claude Skill for tweets/links — all with enforced metadata
> - **Compilation step**: Claude reads new raw files → generates structured summaries + concept entries + updates indexes (All-Sources.md, All-Concepts.md)
> - **Output layer**: Every complex Q&A gets saved as a Markdown file in outputs/qa/ so it becomes permanent knowledge (no more lost chat history)
> - **Health checks**: Weekly LLM audit for contradictions, orphans, missing fields, etc.
> - Strong software-engineering analogies (CI/CD for notes, "compile" instead of "organize," technical debt in your vault)
>
> They also preempt common failure modes: don't jump to RAG too early, start tiny (5–10 articles), use CLAUDE.md as a spec file for consistent output, etc.
>
> ### Strengths
> - **Actionable to the bone** — You could literally copy their folder structure and prompts today and have a working system by tomorrow.
> - **Addresses the real pain** — "I have hundreds of notes but they're rotting and I can't find anything" is the exact problem 90% of Obsidian users hit. The "compile" framing + health checks is a genuine psychological and practical breakthrough.
> - **Scalable mindset** — Starts file-based and simple, only adds RAG later when you actually need it (smart).
> - **Product thinking** — Ends with the "GitHub moment" insight: this hacky stack is the 2006-era version of what will become a mainstream product. Spot on.
> - Tone is generous and clear — no gatekeeping, no fluff.
>
> ### Minor weaknesses / open questions
> - Still somewhat manual at the ingestion/compilation stage (you trigger Claude yourself). Future agents will probably make this fully autonomous.
> - Relies on "Claude Code" (or equivalent desktop LLM that can read your whole vault). Not everyone has that setup yet.
> - No discussion of cost or token limits for very large vaults (though they correctly say wait until you actually hit scale).
> - Backup/sync strategy is mentioned lightly (iCloud 200 GB); power users will want Git + proper versioning.
>
> These are nitpicks — the post is intentionally scoped as "two-week minimum viable knowledge base," not a full enterprise system.
>
> ### Overall verdict
>
> **9/10** — One of the clearest, most useful PKM + AI guides of 2026 so far.
>
> If you're already using Obsidian (or even thinking about it), this thread is required reading. It bridges the gap between Karpathy's elegant high-level idea and actual daily practice better than anything else I've seen. Even if you don't follow it 1:1, the mental model ("treat your notes like code: raw → compile → test → ship") is gold.
>
> Yanhua basically gave the community the missing user manual. The fact that dozens of people in the replies immediately started implementing it (and sharing their tweaks) shows how well it landed.
>
> **Highly recommended.** If you try it, the two-week "minimum closed loop" plan they lay out is honestly the best way to start. Your future self will thank you when your notes stop rotting and start compounding.

---

## 2. Twitter/X 搜索结果 + 最终升级计划（v2.0：对话记忆增强 + 四层工作流）

**搜索时间**：2026-04-05

**核心参考**：
- Andrej Karpathy 的 [LLM Knowledge Bases](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) gist（2026-04-02）：raw → compile → wiki 的完整架构。
- 社区实践中的四层工作流扩展：raw → wiki → brainstorming → artifacts。

> **注意**：原计划中引用的 @AllianzRobbery（Shenron 编译器）和 @highlanderILC（四层工作流）无法通过网络搜索验证，可能为 AI 幻觉生成的引用。四层架构本身是合理的，但来源归属存疑。

### 2.1 推荐目录结构（单一私有 repo）

**部署方案**：GitHub Pro + 私有 repo + GitHub Pages（从 `public/` 目录发布）。

将 `bufrr.github.io` 设为私有，所有内容合并到一个 repo：

```
bufrr.github.io/             # 私有 repo（GitHub Pro 支持私有 Pages）
├── content/                  # 博客源文件（你现有的）
│   └── *.org
├── build-site.el             # 博客构建脚本（你现有的）
├── public/                   # 博客构建输出（GitHub Pages 从这里发布）
│   └── css/
├── gtd/                      # GTD 系统
│   └── *.org
├── kb/                       # 知识库核心
│   ├── raw/
│   │   ├── articles/
│   │   ├── podcasts/
│   │   ├── tweets/
│   │   └── chats/            # Human-AI 对话记录
│   ├── wiki/                 # 编译后的结构化知识（Org-roam 节点）
│   ├── brainstorm/           # 灵感讨论稿
│   ├── artifacts/            # 最终产出（QA、博客草稿、决策）
│   └── index/
├── CLAUDE.md                 # 项目级 Prompt 规范（已有）
└── .gitignore
```

> **GitHub Pages 设置**：repo Settings → Pages → Source 选 `main` 分支 `/public` 目录。
> 私有 repo 的 Pages 站点仍然是**公开可访问**的（这是 GitHub 的设计），但源码不可见。

### 2.2 Doom Emacs 配置变更

以下是基于你现有 `~/.config/doom/` 配置的**增量修改**，不影响现有功能。

#### packages.el — 追加以下内容

```elisp
;; 知识库相关（新增）
(package! org-roam)
(package! org-roam-ui)
(package! org-ql)
(package! gptel)  ; 可选：用于 Emacs 内即时对话。编译流程用 claude -p
```

#### init.el — 一处修改

```diff
- org               ; organize your plain life in plain text
+ (org +roam2)      ; organize your plain life in plain text (+roam2 启用 org-roam v2)
```

#### config.el — 修改路径 + 追加知识库配置

**第一步：修改现有路径**（3 行改动）

```diff
- (setq org-directory "~/org/")
+ (setq org-directory "~/bufrr.github.io/")

- (setq org-current-file "~/org/gtd/current.org")
+ (setq org-current-file "~/bufrr.github.io/gtd/current.org")

- (setq org-archive-file "~/org/gtd/archive.org")
+ (setq org-archive-file "~/bufrr.github.io/gtd/archive.org")

- (setq blog-directory "~/blog/")
+ (setq blog-directory "~/bufrr.github.io/")
```

**第二步：在文件末尾追加知识库配置**（现有 GTD、博客代码不动）

```elisp
;; ============================================================
;; 知识库系统（KB）— 基于 claude -p 编译
;; ============================================================

;; 路径（基于 org-directory，即 ~/bufrr.github.io/）
(setq kb-root (expand-file-name "kb/" org-directory))
(setq kb-raw (expand-file-name "raw/" kb-root))
(setq kb-wiki (expand-file-name "wiki/" kb-root))
(setq kb-brainstorm (expand-file-name "brainstorm/" kb-root))
(setq kb-artifacts (expand-file-name "artifacts/" kb-root))
(setq kb-blog-content (expand-file-name "posts/" org-directory))

;; claude -p 编译命令
(defvar kb-claude-cmd "claude -p"
  "Claude Code CLI 命令。-p 为 pipe/non-interactive 模式。")

;; KB 快捷键（SPC k 前缀，与现有 SPC g/SPC B 不冲突）
(map! :leader
      :desc "KB: 新建 Raw" "k n" #'kb-capture-raw
      :desc "KB: 编译单个文件" "k c" #'kb-compile-file
      :desc "KB: 编译所有新文件" "k C" #'kb-compile-new
      :desc "KB: 打开 Wiki" "k k" (cmd! (dired kb-wiki))
      :desc "KB: 知识图谱" "k g" #'org-roam-ui-mode
      :desc "KB: 健康检查" "k h" #'kb-health-check
      :desc "KB: 发布博客草稿" "k p" #'kb-publish-draft)

;; Org-roam 配置
(setq org-roam-directory (file-truename kb-wiki))
(after! org-roam
  (add-to-list 'org-roam-capture-templates
               '("k" "KB concept" plain "%?" :target
                 (file+head "${slug}.org" "#+title: ${title}\n")
                 :unnarrowed t)))

;; KB capture template（追加到现有 capture templates）
(after! org
  (add-to-list 'org-capture-templates
               '("r" "Raw (KB)" entry (file+headline (lambda () (expand-file-name "inbox.org" kb-raw)) "Inbox")
                 "** %?\n   %U\n   %a" :empty-lines 1)))
```

### 2.3 核心编译流程（基于 `claude -p`）

Claude Code 的 `-p` 模式能直接读写文件系统、自动加载项目 `CLAUDE.md` 规范，非常适合文件编译任务。

Emacs 函数（直接复制到 config.el）

```elisp
(defun kb-capture-raw ()
  "Capture a new raw knowledge entry."
  (interactive)
  (org-capture nil "k"))  ; 在 capture templates 里加 "k" 模板指向 kb/raw/

(defun kb-compile-file (file)
  "用 claude -p 编译单个 raw 文件为 wiki 条目。"
  (interactive (list (read-file-name "Raw file: " kb-raw)))
  (let* ((basename (file-name-sans-extension (file-name-nondirectory file)))
         (wiki-file (expand-file-name (concat basename ".org") kb-wiki))
         (cmd (format "%s '读取 %s，编译为结构化 Org-mode wiki 条目，写入 %s。要求：包含 #+title: 和 #+filetags:，提取关键概念，写摘要和详细笔记，标注原始来源。'"
                      kb-claude-cmd
                      (shell-quote-argument (expand-file-name file))
                      (shell-quote-argument wiki-file))))
    (set-process-sentinel
     (start-process-shell-command "kb-compile" "*KB Compile*" cmd)
     (lambda (proc event)
       (when (string-match-p "finished" event)
         (org-roam-db-sync)
         (message "Compiled: %s -> %s" file wiki-file))))))

(defun kb-compile-new ()
  "用 claude -p 编译所有尚未有对应 wiki 条目的 raw 文件（增量编译）。"
  (interactive)
  (let* ((raw-files (directory-files-recursively kb-raw "\\.org$"))
         (wiki-files (directory-files kb-wiki nil "\\.org$"))
         (wiki-basenames (mapcar #'file-name-sans-extension wiki-files))
         (new-files (seq-filter
                     (lambda (f)
                       (not (member (file-name-sans-extension
                                     (file-name-nondirectory f))
                                    wiki-basenames)))
                     raw-files)))
    (if (null new-files)
        (message "No new raw files to compile.")
      (message "Compiling %d new files..." (length new-files))
      (dolist (f new-files)
        (kb-compile-file f)))))

(defun kb-health-check ()
  "用 claude -p 对知识库进行健康检查。"
  (interactive)
  (let ((cmd (format "%s '对 %s 目录做健康检查：1.缺少 #+title 或 #+filetags 的文件 2.没有反向链接的孤立节点 3.超过90天未更新的条目 4.raw/中有但wiki/中没有对应条目的文件。直接输出 Org-mode 格式的检查报告。'"
                     kb-claude-cmd kb-root)))
    (set-process-sentinel
     (start-process-shell-command "kb-health" "*KB Health Check*" cmd)
     (lambda (proc event)
       (when (string-match-p "finished" event)
         (with-current-buffer "*KB Health Check*"
           (org-mode)
           (goto-char (point-min)))
         (pop-to-buffer "*KB Health Check*"))))))
```

> **与 gptel 的分工**：`claude -p` 负责文件编译和健康检查（需要读写文件系统）；gptel 仍可用于 Emacs buffer 内的即时对话问答（可选安装）。

### 2.4 博客无缝闭环

同一个 repo，不再需要软链接：

- `kb/artifacts/` 里的博客草稿，确认后直接移到 `content/`
- 跑 `./build.sh` 生成 HTML 到 `public/`，push 即发布

```elisp
(defun kb-publish-draft (file)
  "将 artifacts 里的博客草稿发布到 content/ 目录。"
  (interactive (list (read-file-name "Draft: " kb-artifacts)))
  (let ((target (expand-file-name (file-name-nondirectory file) kb-blog-content)))
    (copy-file file target t)
    (message "Published: %s → %s" file target)))
```

### 2.5 健康检查 & 实施路线图

**每周 Prompt**：「对整个 kb/ 做四层健康检查……」

| 周次 | 任务 |
|------|------|
| Day 1 | repo 设为私有 + 建 `gtd/`、`kb/` 目录结构 + Pages 改为 `/public` 发布 |
| Week 1 | Doom 配置 + 迁移 10 篇到 raw/ + 用 `claude -p` 试编译 |
| Week 2 | Org-roam 图谱 + 增量编译 + 博客发布流程 |
| Week 3+ | 日常全流程闭环 |

### 2.6 API 成本估算

| 操作 | 预估 tokens/次 | 成本（Claude Sonnet） |
|------|---------------|----------------------|
| 单篇文章编译（~2000 字原文） | ~4K input + ~2K output | ~$0.02 |
| 10 篇初始批量编译 | ~60K total | ~$0.20 |
| 每周健康检查（100 篇库） | ~50K input + ~5K output | ~$0.18 |
| 单次 Q&A 查询 | ~10K input + ~2K output | ~$0.04 |

**月预算参考**：日常使用（每天编译 1-2 篇 + 每周健康检查）约 $2-5/月。
初始迁移批量编译 50 篇约 $1。远低于 ChatGPT Plus 订阅。

> 建议：先用 `kb-compile-file` 编译单篇测试效果和成本，确认满意后再批量处理。

---

## 3. 参考实现分析

### 3.1 Karpathy — 架构蓝图

**来源**：[llm-wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)（2026-04-02）

完整架构设计文档（[原文](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)），故意保持抽象，需要使用者自行实例化。

**核心洞察 — Wiki 不是 RAG**：
> "大多数人用 LLM 处理文档的体验是 RAG：上传文件，查询时检索相关片段，生成回答。这能用，但 LLM 每次都在从零重新发现知识。没有积累。"
>
> "这里的想法不同。LLM **增量构建并维护一个持久的 wiki** — 一个结构化的、相互链接的 Markdown 文件集合。知识被编译一次然后保持更新，而非每次查询重新推导。"

**三层架构**：
- **Raw sources** — 不可变的原始输入文档。LLM 只读不改。这是你的 source of truth
- **Wiki** — LLM 维护的 Markdown 文件目录。摘要、实体页、概念页、比较、综述。LLM 完全拥有这一层
- **Schema** — 配置文件（CLAUDE.md / AGENTS.md），告诉 LLM wiki 的结构、约定和工作流。你和 LLM 随时间共同演化这个文件

**三个操作**：

| 操作 | 内容 |
|------|------|
| **Ingest** | 新源文件放入 raw/，LLM 读取、讨论要点、写摘要页、更新 index、更新相关实体和概念页。**单次 ingest 可能触及 10-15 个 wiki 页面**。可以逐个 ingest（保持参与）或批量 ingest（少监督） |
| **Query** | 对 wiki 提问。LLM 搜索相关页面、阅读、综合回答并引用。输出可以是 Markdown、比较表、Marp 幻灯片、matplotlib 图表。**关键：好的回答应归档回 wiki 成为新页面** — 查询即积累 |
| **Lint** | 健康检查：页面间矛盾、被新源supersede的过时声明、无入链的孤立页、被提及但没有自己页面的重要概念、缺失的交叉引用、可通过 web search 填补的数据空白 |

**两个关键导航文件**：
- **index.md** — 内容目录。每个页面列出链接、一行摘要、元数据。按类别组织。LLM 每次 ingest 都更新。查询时 LLM 先读 index 找相关页面再深入。**在中等规模（~100 源、~数百页）下够用，不需要 RAG**
- **log.md** — 时间线。Append-only，记录所有 ingest、query、lint。格式如 `## [2026-04-02] ingest | Article Title`，可用 `grep "^## \[" log.md | tail -5` 解析

**推荐工具**：
- [qmd](https://github.com/tobi/qmd) — 本地 Markdown 搜索引擎，BM25 + 向量混合搜索，有 CLI 和 MCP server
- Obsidian Web Clipper — 浏览器扩展，网页转 Markdown
- Marp — Markdown 幻灯片格式
- Dataview — Obsidian 插件，对 YAML frontmatter 做查询

**核心哲学**：
- **Obsidian 是 IDE，LLM 是程序员，Wiki 是代码库**（对应本计划：Emacs 是 IDE，Claude 是程序员，kb/wiki/ 是代码库）
- 人负责：选源、探索、提好问题、思考意义
- LLM 负责：摘要、交叉引用、归档、记账 — 所有让知识库有用的苦力活
- 人类放弃 wiki 是因为维护负担增长快于价值。**LLM 不会厌倦，不会忘记更新交叉引用，一次能改 15 个文件**
- 哲学根源：Vannevar Bush 的 Memex（1945）— 私有、主动策展、文档间连接和文档本身一样有价值

### 3.2 Farza — Farzapedia 完整实现

**来源**：[CLAUDE.md gist](https://gist.github.com/farzaa/c35ac0cfbeb957788650e36aabea836d)

用 LLM 将 2500 条日记、Apple Notes、iMessage 对话编译成 400 篇个人维基百科。是 Karpathy 架构的最完整公开实现。

**7 个命令**：

| 命令 | 作用 |
|------|------|
| **Ingest** | 导入源数据（日记、Notes、iMessage 等）→ 带 YAML frontmatter 的 Markdown 条目 |
| **Absorb** | 核心编译：按时间顺序处理条目，匹配已有文章，提取模式，按主题写入。每 15 条重建索引并审计质量 |
| **Query** | 只读查询，通过 index + 反向链接导航回答问题 |
| **Cleanup** | 并行子 agent 审计所有文章：结构、语气、断链、补充机会 |
| **Breakdown** | 从已有内容里挖掘缺失的文章（值得独立成页的实体和主题） |
| **Rebuild-index** | 重建主索引，带 wikilink 别名和反向链接映射 |
| **Reorganize** | 重组 wiki 分类和架构 |

**目录结构（按主题涌现，不预建）**：
- **Core**：people, projects, places, events, companies, institutions
- **Culture**：books, films, music, games, tools, platforms, courses
- **Inner Life**：philosophies, patterns, tensions, identities, life
- **Narrative**：eras, transitions, decisions, experiments, setbacks
- **Relationships**：relationships, mentorships, communities
- **Work**：strategies, techniques, skills, ideas, artifacts

**写作标准**：
- 维基百科语气 — 事实、中立、平实，不加修辞
- 按主题组织，不按时间 — "这对这个人意味着什么"而非"发生了什么"
- 每条数据必须被"吸收"进理解，不是机械归档
- 1-2 条原文引用承载情感，文章本身保持中立
- 文章长度：最少 15 行，重要传记阶段 60-100 行

**反模式**：
- **反填塞（Anti-cramming）** — 别往已有文章硬塞内容，该开新页就开新页
- **反空壳（Anti-thinning）** — 没有足够内容就别建页面
- **反日记式结构** — 不用日期做标题，用主题概念

**Farza 的四个核心理念**：
1. **显式（Explicit）** — 知识是可见可浏览的 wiki 文件，不是 AI 黑箱里的隐式记忆
2. **你的（Yours）** — 数据在本地，不锁在任何 AI 厂商系统里
3. **文件优于应用（File over App）** — 纯通用格式，任何工具都能处理
4. **自带 AI（BYOAI）** — 想用什么 AI 都行，保持主动权

### 3.3 Garry Tan — GBrain（YC 总裁的工程化方案）

**来源**：[GBrain gist](https://gist.github.com/garrytan/49c88e83cf8d7ae95e087426368809cb)

与 Karpathy/Farza 的扁平文件路线完全不同，GBrain 是一个工程化产品，面向 7000+ 文件、2.3GB 规模的知识库。

**架构选择**：
- **SQLite 单文件**（FTS5 全文搜索 + 向量嵌入）替代扁平 Markdown 文件
- **理由**：Git 在 ~5K 文件后吃力；SQLite 无服务器、支持并发读取
- 支持 `export` 回 Markdown 做 round-trip 验证，不锁数据

**"Above the line / Below the line" 页面结构**（最有价值的设计）：
- **上线（编译后的真相）** — LLM 的当前理解，会被新信息改写更新
- **下线（时间线）** — Append-only，永不改写，是证据基础
- 用 `-----` 分隔。解决了"错误复利"问题 — 永远能追溯到原始证据

**Thin CLI + Fat Skills 架构**：
- CLI 仅 ~500 行 TypeScript，负责数据库操作
- 智能在 5 个独立的 `SKILL.md` 文件里：

| Skill | 作用 |
|-------|------|
| **ingest/SKILL.md** | 处理会议、文章、对话。更新已有页面，为新实体建页，维护交叉引用，解析时间线条目 |
| **query/SKILL.md** | 三层搜索：FTS5 关键词（精确匹配）→ 向量语义（含义匹配）→ 结构化查询（关系导航）。合并去重后综合回答 |
| **maintain/SKILL.md** | 矛盾检测、过期标记、孤立页面、缺失交叉引用、死链清理、标签规范化、嵌入新鲜度验证 |
| **enrich/SKILL.md** | 从外部 API（Crustdata、Exa 等）补充人物和公司数据 |
| **briefing/SKILL.md** | 每日简报：日历、活跃交易、待办线程、近期变更、相关人物 |

**MCP Server**：任何 AI 工具（Claude Code、Cursor、Windsurf）通过标准 Model Context Protocol 接入，不绑定特定 agent。

**技术栈**：Bun（编译二进制）+ SQLite（WAL 模式）+ OpenAI text-embedding-3-small（1536 维）

**规模参考**：1,222 人物档案 + 7,471 Markdown 文件 = 2.3GB。个人知识库的天花板级别。

### 3.4 对比与差距分析

| | Karpathy | Farza | Garry Tan (GBrain) | 本计划（当前） |
|---|---------|-------|-------------------|--------------|
| 定位 | 架构理念 | 个人维基实现 | 工程化产品 | 实现（半成品） |
| 规模 | ~100 篇、~400K 字 | 400 篇 | **7,471 文件、2.3GB** | 起步 ~10 篇 |
| 存储 | 扁平 .md + Git | 扁平 .md | **SQLite**（FTS5 + 向量） | 扁平 .org + Git |
| 搜索 | index.md + qmd | index + backlinks | **三层**（FTS5 + 向量 + 结构化） | index.org（够用） |
| 操作数 | 3（ingest/query/lint） | 7（含 breakdown/reorganize） | 5 个 fat skills | 2（compile/health-check）**← 需补** |
| 页面结构 | 自由 | 维基百科语气 | **上线/下线分层**（编译真相 + 证据时间线） | **未定义 ← 采纳上/下线** |
| 写作规范 | 未定义 | 详细（语气、反模式、长度） | 隐含在 skills 里 | **未定义 ← 需补** |
| 输出回流 | **是** | 是 | 是（timeline append） | **无 ← 需补** |
| AI 接入 | 任何 agent 读文件 | Claude Code | **MCP server**（标准协议） | claude -p |
| CLAUDE.md | 概念级 | 生产级（单文件） | **5 个独立 SKILL.md** | **未写 ← 采纳 fat skills** |
| 增量处理 | 增量，单次触及 10-15 页 | 每 15 条审计 | 事务性写入 | 按文件名匹配 **← 过于简单** |
| 导航文件 | **index.md + log.md** | index | index + structured timeline | **无 ← 采纳 index + log** |

### 3.5 本计划采纳的设计决策

基于三个参考实现的对比，本计划采纳以下设计：

| 采纳项 | 来源 | 理由 |
|--------|------|------|
| **扁平 .org 文件 + Git** | Karpathy | 起步规模 ~10 篇，扁平文件够用。SQLite 是过早优化 |
| **上线/下线页面结构** | GBrain | 成本为零但价值极大。上半部分 LLM 可改写，下半部分证据只追加。解决错误复利问题 |
| **Fat skills 拆分** | GBrain | 不写一个巨大的 CLAUDE.md，按命令拆成独立文件（`kb/skills/*.md`） |
| **index.org + log.org** | Karpathy | index 做内容导航，log 做时间线。log 格式 grep 友好 |
| **写作规范 + 反模式** | Farza | 维基百科语气、反填塞、反空壳、按主题不按时间 |
| **7 个命令** | Farza + Karpathy | ingest/absorb/query/lint/breakdown/reorganize/rebuild-index |
| **查询即积累** | Karpathy | 好的回答归档回 wiki，每次查询增强知识库 |

**下一步**：基于以上决策编写 `kb/skills/` 目录下的 skill 文件：

```
kb/skills/
├── ingest.md        # 导入 raw 数据，适配 Org-mode 格式
├── absorb.md        # 编译 raw → wiki，写作规范 + 反模式 + 上线/下线结构
├── query.md         # 通过 index 导航回答问题，输出存回 artifacts/
├── lint.md          # 数据完整性审计（矛盾、孤立、过期、缺失）
├── breakdown.md     # 从已有内容挖掘缺失文章
├── reorganize.md    # 重组分类架构
└── rebuild-index.md # 重建 index.org 和反向链接
```

这些文件才是整套系统真正的大脑。

---

**优势总结**：文件优于应用（Org 纯文本）、BYOAI（claude -p 可替换）、显式可检查的知识、上线/下线防错误复利、查询即积累、fat skills 模块化、Org-roam 图谱可视化、Emacs 原生速度、博客发布闭环。

---

## 4. 实施 TODO

### Phase 0: Repo 基础设施（Day 1） ✅

- [ ] **0.1** 将 `bufrr.github.io` repo 设为私有（GitHub Settings → Danger Zone → Change visibility） ⚠️ 需手动操作
- [ ] **0.2** 确认 GitHub Pages 仍然工作（私有 repo + Pro 计划，Pages 站点仍公开可访问） ⚠️ 需手动验证
- [ ] **0.3** 配置 Pages 从 `main` 分支 `/public` 目录发布（如果当前不是的话） ⚠️ 需手动操作
- [x] **0.4** 迁移 GTD 文件到 repo：`cp ~/org/gtd/current.org ~/org/gtd/archive.org ~/bufrr.github.io/gtd/`
- [x] **0.5** 验证博客路径：`~/blog/` 是独立目录（非 symlink），repo 内已有 `posts/`、`static/`、`templates/`
- [x] **0.6** 创建知识库目录结构
- [x] **0.7** 创建 `kb/wiki/index.org` — wiki 目录索引
- [x] **0.8** 创建 `kb/wiki/log.org` — 操作日志
- [x] **0.9** 更新 `.gitignore` — 排除 `org-roam.db`、`.claude/`
- [ ] **0.10** 提交初始目录结构 ⚠️ 等用户确认后提交

### Phase 1: Doom Emacs 配置（Day 1-2） ✅

- [x] **1.1** 修改 `~/.config/doom/packages.el` — 追加 `org-roam`、`org-roam-ui`、`org-ql`
- [x] **1.2** 修改 `~/.config/doom/init.el` — 将 `org` 改为 `(org +roam2)`
- [x] **1.3** 修改 `~/.config/doom/config.el` — 更新路径（org-directory, org-current-file, org-archive-file, blog-directory）
- [x] **1.4** 修改 `~/.config/doom/config.el` — 追加知识库配置（路径变量、`kb-claude-cmd`、`SPC k` 快捷键）
- [x] **1.5** 修改 `~/.config/doom/config.el` — 追加 org-roam 配置（`org-roam-directory`、capture templates）
- [x] **1.6** 修改 `~/.config/doom/config.el` — 追加 KB capture template（`"r"` 模板指向 `kb/raw/inbox.org`）
- [x] **1.7** 运行 `doom sync` 安装新包（161 packages, success）
- [ ] **1.8** 验证：打开 Emacs，确认 `SPC g` GTD 快捷键仍然正常 ⚠️ 需手动验证
- [ ] **1.9** 验证：确认 `SPC B` 博客快捷键仍然正常 ⚠️ 需手动验证
- [ ] **1.10** 验证：确认 `SPC k k` 能打开 `kb/wiki/` 目录 ⚠️ 需手动验证
- [ ] **1.11** 验证：确认 `org-roam-ui-mode` 能在浏览器里打开 ⚠️ 需手动验证
- [ ] **1.12** 提交 Doom 配置变更到 `emacs-config` repo ⚠️ 等用户确认后提交

### Phase 2: 编写 Fat Skills（Day 2-3） ✅

- [x] **2.1** 编写 `kb/skills/ingest.md`
- [x] **2.2** 编写 `kb/skills/absorb.md`（含上线/下线结构、写作规范、反模式）
- [x] **2.3** 编写 `kb/skills/query.md`（含输出回流规则）
- [x] **2.4** 编写 `kb/skills/lint.md`（含 8 项检查）
- [x] **2.5** 编写 `kb/skills/breakdown.md`
- [x] **2.6** 编写 `kb/skills/reorganize.md`
- [x] **2.7** 编写 `kb/skills/rebuild-index.md`
- [ ] **2.8** 提交所有 skill 文件 ⚠️ 等用户确认后提交

### Phase 3: 更新项目 CLAUDE.md（Day 3） ✅

- [x] **3.1** 更新 `bufrr.github.io/CLAUDE.md`（完整命令映射表、目录结构、wiki 规则）
- [x] **3.2** 创建 `kb/wiki/index.org` 初始模板（Phase 0 中已完成）
- [x] **3.3** 创建 `kb/wiki/log.org` 初始模板（Phase 0 中已完成）
- [ ] **3.4** 提交 CLAUDE.md 和初始模板 ⚠️ 等用户确认后提交

### Phase 4: Elisp 函数（Day 3-4） ✅

- [x] **4.1** 实现 `kb-capture-raw`
- [x] **4.2** 实现 `kb-compile-file`（异步 `start-process-shell-command` + `claude -p`）
- [x] **4.3** 实现 `kb-compile-new`
- [x] **4.4** 实现 `kb-health-check`
- [x] **4.5** 实现 `kb-publish-draft`
- [x] **4.6** 绑定所有 `SPC k` 快捷键（n/c/C/k/g/h/p）
- [ ] **4.7** 验证：`SPC k n` 弹出 capture 窗口 ⚠️ 需手动验证
- [ ] **4.8** 验证：所有现有快捷键未被破坏 ⚠️ 需手动验证
- [ ] **4.9** 提交 config.el 变更到 emacs-config repo ⚠️ 等用户确认后提交

### Phase 5: 冒烟测试 — 首次编译循环（Day 4-5）

- [x] **5.1** 创建 3 个测试 raw 文件到 `kb/raw/articles/`（从现有博客文章复制：emacs, waku, babylon）
- [ ] **5.2** 在终端直接测试 `claude -p` 编译单个文件：
  ```
  echo "读取 kb/raw/articles/test.org，按 kb/skills/absorb.md 的规则编译为 wiki 条目，写入 kb/wiki/" | claude -p
  ```
- [ ] **5.3** 检查生成的 wiki 页面：是否有正确的 `#+title:`、上线/下线结构、链接格式
- [ ] **5.4** 检查 `index.org` 是否被更新
- [ ] **5.5** 检查 `log.org` 是否有新条目
- [ ] **5.6** 在 Emacs 里测试 `SPC k c` 编译单个文件（调用 `kb-compile-file`）
- [ ] **5.7** 在 Emacs 里测试 `SPC k C` 批量编译
- [ ] **5.8** 打开 `org-roam-ui` 验证 wiki 页面出现在图谱中
- [ ] **5.9** 测试 query：在终端对 wiki 提问，验证 Claude 能通过 index.org 导航
- [ ] **5.10** 测试 lint：运行 `SPC k h` 健康检查
- [ ] **5.11** 如果有问题：调整 skill 文件中的 prompt，重新测试
- [ ] **5.12** 提交测试数据和修正后的 skill 文件

### Phase 6: 迁移已有内容（Week 2）

- [ ] **6.1** 盘点现有内容：你有多少可迁移的笔记/文章/博客文章？
- [ ] **6.2** 将现有博客文章（`posts/*.org`）作为 raw 源导入 — 复制到 `kb/raw/articles/`
- [ ] **6.3** 批量编译已有内容：`SPC k C` 或终端 `claude -p` 循环
- [ ] **6.4** 审查编译结果：抽查 5 篇 wiki 条目质量
- [ ] **6.5** 运行首次 breakdown：让 Claude 识别缺失的文章
- [ ] **6.6** 运行首次完整 lint
- [ ] **6.7** 根据 lint 和 breakdown 结果调整 skill 文件
- [ ] **6.8** 提交迁移后的完整知识库

### Phase 7: 日常工作流闭环（Week 2-3）

- [ ] **7.1** 测试完整日常循环：采集 → 编译 → 浏览 → 查询 → 输出回流
- [ ] **7.2** 测试博客发布闭环：在 `kb/artifacts/` 生成草稿 → `SPC k p` 发布 → `./build.sh` → push
- [ ] **7.3** 测试 GTD 闭环：确认 `SPC g c/a/w/A` 在新路径下全部正常
- [ ] **7.4** 建立每周健康检查习惯：每周日运行 `SPC k h`
- [ ] **7.5** 持续使用 2 周，收集问题和改进点
- [ ] **7.6** 根据实际使用体验调整 skill 文件（prompt 微调）
- [ ] **7.7** 评估是否需要 `org-ql` 做更高级的查询
- [ ] **7.8** 评估 wiki 规模是否需要 qmd 或其他搜索工具

### Phase 8: 优化与扩展（Week 3+，按需）

- [ ] **8.1** 如果 wiki 超过 50 篇：评估 index.org 导航是否仍然够用
- [ ] **8.2** 如果需要更好的搜索：集成 qmd 或 org-ql 作为搜索后端
- [ ] **8.3** 如果需要自动采集：研究 agent-browser 或 org-cliplink 集成
- [ ] **8.4** 如果需要可视化输出：研究 Org-mode 导出为幻灯片（org-reveal/Marp）
- [ ] **8.5** 远期：评估用 wiki 数据做 finetuning 的可行性
- [ ] **8.6** 远期：评估 MCP server 集成（让其他 AI 工具也能接入知识库）

---

### 依赖关系

```
Phase 0 (repo 基础设施)
  └→ Phase 1 (Doom 配置)
       └→ Phase 4 (Elisp 函数)
            └→ Phase 5 (冒烟测试)
                 └→ Phase 6 (迁移内容)
                      └→ Phase 7 (日常闭环)
                           └→ Phase 8 (优化扩展)

Phase 0 (repo 基础设施)
  └→ Phase 2 (Fat Skills) ←← 可与 Phase 1 并行
       └→ Phase 3 (CLAUDE.md)
            └→ Phase 5 (冒烟测试)
```

**估算**：Phase 0-4 约 3-4 天完成核心搭建。Phase 5 用 1 天验证。Phase 6-7 用 1-2 周磨合。Phase 8 持续迭代。
