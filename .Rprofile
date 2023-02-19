# avoid parsing examples in scripts
setHook(packageEvent("pkgdown", "onLoad"), function(...) {
  assignInNamespace("can_parse", function (x) TRUE, "pkgdown")
})

# avoid highlighting errors in scripts
setHook(packageEvent("pkgdown", "onLoad"), function(...) {
  fun <- getFromNamespace("highlight_examples", asNamespace("pkgdown"))
  assignInNamespace("highlight_examples", function (code, topic, env) {
    if (topic == "scripts")
      pkgdown:::highlight_text(code)
    else fun(code, topic, env)
  }, "pkgdown")
})
