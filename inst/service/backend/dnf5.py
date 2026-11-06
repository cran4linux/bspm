from ._utils import mark, pkg_record
from .dnf5_progress import DownloadCallbacks, TransactionCallbacks
import libdnf5

GLOB = libdnf5.common.QueryCmp_GLOB
NEQ = libdnf5.common.QueryCmp_NEQ
AVAILABLE = libdnf5.repo.Repo.Type_AVAILABLE
SYSTEM = libdnf5.repo.Repo.Type_SYSTEM

def _setup(repo_type=None):
    base = libdnf5.base.Base()
    base.load_config()
    base.setup()
    callbacks = DownloadCallbacks()
    callbacks.__disown__() # now owned by base
    base.set_download_callbacks(libdnf5.repo.DownloadCallbacksUniquePtr(callbacks))
    repo_sack = base.get_repo_sack()
    repo_sack.create_repos_from_system_configuration()

    if repo_type != SYSTEM:
        print("Updating and loading repositories:", flush=True)
    if repo_type is None:
        repo_sack.load_repos()
    else:
        repo_sack.load_repos(repo_type)
    if repo_type != SYSTEM:
        print("Repositories loaded.", flush=True)

    callbacks.reset(packages=True)
    return base

def discover():
    base = _setup(AVAILABLE)

    q = libdnf5.rpm.PackageQuery(base)
    q.filter_name("R-*[!-debuginfo][!-devel]", GLOB)
    prefixes = {"-".join(x.get_name().split("-")[:-1]) + "-" for x in q}

    return {
        "prefixes": sorted(list(prefixes - {"R-TH-"})),
        "exclusions": ["R-core", "R-core-devel", "R-devel", "R-java",
            "R-java-devel", "R-rpm-macros"]
    }

def available(prefixes, exclusions):
    base = _setup(AVAILABLE)

    q = libdnf5.rpm.PackageQuery(base)
    # exclude source packages: unlike dnf4, they have a source name
    q.filter_arch(["src"], NEQ)
    q.filter_latest_evr()
    q.filter_name([_ + "*" for _ in prefixes], GLOB)
    pkgs = []
    for pkg in q:
        if pkg.get_name() in exclusions:
            continue
        pkgs.append(pkg_record(
            prefixes,
            pkg.get_source_name(),
            pkg.get_version(),
            pkg.get_repo_id()
        ))
    pkgs = list(dict.fromkeys(pkgs))

    return pkgs

def _add(base, fn_installed, fn_available = None):
    class Query:
        def __init__(self, pkg):
            self.q = libdnf5.rpm.PackageQuery(base)
            self.q.filter_name(pkg)
            self.q.filter_arch(["src"], NEQ)
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
    if transaction.get_problems() != libdnf5.base.GoalProblem_NO_PROBLEM:
        raise Exception("\n".join(transaction.get_resolve_logs_as_strings()))
    if transaction.empty():
        return

    actions = [_.get_action() for _ in transaction.get_transaction_packages()]
    actions = {iats(_) : actions.count(_) for _ in [INSTALL, UPGRADE, REMOVE]}
    transaction.set_description(f"bspm transaction: {actions}")

    transaction.download()

    print("Running transaction", flush=True)
    callbacks = TransactionCallbacks(transaction)
    callbacks.__disown__() # now owned by transaction
    transaction.set_callbacks(libdnf5.rpm.TransactionCallbacksUniquePtr(callbacks))
    ret = transaction.run()
    callbacks.finish()

    if ret != libdnf5.base.Transaction.TransactionRunResult_SUCCESS:
        raise Exception("\n".join([
            transaction.transaction_result_to_string(ret),
            *transaction.get_transaction_problems(),
            *transaction.get_gpg_signature_problems()
        ]))

def install(prefixes, pkgs, exclusions):
    base = _setup()

    goal = libdnf5.base.Goal(base)
    fn = _add(base, goal.add_upgrade, goal.add_install)
    notavail = mark(fn, prefixes, pkgs, exclusions)
    _run(goal)

    return notavail

def remove(prefixes, pkgs, exclusions):
    base = _setup(SYSTEM)

    goal = libdnf5.base.Goal(base)
    goal.set_allow_erasing(True)
    fn = _add(base, goal.add_remove)
    notavail = mark(fn, prefixes, pkgs, exclusions)
    _run(goal)

    return notavail
