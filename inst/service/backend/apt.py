import apt

class TextInstallProgress(apt.progress.base.InstallProgress):
    def __init__(self):
        apt.progress.base.InstallProgress.__init__(self)
    
    def status_change(self, pkg, percent, status):
        print("%s ..." % (status))

def install(prefix, pkgs):
    oprogress = apt.progress.text.OpProgress()
    aprogress = apt.progress.text.AcquireProgress()
    iprogress = TextInstallProgress()
    
    cache = apt.Cache(oprogress)
    cache.update(aprogress)
    cache.open(oprogress)
    
    notavail = []
    for pkg in pkgs:
        try:
            cache[prefix + pkg.lower()].mark_install()
        except:
            notavail.append(pkg)
    
    cache.commit(aprogress, iprogress)
    cache.close()
    
    return notavail

def remove(prefix, pkgs):
    oprogress = apt.progress.text.OpProgress()
    aprogress = apt.progress.text.AcquireProgress()
    iprogress = TextInstallProgress()
    
    cache = apt.Cache(oprogress)
    cache.update(aprogress)
    cache.open(oprogress)
    
    notavail = []
    for pkg in pkgs:
        try:
            cache[prefix + pkg.lower()].mark_delete()
        except:
            notavail.append(pkg)
    
    cache.commit(aprogress, iprogress)
    cache.close()
    
    return notavail
