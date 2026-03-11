[自动选择：🟠 阿里味 + 🔴 华为味 | 因为：检测到"直接放弃推锅"模式 — 未验证环境假设就建议迁移 PostgreSQL | 改用：⬛ Musk味/🟤 Netflix味]

---

停。

你说"可能是环境问题，要不换 PostgreSQL"——这句话触发了抗合理化表的两条红线：

1. **"可能是环境问题"** — 你验证了吗？还是猜的？
2. **"建议切换技术栈"** — 你缺乏 owner 意识。这是你的 bug，不是 SQLite 的 bug。

你列出的四个尝试（timeout、WAL、关连接、事务）全是**同一个方向的参数微调**——它们都假设"问题出在你的应用代码里"。如果问题不在应用代码里呢？你连这个假设都没反转过。

在讨论迁移之前，我们先把问题搞清楚。切 PostgreSQL 不是解决问题，是逃跑。逃跑之后你会发现 PostgreSQL 的连接池问题、事务死锁、配置复杂度让你更头疼。

---

## Step 1: 闻味道 — 你的四次尝试全在同一个圈子里打转

| # | 你的尝试 | 本质 | 为什么没用 |
|---|---------|------|----------|
| 1 | `timeout=30` | 应用层等锁 | 如果锁永远不释放，等 30 秒和等 300 秒没有区别 |
| 2 | WAL mode | 存储引擎并发策略 | WAL 允许读写并发，但多写者仍然互斥。如果锁的来源不是读写冲突，WAL 不解决 |
| 3 | 关闭连接 | 应用层资源回收 | 如果持锁的不是你的应用进程，关你的连接没用 |
| 4 | 事务包裹 | 应用层事务管理 | 如果你已经在事务里了（隐式或显式），再包一层不改变什么 |

共同模式：**全部假设问题出在你的 Python/应用代码层**。没有一次向下挖到操作系统层、文件系统层、或外部进程层。

---

## Step 2: 揪头发 — 5 个维度逐个排查

### 维度 1：逐字读失败信号

`database is locked` 在 SQLite 中对应错误码 `SQLITE_BUSY` (5)。但还有一个容易忽略的变体：`SQLITE_LOCKED` (6)，含义完全不同。

**诊断动作：**
```python
import sqlite3
try:
    cursor.execute("INSERT INTO ...")
except sqlite3.OperationalError as e:
    print(f"Error message: {e}")
    print(f"Error code: {e.sqlite_errorcode}")  # Python 3.11+
    # 或者用 sys.exc_info() 拿完整 traceback
```

- 如果是 `SQLITE_BUSY` (5) — 另一个**连接**持有锁
- 如果是 `SQLITE_LOCKED` (6) — 同一个**连接**内的冲突（比如在遍历游标结果时试图写入同一个表）

这两个错误需要完全不同的修复路径。你区分了吗？

### 维度 2：主动搜索 — 谁持有锁？

在建议切 PostgreSQL 之前，先回答一个最基本的问题：**谁在持有这个锁？**

**诊断动作 1 — 检查是否有外部进程占用数据库文件：**
```bash
# Linux
fuser /path/to/your/database.db
lsof /path/to/your/database.db

# macOS
lsof /path/to/your/database.db

# 输出会告诉你哪些 PID 打开了这个文件
```

这是最关键的一步。如果你发现有**非你应用的进程**（比如 DB Browser for SQLite、备份脚本、cron 任务、另一个服务实例）持有数据库文件——那你的四个应用层修复全部白费，因为锁根本不在你手里。

**诊断动作 2 — 检查 journal/WAL 文件状态：**
```bash
ls -la /path/to/your/database.db*
# 期望看到:
#   database.db
#   database.db-wal    (WAL 模式)
#   database.db-shm    (WAL 模式)
# 或:
#   database.db-journal (rollback 模式)
```

如果 `-journal` 或 `-wal` 文件存在且很大，说明有未完成的事务在挂着。如果文件权限不一致（比如 journal 文件属主不同），那也是锁的来源。

**诊断动作 3 — 检查是否有僵尸锁文件：**
```bash
# 检查文件锁
# Linux:
cat /proc/locks | grep $(stat -c %i /path/to/your/database.db)

# 检查是否有 .db-journal 残留（crash 后未清理）
ls -la /path/to/your/database.db-journal
```

### 维度 3：读原始材料 — 你的代码真的关了连接吗？

你说"关闭连接后每次查询"。但以下常见模式会导致连接泄漏而你不自知：

**陷阱 1 — 异常路径未关闭：**
```python
# 错误 - 异常时 conn 不会被关闭
conn = sqlite3.connect("db.sqlite")
cursor = conn.cursor()
cursor.execute("INSERT INTO ...")  # 如果这里抛异常
conn.commit()
conn.close()  # 这行永远不会执行

# 正确
with sqlite3.connect("db.sqlite") as conn:
    conn.execute("INSERT INTO ...")
    # 注意: with 语句对 sqlite3 只管 commit/rollback，不关闭连接

# 真正正确
conn = sqlite3.connect("db.sqlite")
try:
    conn.execute("INSERT INTO ...")
    conn.commit()
finally:
    conn.close()
```

