from ._utils import mark
import apt

# workaround for Ubuntu 18.04
# https://github.com/Enchufa2/bspm/issues/15
import os
if not os.getenv("PATH"):
    os.environ["PATH"] = "/usr/bin:/usr/sbin:/bin:/sbin"

CACHE_INVALIDATION_TIME = 5 # minutes

def discover():
    import re
    
    cache = apt.Cache()
    cache_update(cache, apt.progress.text.AcquireProgress(), force=True)
    cache.open()
    pkgs = [x for x in cache.keys() if re.match("^r-(.*)-(.*)", x)]
    prefixes = {"-".join(x.split("-")[0:2]) + "-" for x in pkgs}
    
    return {
        "prefixes": list(prefixes - {"r-doc-", "r-base-"}),
        "exclusions": []
    }

def cache_update(cache, aprogress=None, force=False):
    import time
    from pathlib import Path
    from os import path
    cache_file = path.dirname(path.realpath(__file__)) + "/_cache"
    try:
        cache_time = path.getmtime(cache_file)
    except:
        cache_time = 0
    if force or time.time() - cache_time > CACHE_INVALIDATION_TIME * 60:
        cache.update(aprogress)
        Path(cache_file).touch()

def operation(op, prefixes, pkgs, exclusions):
    def cc(cache, method):
        def wrapper(pkgname):
            getattr(cache[pkgname], "mark_" + method)()
            if not getattr(cache[pkgname], "marked_" + method):
                raise Exception("cannot " + method + " " + pkgname)
        return wrapper
    
    oprogress = apt.progress.text.OpProgress()
    aprogress = apt.progress.text.AcquireProgress()
    
    cache = apt.Cache(oprogress)
    cache_update(cache, aprogress)
    cache.open(oprogress)
    
    notavail = mark(cc(cache, op), prefixes, pkgs, exclusions, trans="lower")
    
    cache.commit(aprogress)
    cache.close()
    
    return notavail

def install(prefixes, pkgs, exclusions):
    return operation("install", prefixes, pkgs, exclusions)

def remove(prefixes, pkgs, exclusions):
    return operation("delete", prefixes, pkgs, exclusions)
