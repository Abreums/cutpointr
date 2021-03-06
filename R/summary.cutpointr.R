#' @export
summary.cutpointr <- function(object, ...) {
    x_summary <- vector("list", nrow(object))
    names(x_summary) <- suppressWarnings(object$subgroup)
    for (r in 1:nrow(object)) {
        temprow <- object[r, ]
        if (has_column(object, "subgroup")) {
            x_summary[[r]]$subgroup <- temprow$subgroup
        }
        x_summary[[r]]$cutpointr <- temprow
        x_summary[[r]]$desc <- dplyr::bind_cols(
            tibble::tibble(Data = "Overall"),
            summary_sd_df(temprow$data[[1]] %>%
                              dplyr::select(temprow$predictor))
        )
        temprow_split <- temprow$data[[1]] %>%
            split(temprow$data[[1]][, temprow$outcome])
        x_summary[[r]]$desc_byclass <- temprow_split %>%
            purrr::map_df(function(x) {
                summary_sd_df(x %>% dplyr::select(temprow$predictor))
            })
        x_summary[[r]]$desc_byclass <- dplyr::bind_cols(
            data.frame(Data = names(temprow_split), stringsAsFactors = FALSE),
            x_summary[[r]]$desc_byclass
        )
        x_summary[[r]]$n_obs <- nrow(temprow$data[[1]])
        x_summary[[r]]$n_pos <- temprow$data[[1]] %>%
            dplyr::select(temprow$outcome) %>%
            unlist %>% (function(x) sum(x == temprow$pos_class))
        x_summary[[r]]$n_neg <- x_summary[[r]]$n_obs - x_summary[[r]]$n_pos
        # Confusion Matrix
        oi <- get_opt_ind(temprow$roc_curve[[1]],
                          oc = unlist(temprow$optimal_cutpoint),
                          direction = temprow$direction)
        x_summary[[r]]$confusion_matrix <- data.frame(
            cutpoint = unlist(temprow$optimal_cutpoint),
            temprow$roc_curve[[1]][oi, c("tp", "fn", "fp", "tn")]
        )
        if (has_boot_results(temprow)) {
            x_summary[[r]][["boot"]] <- temprow[["boot"]][[1]] %>%
                dplyr::select(-(TP_b:roc_curve_oob)) %>%
                purrr::map(function(x) {
                    summary_sd(x)
                })
            x_summary[[r]][["boot"]] <- do.call(rbind, x_summary[[r]][["boot"]])
            x_summary[[r]][["boot"]] <- as.data.frame(x_summary[[r]][["boot"]])
            x_summary[[r]][["boot"]] <- tibble::rownames_to_column(x_summary[[r]][["boot"]],
                                                              var = "Variable")
            x_summary[[r]]$boot_runs <- nrow(temprow[["boot"]][[1]])
        }
    }
    x_summary <- purrr::map_df(x_summary, tidy_summary)
    class(x_summary) <- c("summary_cutpointr", class(x_summary))
    return(x_summary)
}

# Convert the list output of summary.cutpointr to a data.frame
# x is a single element of the resulting list from summary.cutpointr.
tidy_summary <- function(x) {
    res <- tibble::tibble(
        cutpointr = list(x$cutpointr),
        desc = list(x$desc),
        desc_by_class = list(x$desc_byclass),
        n_obs = x$n_obs, n_pos = x$n_pos, n_neg = x$n_neg,
        confusion_matrix = list(x$confusion_matrix)
    )
    if (has_boot_results(x)) {
        res <- dplyr::bind_cols(res,
                                tibble::tibble(boot = list(x[["boot"]])),
                                boot_runs = x$boot_runs)
    }
    if (has_column(x, "subgroup")) {
        res <- dplyr::bind_cols(subgroup = x$subgroup, res)
    }
    return(res)
}