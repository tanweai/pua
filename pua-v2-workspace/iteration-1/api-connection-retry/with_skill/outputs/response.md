[自动选择：🟠 阿里L2 | 因为：卡住原地打转（换 URL 版本 + 加 timeout，本质都是参数微调，没换思路） | 改用：⬜ Jobs味/⬛ Musk味]

---

> 你这个方案的**底层逻辑**是什么？顶层设计在哪？抓手在哪？你换了 v2 到 v1，加了 timeout——这两个操作的底层假设都是"服务端能收到请求但响应有问题"。但 `ConnectionError` 说的是**连接本身就没建立起来**。你在调参数，但你连问题在哪一层都没搞清楚。你的差异化价值是什么？你的思考和方法论沉淀在哪？
>
> 今天最好的表现，是明天最低的要求。

---

## Step 1: 闻味道 -- 诊断卡壳模式

你尝试过的方案：
1. 原始调用 `https://api.example.com/v2/users` -- ConnectionError
2. 改 URL 为 `https://api.example.com/v1/users` -- ConnectionError
3. 添加 timeout 参数 -- ConnectionError

**共同模式**：三次尝试都是在"请求参数"层面微调（URL path、timeout）。但 `ConnectionError` 发生在 TCP/TLS 握手阶段，根本没到 HTTP 路由层。换 URL path 和加 timeout 对连接建立阶段的失败毫无意义。你在原地打转。

## Step 2: 揪头发 -- 拉高视角，5 个维度逐个执行

### 维度 1：逐字读失败信号

`ConnectionError` 不是 `HTTPError`、不是 `TimeoutError`、不是 `404`。它意味着：

- TCP 连接无法建立，或
- TLS 握手失败，或
- DNS 解析失败，或
- 连接被主动拒绝/重置

**我会执行的第一个动作**：要求你提供完整的 traceback 和错误信息。不是"ConnectionError"三个字，是完整的 stack trace。90% 的答案在你忽略的那些行里。

```python
import traceback
try:
    response = requests.get("https://api.example.com/v2/users")
except Exception as e:
    traceback.print_exc()  # 完整输出，不要只 print(e)
```

不同的底层异常指向完全不同的根因：

| 完整异常 | 含义 | 方向 |
|---------|------|------|
| `ConnectionError(MaxRetryError(NewConnectionError))` | TCP 连接建不上 | DNS/网络/防火墙 |
| `ConnectionError(SSLError)` | TLS 握手失败 | 证书/TLS版本/SNI |
| `ConnectionError(ConnectionResetError)` | 连接被对方重置 | 防火墙/WAF/IP封禁 |
| `ConnectionError(ProxyError)` | 代理配置问题 | 代理设置 |

### 维度 2：主动搜索 -- 用工具验证，不靠猜

我会执行以下命令来获取事实：

**DNS 解析验证**：
```bash
# 域名能不能解析？解析到什么 IP？
nslookup api.example.com
dig api.example.com +short
```

**网络连通性验证**：
```bash
# TCP 443 端口能不能通？
curl -v --connect-timeout 5 https://api.example.com/v2/users 2>&1

# 更底层：端口能不能连上？
nc -zv api.example.com 443 -w 5

# TLS 握手能不能成功？
openssl s_client -connect api.example.com:443 -servername api.example.com </dev/null 2>&1
```

**代理检测**：
```bash
# 环境里有没有代理变量在捣鬼？
echo $HTTP_PROXY $HTTPS_PROXY $http_proxy $https_proxy $NO_PROXY
env | grep -i proxy
```

**Python 环境内验证**：
```python
import socket
# DNS 层面
try:
    ip = socket.getaddrinfo("api.example.com", 443)
    print(f"DNS OK: {ip}")
except socket.gaierror as e:
    print(f"DNS FAILED: {e}")

# TCP 层面
import ssl, urllib3
urllib3.disable_warnings()
print(f"requests version: {requests.__version__}")
print(f"urllib3 version: {urllib3.__version__}")
print(f"OpenSSL version: {ssl.OPENSSL_VERSION}")
```

### 维度 3：读原始材料

我会检查你的实际代码。不是你描述的代码，是实际文件：

```
- 调用 API 的那个文件，出错行上下 50 行
- requirements.txt / pyproject.toml -- requests 版本是什么？
- 项目里有没有自定义的 Session、Adapter、或 SSL 配置？
- 有没有 .env 文件设置了代理？
- 有没有 requests 的 hooks 或 middleware？
```

### 维度 4：验证前置假设

你的隐含假设，逐个验证：

| 假设 | 验证方法 | 状态 |
|------|---------|------|
| `api.example.com` 域名存在且可解析 | `dig api.example.com` | 待验证 |
| 443 端口可达 | `nc -zv api.example.com 443` | 待验证 |
| 没有代理拦截 | `env \| grep -i proxy` | 待验证 |
| TLS 版本兼容 | `openssl s_client` | 待验证 |
| 本机网络正常 | `curl https://httpbin.org/get` | 待验证 |
| requests 库没有损坏 | `python -c "import requests; print(requests.__version__)"` | 待验证 |
| 没有防火墙/安全组拦截 | 从其他网络/机器测试 | 待验证 |

