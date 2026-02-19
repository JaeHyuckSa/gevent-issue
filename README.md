# gevent-ssl-traceback-leak

> `gevent.ssl._SSLErrorReadTimeout` singleton exception accumulates `__traceback__` frames on every raise, causing unbounded memory growth

## Why

`gevent/ssl.py` defines timeout exceptions as **module-level singletons**:

```python
_SSLErrorReadTimeout = _socket_timeout('The read operation timed out')
_SSLErrorWriteTimeout = _socket_timeout('The write operation timed out')
```

Any repeated SSL read/write timeout raises the **same object**. In Python 3, each `raise` chains a new `__traceback__` frame via `tb_next` — the chain grows forever and is never garbage collected.

```
SSLSocket.read() → _wait() → raise _SSLErrorReadTimeout  ← same singleton
  → Python attaches __traceback__, linked to previous via tb_next
    → chain: 1 → 2 → 3 → ... → unbounded
```

### Related Fix

The same bug was fixed for `FileObjectClosed` and `cancel_wait_ex` in [commit 52f5022](https://github.com/gevent/gevent/commit/52f5022) (2017) — converting singleton instances to classes. The SSL timeout singletons were missed.

## How to Reproduce

```bash
./certs/generate.sh
docker compose up --build
```

## Result

```
chain=96   | tb_size=5,376 bytes   | rss=54.1 MB
chain=320  | tb_size=17,920 bytes  | rss=54.2 MB
chain=528  | tb_size=29,568 bytes  | rss=54.2 MB
chain=736  | tb_size=41,216 bytes  | rss=54.4 MB
chain=944  | tb_size=52,864 bytes  | rss=54.4 MB
...                                  (keeps growing)
```

| Component | Version |
|-----------|---------|
| Python | 3.14 |
| gevent | 25.9.1 |
