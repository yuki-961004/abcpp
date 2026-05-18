############################
# Development Package Setup
############################

# Developer note.
local_r_libs <- base::c(
    base::file.path("build", "Rlib45"),
    base::file.path("build", "Rlib")
)
local_r_libs <- local_r_libs[base::dir.exists(local_r_libs)]
if (base::length(local_r_libs) > 0L) {
    base::.libPaths(base::c(local_r_libs, base::.libPaths()))
}

# Developer note.
ensure_namespace <- function(package_name) {
    if (!base::requireNamespace(package_name, quietly = TRUE)) {
        base::stop(
            "Package '",
            package_name,
            "' is required for this development script.",
            call. = FALSE
        )
    }
}

# Developer note.
ensure_abcpp <- function() {
    if (base::requireNamespace("abcpp", quietly = TRUE)) {
        return(base::invisible(TRUE))
    }

    if (base::requireNamespace("devtools", quietly = TRUE)) {
        devtools::load_all(base::file.path(".", "R"), quiet = TRUE)
        return(base::invisible(TRUE))
    }

    base::stop(
        "Install abcpp first, or install devtools for load_all().",
        call. = FALSE
    )
}

ensure_abcpp()
ensure_namespace("abc")

# Developer note.
base::options(width = base::max(120L, base::getOption("width")))

# Developer note.
dev_sections <- base::strsplit(
    x = base::Sys.getenv("ABCPP_DEV_SECTIONS", unset = "all"),
    split = ",",
    fixed = TRUE
)[[1L]]
dev_sections <- base::tolower(base::trimws(dev_sections))

run_dev_section <- function(section_name) {
    base::any(dev_sections %in% base::c("all", section_name))
}


############################
# Shared Helper Functions
############################

# Developer note.
max_abs_diff <- function(left, right) {
    left_matrix <- base::as.matrix(left)
    right_matrix <- base::as.matrix(right)
    base::max(base::abs(left_matrix - right_matrix))
}

# Developer note.
posterior_mean <- function(fit) {
    has_adjusted <- !base::is.null(fit$adj.values) &&
        base::length(fit$adj.values) > 0L

    if (has_adjusted) {
        values <- base::as.matrix(fit$adj.values)
    } else {
        values <- base::as.matrix(fit$unadj.values)
    }

    base::colMeans(values)
}

# Developer note.
posterior_weighted_mode <- function(fit) {
    has_adjusted <- !base::is.null(fit$adj.values) &&
        base::length(fit$adj.values) > 0L

    if (has_adjusted) {
        values <- base::as.matrix(fit$adj.values)
    } else {
        values <- base::as.matrix(fit$unadj.values)
    }

    has_weights <- !base::is.null(fit$weights) &&
        base::length(fit$weights) == base::nrow(values)

    if (has_weights) {
        weights <- base::as.numeric(fit$weights)
    } else {
        weights <- base::rep(1, base::nrow(values))
    }

    # Developer note.
    if (base::sum(weights) <= 0 || base::any(!base::is.finite(weights))) {
        weights <- base::rep(1, base::nrow(values))
    }
    weights <- weights / base::sum(weights)

    base::apply(
        X = values,
        MARGIN = 2L,
        FUN = function(column) {
            density_result <- stats::density(column, weights = weights)
            density_result$x[base::which.max(density_result$y)]
        }
    )
}

# Developer note.
safe_mean <- function(values) {
    if (base::length(values) == 0L) {
        return(0)
    }
    base::mean(values)
}

# Developer note.
safe_sd <- function(values) {
    if (base::length(values) < 2L) {
        return(0)
    }
    stats::sd(values)
}

# Developer note.
safe_cor <- function(left, right) {
    left_sd <- safe_sd(left)
    right_sd <- safe_sd(right)

    if (left_sd <= 0 || right_sd <= 0) {
        return(NA_real_)
    }

    stats::cor(left, right)
}


