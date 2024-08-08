from ._utils import mark, pkg_record
import libdnf5

GLOB = libdnf5.rpm.common.QueryCmp_GLOB
AVAILABLE = libdnf5.repo.Repo.Type_AVAILABLE
SYSTEM = libdnf5.repo.Repo.Type_SYSTEM

def _setup():
    base = libdnf5.base.Base()
    # add callbacks for progress report??
    base.load_config()
    base.setup()
    repo_sack = base.get_repo_sack()
    repo_sack.create_repos_from_system_configuration()
    return base, repo_sack

def discover():
    base, repo_sack = _setup()
    repo_sack.load_repos(AVAILABLE)

    q = libdnf5.rpm.PackageQuery(base)
    q.filter_name("R-*[!-debuginfo][!-devel]", GLOB)
    prefixes = {"-".join(x.get_name().split("-")[:-1]) + "-" for x in q}

    return {
        "prefixes": sorted(list(prefixes - {"R-TH-"})),
        "exclusions": ["R-core", "R-core-devel", "R-devel", "R-java",
            "R-java-devel", "R-rpm-macros"]
    }

def available(prefixes, exclusions):
    base, repo_sack = _setup()
    repo_sack.load_repos(AVAILABLE)

    q = libdnf5.rpm.PackageQuery(base)
    q.filter_latest_evr()
    q.filter_name([_ + "*" for _ in prefixes], GLOB)
    pkgs = []
    for pkg in q:
        if not pkg.get_source_name() or pkg.get_name() in exclusions:
            continue
        pkgs.append(pkg_record(
            prefixes,
            pkg.get_source_name(),
            pkg.get_version(),
            pkg.get_repo_name()
        ))
    pkgs = list(dict.fromkeys(pkgs))

    return pkgs

def _add(base, fn_installed, fn_available = None):
    class Query:
        def __init__(self, pkg):
            self.q = libdnf5.rpm.PackageQuery(base)
            self.q.filter_name(pkg)
        def is_installed(self):
            self.q.filter_installed()
            return self.q.size() > 0
        def is_available(self):
            self.q.filter_available()
            return self.q.size() > 0

    def wrapper(pkg):
        if Query(pkg).is_installed():
            return fn_installed(pkg)
        if Query(pkg).is_available() and fn_available is not None:
            return fn_available(pkg)
        raise Exception(f"Package {pkg} not found")
    return wrapper

def _run(goal):
    INSTALL = libdnf5.transaction.TransactionItemAction_INSTALL
    UPGRADE = libdnf5.transaction.TransactionItemAction_UPGRADE
    REMOVE  = libdnf5.transaction.TransactionItemAction_REMOVE
    iats = libdnf5.transaction.transaction_item_action_to_string

    transaction = goal.resolve()
    actions = [_.get_action() for _ in transaction.get_transaction_packages()]
    actions = {iats(_) : actions.count(_) for _ in [INSTALL, UPGRADE, REMOVE]}
    transaction.set_description(f"bspm transaction: {actions}")

    transaction.download()
    ret = transaction.run()
    if ret:
        raise Exception(transaction.transaction_result_to_string(ret))

def install(prefixes, pkgs, exclusions):
    base, repo_sack = _setup()
    repo_sack.load_repos()

    goal = libdnf5.base.Goal(base)
    fn = _add(base, goal.add_upgrade, goal.add_install)
    notavail = mark(fn, prefixes, pkgs, exclusions)
    _run(goal)

    return notavail

def remove(prefixes, pkgs, exclusions):
    base, repo_sack = _setup()
    repo_sack.load_repos(SYSTEM)

    goal = libdnf5.base.Goal(base)
    fn = _add(base, goal.add_remove)
    notavail = mark(fn, prefixes, pkgs, exclusions)
    _run(goal)

    return notavail
