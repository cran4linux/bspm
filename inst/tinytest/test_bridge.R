root_call <- bspm:::root_call

# fake sudo: receives <script> <method> -o <file> <pkgs>
fake_sudo <- function(...) {
  sudo <- tempfile()
  writeLines(c("#!/bin/sh", ...), sudo)
  Sys.chmod(sudo, "755")
  sudo
}

# failure before the script can report: stderr is shown
sudo <- fake_sudo("echo 'sudo: a terminal is required' >&2", "exit 1")
expect_error(root_call("install", "foo", sudo=sudo), "a terminal is required")

# failure reported by the script: stderr noise is not shown
sudo <- fake_sudo("echo 'no backend' >> \"$4\"", "echo 'Traceback' >&2", "exit 1")
expect_error(root_call("install", "foo", sudo=sudo), "^no backend$")

# failure with no output at all: exit status is shown
sudo <- fake_sudo("exit 137")
expect_error(root_call("install", "foo", sudo=sudo), "exit status 137")

# success: stderr does not leak into the results
sudo <- fake_sudo("echo 'r-cran-foo' >> \"$4\"", "echo 'sudo: warning' >&2")
expect_equal(root_call("install", "foo", sudo=sudo), "r-cran-foo")
