from ._utils import mark, cache_update
from functools import partial
import pycman

def discover():
    # TBD
    return {
        "prefixes": ["r-"],
        "exclusions": []
    }

def _update(handle):
    for db in handle.get_syncdbs():
        db.update(False)

def _install(handle, t, repos, name):
    ok, pkg = pycman.action_sync.find_sync_package(name, repos)
    t.add_pkg(pkg)

def _remove(handle, t, repos, name):
    pkg = handle.get_localdb().get_pkg(name)
    t.remove_pkg(pkg)

def operation(op, prefixes, pkgs, exclusions):
    args = pycman.action_sync.parse_options([])
    handle = pycman.config.init_with_config_and_options(args)
    
    handle.dlcb = pycman.transaction.cb_dl
    handle.eventcb = pycman.transaction.cb_event
    handle.questioncb = pycman.transaction.cb_conv
    handle.progresscb = pycman.transaction.cb_progress
    
    repos = dict((db.name, db) for db in handle.get_syncdbs())
    t = handle.init_transaction()
    cache_update(partial(_update, handle))
    
    fun = partial(op, handle, t, repos)
    notavail = mark(fun, prefixes, pkgs, exclusions, trans="lower")
    
    try:
        t.prepare()
        t.commit()
    except:
        pass
    t.release()
    
    return notavail

def install(prefixes, pkgs, exclusions):
    return operation(_install, prefixes, pkgs, exclusions)

def remove(prefixes, pkgs, exclusions):
    return operation(_remove, prefixes, pkgs, exclusions)
