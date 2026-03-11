[自动选择：🔍 没搜索就猜 + 🚪 直接放弃推锅 | 因为：用户未验证环境假设就提议换数据库 = "可能是环境问题"未经验证 + 逃向 PostgreSQL = 放弃推锅 | 改用：🟡 字节味/🔴 华为味]

---

停。

你说"什么都试过了"，然后结论是"换 PostgreSQL"。我来逐字审视你试过的四件事：

1. `timeout=30` — 这只是让等锁的时间变长，不解决锁的根因。
2. WAL mode — WAL 允许读写并发，但写写仍然互斥。如果你的问题是多个写者竞争，WAL 救不了你。
3. 关闭连接 — 关了哪个？什么时候关的？是请求结束时关，还是用完立刻关？有没有连接池在暗中持有？
4. 事务包裹 — 包的是什么类型的事务？`BEGIN` 默认是 `DEFERRED`，写操作拿不到写锁直到真正 WRITE 时才升级，升级时如果有别的读者持有共享锁，就会 `SQLITE_BUSY`。

你做了四件"正确但浅层"的事。没有一件触及根因。现在你要逃向 PostgreSQL —— 这不是解决问题，这是换一个更复杂的问题。

---

## Step 1: 闻味道 — 你卡在什么模式上

你的四个尝试全是"调 SQLite 参数"。方向单一，全是配置层面的微调。没有做过任何**诊断**。你不知道锁是谁持有的、持有多久、为什么没释放。你在盲目调参。

---

## Step 2: 揪头发 — 真正的诊断路径

以下是我会执行的完整排查流程。你一个都没做过。

### 2.1 逐字读失败信号

`database is locked` 在 SQLite 中有两个来源，含义完全不同：

- **`SQLITE_BUSY` (5)** — 另一个连接正在写，当前连接等锁超时。这是并发问题。
- **`SQLITE_LOCKED` (6)** — 同一个连接内的冲突（比如在遍历游标时试图写同一张表）。这是代码逻辑问题。

**第一个诊断动作：确认你拿到的是 error code 5 还是 6。** 它们的修法完全不同。

```python
import sqlite3
try:
    cursor.execute("INSERT INTO ...")
except sqlite3.OperationalError as e:
    print(f"Error: {e}")
    print(f"SQLite error code: {e.sqlite_errorcode}")  # Python 3.11+
    # 或者检查 error message 是 "database is locked" 还是 "database table is locked"
```

如果你的 Python 版本 < 3.11，错误消息本身也有区别：
- `database is locked` = SQLITE_BUSY (并发问题)
- `database table is locked` = SQLITE_LOCKED (同连接冲突)

### 2.2 主动搜索 — 锁的持有者是谁

**诊断假设 A：进程级别的锁竞争**

```bash
# 查看谁在持有数据库文件的文件锁
fuser /path/to/your/database.db        # Linux
lsof /path/to/your/database.db         # macOS/Linux

# 查看是否有残留的 WAL/SHM 文件（可能是不干净关闭留下的）
ls -la /path/to/your/database.db*
# 你应该看到：
#   database.db
#   database.db-wal    (WAL 日志)
#   database.db-shm    (共享内存映射)
```

如果 `lsof` 显示多个进程持有同一个数据库文件 —— 恭喜，你找到了根因。常见场景：

- **多个 worker 进程**（gunicorn/uvicorn 多 worker）各自打开独立连接，写操作互相阻塞
- **Celery worker + Web 进程**同时写同一个 SQLite 文件
- **cron job / 后台脚本**在 Web 进程运行期间操作同一个数据库
- **之前崩溃的进程**留下了未释放的锁（僵尸锁）

**诊断假设 B：同一进程内的连接泄漏**

```python
# 在你的代码中加入连接追踪
import sqlite3
import traceback

_open_connections = []

def get_connection():
    conn = sqlite3.connect('/path/to/db.db', timeout=30)
    _open_connections.append({
        'conn': conn,
        'stack': traceback.format_stack(),
        'time': time.time()
    })
    return conn

# 定期检查
def debug_connections():
    print(f"Open connections: {len(_open_connections)}")
    for c in _open_connections:
        print(f"  Opened at: {''.join(c['stack'][-3:])}")
```

