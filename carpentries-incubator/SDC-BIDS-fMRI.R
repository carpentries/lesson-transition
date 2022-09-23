# Episode 2 has a problem with the translation because they have a double 
# block quote when they only needed a single block quote. 
f <- fs::path(new, "episodes", "02-exploring-fmriprep.md")
k <- readLines(f)
k <- sub( '^[>][>]', '>', k)
writeLines(k, f)

e <- pegboard::Episode$new(fs::path(new, "episodes", "02-exploring-fmriprep.md"))
transform(e)

