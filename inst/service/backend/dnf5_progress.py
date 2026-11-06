import os, sys, time
import libdnf5

# progress report, ported from libdnf5-cli (progress bars) and dnf5 (callbacks),
# because the former cannot be used from Python: there is no way to add a bar to
# a MultiProgressBar (it requires a unique_ptr), and they don't honor sys.stdout

READY, STARTED, SUCCESS, ERROR = range(4)
INFO, OK, WARNING, FAILURE = "", "\033[32m", "\033[33m", "\033[31m"
RESET, CLEAR = "\033[0m", "\033[0J"
PREFIX = ">>> "

def _size(x):
    units = ["B", "KiB", "MiB", "GiB", "TiB", "PiB"]
    while x > 999:
        x /= 1024
        units.pop(0)
    return f"{x:.1f} {units[0]:>3}".rjust(9)

def _time(x):
    minutes, seconds = divmod(abs(x), 60)
    if minutes < 60:
        return f" {minutes:02d}m{seconds:02d}s"
    hours, minutes = divmod(minutes, 60)
    if hours < 24:
        return f" {hours:02d}h{minutes:02d}m"
    days, hours = divmod(hours, 24)
    return f" {days:02d}d{hours:02d}h" if days < 100 else " ?     "

def _tty():
    return sys.stdout.isatty()

def _width():
    try:
        return os.get_terminal_size(sys.stdout.fileno()).columns or 80
    except (OSError, ValueError):
        return 80

