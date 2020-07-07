#!/usr/bin/python3

import backend

from os.path import realpath, dirname
path = dirname(realpath(__file__))
exec(open(path + "/dbus-paths").read())
exec(open(path + "/PackageManager.conf").read())

import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-r", action="store_true",
                    help="remove; otherwise, install (with -u only)")
parser.add_argument("-o", metavar="file", type=str,
                    help="output file (with -u only)")
parser.add_argument("-u", metavar="pkg", type=str, nargs="+",
                    help="run as a user instead of as a service")
args = parser.parse_args()

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
    
    def redirect_stdout_handle_exceptions(timeout):
        def _redirect_stdout_handle_exceptions(fn):
            @wraps(fn)
            def wrapper(self, pid, *args, **kw):
                signal.alarm(0)
                with stderr(pid) as f, redirect_stdout(f):
                    try:
                        out = fn(self, pid, *args, **kw)
                    except Exception as err:
                        raise PackageManagerException(str(err))
                    finally:
                        signal.alarm(timeout)
                return out
            return wrapper
        return _redirect_stdout_handle_exceptions
    
    class PackageManager(dbus.service.Object):
        
        @dbus.service.method(IFACE, in_signature="ias", out_signature="as")
        @redirect_stdout_handle_exceptions(10)
        def install(self, pid, pkgs):
            print("Installing system packages...", flush=True)
            return backend.install(PREFIX, pkgs)
        
        @dbus.service.method(IFACE, in_signature="ias", out_signature="as")
        @redirect_stdout_handle_exceptions(10)
        def remove(self, pid, pkgs):
            print("Removing system packages...", flush=True)
            return backend.remove(PREFIX, pkgs)
    
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

def run_as_user():
    if not args.r:
        print("Installing system packages...", flush=True)
        pkgs = backend.install(PREFIX, args.u)
    else:
        print("Removing system packages...", flush=True)
        pkgs = backend.remove(PREFIX, args.u)
    
    if args.o is not None:
        with open(args.o, "a") as f:
            for pkg in pkgs:
                f.write(pkg + "\n")
    else:
        print("Not processed:", pkgs)

if __name__ == "__main__":
    if args.u is None:
        run_as_service()
    else:
        run_as_user()
