from ._utils import mark
import apt

CACHE_INVALIDATION_TIME = 5 # minutes

def discover():
    return {
        "prefixes": ["r-cran-", "r-bioc-", "r-omegahat-", "r-other-"],
        "exclusions": []
    }

def cache_update(cache, aprogress=None):
    import time
    from pathlib import Path
    from os import path
    cache_file = path.dirname(path.realpath(__file__)) + "/_cache"
    try:
        cache_time = path.getmtime(cache_file)
    except:
        cache_time = 0
    if time.time() - cache_time > CACHE_INVALIDATION_TIME * 60:
        cache.update(aprogress)
        Path(cache_file).touch()

def operation(op, prefixes, pkgs, exclusions):
    def cc(cache, method):
        def wrapper(pkgname):
            getattr(cache[pkgname], method)()
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
    return operation("mark_install", prefixes, pkgs, exclusions)

def remove(prefixes, pkgs, exclusions):
    return operation("mark_delete", prefixes, pkgs, exclusions)
