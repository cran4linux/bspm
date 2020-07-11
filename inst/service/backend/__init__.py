libnames = ["dnf", "apt"]
attrs = ["discover", "install", "remove"]

for libname in libnames:
    try:
        lib = __import__("backend." + libname, globals(), locals(), attrs, 0)
        for attr in attrs:
            globals()[attr] = getattr(lib, attr)
        del globals()[libname]
        break
    except:
        pass

if attrs[0] not in globals():
    raise ImportError("no suitable backend found")

del lib, libname, libnames, attr, attrs
