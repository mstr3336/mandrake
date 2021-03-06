context("Does col roclet correctly process col tags?")


test_that("Col roclet correctly handles col tags", {
  fail("TNI")
})

test_that("Col roclet correctly handles inheritCol tags", {
  fail("TNI")
})

setup_input_no_tags <- function() {
"
#' Hello
#'
foo <- function() 'bar'
"
}

test_that("Col roclet correctly handles no col / inheritCol tags", {
  input <- setup_input_no_tags()
  d <- tempdir()

  results <- roxygen2::roc_proc_text(col_roclet(), input)

  expect_true(rlang::is_empty(results) | nrow(results) == 0)

  roxygen2::roclet_output(col_roclet(), results, d)

  expect_false(file.exists(file.path(d, "inst/mandrake")))


})

