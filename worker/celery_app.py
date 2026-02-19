import logging
import os
import resource
import ssl
import sys
import time

import gevent
from celery import Celery
from celery.signals import worker_ready
from kombu import Exchange
from kombu import Queue

logging.basicConfig(level=logging.WARNING)
log = logging.getLogger(__name__)

app = Celery("reproduce")
app.conf.update(
    broker_url=os.environ.get("BROKER_URL", "amqps://guest:guest@rabbitmq:5671//"),
    broker_use_ssl={"ca_certs": "/certs/ca.crt", "cert_reqs": ssl.CERT_NONE},
    task_queues=[Queue("gevent", Exchange("celery"), routing_key="gevent.#")],
)


def _monitor_loop():
    time.sleep(5)
    from gevent.ssl import _SSLErrorReadTimeout

    while True:
        tb, count, size = _SSLErrorReadTimeout.__traceback__, 0, 0
        while tb:
            count += 1
            size += sys.getsizeof(tb)
            tb = tb.tb_next
        rss = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024
        log.warning("chain=%d | tb_size=%s bytes | rss=%.1f MB", count, f"{size:,}", rss)
        time.sleep(10)


@worker_ready.connect
def on_worker_ready(**kwargs):
    gevent.spawn(_monitor_loop)
