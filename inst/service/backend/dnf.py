from ._utils import mark
import sys
import dnf
import dnf.cli.progress
import dnf.cli.output

def discover():
    return {
        "prefixes": ["R-"],
        "exclusions": ["R-core", "R-core-devel", "R-devel", "R-java",
            "R-java-devel", "R-rpm-macros"]
    }

def install(prefixes, pkgs, exclusions):
    progress = dnf.cli.progress.MultiFileProgressMeter(fo=sys.stdout)
    base = dnf.Base()
    base.read_all_repos()
    base.repos.all().set_progress_bar(progress)
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
