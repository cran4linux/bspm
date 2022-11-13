from ._utils import mark, cache_update
from functools import partial
import re
import apt

# workaround for Ubuntu 18.04
# https://github.com/Enchufa2/bspm/issues/15
import os
if not os.getenv("PATH"):
    os.environ["PATH"] = "/usr/bin:/usr/sbin:/bin:/sbin"

def discover():
    aprogress = apt.progress.text.AcquireProgress()
    cache = apt.Cache()
    cache_update(partial(cache.update, aprogress), force=True)
    cache.open()

    pkgs = [x for x in cache.keys() if re.match("^r-(.*)-(.*)", x)]
    prefixes = {"-".join(x.split("-")[0:2]) + "-" for x in pkgs}

    cache.close()

    return {
        "prefixes": list(prefixes - {"r-doc-", "r-base-"}),
        "exclusions": []
    }

def operation(op, prefixes, pkgs, exclusions):
    def cc(cache, method):
        def wrapper(pkgname):
            getattr(cache[pkgname], "mark_" + method)()
        return wrapper

    oprogress = apt.progress.text.OpProgress()
    aprogress = apt.progress.text.AcquireProgress()

    cache = apt.Cache(oprogress)
    cache_update(partial(cache.update, aprogress))
    cache.open(oprogress)

    notavail = mark(cc(cache, op), prefixes, pkgs, exclusions, trans="lower")

    cache.commit(aprogress)
    cache.close()

    return notavail

def install(prefixes, pkgs, exclusions):
    return operation("install", prefixes, pkgs, exclusions)

def remove(prefixes, pkgs, exclusions):
    return operation("delete", prefixes, pkgs, exclusions)