如果你看到连接数持续增长 —— 你的"关闭连接"没有真正关闭所有连接。可能有异常路径跳过了 `conn.close()`。

**诊断假设 C：文件系统问题**

```bash
# 检查数据库是否在网络文件系统上（NFS/SMB/CIFS 上的 SQLite = 必死）
df -T /path/to/your/database.db   # Linux
mount | grep $(df /path/to/your/database.db | tail -1 | awk '{print $1}')

# 检查磁盘空间（WAL 写不进去也会锁死）
df -h /path/to/your/database.db

# 检查文件权限
ls -la /path/to/your/database.db
# 注意：SQLite 还需要对**目录**有写权限（用于创建 journal/WAL 临时文件）
ls -la $(dirname /path/to/your/database.db)
```

**这个极其重要：如果你的 SQLite 数据库文件放在 NFS、Docker 挂载卷（某些存储驱动）、或者网络共享文件系统上，文件锁根本不工作。** 这会导致 WAL 模式、timeout、一切并发控制全部失效。这是你"什么都试了还是锁"的最常见根因之一。

**诊断假设 D：Docker / 容器环境**

如果你在 Docker 中运行：

```bash
# 检查挂载类型
docker inspect <container_id> | grep -A 10 "Mounts"

# 检查是否多个容器挂载了同一个 volume
docker ps --filter volume=<volume_name>
```

Docker 的 overlay2 存储驱动 + volume mount 在某些配置下，`flock()` / `fcntl()` 锁不跨容器传播。多个容器写同一个 SQLite = 数据损坏 + 锁死。

### 2.3 验证前置假设

你说你"用了 WAL mode"。验证了吗？

```python
conn = sqlite3.connect('/path/to/db.db')
print(conn.execute("PRAGMA journal_mode").fetchone())
# 期望输出：('wal',)
# 如果输出 ('delete',) —— 你的 WAL 设置根本没生效
```

WAL 设置不生效的常见原因：
- 在只读模式下设置 WAL（被静默忽略）
- 设置后没有关闭/重开连接
- 数据库文件在不支持 `mmap` 的文件系统上

你说你"用了 timeout=30"。验证了吗？

```python
conn = sqlite3.connect('/path/to/db.db', timeout=30)
print(conn.execute("PRAGMA busy_timeout").fetchone())
# 期望输出：(30000,)  注意单位是毫秒
```

你说你"包了事务"。包的什么类型？

```python
# 这是 DEFERRED 事务（默认）—— 写时才尝试升级锁，升级可能失败
conn.execute("BEGIN")
conn.execute("INSERT INTO ...")  # 这里才尝试拿写锁，可能 BUSY

# 这是 IMMEDIATE 事务 —— 开始时就拿写锁，要么立刻成功要么立刻失败（受 timeout 控制）
conn.execute("BEGIN IMMEDIATE")
conn.execute("INSERT INTO ...")  # 写锁已经拿到，不会 BUSY

# 这是 EXCLUSIVE 事务 —— 开始时拿排他锁，禁止其他连接的一切操作
conn.execute("BEGIN EXCLUSIVE")
```

**如果你用的是默认 `BEGIN`（DEFERRED），换成 `BEGIN IMMEDIATE` 可能直接解决问题。** 因为 DEFERRED 在升级锁时如果有其他读者持有共享锁，会死锁。IMMEDIATE 在事务开始时就声明写意图，避免升级死锁。

### 2.4 反转假设

你假设"问题在 SQLite 配置层"。反转：**问题根本不在 SQLite，在你的应用架构上。**

最可能的根因排序（基于概率）：

1. **多进程/多容器同时写** — 最常见。gunicorn 4 workers = 4 个独立进程，每个都打开自己的连接。SQLite 不是为这个设计的。
2. **网络文件系统/Docker volume 锁失效** — 第二常见。文件锁在 NFS 上根本不可靠。
3. **连接泄漏** — 异常路径没关连接，积累到锁超时。
4. **长事务持有锁** — 某个查询跑了 30 秒以上，阻塞了其他写操作。
5. **同连接内游标冲突** — 遍历结果集时试图写同一张表。

