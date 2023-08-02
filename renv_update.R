renvpkg <- packageDescription("renv")
ver <- as.character(renvpkg$Version)
print(renvpkg)
if (endsWith(ver, "9000") && length(renvpkg$GithubRef) > 0L) {
  ver <- paste0("rstudio/renv@", renvpkg$GithubRef)
} else {
  ver <- paste0("renv@", ver)
}
cat(paste("updating to", ver))
renv::record(ver)
renv::restore(library = renv::paths$library())
renv::update(library = renv::paths$library())
renv::snapshot()