### 维度 5：反转假设

你一直假设"问题在请求参数"。现在反转：**问题根本不在你的代码里，而在基础设施层。**

三个本质不同的假设：

**假设 A -- 网络层问题（DNS/防火墙/代理）**：
你的机器根本连不上 `api.example.com`。可能是 DNS 污染、公司防火墙、代理配置、VPN 状态、或者这个域名本身就不存在（example.com 是保留域名）。

验证：`curl -v https://api.example.com/v2/users` 的输出。如果卡在 `Trying X.X.X.X...` 或 `Could not resolve host`，就是这个原因。

**假设 B -- TLS/SSL 层问题**：
TCP 能连上，但 TLS 握手失败。可能是 Python 的 OpenSSL 版本太旧不支持服务端要求的 TLS 1.3，或者服务端证书有问题，或者 SNI 配置不对。

验证：`openssl s_client -connect api.example.com:443` 的输出。看 `SSL handshake` 是否成功。

**假设 C -- 客户端环境问题**：
requests/urllib3 版本冲突、系统 CA 证书缺失、或者 Python 环境的 SSL 模块编译有问题（macOS 上 Python 3.12 的已知问题）。

验证：
```python
import ssl
print(ssl.OPENSSL_VERSION)
ctx = ssl.create_default_context()
print(f"CA certs loaded: {ctx.cert_store_stats()}")
```

## Step 3: 照镜子 -- 你犯了什么错

- 你在重复同一思路的变体：换 URL path 和加 timeout 都是 HTTP 层的调整，但 ConnectionError 发生在 TCP/TLS 层。这是**层级错误**。
- 你只看了表面症状（ConnectionError），没有读完整 traceback 找根因。
- 你该执行 `curl -v` 却没执行。该检查 DNS 却没检查。该查代理环境变量却没查。

## Step 4: 我会按以下顺序执行新方案

**方案 1（最可能）：网络层排查**
```bash
# 1. DNS
dig api.example.com +short

# 2. TCP 连通
nc -zv api.example.com 443 -w 5

# 3. 完整 curl 含 TLS 握手细节
curl -vvv --connect-timeout 10 https://api.example.com/v2/users 2>&1

# 4. 代理
env | grep -i proxy
```

如果 curl 也失败 -- 问题在网络层，不在 Python。
如果 curl 成功但 Python 失败 -- 问题在 Python 环境。

**方案 2（如果网络正常）：Python SSL 环境排查**
```python
import ssl, certifi, requests, urllib3
print(f"requests: {requests.__version__}")
print(f"urllib3: {urllib3.__version__}")
print(f"OpenSSL: {ssl.OPENSSL_VERSION}")
print(f"certifi CA: {certifi.where()}")

# 用底层 socket 直接连接
import socket
sock = socket.create_connection(("api.example.com", 443), timeout=10)
context = ssl.create_default_context()
ssock = context.wrap_socket(sock, server_hostname="api.example.com")
print(f"TLS version: {ssock.version()}")
ssock.close()
```

**方案 3（如果以上都正常）：隔离代码问题**
```python
# 最小复现 -- 排除项目中所有自定义配置
import requests
# 不用项目的 Session、不用自定义 Adapter、不用 .env
resp = requests.get("https://httpbin.org/get", timeout=10)
print(resp.status_code)  # 如果这个成功，问题在目标服务

resp2 = requests.get("https://api.example.com/v2/users", timeout=10)
print(resp2.status_code)
```

## 你现在需要给我的东西

我需要以下信息来精准定位（我已经列出了我会自行排查的所有步骤，这些是只有你能提供的）：

1. **完整的 traceback**（不是 "ConnectionError"，是 `traceback.print_exc()` 的完整输出）
2. **`curl -vvv https://api.example.com/v2/users 2>&1` 的输出**（含 TLS 握手过程）
3. **运行环境**：本地/Docker/CI？是否有 VPN/代理？公司网络还是公网？
4. **`env | grep -i proxy` 的输出**

## 主动延伸检查

即使当前问题解决后，我还会检查：

- [ ] 项目中其他 API 调用是否有同样的潜在风险（同一个 base URL 的其他 endpoint）
- [ ] 是否需要配置重试机制（`urllib3.util.Retry` + `requests.adapters.HTTPAdapter`）防止瞬时网络抖动
- [ ] 是否需要设置合理的 `connect_timeout` 和 `read_timeout` 分离（而不是一个笼统的 timeout）
- [ ] 错误处理是否完善 -- 区分 `ConnectionError`、`Timeout`、`HTTPError` 给用户不同的提示

---

**总结**：你之前三次尝试全部在 HTTP 层（URL path、timeout）做文章，但 `ConnectionError` 是 TCP/TLS 层的问题。这就像门锁坏了你在换钥匙的颜色。现在需要的是从网络层开始逐层排查：DNS -> TCP -> TLS -> 代理 -> Python SSL 环境 -> 代码。给我上面要求的 4 项信息，我来定位根因。