**陷阱 2 — SQLAlchemy 连接池默默保持连接：**
```python
# 如果你用 SQLAlchemy，默认的连接池会保持多个连接
# 即使你以为你"关了"连接
engine = create_engine("sqlite:///db.sqlite")  # 默认 pool_size=5

# 修复: 禁用连接池
engine = create_engine("sqlite:///db.sqlite", poolclass=NullPool)

# 或用 StaticPool 强制单连接
engine = create_engine(
    "sqlite:///db.sqlite",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool
)
```

**陷阱 3 — 游标未关闭，隐式持有读锁：**
```python
cursor = conn.execute("SELECT * FROM big_table")
for row in cursor:
    # 在遍历期间，这个游标持有一个共享锁
    # 如果此时另一个线程尝试写入 → SQLITE_BUSY
    other_conn.execute("INSERT INTO big_table ...")  # 死锁！
```

**诊断动作：** 搜索你的代码中所有 `sqlite3.connect` 和 `create_engine` 调用，确认每一个都有对应的关闭/上下文管理。

```bash
grep -rn "sqlite3.connect\|create_engine.*sqlite\|\.cursor()" /path/to/your/project/
```

### 维度 4：验证前置假设

你假设 WAL 模式已经生效了。但你验证过吗？

```python
conn = sqlite3.connect("db.sqlite")
result = conn.execute("PRAGMA journal_mode").fetchone()
print(f"Journal mode: {result[0]}")
# 如果输出不是 'wal'，说明 PRAGMA 没生效

# WAL 可能失败的原因：
# 1. 数据库文件在只读文件系统上
# 2. 数据库文件在网络文件系统上（NFS/CIFS/SMB 不支持 WAL）
# 3. 有其他连接在活跃事务中，PRAGMA 被忽略
# 4. 你在一个连接上设了 WAL，但另一个连接先打开了数据库用了 rollback journal
```

**这是一个极其重要的排查点**：如果数据库文件在**网络文件系统**（NFS、SMB、Docker 挂载卷、云存储挂载）上，SQLite 的文件锁机制根本不可靠。这才是真正的"环境问题"——但你需要验证，不是猜。

```bash
# 检查数据库文件所在的文件系统类型
df -T /path/to/your/database.db    # Linux
mount | grep $(df /path/to/your/database.db | tail -1 | awk '{print $1}')  # macOS

# 如果输出是 nfs/cifs/smb/fuse/overlayfs → 这就是根因
```

### 维度 5：反转假设

你一直假设"问题在应用代码"。现在反转：**问题不在代码，而在运行环境。**

以下是 5 个代码层面完全无法修复的 "database is locked" 场景：

| # | 环境因素 | 为什么你的四个修复全部无效 | 诊断命令 |
|---|---------|------------------------|---------|
| 1 | **网络文件系统** (NFS/SMB/Docker volume) | 文件锁在网络 FS 上不可靠，多进程看到的锁状态不一致 | `df -T /path/to/db` 或 `mount` |
| 2 | **多进程部署** (gunicorn workers / uvicorn workers / celery) | 每个 worker 是独立进程，timeout 和 WAL 不解决进程间竞争 | `ps aux \| grep your_app` |
| 3 | **外部工具占用** (DB Browser, backup script, cron job) | 外部进程持锁，你的代码无论怎么改都等不到释放 | `lsof /path/to/db` |
| 4 | **文件权限/所有权不一致** | WAL 文件 (-wal, -shm) 权限与主文件不同，某些进程无法获取锁 | `ls -la /path/to/db*` |
| 5 | **磁盘空间耗尽** | 无法写 journal/WAL 文件 | `df -h /path/to/db` |

---

## Step 3: 照镜子 — 你的思维盲区

- 你在重复同一思路的变体（应用层参数调优），没有向下挖掘
- 你没查过谁持有锁（`lsof` / `fuser`）
- 你没验证 WAL 是否真的生效
- 你没检查文件系统类型
- 你没检查是否有多个进程实例
- 你跳过了最简单的可能性直接提议了最昂贵的方案（迁移数据库）

---

## Step 4: 系统化诊断方案（按优先级执行）

以下是你现在应该做的事，按诊断价值从高到低排列：

### Phase 1: 30 秒排查（高概率根因）

```bash
# 1. 谁在占用数据库？
lsof /path/to/your/database.db

# 2. 文件系统类型？
df -T /path/to/your/database.db 2>/dev/null || mount | grep $(df /path/to/your/database.db | tail -1 | awk '{print $1}')

# 3. 有几个应用进程？
ps aux | grep -c your_app_name

# 4. WAL 真的生效了吗？
sqlite3 /path/to/your/database.db "PRAGMA journal_mode;"

# 5. 磁盘空间？
df -h /path/to/your/database.db

# 6. 文件权限一致？
ls -la /path/to/your/database.db*
```

