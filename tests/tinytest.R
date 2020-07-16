if (requireNamespace("tinytest", quietly=TRUE)) {
  home <- identical(Sys.getenv("CI"), "true")
  tinytest::test_package("bspm", at_home=home)
}