###############################################################################
# Section 1: Minimal ABC Sanity Check
###############################################################################

if (run_dev_section("minimal")) {

# Developer note.
toy_grid <- base::expand.grid(
    theta_1 = base::seq(from = 0.05, to = 0.95, length.out = 10L),
    theta_2 = base::seq(from = 0.10, to = 0.90, length.out = 9L)
)
toy_param <- base::as.matrix(toy_grid)
toy_theta_1 <- toy_param[, "theta_1"]
toy_theta_2 <- toy_param[, "theta_2"]

# Developer note.
toy_sumstat <- base::cbind(
    stat_1 = toy_theta_1 + 0.25 * toy_theta_2,
    stat_2 = toy_theta_1 * toy_theta_1 - 0.10 * toy_theta_2,
    stat_3 = toy_theta_2 * toy_theta_2 + 0.10 * toy_theta_1,
    stat_4 = base::sin(base::pi * toy_theta_1) +
        base::cos(base::pi * toy_theta_2)
)
toy_target_param <- base::c(theta_1 = 0.45, theta_2 = 0.55)
toy_target <- base::c(
    stat_1 = toy_target_param["theta_1"] + 0.25 * toy_target_param["theta_2"],
    stat_2 = toy_target_param["theta_1"] * toy_target_param["theta_1"] -
        0.10 * toy_target_param["theta_2"],
    stat_3 = toy_target_param["theta_2"] * toy_target_param["theta_2"] +
        0.10 * toy_target_param["theta_1"],
    stat_4 = base::sin(base::pi * toy_target_param["theta_1"]) +
        base::cos(base::pi * toy_target_param["theta_2"])
)

# Developer note.
toy_r_rejection <- abc::abc(
    target = toy_target,
    param = toy_param,
    sumstat = toy_sumstat,
    tol = 0.10,
    method = "rejection"
)
toy_cpp_rejection <- abcpp::abc(
    target = toy_target,
    param = toy_param,
    sumstat = toy_sumstat,
    tol = 0.10,
    method = "rejection",
    transf = base::rep("none", 2L),
    reduction = "none"
)

# Developer note.
toy_r_loclinear <- base::suppressWarnings(abc::abc(
    target = toy_target,
    param = toy_param,
    sumstat = toy_sumstat,
    tol = 0.20,
    method = "loclinear",
    hcorr = FALSE,
    transf = base::rep("none", 2L)
))
toy_cpp_loclinear <- abcpp::abc(
    target = toy_target,
    param = toy_param,
    sumstat = toy_sumstat,
    tol = 0.20,
    method = "loclinear",
    hcorr = FALSE,
    transf = base::rep("none", 2L),
    reduction = "none"
)

toy_r_ridge <- base::suppressWarnings(abc::abc(
    target = toy_target,
    param = toy_param,
    sumstat = toy_sumstat,
    tol = 0.20,
    method = "ridge",
    hcorr = FALSE,
    transf = base::rep("none", 2L),
    lambda = base::c(0.001, 0.01)
))
toy_cpp_ridge <- abcpp::abc(
    target = toy_target,
    param = toy_param,
    sumstat = toy_sumstat,
    tol = 0.20,
    method = "ridge",
    hcorr = FALSE,
    transf = base::rep("none", 2L),
    lambda = base::c(0.001, 0.01),
    reduction = "none"
)
toy_target_matrix <- base::matrix(toy_target, nrow = 2L, byrow = TRUE)
toy_sumstat_matrices <- base::lapply(
    X = base::seq_len(base::nrow(toy_sumstat)),
    FUN = function(index) {
        base::matrix(toy_sumstat[index, ], nrow = 2L, byrow = TRUE)
    }
)
toy_cpp_matrix_list <- abcpp::abc(
    target = toy_target_matrix,
    param = toy_param,
    sumstat = toy_sumstat_matrices,
    tol = 0.10,
    method = "rejection",
    transf = base::rep("none", 2L),
    reduction = "none"
)

toy_alignment <- base::data.frame(
    check = base::c(
        "rejection_accepted_count",
        "rejection_posterior_max_abs_diff",
        "loclinear_mean_max_abs_diff",
        "ridge_mean_max_abs_diff",
        "matrix_list_numstat"
    ),
    r_abc = base::c(
        base::sum(toy_r_rejection$region),
        NA_real_,
        NA_real_,
        NA_real_,
        NA_real_
    ),
    abcpp = base::c(
        base::sum(toy_cpp_rejection$region),
        NA_real_,
        NA_real_,
        NA_real_,
        toy_cpp_matrix_list$numstat
    ),
    max_abs_diff = base::c(
        NA_real_,
        max_abs_diff(toy_r_rejection$unadj.values,
                     toy_cpp_rejection$unadj.values),
        max_abs_diff(posterior_mean(toy_r_loclinear),
                     posterior_mean(toy_cpp_loclinear)),
        max_abs_diff(posterior_mean(toy_r_ridge),
                     posterior_mean(toy_cpp_ridge)),
        max_abs_diff(toy_cpp_matrix_list$unadj.values,
                     toy_cpp_rejection$unadj.values)
    )
)

toy_means <- base::rbind(
    loclinear_r_abc = posterior_mean(toy_r_loclinear),
    loclinear_abcpp = posterior_mean(toy_cpp_loclinear),
    ridge_r_abc = posterior_mean(toy_r_ridge),
    ridge_abcpp = posterior_mean(toy_cpp_ridge)
)

base::cat("\n\n=== Minimal ABC Alignment ===\n")
base::print(toy_alignment, row.names = FALSE)
base::cat("\n=== Minimal Posterior Means ===\n")
base::print(toy_means)

# Developer note.
base::rm(
    toy_theta_1,
    toy_theta_2,
    toy_grid,
    toy_param,
    toy_sumstat,
    toy_target_param,
    toy_target,
    toy_r_rejection,
    toy_cpp_rejection,
    toy_r_loclinear,
    toy_cpp_loclinear,
    toy_r_ridge,
    toy_cpp_ridge,
    toy_target_matrix,
    toy_sumstat_matrices,
    toy_cpp_matrix_list,
    toy_alignment,
    toy_means
)

}


