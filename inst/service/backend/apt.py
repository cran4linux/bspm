from ._utils import mark
import apt

def discover():
    return {
        "prefixes": ["r-cran-", "r-bioc-", "r-omegahat-", "r-other-"],
        "exclusions": []
    }

class TextInstallProgress(apt.progress.base.InstallProgress):
    def __init__(self):
        apt.progress.base.InstallProgress.__init__(self)
    
    def status_change(self, pkg, percent, status):
        print("%s ..." % (status))

def operation(op, prefixes, pkgs, exclusions):
    def cc(cache, method):
        def wrapper(pkgname):
            getattr(cache[pkgname], method)()
        return wrapper
    
    oprogress = apt.progress.text.OpProgress()
    aprogress = apt.progress.text.AcquireProgress()
    iprogress = TextInstallProgress()
    
    cache = apt.Cache(oprogress)
    cache.update(aprogress)
    cache.open(oprogress)
    
    notavail = mark(cc(cache, op), prefixes, pkgs, exclusions, trans="lower")
    
    cache.commit(aprogress, iprogress)
    cache.close()
    
    return notavail

def install(prefixes, pkgs, exclusions):
    return operation("mark_install", prefixes, pkgs, exclusions)

def remove(prefixes, pkgs, exclusions):
    return operation("mark_delete", prefixes, pkgs, exclusions)
