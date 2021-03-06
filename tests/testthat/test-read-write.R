context("read-write")

sc <- testthat_spark_connection()

test_that("spark_read_csv() succeeds when column contains similar non-ascii", {
  csv <- file("test.csv", "w+", encoding = "latin1")
  cat("Município;var;var 1.0\n1233;1;2", file=csv)
  close(csv)

  df <- spark_read_csv(sc,name="teste",path="test.csv",header = TRUE,
                       delimiter = ";",charset = "Latin1",memory = FALSE)

  expect_true(
    all(dplyr::tbl_vars(df) == c("Municipio", "var", "var_1_0")),
    info = "success reading non-ascii similar columns from csv")

  file.remove("test.csv")
})

test_that("spark_read_json() can load data using column names", {
  json <- file("test.json", "w+")
  cat("{\"Sepal_Length\":5.1,\"Species\":\"setosa\", \"Other\": { \"a\": 1, \"b\": \"x\"}}\n", file = json)
  cat("{\"Sepal_Length\":4.9,\"Species\":\"setosa\", \"Other\": { \"a\": 2, \"b\": \"y\"}}\n", file = json)
  close(json)

  df <- spark_read_json(
    sc,
    name = "iris_json_named",
    path = "test.json",
    columns = c("a", "b", "c")
  )

  testthat::expect_equal(colnames(df), c("a", "b", "c"))

  file.remove("test.json")
})

test_that("spark_read_json() can load data using column types", {
  json <- file("test.json", "w+")
  cat("{\"Sepal_Length\":5.1,\"Species\":\"setosa\", \"Other\": { \"a\": 1, \"b\": \"x\"}}\n", file = json)
  cat("{\"Sepal_Length\":4.9,\"Species\":\"setosa\", \"Other\": { \"a\": 2, \"b\": \"y\"}}\n", file = json)
  close(json)

  df <- spark_read_json(
    sc,
    name = "iris_json_typed",
    path = "test.json",
    columns = list("Sepal_Length" = "character", "Species" = "character", "Other" = "struct<a:integer,b:character>")
  ) %>% collect()

  expect_true(is.character(df$Sepal_Length))
  expect_true(is.character(df$Species))
  expect_true(is.list(df$Other))

  file.remove("test.json")
})

test_that("spark_read_csv() can read long decimals", {
  csv <- file("test.csv", "w+")
  cat("decimal\n1\n12312312312312300000000000000", file = csv)
  close(csv)

  df <- spark_read_csv(
    sc,
    name = "test_big_decimals",
    path = "test.csv"
  )

  expect_equal(nrow(df), 2)

  file.remove("test.csv")
})
