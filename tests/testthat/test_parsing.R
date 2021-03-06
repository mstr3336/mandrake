context("May parse tags correctly")

help_test_matthews_col <- function(my_tag) {
  expect_equal(my_tag$tag, "col")
  expect_equal(my_tag$val$name, "matthews_col")
  expect_equal(my_tag$val$direction, list("in"))
  expect_identical(my_tag$val$aliases, list("matts_col"))
  expect_match(my_tag$val$rd, ".*\\\\strong\\{Beautiful\\}.*")
  expect_match(my_tag$val$rd, ".*\\\\link\\[mandrake:extract_column_names\\].*")

  expect_match(
    my_tag$val$html[[1]],
    "<strong>Beautiful</strong>",
    all = F)
  expect_match(
    my_tag$val$html[[1]],
    "<a href='.*/extract_column_names.html'>mandrake::extract_column_names.*</a>",
    all = F)
}

test_that("parsing our tag works", {
  input <- "
  #' @col [in] matthews_col [matts_col]
  #' I love matt's col. It is **Beautiful**.
  #' Check out [mandrake::extract_column_names()]
  #' @md
  matthews_function <- function(df) df
  "

  block <- roxygen2::parse_text(input)

  my_tag <- block[[1]]$tags[[1]]
  help_test_matthews_col(my_tag)


})

test_that("parsing a block with 2 deffs of our tag works", {
  input <- "
  #' @col [in] matthews_col [matts_col]
  #' I love matt's col. It is **Beautiful**.
  #' Check out [mandrake::extract_column_names()]
  #' @col [out] matthews_new_col [newcol, newest_col]
  #' @md
  matthews_function <- function(df) df
  "

  block <- roxygen2::parse_text(input)
  tags <- block[[1]]$tags

  help_test_matthews_col(tags[[1]])

  next_tag <- tags[[2]]

  expect_equal(next_tag$val$direction, list("out"))
  expect_equal(next_tag$tag, "col")
  expect_equal(next_tag$val$name, "matthews_new_col")
  expect_equal(!!next_tag$val$aliases, list(c("newcol", "newest_col")))

})

test_that("May parse valid R columns, such as those with full-stops", {
  fail("Test not implemented")
})

setup_input_inherit <- function() {
"
#' Hello
#' @col [in] matthews_col [matts_col]
#' I love matt's col. It is **Beautiful**.
#' Check out [mandrake::extract_column_names()]  is_in <- any(x$val$direction %in% dirs_in)
#'
#' @inheritCol mandrake [mpg, cyl]
#' @md
matthews_function_inherit <- function(df) df
"
}

inherit_parsed_expect <- function() {
  tibble::tibble(src = "mandrake", columns = list(c("mpg", "cyl")))
}

test_that("May parse inheritCol correctly", {
  input <- setup_input_inherit()
  block <- roxygen2::parse_text(input)

  block %<>% .[[1]]

  tags <- roxygen2::block_get_tags(block, "inheritCol")
  val <- tags[[1]]$val
  expect_equal(val, inherit_parsed_expect())

})
