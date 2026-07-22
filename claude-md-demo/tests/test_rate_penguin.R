library(testthat)

# Locate this file, so the test runs from any working directory.
.this_file <- NULL
for (.f in sys.frames()) {
  if (!is.null(.f$ofile)) .this_file <- .f$ofile
}
if (is.null(.this_file)) {
  # Not source()d (e.g. Rscript) -- fall back to the script path.
  .args <- commandArgs(trailingOnly = FALSE)
  .this_file <- sub("^--file=", "", grep("^--file=", .args, value = TRUE))
}
.repo <- dirname(dirname(normalizePath(.this_file)))
source(file.path(.repo, "R", "rate_penguin.R"))

test_that("chinstraps get the hat bonus", {
  expect_gt(rate_penguin("Pingu", "chinstrap"), rate_penguin("Pingu", "adelie"))
})

test_that("scores stay in range", {
  expect_lte(rate_penguin("Bartholomew Featherington III", "chinstrap"), 10)
  expect_gte(rate_penguin("Al"), 1)
})

test_that("nonsense input is rejected", {
  expect_error(rate_penguin(42))
  expect_error(rate_penguin("Pingu", "ostrich"))
})

test_that("colonies come back sorted best first", {
  colony <- rate_colony(c("Al", "Bartholomew"))
  expect_equal(colony$name[1], "Bartholomew")
})