###############################################################################
# Section 2: Simple Signal Detection Theory Validation
###############################################################################

if (run_dev_section("sdt")) {

# Developer note.
sdt_summary <- function(stim, resp, conf) {
    signal <- stim == 1L
    noise <- stim == 0L
    correct <- stim == resp

    out <- base::c(
        hit = safe_mean(resp[signal] == 1L),
        false_alarm = safe_mean(resp[noise] == 1L),
        mean_conf = safe_mean(conf),
        high_conf = safe_mean(conf >= 3L),
        correct_high_conf = safe_mean(conf[correct] >= 3L),
        error_high_conf = safe_mean(conf[!correct] >= 3L)
    )

    # Developer note.
    for (stim_level in base::c(0L, 1L)) {
        stim_mask <- stim == stim_level
        for (conf_level in base::seq_len(3L)) {
            stat_name <- base::paste0(
                "p_s",
                stim_level,
                "_conf",
                conf_level
            )
            out[stat_name] <- safe_mean(conf[stim_mask] == conf_level)
        }
    }

    out
}

# Developer note.
simulate_sdt <- function(stim, d_value, criterion) {
    evidence_mean <- base::ifelse(stim == 1L, d_value, 0)
    evidence <- stats::rnorm(
        n = base::length(stim),
        mean = evidence_mean,
        sd = 1
    )
    resp <- base::as.integer(evidence > criterion)
    margin <- base::abs(evidence - criterion)
    conf <- base::findInterval(margin, base::c(0.35, 0.75, 1.25)) + 1L

    base::list(resp = resp, conf = conf)
}

# Developer note.
make_sdt_abc_bank <- function(stim, n_sims, target_names) {
    param <- base::matrix(NA_real_, nrow = n_sims, ncol = 2L)
    sumstat <- base::matrix(
        NA_real_,
        nrow = n_sims,
        ncol = base::length(target_names)
    )
    base::colnames(param) <- base::c("d", "criterion")
    base::colnames(sumstat) <- target_names

    for (index in base::seq_len(n_sims)) {
        # Developer note.
        d_value <- stats::runif(n = 1L, min = 0.2, max = 3.5)
        criterion <- stats::runif(n = 1L, min = -1.5, max = 2.5)
        param[index, ] <- base::c(d_value, criterion)

        simulated <- simulate_sdt(
            stim = stim,
            d_value = d_value,
            criterion = criterion
        )
        sumstat[index, ] <- sdt_summary(
            stim = stim,
            resp = simulated$resp,
            conf = simulated$conf
        )
    }

    base::list(param = param, sumstat = sumstat)
}

# Developer note.
read_sdt_subject <- function(path, subject_id) {
    data <- utils::read.csv(path)
    data <- data[data$subj_id == subject_id, , drop = FALSE]

    base::list(
        stim = base::as.integer(data$stim),
        resp = base::as.integer(data$resp),
        conf = base::as.integer(data$conf)
    )
}

base::set.seed(1004L)
sdt_data_path <- base::file.path("data", "exp1.csv")
if (!base::file.exists(sdt_data_path)) {
    base::stop("This script expects data/exp1.csv.", call. = FALSE)
}

sdt_subject <- read_sdt_subject(path = sdt_data_path, subject_id = 1L)
sdt_target <- sdt_summary(
    stim = sdt_subject$stim,
    resp = sdt_subject$resp,
    conf = sdt_subject$conf
)
sdt_bank <- make_sdt_abc_bank(
    stim = sdt_subject$stim,
    n_sims = 1200L,
    target_names = base::names(sdt_target)
)

sdt_r_rejection <- abc::abc(
    target = sdt_target,
    param = sdt_bank$param,
    sumstat = sdt_bank$sumstat,
    tol = 0.12,
    method = "rejection"
)
sdt_cpp_rejection <- abcpp::abc(
    target = sdt_target,
    param = sdt_bank$param,
    sumstat = sdt_bank$sumstat,
    tol = 0.12,
    method = "rejection",
    transf = base::rep("none", 2L),
    reduction = "none"
)

sdt_r_loclinear <- base::suppressWarnings(abc::abc(
    target = sdt_target,
    param = sdt_bank$param,
    sumstat = sdt_bank$sumstat,
    tol = 0.12,
    method = "loclinear",
    hcorr = FALSE,
    transf = base::rep("none", 2L)
))
sdt_cpp_loclinear <- abcpp::abc(
    target = sdt_target,
    param = sdt_bank$param,
    sumstat = sdt_bank$sumstat,
    tol = 0.12,
    method = "loclinear",
    hcorr = FALSE,
    transf = base::rep("none", 2L),
    reduction = "none"
)

sdt_r_ridge <- base::suppressWarnings(abc::abc(
    target = sdt_target,
    param = sdt_bank$param,
    sumstat = sdt_bank$sumstat,
    tol = 0.12,
    method = "ridge",
    hcorr = FALSE,
    transf = base::rep("none", 2L),
    lambda = base::c(0.001, 0.01)
))
sdt_cpp_ridge <- abcpp::abc(
    target = sdt_target,
    param = sdt_bank$param,
    sumstat = sdt_bank$sumstat,
    tol = 0.12,
    method = "ridge",
    hcorr = FALSE,
    transf = base::rep("none", 2L),
    lambda = base::c(0.001, 0.01),
    reduction = "none"
)

sdt_cpp_pca <- abcpp::abc(
    target = sdt_target,
    param = sdt_bank$param,
    sumstat = sdt_bank$sumstat,
    tol = 0.12,
    method = "ridge",
    hcorr = FALSE,
    transf = base::rep("none", 2L),
    reduction = "pca",
    n_comp = 4L
)
sdt_cpp_pls <- abcpp::abc(
    target = sdt_target,
    param = sdt_bank$param,
    sumstat = sdt_bank$sumstat,
    tol = 0.12,
    method = "ridge",
    hcorr = FALSE,
    transf = base::rep("none", 2L),
    reduction = "pls",
    n_comp = 2L
)

sdt_alignment <- base::data.frame(
    check = base::c(
        "rejection_accepted_count",
        "rejection_posterior_max_abs_diff",
        "loclinear_mean_max_abs_diff",
        "ridge_mean_max_abs_diff"
    ),
    r_abc = base::c(
        base::sum(sdt_r_rejection$region),
        NA_real_,
        NA_real_,
        NA_real_
    ),
    abcpp = base::c(
        base::sum(sdt_cpp_rejection$region),
        NA_real_,
        NA_real_,
        NA_real_
    ),
    max_abs_diff = base::c(
        NA_real_,
        max_abs_diff(sdt_r_rejection$unadj.values,
                     sdt_cpp_rejection$unadj.values),
        max_abs_diff(posterior_mean(sdt_r_loclinear),
                     posterior_mean(sdt_cpp_loclinear)),
        max_abs_diff(posterior_mean(sdt_r_ridge),
                     posterior_mean(sdt_cpp_ridge))
    )
)

sdt_means <- base::rbind(
    loclinear_r_abc = posterior_mean(sdt_r_loclinear),
    loclinear_abcpp = posterior_mean(sdt_cpp_loclinear),
    ridge_r_abc = posterior_mean(sdt_r_ridge),
    ridge_abcpp = posterior_mean(sdt_cpp_ridge)
)

sdt_reduction <- base::data.frame(
    reduction = base::c("none", "pca", "pls"),
    accepted = base::c(
        base::nrow(sdt_cpp_loclinear$unadj.values),
        base::nrow(sdt_cpp_pca$unadj.values),
        base::nrow(sdt_cpp_pls$unadj.values)
    ),
    numstat = base::c(
        sdt_cpp_loclinear$numstat,
        sdt_cpp_pca$numstat,
        sdt_cpp_pls$numstat
    )
)

base::cat("\n\n=== SDT ABC Alignment ===\n")
base::print(sdt_alignment, row.names = FALSE)
base::cat("\n=== SDT Posterior Means ===\n")
base::print(sdt_means)
base::cat("\n=== SDT Reduction Summary ===\n")
base::print(sdt_reduction, row.names = FALSE)

# Developer note.
base::rm(
    sdt_data_path,
    sdt_subject,
    sdt_target,
    sdt_bank,
    sdt_r_rejection,
    sdt_cpp_rejection,
    sdt_r_loclinear,
    sdt_cpp_loclinear,
    sdt_r_ridge,
    sdt_cpp_ridge,
    sdt_cpp_pca,
    sdt_cpp_pls,
    sdt_alignment,
    sdt_means,
    sdt_reduction
)

}


