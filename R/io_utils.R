tag_item <- function(x, tag_val) {
  if (is.null(x)) x <- list()
  attr(x, "tag") <- tag_val
  x
}

tag_list_col <- function(x) {
  x %<>%
    purrr::modify(~tag_item(., "list")) %>%
    tag_item("list_col")
  x
}


serialize_df <- function(x) {

  out <- x %>%
    dplyr::mutate(dplyr::across(where(is.list), tag_list_col)) %>%
    purrr::transpose() %>%
    purrr::set_names( nm = purrr::map_chr(., "name"))

  out %<>%
    yaml::as.yaml()
  out
}

list_handler <- function(x) {
  tag_item(x, "list")
}

has_list_tag <- function(x) {
  x %<>% attr("tag")

  if (rlang::is_empty(x)) return(FALSE)

  return("list" %in% x)
}

restore_col_type <- function(x) {
  is_list_col <- x %>%
    purrr::map_lgl(has_list_tag) %>%
    any()

  if (is_list_col) {
    x %<>%
      tag_list_col() %>%
      purrr::simplify_all()
  } else {
    x %<>% unlist()
  }

  x
}

deserialize_df <- function(x) {
  out <- x %>% yaml::yaml.load(handlers = list(list = list_handler))

  out %<>% purrr::set_names(NULL)

  out %<>%
    purrr::transpose() %>%
    tibble::as_tibble()

  out %<>%
    dplyr::mutate(
      dplyr::across(
        dplyr::everything(), restore_col_type)
    )

  out
}

default_column_map_input_path <- function() {
  "mandrake"
}

#' Load a package colspec to case
#'
#' The package colspec may be consumed by [link_col2doc()], in order to
#' link column names to their metadata.
#' If `lookup_cache` is `NULL`/empty, a new one will be made.
#'
#' @export
#' @param pkg_name the name of the package from which the set of columns
#'        should be loaded.
#' @param lookup_cache the `storr::storr` object, generated by
#'        `load_package_colspec()`, containing keys (given by column aliases)
#'        mapping to column metadata lists.
load_package_colspec <- function(pkg_name, lookup_cache = NULL) {
  # If no store is given, make one
  st <- lookup_cache
  if (rlang::is_empty(st)) st <- storr::storr_environment()

  `%||%` <- rlang::`%||%`
  pkg_path <- system.file(package = pkg_name, lib.loc = .libPaths())

  opts <- roxygen2::load_options(pkg_path)

  mandrake_path <- opts$mandrake_output %||%
    default_column_map_input_path()

  # The directory containing the mapppings
  mandrake_path <- file.path(pkg_path, mandrake_path)

  message("Adding cols from ", pkg_name, " to lookup cache")

  spec_paths <- mandrake_path %>%
    list.files(pattern = ".*\\.ya?ml$")

  spec_paths %>%
    purrr::walk(function(path) {
      message("Including ", path, " in lookup cache")
      spec <- file.path(mandrake_path, path) %>% load_colspec_file()

      spec %>%
        dplyr::group_by(name) %>%
        dplyr::group_walk(add_entry_to_cache, lookup_cache = st, .keep = TRUE)

      invisible(NULL)
    })


  return(st)
}


#' Load colspec from a single file, to be imported into storr cache
load_colspec_file <- function(path) {
  out <- path %>%
    readLines() %>%
    paste0(collapse = "\n") %>%
    deserialize_df()

  out
}

add_entry_to_cache <- function(entry, keys, lookup_cache = NULL) {
  if (rlang::is_empty(lookup_cache))
    stop("Empty lookup cache given to add_entry_to_cache")

  grouping_cols <- names(keys)

  keys %<>% dplyr::pull()

  main_key <- keys


  fix_entry_duplication <- function(entry, main_key) {
    first_entry <- entry %>% dplyr::slice_head()

    topics <- entry$topic %>% jsonlite::toJSON()
    first_topic <- first_entry$topic %>% jsonlite::toJSON()

    if (nrow(entry) > 1) {
      warning(
        "Multiple defintions for ", main_key, " given in ",
        topics, " keeping only definition from ", first_topic
        )
    }

    return(first_entry)
  }

  entry %<>% fix_entry_duplication(main_key)

  aliases <- entry %>%
    dplyr::pull(aliases) %>%
    purrr::flatten_chr()

  keys %<>% c(aliases)

  pkg_ns <- paste0("package:",entry$package)

  dest_namespace <- "unique"
  src_namespace <- lookup_cache$default_namespace

  handle_previous_defs <- function(keys, entry, lookup_cache) {
    already_defined <- lookup_cache$exists(keys)

    if (any(already_defined)) {
      defd_keys <- keys[already_defined]
      previous_defs <- defd_keys %>%
        lookup_cache$mget() %>%
        purrr::map2_dfr(defd_keys, function(entry, key) {
          entry %<>%
            dplyr::mutate(key = key)
          entry
        }) %>%
        glue::glue_data(
          "{key}@{package}::{topic}"
        )

      warning(
        "For entry @ ",
        jsonlite::toJSON(entry$topic),
        ". keys already defined: ",
        jsonlite::toJSON(previous_defs))

      keys %<>% .[!already_defined]
    }
    keys
  }

  keys %<>% handle_previous_defs(entry, lookup_cache)

  entry %<>% dplyr::filter(name %in% keys)

  # Only bother filling the cache if there's something to fill
  if (!rlang::is_empty(keys) & nrow(entry) > 0) {
    # Make the value referencable by the formal name, or any of its
    # aliases
    lookup_cache$fill(keys, entry)
    lookup_cache$fill(keys, entry, namespace = pkg_ns)
    # Add it to the 1:1 namespace that links formal name to values
    # (no alias linkage)
    lookup_cache$duplicate(
      main_key,
      main_key,
      namespace_src = src_namespace,
      namespace_dest = dest_namespace
    )
  }

  # Drop these before return to ensure functionality
  # with group_modify
  entry %<>% dplyr::select(-c(grouping_cols))

  invisible(entry)
}
