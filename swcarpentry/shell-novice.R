# transform shell-novice

# Fix episode 3, which has a div for a figure and it's messing up my parser :(
f <- fs::path(new, "episodes", "03-create.md")
ep3 <- readLines(f)
ep3_lines <- startsWith(ep3, "<div") | endsWith(ep3, "div>")
fig <- paste(ep3[ep3_lines], collapse = "")
if (fig != "") {
  img <- xml2::read_html(fig) |> xml2::xml_find_first(".//img")
  img_markdown <- paste0("![", xml2::xml_attr(img, "alt"), "](", 
    sub("../", "", xml2::xml_attr(img, "src")), ")")
  ep3[ep3_lines] <- c(img_markdown, rep("", sum(ep3_lines) - 1L))
}
writeLines(ep3, f)
ep <- Episode$new(f, fix_liquid = TRUE)
transform(ep, new)