###############################################################################
# Section 3: binaryRL Parameter Recovery Validation
###############################################################################

if (run_dev_section("binaryrl")) {

# Developer note.
if (!base::requireNamespace("binaryRL", quietly = TRUE)) {
    rl_alignment <- base::data.frame(
        status = "skipped",
        reason = "binaryRL is not installed in this R library."
    )
    base::cat("\n\n=== binaryRL ABC Alignment ===\n")
    base::print(rl_alignment, row.names = FALSE)
    base::rm(rl_alignment)
} else {
    # Developer note.
    extract_binaryrl_params <- function(x) {
        param_vector <- base::as.numeric(x$input)
        base::names(param_vector) <- base::c("eta", "tau")
        param_vector
    }

    # Developer note.
    extract_binaryrl_sumstats <- function(x, blocks) {
        data <- x[["data"]]
        data <- data[data$Frame %in% base::c("Gain", "Loss"), , drop = FALSE]
        risky <- base::ifelse(data$Sub_Choose %in% base::c("B", "D"), 1, 0)

        out <- base::numeric(base::length(blocks) * 2L)
        out_names <- base::character(base::length(out))

        for (index in base::seq_along(blocks)) {
            # Developer note.
            block_value <- blocks[index]
            block_risky <- risky[data$Block == block_value]
            mean_index <- 2L * index - 1L
            sd_index <- 2L * index

            out[mean_index] <- safe_mean(block_risky)
            out[sd_index] <- safe_sd(block_risky)
            out_names[mean_index] <- base::paste0(
                "block_",
                block_value,
                "_mean_risky"
            )
            out_names[sd_index] <- base::paste0(
                "block_",
                block_value,
                "_sd_risky"
            )
        }

        out[!base::is.finite(out)] <- 0
        base::names(out) <- out_names
        out
    }

    base::set.seed(1004L)
    rl_n_train <- 500L
    rl_n_valid <- 100L
    rl_n_total <- rl_n_train + rl_n_valid

    # Developer note.
    utils::capture.output({
        rl_simulated <- base::suppressWarnings(base::suppressMessages(
            binaryRL::simulate_list(
                data = binaryRL::Mason_2024_G2,
                id = 1L,
                n_params = 2L,
                n_trials = 360L,
                obj_func = binaryRL::TD,
                rfun = base::list(
                    eta = function() {
                        stats::runif(n = 1L, min = 0, max = 1)
                    },
                    tau = function() {
                        stats::rexp(n = 1L, rate = 1)
                    }
                ),
                iteration = rl_n_total
            )
        ))
    })

    rl_blocks <- base::sort(base::unique(
        rl_simulated[[1L]]$data$Block[
            rl_simulated[[1L]]$data$Frame %in% base::c("Gain", "Loss")
        ]
    ))
    rl_train <- rl_simulated[base::seq_len(rl_n_train)]
    rl_valid <- rl_simulated[(rl_n_train + 1L):rl_n_total]

    rl_train_params <- base::do.call(
        what = base::rbind,
        args = base::lapply(rl_train, extract_binaryrl_params)
    )
    rl_valid_params <- base::do.call(
        what = base::rbind,
        args = base::lapply(rl_valid, extract_binaryrl_params)
    )
    rl_train_sumstats <- base::do.call(
        what = base::rbind,
        args = base::lapply(
            rl_train,
            extract_binaryrl_sumstats,
            blocks = rl_blocks
        )
    )
    rl_valid_sumstats <- base::do.call(
        what = base::rbind,
        args = base::lapply(
            rl_valid,
            extract_binaryrl_sumstats,
            blocks = rl_blocks
        )
    )

    rl_run_neuralnet <- base::requireNamespace("nnet", quietly = TRUE)
    rl_pred_r_neuralnet <- base::matrix(
        NA_real_,
        nrow = rl_n_valid,
        ncol = 2L
    )
    rl_pred_cpp_neuralnet <- base::matrix(
        NA_real_,
        nrow = rl_n_valid,
        ncol = 2L
    )
    base::colnames(rl_pred_r_neuralnet) <- base::c("eta", "tau")
    base::colnames(rl_pred_cpp_neuralnet) <- base::c("eta", "tau")

    rl_old_warn <- base::getOption("warn")
    base::options(warn = -1L)

    # Developer note.
    for (index in base::seq_len(rl_n_valid)) {
        rl_target <- base::as.numeric(rl_valid_sumstats[index, ])
        if (rl_run_neuralnet) {
            # Developer note.
            base::set.seed(2000L + index)
            utils::capture.output({
                rl_r_neuralnet_fit <- abc::abc(
                    target = rl_target,
                    param = rl_train_params,
                    sumstat = rl_train_sumstats,
                    tol = 0.10,
                    method = "neuralnet",
                    hcorr = FALSE,
                    transf = base::c("logit", "none"),
                    logit.bounds = base::rbind(
                        base::c(0, 1),
                        base::c(NA_real_, NA_real_)
                    ),
                    numnet = 10L,
                    sizenet = 5L,
                    lambda = base::c(0.0001, 0.001, 0.01),
                    trace = FALSE,
                    maxit = 500L
                )
            })
            rl_cpp_neuralnet_fit <- abcpp::abc(
                target = rl_target,
                param = rl_train_params,
                sumstat = rl_train_sumstats,
                tol = 0.10,
                method = "neuralnet",
                hcorr = FALSE,
                transf = base::c("logit", "none"),
                logit.bounds = base::rbind(
                    base::c(0, 1),
                    base::c(NA_real_, NA_real_)
                ),
                numnet = 10L,
                sizenet = 5L,
                lambda = base::c(0.0001, 0.001, 0.01),
                trace = FALSE,
                maxit = 500L,
                seed = 2000L + index,
                reduction = "none"
            )

            rl_pred_r_neuralnet[index, ] <- posterior_weighted_mode(
                rl_r_neuralnet_fit
            )
            rl_pred_cpp_neuralnet[index, ] <- posterior_weighted_mode(
                rl_cpp_neuralnet_fit
            )
        }
    }
    base::options(warn = rl_old_warn)

    if (rl_run_neuralnet) {
        rl_recovery <- base::data.frame(
            method = base::rep("neuralnet", 2L),
            point_estimate = base::rep("weighted_mode", 2L),
            parameter = base::c("eta", "tau"),
            corr_r_abc = base::c(
                safe_cor(
                    rl_valid_params[, "eta"],
                    rl_pred_r_neuralnet[, "eta"]
                ),
                safe_cor(
                    rl_valid_params[, "tau"],
                    rl_pred_r_neuralnet[, "tau"]
                )
            ),
            corr_abcpp = base::c(
                safe_cor(
                    rl_valid_params[, "eta"],
                    rl_pred_cpp_neuralnet[, "eta"]
                ),
                safe_cor(
                    rl_valid_params[, "tau"],
                    rl_pred_cpp_neuralnet[, "tau"]
                )
            ),
            mean_abs_diff = base::c(
                base::mean(base::abs(
                    rl_pred_r_neuralnet[, "eta"] -
                        rl_pred_cpp_neuralnet[, "eta"]
                )),
                base::mean(base::abs(
                    rl_pred_r_neuralnet[, "tau"] -
                        rl_pred_cpp_neuralnet[, "tau"]
                ))
            )
        )
        base::cat("\n\n=== binaryRL Neuralnet Parameter Recovery ===\n")
        base::print(rl_recovery, row.names = FALSE)
    }

    if (!rl_run_neuralnet) {
        base::cat("\n=== binaryRL Neuralnet Status ===\n")
        base::print(
            base::data.frame(
                status = "skipped",
                reason = "R package nnet is not installed."
            ),
            row.names = FALSE
        )
    }

    # Developer note.
    base::rm(list = base::intersect(
        x = base::ls(),
        y = base::c(
            "extract_binaryrl_params",
            "extract_binaryrl_sumstats",
            "rl_n_train",
            "rl_n_valid",
            "rl_n_total",
            "rl_simulated",
            "rl_blocks",
            "rl_train",
            "rl_valid",
            "rl_train_params",
            "rl_valid_params",
            "rl_train_sumstats",
            "rl_valid_sumstats",
            "rl_pred_r_neuralnet",
            "rl_pred_cpp_neuralnet",
            "rl_run_neuralnet",
            "rl_old_warn",
            "rl_target",
            "rl_r_neuralnet_fit",
            "rl_cpp_neuralnet_fit",
            "rl_recovery",
            "index"
        )
    ))
}

}

# Developer note.
base::invisible(base::gc())
