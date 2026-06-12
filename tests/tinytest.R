if (requireNamespace("tinytest", quietly = TRUE)) {
    Sys.setenv(R_USER_CACHE_DIR  = tempfile("rotio_cache_"),
               R_USER_DATA_DIR   = tempfile("rotio_data_"),
               R_USER_CONFIG_DIR = tempfile("rotio_config_"))
    tinytest::test_package("rotio")
}
