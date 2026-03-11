## Nginx Config Review

You asked if it "looks OK." Short answer: it works, but it has several issues that will bite you in production. A P8 doesn't say "looks fine" and walk away -- here's the full picture.

### The Config You Gave Me

```nginx
server {
    listen 80;
    server_name example.com;
    location / {
        proxy_pass http://localhost:3000;
    }
}
```

---

### Issue 1: No HTTPS -- Traffic is Plaintext

This only listens on port 80 (HTTP). All traffic between clients and nginx is unencrypted. For any production site, you need TLS.

**Fix:** Add an HTTPS server block and redirect HTTP to HTTPS:

```nginx
server {
    listen 80;
    server_name example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com;

    ssl_certificate     /etc/ssl/certs/example.com.pem;
    ssl_certificate_key /etc/ssl/private/example.com.key;

    location / {
        proxy_pass http://localhost:3000;
    }
}
```

---

### Issue 2: Missing Proxy Headers

Without forwarding headers, your backend app on port 3000 will see every request as coming from `127.0.0.1`. It won't know the real client IP, the original protocol, or the requested host. This breaks logging, rate limiting, auth checks, and any redirect logic.

**Fix:** Add these inside the `location /` block:

```nginx
proxy_set_header Host              $host;
proxy_set_header X-Real-IP         $remote_addr;
proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
```

---

### Issue 3: No WebSocket Support

If your app on port 3000 uses WebSockets (common with Node.js frameworks, hot-reload in dev, real-time features), connections will fail silently because nginx defaults to HTTP/1.0 for upstream and doesn't pass the `Upgrade` header.

**Fix:**

```nginx
proxy_http_version 1.1;
proxy_set_header Upgrade    $http_upgrade;
proxy_set_header Connection "upgrade";
```

---

### Issue 4: No Timeouts or Buffering Controls

With defaults, a slow backend response can tie up nginx worker connections. You have no explicit timeout policy.

**Fix:** Add sensible defaults:

```nginx
proxy_connect_timeout 10s;
proxy_send_timeout    30s;
proxy_read_timeout    30s;
proxy_buffering       on;
```

---

### Issue 5: No `www` Handling

If someone visits `www.example.com`, this config won't match it (unless there's another server block or a wildcard). That's a silent 404 or default-server fallback.

**Fix:** Either add `www.example.com` to `server_name` or add a redirect block:

```nginx
server {
    listen 80;
    server_name www.example.com;
    return 301 https://example.com$request_uri;
}
```

---

### Issue 6: No Rate Limiting or Security Headers

No protection against basic abuse, and no security headers for the browser.

**Recommended additions** (in the server or http context):

```nginx
# Rate limiting (define zone in http block)
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;

# In server block
add_header X-Frame-Options        "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection       "1; mode=block" always;
add_header Referrer-Policy         "strict-origin-when-cross-origin" always;
```

---

### Issue 7: No Access or Error Log Paths

Without explicit log directives, logs go to the global default. For multi-site setups, this makes debugging painful.

```nginx
access_log /var/log/nginx/example.com.access.log;
error_log  /var/log/nginx/example.com.error.log;
```

---

### Recommended Full Config

Putting it all together:

```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    return 301 https://example.com$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com;

    ssl_certificate     /etc/ssl/certs/example.com.pem;
    ssl_certificate_key /etc/ssl/private/example.com.key;

    access_log /var/log/nginx/example.com.access.log;
    error_log  /var/log/nginx/example.com.error.log;

    add_header X-Frame-Options        "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection       "1; mode=block" always;
    add_header Referrer-Policy         "strict-origin-when-cross-origin" always;

    location / {
        proxy_pass http://localhost:3000;

        proxy_http_version 1.1;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade           $http_upgrade;
        proxy_set_header Connection        "upgrade";

        proxy_connect_timeout 10s;
        proxy_send_timeout    30s;
        proxy_read_timeout    30s;
        proxy_buffering       on;
    }
}
```

---

### Summary

| # | Issue | Severity | Impact |
|---|-------|----------|--------|
| 1 | No HTTPS | Critical | All traffic is plaintext |
| 2 | No proxy headers | High | Backend can't see real client info |
| 3 | No WebSocket support | Medium | WebSocket connections silently fail |
| 4 | No timeouts | Medium | Slow backends can exhaust workers |
| 5 | No www handling | Low | www subdomain falls through |
| 6 | No security headers | Medium | Missing browser-side protections |
| 7 | No per-site logs | Low | Harder to debug in multi-site setups |

The original config is syntactically valid and will technically proxy traffic. But "it works" and "it's production-ready" are very different bars. The issues above are what separate a dev test from a real deployment.