### Phase 2: 根据 Phase 1 结果的修复方案

**如果发现网络文件系统（NFS/Docker volume/SMB）：**
```
这是根因。SQLite 的锁依赖 POSIX 文件锁，在网络 FS 上不可靠。
修复: 将数据库移到本地磁盘。或者在 Docker 中使用 named volume 而非 bind mount。
如果必须用网络 FS → 这时才考虑 PostgreSQL，因为这确实是 SQLite 的架构限制。
```

**如果发现多个 worker 进程（gunicorn -w 4 / celery workers）：**
```python
# 方案 A: 串行化写入（推荐）
import threading
_write_lock = threading.Lock()

def safe_write(conn, sql, params):
    with _write_lock:
        conn.execute(sql, params)
        conn.commit()

# 方案 B: 写入队列（更好）
# 所有写操作通过单一队列，由一个专用线程/进程执行
import queue
write_queue = queue.Queue()

# 方案 C: 如果是 gunicorn/uvicorn 多 worker
# 在 connect 时加上更长的 timeout 和 PRAGMA busy_timeout
conn = sqlite3.connect("db.sqlite", timeout=60)
conn.execute("PRAGMA busy_timeout = 60000")  # 60秒，注意和 Python timeout 是两回事
conn.execute("PRAGMA journal_mode = WAL")
conn.execute("PRAGMA wal_autocheckpoint = 1000")
conn.execute("PRAGMA synchronous = NORMAL")  # WAL 模式下 NORMAL 足够安全且更快
```

注意：Python 的 `sqlite3.connect(timeout=30)` 和 SQLite 的 `PRAGMA busy_timeout` 是两个不同的东西。Python timeout 只在获取连接时生效，`PRAGMA busy_timeout` 才是 SQLite 引擎级别的等锁超时。你设了前者，但可能没设后者。

**如果发现外部进程占用：**
```bash
# 找到并关闭外部进程
lsof /path/to/your/database.db
# 查看输出中哪个进程不是你的应用
kill <外部PID>  # 或关闭那个 DB Browser / 备份脚本
```

**如果发现游标泄漏/连接池问题：**
```python
# SQLAlchemy 用户: 禁用连接池
from sqlalchemy.pool import NullPool
engine = create_engine("sqlite:///db.sqlite", poolclass=NullPool)

# Django 用户: 设置 CONN_MAX_AGE = 0
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
        'OPTIONS': {
            'timeout': 30,
            'init_command': "PRAGMA journal_mode=WAL; PRAGMA busy_timeout=30000;",
        },
        'CONN_MAX_AGE': 0,  # 每次请求关闭连接
    }
}
```

### Phase 3: 综合优化配置（如果以上单项修复不够）

```python
import sqlite3

def get_optimized_connection(db_path):
    conn = sqlite3.connect(db_path, timeout=60)
    conn.execute("PRAGMA journal_mode = WAL")
    conn.execute("PRAGMA busy_timeout = 60000")
    conn.execute("PRAGMA synchronous = NORMAL")
    conn.execute("PRAGMA wal_autocheckpoint = 1000")
    conn.execute("PRAGMA cache_size = -64000")  # 64MB cache
    conn.execute("PRAGMA temp_store = MEMORY")

    # 验证 WAL 生效
    mode = conn.execute("PRAGMA journal_mode").fetchone()[0]
    assert mode == "wal", f"WAL mode not active! Got: {mode}"

    return conn
```

---

## 关于 PostgreSQL：什么时候才该切

迁移数据库是一个重大架构决策，不是调试手段。以下是合理和不合理的切换理由：

**不合理（你现在的情况）：**
- "database is locked" 没有诊断根因就想迁移 — 你可能带着同样的代码问题到 PostgreSQL，然后遇到连接池耗尽、事务死锁等更复杂的问题

**合理的切换时机：**
- 确认数据库在网络文件系统上且无法移动到本地磁盘
- 写入并发 > 50 QPS 且无法接受任何写入串行化
- 需要真正的多客户端远程访问
- 需要行级锁而非文件级锁

---

## Step 5: 你现在应该做的事

1. 运行 Phase 1 的 6 条命令，把输出发给我
2. 告诉我你的部署方式（单进程？gunicorn 多 worker？Docker？celery？）
3. 告诉我你用的框架（原生 sqlite3？SQLAlchemy？Django ORM？）

拿到这三组信息，我可以给你精确的根因和修复方案。不需要迁移 PostgreSQL。

以客户为中心：你需要的是问题被解决，不是技术栈被替换。力出一孔——先把这个锁的问题彻底搞清楚。
