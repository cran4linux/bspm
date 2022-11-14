#!/usr/bin/python3

import backend

from os import path
WDIR = path.dirname(path.realpath(__file__))
exec(open(WDIR + "/dbus-paths").read())

def read_conf(force_discover=False):
    global PREF, EXCL
    pref = WDIR + "/bspm.pref"
    excl = WDIR + "/bspm.excl"

    force_discover = force_discover and not path.exists(WDIR + "/nodiscover")
    if force_discover or not path.exists(pref) or not path.exists(excl):
        conf = backend.discover()
        with open(pref, "w") as fpref, open(excl, "w") as fexcl:
            for i in conf["prefixes"]:
                print(i, file=fpref)
            for i in conf["exclusions"]:
                print(i, file=fexcl)
    with open(pref) as fpref, open(excl) as fexcl:
        PREF = [line.rstrip() for line in fpref]
        EXCL = [line.rstrip() for line in fexcl]

def call_backend(cmd, pkgs=None, root=False):
    msg = cmd.capitalize() + " system packages"
    if root:
        msg = msg + " as root"
    msg = msg + "..."
    print(msg, flush=True)
    if pkgs:
        return getattr(backend, cmd)(PREF, pkgs, EXCL)
    return getattr(backend, cmd)(PREF, EXCL)

def run_as_service():
    from gi.repository import GLib

    import dbus
    import dbus.service
    import dbus.mainloop.glib

    from functools import wraps
    from contextlib import redirect_stdout
    import signal

    class PackageManagerException(dbus.DBusException):
        _dbus_error_name = IFACE + ".PackageManagerException"

    def stderr(pid):
        return open("/proc/" + str(pid) + "/fd/2", "w")

    def redirect_output(fn):
        @wraps(fn)
        def wrapper(self, pid, *args, **kw):
            with stderr(pid) as f, redirect_stdout(f):
                return fn(self, pid, *args, **kw)
        return wrapper

    def handle_exceptions(timeout):
        def _handle_exceptions(fn):
            @wraps(fn)
            def wrapper(*args, **kw):
                signal.alarm(0)
                try:
                    out = fn(*args, **kw)
                except Exception as err:
                    raise PackageManagerException(str(err))
                finally:
                    signal.alarm(timeout)
                return out
            return wrapper
        return _handle_exceptions

    class PackageManager(dbus.service.Object):

        @dbus.service.method(IFACE, in_signature="i", out_signature="")
        @handle_exceptions(10)
        @redirect_output
        def discover(self, pid):
            read_conf(True)
            return

        @dbus.service.method(IFACE, in_signature="i", out_signature="as")
        @handle_exceptions(10)
        @redirect_output
        def available(self, pid):
            return call_backend("available")

        @dbus.service.method(IFACE, in_signature="ias", out_signature="as")
        @handle_exceptions(10)
        @redirect_output
        def install(self, pid, pkgs):
            return call_backend("install", pkgs)

        @dbus.service.method(IFACE, in_signature="ias", out_signature="as")
        @handle_exceptions(10)
        @redirect_output
        def remove(self, pid, pkgs):
            return call_backend("remove", pkgs)

    def sigterm_handler(_signo, _stack_frame):
        mainloop.quit()

    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    signal.signal(signal.SIGINT, sigterm_handler)
    signal.signal(signal.SIGTERM, sigterm_handler)
    signal.signal(signal.SIGALRM, sigterm_handler)

    bus = dbus.SystemBus()
    bus.request_name(BUS_NAME)
    pm = PackageManager(bus, OPATH)

    mainloop = GLib.MainLoop()
    mainloop.run()

def run_as_root(args):
    if args.cmd == "discover":
        read_conf(True)
    else:
        pkgs = None
        if hasattr(args, "pkg"):
            pkgs = args.pkg
        pkgs = call_backend(args.cmd, pkgs, root=True)
        if args.o is not None:
            with open(args.o, "a") as f:
                for pkg in pkgs:
                    print(pkg, file=f)
        else:
            print("Result:", pkgs)

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    subparser = parser.add_subparsers(dest="cmd")
    parser_discover = subparser.add_parser("discover", aliases=["available"])
    parser_discover.add_argument("-o", metavar="file", type=str, help="output file")
    parser_install = subparser.add_parser("install", aliases=["remove"])
    parser_install.add_argument("pkg", type=str, nargs="+")
    parser_install.add_argument("-o", metavar="file", type=str, help="output file")

    args = parser.parse_args()
    read_conf()

    if args.cmd is None:
        run_as_service()
    else:
        run_as_root(args)
