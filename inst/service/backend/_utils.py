from contextlib import suppress

def mark(method, prefixes, pkgs, exclusions, trans=None, post=None):
    processed = []
    for pkg in pkgs:
        for prefix in prefixes:
            pkgname = prefix + pkg
            if trans is not None:
                pkgname = getattr(pkgname, trans)()
            if pkgname in exclusions:
                continue
            with suppress(Exception):
                method(pkgname)
                processed.append(pkg)
                if post is not None:
                    with suppress(Exception):
                        post(pkgname)
                break
    return list(set(pkgs) - set(processed))
