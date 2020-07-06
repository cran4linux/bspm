import sys
import dnf
import dnf.cli.progress
import dnf.cli.output

def install(prefix, pkgs):
    progress = dnf.cli.progress.MultiFileProgressMeter(fo=sys.stdout)
    base = dnf.Base()
    base.read_all_repos()
    base.repos.all().set_progress_bar(progress)
    base.fill_sack()
    
    notavail = []
    for pkg in pkgs:
        try:
            base.install(prefix + pkg)
            base.upgrade(prefix + pkg)
        except dnf.exceptions.PackagesNotInstalledError:
            pass
        except:
            notavail.append(pkg)
    
    base.resolve()
    base.download_packages(base.transaction.install_set, progress)
    base.do_transaction(dnf.cli.output.CliTransactionDisplay())
    base.close()
    
    return notavail

def remove(prefix, pkgs):
    base = dnf.Base()
    base.fill_sack()
    
    notavail = []
    for pkg in pkgs:
        try:
            base.remove(prefix + pkg)
        except:
            notavail.append(pkg)
    
    base.resolve(True)
    base.do_transaction(dnf.cli.output.CliTransactionDisplay())
    base.close()
    
    return notavail