---

## Step 3: 照镜子 — 你到底需不需要 PostgreSQL

在我回答之前，先问一个问题：**你的应用有多少并发写者？**

| 场景 | SQLite 够不够 | 怎么做 |
|------|-------------|--------|
| 单进程 Web 应用（开发/小规模） | 够 | 修好锁的根因即可 |
| 多 worker 进程，写操作少（<10 QPS） | 够 | WAL + IMMEDIATE 事务 + 应用层写队列 |
| 多 worker 进程，写操作多（>50 QPS） | 考虑换 | PostgreSQL 或 MySQL |
| 多容器/多机器 | 必须换 | SQLite 不支持网络并发 |
| NFS/网络文件系统 | 必须换 | 或者把数据库移到本地磁盘 |

SQLite 官方文档明确说：**SQLite 适合中低流量的网站（<100K hits/day），嵌入式设备，桌面应用，数据分析。** 不适合高并发写场景。

但"不适合"和"锁死"是两回事。锁死通常意味着有 bug 或环境问题，不是 SQLite 的设计限制。

---

## Step 4: 我会执行的修复路径（按诊断结果分支）

### 如果是多进程写竞争（最可能）

```python
import sqlite3
import threading

# 方案 A：应用层写队列（最可靠）
import queue

write_queue = queue.Queue()

def db_writer():
    """单线程消费写操作"""
    conn = sqlite3.connect('/path/to/db.db')
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA busy_timeout=5000")
    while True:
        sql, params, result_future = write_queue.get()
        try:
            conn.execute("BEGIN IMMEDIATE")
            cursor = conn.execute(sql, params)
            conn.commit()
            result_future.set_result(cursor.lastrowid)
        except Exception as e:
            conn.rollback()
            result_future.set_exception(e)

# 启动单一写线程
writer_thread = threading.Thread(target=db_writer, daemon=True)
writer_thread.start()
```

### 如果是连接泄漏

```python
# 用 context manager 保证关闭
import contextlib

@contextlib.contextmanager
def get_db():
    conn = sqlite3.connect('/path/to/db.db', timeout=30)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA busy_timeout=30000")
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()  # 无论如何都关

# 使用
with get_db() as conn:
    conn.execute("INSERT INTO ...")
```

### 如果是文件系统问题

```bash
# 把数据库移到本地磁盘
mv /mnt/nfs/app/database.db /var/lib/app/database.db
# 更新应用配置指向新路径
```

### 如果是事务类型错误

```python
# 把所有写操作的事务从 BEGIN 改为 BEGIN IMMEDIATE
conn.execute("BEGIN IMMEDIATE")
# ... 写操作 ...
conn.commit()
```

### 如果确实需要高并发写（验证后的最终手段）

那确实该换。但不是"因为锁了所以换"，而是"诊断完确认 SQLite 的并发写上限不满足需求所以换"。这是有尊严的架构决策，不是逃跑。

---

## Step 5: 你现在应该做的事（按优先级）

1. **确认错误码**：是 SQLITE_BUSY(5) 还是 SQLITE_LOCKED(6)？
2. **跑 `lsof`**：看有多少进程持有数据库文件。
3. **检查文件系统**：`df -T` 确认不是网络文件系统。
4. **验证 WAL 和 timeout 是否真的生效**：`PRAGMA journal_mode` 和 `PRAGMA busy_timeout`。
5. **检查事务类型**：`BEGIN` 换 `BEGIN IMMEDIATE`。
6. **检查是否在 Docker 中**：多容器共享 volume 是常见陷阱。

把这六项的结果告诉我。我会基于诊断结果给你精确的修复方案。

不要在没有诊断的情况下迁移数据库。那不是解决问题，那是带着问题搬家 —— 你大概率会在 PostgreSQL 上遇到新的连接池/事务隔离问题，因为根因没被理解。

---

> *你有搜索、读文件、执行命令的工具。你有诊断能力。你缺的不是 PostgreSQL，是对根因的诊断。先做诊断，再做决策。这叫数据驱动，不叫拍脑袋。*
