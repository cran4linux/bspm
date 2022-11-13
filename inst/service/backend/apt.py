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

def available(prefixes, exclusions):
    aprogress = apt.progress.text.AcquireProgress()
    cache = apt.Cache()
    cache_update(partial(cache.update, aprogress))
    cache.open()

    q = [x for x in cache.keys() if re.match("|".join(prefixes), x)]
    pkgs = []
    for pkg in q:
        if pkg in exclusions:
            continue
        version = cache[pkg].candidate.version
        version = list(reversed(version.split(":", 1)))[0]
        version = version.rsplit("-", 1)[0]
        version = version.rsplit("+")[0]
        # remove things like .r79, see r-cran-rniftilib
        version = re.sub("\.r[0-9]+", "", version)
        pkgs.append(" ".join([
            cache[pkg].candidate.source_name,
            version,
            cache[pkg].candidate.origins[0].origin
        ]))

    cache.close()

    return pkgs

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
