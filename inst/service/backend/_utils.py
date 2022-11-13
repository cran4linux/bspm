from contextlib import suppress
from pathlib import Path
from os import path
import time

CACHE_INVALIDATION_TIME = 5 # minutes

def mark(method, prefixes, pkgs, exclusions, trans=None, post=None):
    processed = []
    for pkg in pkgs:
        for prefix in prefixes:
            pkgname = prefix + pkg
            if trans is not None:
                pkgname = getattr(pkgname, trans)()
            if pkgname in exclusions:
                continue
            with suppress(Exception):
                method(pkgname)
                processed.append(pkg)
                if post is not None:
                    with suppress(Exception):
                        post(pkgname)
                break
    return list(set(pkgs) - set(processed))

def cache_update(method, force=False):
    cache_file = path.dirname(path.realpath(__file__)) + "/_cache"
    try:
        cache_time = path.getmtime(cache_file)
    except:
        cache_time = 0
    if force or time.time() - cache_time > CACHE_INVALIDATION_TIME * 60:
        method()
        Path(cache_file).touch()

def pkg_strip(prefixes, pkg):
    for prefix in prefixes:
        pkg = pkg.replace(prefix, "")
    return pkg
