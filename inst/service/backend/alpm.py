from ._utils import mark, pkg_strip, ver_strip
from functools import partial
import pycman

_db_sync = False
_target = None

def discover():
    # TBD
    return {
        "prefixes": ["r-"],
        "exclusions": []
    }

def _get_handle():
    def _cb_dl(filename, tx, total):
        global _db_sync, _target
        if _db_sync:
            if tx == 3:
                print(" %s" % filename.split(".")[0])
        else:
            if filename != _target:
                _target = filename
                print(" %s" % filename.split(".pkg.")[0])

    def _cb_event(id, msg):
        global _target
        if id == 9:
            print(":: Processing package changes...")
        elif id == 21:
            _target = None
            print(":: Retrieving packages...")

    def _cb_progress(target, percent, n, i):
        global _target
        if len(target) > 0 and target != _target:
            _target = target
            print("(%d/%d) %s" % (i, n, target))

    args = pycman.action_sync.parse_options([])
    handle = pycman.config.init_with_config_and_options(args)

    handle.dlcb = _cb_dl
    handle.eventcb = _cb_event
    handle.progresscb = _cb_progress

    return handle

def _update(handle):
    global _db_sync
    print(":: Synchronizing package databases...")
    _db_sync = True
    for db in handle.get_syncdbs():
        db.update(False)
    _db_sync = False

def _install(handle, t, repos, name):
    ok, pkg = pycman.action_sync.find_sync_package(name, repos)
    t.add_pkg(pkg)

def _remove(handle, t, repos, name):
    pkg = handle.get_localdb().get_pkg(name)
    t.remove_pkg(pkg)

def available(prefixes, exclusions):
    handle = _get_handle()

    q = []
    for db in handle.get_syncdbs():
        for prefix in prefixes:
            q += [_ for _ in db.search(prefix) if _.name.startswith(prefix)]
    pkgs = []
    for pkg in q:
        if pkg.name in exclusions:
            continue
        pkgs.append(" ".join([
            pkg_strip(sorted(prefixes, reverse=True), pkg.name),
            ver_strip(pkg.version),
            pkg.db.name
        ]))

    return pkgs

def operation(op, prefixes, pkgs, exclusions):
    handle = _get_handle()
    repos = dict((db.name, db) for db in handle.get_syncdbs())
    t = handle.init_transaction()
    _update(handle)

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