class _Bar:
    def __init__(self, total_ticks, description, numbered=True):
        self.total_ticks = total_ticks
        self.description = description
        self.numbered = numbered
        self.state = READY
        self.number = self.total = self.ticks = 0
        self.percent = self.current_speed = self.average_speed = 0
        self.elapsed = self.remaining = 0
        self.messages = []

    def start(self):
        self.begin = self.window_start = time.monotonic()
        self.window_ticks = 0
        self.state = STARTED

    def set_ticks(self, ticks):
        if self.state == STARTED:
            self.window_ticks += ticks - self.ticks
        self.ticks = ticks

    def set_state(self, state):
        self.update()
        self.state = state

    def finished(self):
        return self.state in (SUCCESS, ERROR)

    def update(self):
        if self.finished() or self.state == READY:
            return
        if self.total_ticks < 0:
            self.percent = -1
        elif self.total_ticks == 0 or self.ticks >= self.total_ticks:
            self.percent = 100
        else:
            self.percent = int(self.ticks / self.total_ticks * 100)

        now = time.monotonic()
        ms = int((now - self.window_start) * 1000)
        if ms > 950:
            self.current_speed = self.window_ticks * 1000 // ms
            self.window_ticks, self.window_start = 0, now
        elif self.current_speed == 0 and ms != 0:
            self.current_speed = self.window_ticks * 1000 // ms
        ms = int((now - self.begin) * 1000)
        self.average_speed = self.ticks * 1000 // ms if ms else 0
        self.elapsed = round(now - self.begin)

        if self.total_ticks < 0:
            self.remaining = -1
        elif self.ticks >= self.total_ticks:
            self.remaining = 0
        elif self.current_speed:
            self.remaining = (self.total_ticks - self.ticks) // self.current_speed

    def _progress(self):
        if self.total_ticks > 0 and self.ticks > 0:
            done = round(self.ticks / self.total_ticks * 18)
            return "[" + ("=" * done).ljust(18) + "]"
        pos = int((time.monotonic() - self.begin) * 2) % 16
        return "[" + " " * pos + "<=>" + " " * (15 - pos) + "]"

    def to_string(self, width):
        self.update()
        final = self.finished() or self.total_ticks < 0
        n = len(str(max(self.number, self.total)))
        percent = "???" if self.percent < 0 else self.percent
        speed = self.average_speed if final else self.current_speed
        # widgets as [name, text, width]
        widgets = [
            ["desc", " " + self.description, 22],
            ["percent", f" {percent:>3}%", 5],
            ["progress", " " + self._progress() if self.state == STARTED else "", 21],
            ["speed", f" | {_size(speed)}/s", 14],
            ["size", f" | {_size(self.ticks)}", 12],
            ["time", " | " + _time(self.elapsed if final else self.remaining), 10],
        ]
        if self.numbered:
            widgets.insert(0, ["number", f"[{self.number:>{n}}/{self.total:>{n}}]", 3 + 2 * n])

        used = lambda: sum(w[2] for w in widgets)
        desc = next(w for w in widgets if w[0] == "desc")
        for name in ["progress", "speed", "time"]:
            if used() > width or (name == "progress" and self.state != STARTED):
                widgets = [w for w in widgets if w[0] != name]
        if used() > width and desc[2] > used() - width:
            desc[2] -= used() - width
        elif used() < width:
            desc[2] += width - used()

        tty = _tty()
        line = "".join(text[:size].ljust(size) for _, text, size in widgets)
        if tty and self.state == ERROR:
            line = FAILURE + line + RESET
        for color, message in self.messages:
            line += "\n" + PREFIX
            line += color + message + RESET if tty and color else message
        return line

    def message_lines(self, width):
        return sum((len(PREFIX + m) - 1) // width + 1 if m else 1 for _, m in self.messages)

class _MultiBar:
    def __init__(self, show_total=False):
        self.show_total = show_total
        self.bars = 0
        self.todo = []
        self.done = self.done_ticks = 0
        self.lines = 0
        self.last = time.monotonic()
        self.total = _Bar(0, "Total")
        self.total.start()

    def add(self, bar):
        self.bars += 1
        bar.number = self.bars
        self.total.total = max(self.total.total, self.bars)
        self.todo.append(bar)

    def print_throttled(self):
        now = time.monotonic()
        if now - self.last > 0.1:
            self.last = now
            self.print()

    def print(self):
        tty, width = _tty(), _width()
        out = ""
        if tty and self.lines > 0:
            if self.lines > 1:
                out += f"\033[{self.lines - 1}A"
            out += "\r" + CLEAR
        self.lines = 0
        pending = False
        number = self.done

        for bar in [_ for _ in self.todo if _.finished()]:
            number += 1
            bar.number, bar.total = number, self.total.total
            out += bar.to_string(width) + "\n"
            self.done_ticks += max(bar.ticks, 0)
            self.done += 1
            self.todo.remove(bar)

        for bar in [_ for _ in self.todo if _.state == STARTED]:
            number += 1
            bar.number = number
            if not tty:
                bar.update()
                continue
            bar.total = self.total.total
            out += ("\n" if pending else "") + bar.to_string(width)
            pending = True
            self.lines += 1 + bar.message_lines(width)

        all_done = self.bars == self.done
        if self.show_total and (tty or all_done):
            out += ("\n" if pending else "") + "-" * width + "\n"
            total = self.total
            total.number = self.done
            total.total_ticks = self.done_ticks + sum(max(_.total_ticks, 0) for _ in self.todo)
            total.set_ticks(self.done_ticks + sum(max(_.ticks, 0) for _ in self.todo))
            if all_done:
                total.set_state(SUCCESS)
            out += total.to_string(width)
            self.lines += 2
            if total.finished():
                out += "\n"

        print(out, end="", flush=True)

class DownloadCallbacks(libdnf5.repo.DownloadCallbacks):
    def __init__(self):
        super().__init__()
        self.reset()

    def reset(self, packages=False):
        self.packages = packages
        self.multi = _MultiBar(show_total=packages)
        self.items = []

    def add_new_download(self, user_data, description, total_to_download):
        total = int(total_to_download) if total_to_download > 0 else -1
        bar = _Bar(total, description, numbered=self.packages)
        self.multi.add(bar)
        self.items.append(bar)
        return len(self.items) - 1

    def progress(self, user_cb_data, total_to_download, downloaded):
        bar = self.items[user_cb_data]
        if total_to_download > 0:
            bar.total_ticks = int(total_to_download)
        if bar.state == READY:
            bar.start()
        bar.set_ticks(int(downloaded))
        self.multi.print_throttled()
        return self.OK

    def end(self, user_cb_data, status, msg):
        bar = self.items[user_cb_data]
        if status == self.TransferStatus_SUCCESSFUL:
            if bar.state == READY:
                bar.start()
            bar.total_ticks = bar.ticks
            bar.set_state(SUCCESS)
        elif status == self.TransferStatus_ALREADYEXISTS:
            bar.ticks = bar.total_ticks = 0
            bar.messages.append((OK, msg))
            bar.start()
            bar.set_state(SUCCESS)
        else:
            if bar.state == READY:
                bar.start()
            bar.messages.append((FAILURE, msg))
            bar.set_state(ERROR)
        self.multi.print()
        return self.OK

    def mirror_failure(self, user_cb_data, msg, url, metadata):
        message = f"{msg} - {url}" + (f" - {metadata}" if metadata else "")
        self.items[user_cb_data].messages.append((FAILURE, message))
        self.multi.print()
        return self.OK

class TransactionCallbacks(libdnf5.rpm.TransactionCallbacks):
    def __init__(self, transaction):
        super().__init__()
        self.transaction = transaction
        self.multi = _MultiBar()
        self.multi.total.total = transaction.get_transaction_packages_count() + 1
        self.active = None

    def _new_bar(self, total, description):
        if self.active and self.active.state != ERROR:
            self.active.set_state(SUCCESS)
        self.active = _Bar(total, description)
        self.multi.add(self.active)
        self.active.start()

    def _set_ticks(self, amount):
        self.active.set_ticks(amount)
        self.multi.print_throttled()

    def _rpm_messages(self, color):
        msgs = [f"[RPM] {_}" for _ in self.transaction.get_rpm_messages()]
        self.active.messages += [(color, _) for _ in msgs]
        return len(msgs)

    def _script_output(self, color):
        lines = self.transaction.get_last_script_output().split("\n")
        if lines == [""]:
            return 0
        self.active.messages += [(color, _) for _ in ["Scriptlet output:", *lines]]
        return len(lines)

    def _stop(self, item, amount, total):
        self._rpm_messages(WARNING)
        self.multi.print()

    def _error(self, name, item):
        self._rpm_messages(FAILURE)
        self.active.messages.append((FAILURE, f"{name} error: {item.get_package().get_full_nevra()}"))
        self.active.set_state(ERROR)
        self.multi.print()

    def finish(self):
        if self.active and self.active.state != ERROR:
            self.active.set_state(SUCCESS)
        if self.active:
            self.multi.print()
        self.transaction = None

    def install_start(self, item, total):
        action = item.get_action()
        msg = {
            libdnf5.transaction.TransactionItemAction_UPGRADE: "Upgrading",
            libdnf5.transaction.TransactionItemAction_DOWNGRADE: "Downgrading",
            libdnf5.transaction.TransactionItemAction_REINSTALL: "Reinstalling",
        }.get(action, "Installing")
        self._new_bar(total, f"{msg} {item.get_package().get_full_nevra()}")

    def install_progress(self, item, amount, total):
        self._set_ticks(amount)

    def install_stop(self, item, amount, total):
        self._stop(item, amount, total)

    def uninstall_start(self, item, total):
        msg = "Removing" if item.get_action() in (
            libdnf5.transaction.TransactionItemAction_REMOVE,
            libdnf5.transaction.TransactionItemAction_REPLACED) else "Cleanup"
        self._new_bar(total, f"{msg} {item.get_package().get_full_nevra()}")

    def uninstall_progress(self, item, amount, total):
        self._set_ticks(amount)

    def uninstall_stop(self, item, amount, total):
        self._stop(item, amount, total)

    def transaction_start(self, total):
        self._new_bar(total, "Prepare transaction")

    def transaction_progress(self, amount, total):
        self._set_ticks(amount)

    def transaction_stop(self, total):
        self.active.set_ticks(total)
        self.multi.print()

    def verify_start(self, total):
        self.multi.total.total += 1
        self._new_bar(total, "Verify package files")

    def verify_progress(self, amount, total):
        self._set_ticks(amount)

    def verify_stop(self, total):
        self.active.set_ticks(total)
        self.multi.print()

    def script_start(self, item, nevra, type):
        if not self.active:
            self.multi.total.total += 1
            self._new_bar(-1, "Running scriptlets")
        name = libdnf5.rpm.to_full_nevra_string(nevra)
        script = self.script_type_to_string(type)
        self.active.messages.append((INFO, f"Running {script} scriptlet: {name}"))
        self.multi.print()

    def script_stop(self, item, nevra, type, return_code):
        name = libdnf5.rpm.to_full_nevra_string(nevra)
        script = self.script_type_to_string(type)
        color = WARNING
        if return_code == 0:
            self.active.messages.append((INFO, f"Finished {script} scriptlet: {name}"))
        elif return_code == 1:
            self.active.messages.append((WARNING, f"Non-critical error in {script} scriptlet: {name}"))
        else:
            color = FAILURE
            self.active.messages.append((FAILURE, f"Error in {script} scriptlet: {name}"))
        lines = self._script_output(color) + self._rpm_messages(color)
        if return_code == 0 and lines == 0:
            del self.active.messages[-2:]
        self.multi.print()

    def unpack_error(self, item):
        self._error("Unpack", item)

    def cpio_error(self, item):
        self._error("Cpio", item)
