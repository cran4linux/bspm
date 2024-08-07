from ._utils import mark, pkg_record
import libdnf5

GLOB = libdnf5.rpm.common.QueryCmp_GLOB
AVAILABLE = libdnf5.repo.Repo.Type_AVAILABLE
SYSTEM = libdnf5.repo.Repo.Type_SYSTEM

def _setup(repo_type):
    base = libdnf5.base.Base()
    # add callbacks for progress report??
    base.load_config()
    base.setup()
    repo_sack = base.get_repo_sack()
    repo_sack.create_repos_from_system_configuration()
    repo_sack.load_repos(repo_type)
    return base, repo_sack

def discover():
    base, repo_sack = _setup(AVAILABLE)

    q = libdnf5.rpm.PackageQuery(base)
    q.filter_available()
    q.filter_name("R-*[!-debuginfo][!-devel]", GLOB)
    prefixes = {"-".join(x.get_name().split("-")[:-1]) + "-" for x in q}

    return {
        "prefixes": sorted(list(prefixes - {"R-TH-"})),
        "exclusions": ["R-core", "R-core-devel", "R-devel", "R-java",
            "R-java-devel", "R-rpm-macros"]
    }

def available(prefixes, exclusions):
    base, repo_sack = _setup(AVAILABLE)

    q = libdnf5.rpm.PackageQuery(base)
    q.filter_available()
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

def install(prefixes, pkgs, exclusions): # does not work
    base, repo_sack = _setup(AVAILABLE)

    goal = libdnf5.base.Goal(base)
    ifun = goal.add_install # does not fail if package doesn't exist
    ufun = goal.add_upgrade
    notavail = mark(ifun, prefixes, pkgs, exclusions, post=ufun)

    transaction = goal.resolve()
    transaction.download()
    transaction.run() # does not raise, but returns an error code

    return notavail

def remove(prefixes, pkgs, exclusions): # does not work
    base, repo_sack = _setup(SYSTEM)

    goal = libdnf5.base.Goal(base)
    notavail = mark(goal.add_remove, prefixes, pkgs, exclusions)

    transaction = goal.resolve()
    transaction.run()

    return notavail
