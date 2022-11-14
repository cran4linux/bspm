from ._utils import mark, pkg_record
import sys
import dnf
import dnf.cli.progress
import dnf.cli.output

def discover():
    progress = dnf.cli.progress.MultiFileProgressMeter(fo=sys.stdout)
    base = dnf.Base()
    base.read_all_repos()
    base.repos.all().set_progress_bar(progress)
    base.fill_sack()

    q = base.sack.query()
    pkgs = q.available().filterm(name__glob="R-*[!-debuginfo][!-devel]")
    prefixes = {"-".join(x.name.split("-")[:-1]) + "-" for x in pkgs}

    base.close()

    return {
        "prefixes": sorted(list(prefixes - {"R-TH-"})),
        "exclusions": ["R-core", "R-core-devel", "R-devel", "R-java",
            "R-java-devel", "R-rpm-macros"]
    }

def available(prefixes, exclusions):
    progress = dnf.cli.progress.MultiFileProgressMeter(fo=sys.stdout)
    base = dnf.Base()
    base.read_all_repos()
    base.repos.all().set_progress_bar(progress)
    base.update_cache()
    base.fill_sack()

    q = base.sack.query().available().latest()
    q = q.filterm(name__glob=[_ + "*" for _ in prefixes])
    pkgs = []
    for pkg in q:
        if not pkg.source_name or pkg.name in exclusions:
            continue
        pkgs.append(pkg_record(
            prefixes,
            pkg.source_name,
            pkg.version,
            pkg.reponame
        ))
    pkgs = list(dict.fromkeys(pkgs))

    base.close()

    return pkgs

def install(prefixes, pkgs, exclusions):
    progress = dnf.cli.progress.MultiFileProgressMeter(fo=sys.stdout)
    base = dnf.Base()
    base.read_all_repos()
    base.repos.all().set_progress_bar(progress)
    base.update_cache()
    base.fill_sack()

    notavail = mark(base.install, prefixes, pkgs, exclusions, post=base.upgrade)

    base.resolve()
    base.download_packages(base.transaction.install_set, progress)
    base.do_transaction(dnf.cli.output.CliTransactionDisplay())
    base.close()

    return notavail

def remove(prefixes, pkgs, exclusions):
    base = dnf.Base()
    base.fill_sack()

    notavail = mark(base.remove, prefixes, pkgs, exclusions)

    base.resolve(True)
    base.do_transaction(dnf.cli.output.CliTransactionDisplay())
    base.close()

    return notavail
