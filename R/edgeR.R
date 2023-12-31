#' Estimate edgeR dispersion parameters from the beads-only data using qCML
#'
#' Wrapper function to estimate edgeR dispersion parameters from beads-only
#' samples. Peptides can be pre-filtered based on a minimum read count per
#' million (cpm) and the proportion of beads-only samples that surpass the cpm
#' threshold.
#'
#' @param object \code{\link[PhIPData]{PhIPData}} object (can have actual serum
#' samples)
#' @param threshold.cpm CPM threshold to be considered present in a sample
#' @param threshold.prevalence proportion of beads-only samples that surpass
#' \code{threshold.cpm}.
#'
#' @return a DGEList object with common, trended, and tagwise dispersion
#' estimates
#'
#' @importFrom edgeR calcNormFactors
#' @importFrom methods as
.edgeRBeads <- function(object, threshold.cpm = 0, threshold.prevalence = 0) {
    edgeR_beads <- as(PhIPData::subsetBeads(object), "DGEList")

    ## For dispersion estimates, keep only peptides with cpm above the
    ## specified threshold in the given number of samples.
    keep_ind <- rowSums(edgeR::cpm(edgeR_beads) >= threshold.cpm) >=
        threshold.prevalence

    ## Estimate common, trended, and tagwise dispersion in the beads-only data
    edgeR_beads <- edgeR_beads[keep_ind, , keep.lib.size = FALSE]
    edgeR_beads <- edgeR::calcNormFactors(edgeR_beads)
    edgeR_beads <- suppressMessages(edgeR::estimateDisp(edgeR_beads))

    edgeR_beads
}

#' Estimate edgeR dispersion parameters from the beads-only samples using
#' Cox-Reid profile adjusted likelihood method for estimating dispersions.
#'
#' Wrapper function to estimate edgeR dispersion parameters from beads-only
#' samples. Peptides can be pre-filtered based on a minimum read count per
#' million (cpm) and the proportion of beads-only samples that surpass the cpm
#' threshold.
#'
#' @param object \code{\link[PhIPData]{PhIPData}} object (can have actual serum
#' samples)
#' @param threshold.cpm CPM threshold to be considered present in a sample
#' @param threshold.prevalence proportion of beads-only samples that surpass
#' \code{threshold.cpm}.
#'
#' @return a DGEList object with common, trended, and tagwise dispersion
#' estimates
#'
#' @importFrom edgeR calcNormFactors
#' @importFrom methods as
#' @importFrom stats model.matrix
.edgeRBeadsQLF <- function(object, threshold.cpm = 0, threshold.prevalence = 0) {
    phip_beads <- PhIPData::subsetBeads(object)
    edgeR_beads <- as(phip_beads, "DGEList")

    ## For dispersion estimates, keep only peptides with cpm above the
    ## specified threshold in the given number of samples.
    keep_ind <- rowSums(edgeR::cpm(edgeR_beads) >= threshold.cpm) >=
        threshold.prevalence
    edgeR_beads <- edgeR_beads[keep_ind, , keep.lib.size = FALSE]

    ## Estimate common, trended, and tagwise dispersion in the beads-only data
    ## Define design matrix
    design_intercept <- model.matrix(~1, data = sampleInfo(phip_beads))

    # Estimate dispersions
    edgeR::estimateDisp(edgeR_beads, design_intercept)
}

#' Run edgeR for one sample against all the beads-only samples.
#'
#' This function is not really for external use. It's exported for
#' parallelization purposes. For more detailed descriptions see
#' \code{\link{runEdgeR}}.
#'
#' @param object \code{\link[PhIPData]{PhIPData}} object
#' @param sample sample name of the sample to compare against beads-only samples
#' @param beads sample names for beads-only samples
#' @param common.disp edgeR estimated common dispersion parameter
#' @param tagwise.disp edgeR estimated tagwise dispersion parameter
#' @param trended.disp edgeR estimated trended dispersion parameter
#'
#' @return list with sample name, log2 fc estimate, and log10 p-value
#'
#' @examples
#' sim_data <- readRDS(system.file("extdata", "sim_data.rds", package = "beer"))
#'
#' beads_disp <- beer:::.edgeRBeads(sim_data)
#' edgeROne(
#'     sim_data, "9", colnames(sim_data)[sim_data$group == "beads"],
#'     beads_disp$common.dispersion, beads_disp$tagwise.disp,
#'     beads_disp$trended.disp
#' )
#' @export
#' @importFrom edgeR exactTest
#' @importFrom methods as
#' @import PhIPData
edgeROne <- function(object, sample, beads,
    common.disp, tagwise.disp, trended.disp) {
    ## Coerce into edgeR object
    ## Set common dispersion to disp estimated from beads-only samples
    data <- as(object[, c(beads, sample)], "DGEList")
    data$common.dispersion <- common.disp
    data$tagwise.dispersion <- tagwise.disp
    data$trended.disp <- trended.disp

    ## edgeR output
    output <- edgeR::exactTest(data)$table
    # Convert to one-sided p-values and take -log10
    log10pval <- ifelse(output$logFC > 0, -log10(output$PValue / 2),
        -log10(1 - output$PValue / 2)
    )

    list(
        sample = sample,
        logfc = output$logFC,
        log10pval = log10pval
    )
}

#' Run edgeR for one sample against all the beads-only samples using edgeR's
#' QLF Test for differential expression.
#'
#' This function is not really for external use. It's exported for
#' parallelization purposes. For more detailed descriptions see
#' \code{\link{runEdgeR}}.
#'
#' @param object \code{\link[PhIPData]{PhIPData}} object
#' @param sample sample name of the sample to compare against beads-only samples
#' @param beads sample names for beads-only samples
#' @param common.disp edgeR estimated common dispersion parameter
#' @param tagwise.disp edgeR estimated tagwise dispersion parameter
#' @param trended.disp edgeR estimated trended dispersion parameter
#'
#' @return list with sample name, log2 fc estimate, and log10 p-value
#'
#' @examples
#' sim_data <- readRDS(system.file("extdata", "sim_data.rds", package = "beer"))
#'
#' beads_disp <- beer:::.edgeRBeadsQLF(sim_data)
#' edgeROneQLF(
#'     sim_data, "9", colnames(sim_data)[sim_data$group == "beads"],
#'     beads_disp$common.dispersion, beads_disp$tagwise.disp,
#'     beads_disp$trended.disp
#' )
#' @export
#' @importFrom edgeR glmQLFit glmQLFTest
#' @importFrom methods as
#' @importFrom stats model.matrix
#' @import PhIPData
edgeROneQLF <- function(object, sample, beads,
    common.disp, tagwise.disp, trended.disp) {

    ## Coerce into edgeR object
    ## Set common dispersion to disp estimated from beads-only samples
    phip_subset <- object[, c(beads, sample)]

    data <- as(phip_subset, "DGEList")
    data$common.dispersion <- common.disp
    data$tagwise.dispersion <- tagwise.disp
    data$trended.disp <- trended.disp

    ## Define model
    design_sample <- model.matrix(~ sampleInfo(phip_subset)$group)

    ## edgeR output
    fit <- edgeR::glmQLFit(data, design_sample)
    output <- edgeR::glmQLFTest(fit, 2)
    # Convert to one-sided p-values and take -log10
    log10pval <- ifelse(output$table$logFC > 0, -log10(output$table$PValue / 2),
        -log10(1 - output$table$PValue / 2)
    )

    list(
        sample = sample,
        logfc = output$table$logFC,
        log10pval = log10pval
    )
}

#' Run edgeR on PhIP-Seq data
#'
#'
#' @param object \code{\link[PhIPData]{PhIPData}} object
#' @param threshold.cpm CPM threshold to be considered present in a sample
#' @param threshold.prevalence proportion of beads-only samples that surpass
#' \code{threshold.cpm}.
#' @param assay.names named vector specifying the assay names for the
#' log2(fold-change) and exact test p-values. If the vector is not names, the
#' first and second entries are used as defaults
#' @param beadsRR logical value specifying whether each beads-only sample
#' should be compared to all other beads-only samples.
#' @param de.method character describing which edgeR test for differential
#' expression should be used. Must be one of `exactTest` or `glmQLFTest`
#' @param BPPARAM \code{[BiocParallel::BiocParallelParam]} passed to
#' BiocParallel functions.
#'
#' @return PhIPData object with log2 estimated fold-changes and p-values for
#' enrichment stored in the assays specified by `assay.names`.
#'
#' @seealso \code{[BiocParallel::BiocParallelParam]}, \code{\link{beadsRR}}
#'
#' @examples
#' sim_data <- readRDS(system.file("extdata", "sim_data.rds", package = "beer"))
#'
#' ## Default back-end evaluation
#' runEdgeR(sim_data)
#'
#' ## Serial
#' runEdgeR(sim_data, BPPARAM = BiocParallel::SerialParam())
#'
#' ## Snow
#' runEdgeR(sim_data, BPPARAM = BiocParallel::SnowParam())
#'
#' ## With glmQLFTest
#' runEdgeR(sim_data, de.method = "glmQLFTest")
#'
#' @importFrom BiocParallel bplapply bpparam
#' @importFrom cli cli_alert_warning
#' @import PhIPData SummarizedExperiment
#' @export
runEdgeR <- function(object, threshold.cpm = 0, threshold.prevalence = 0,
    assay.names = c(logfc = "logfc", prob = "prob"),
    beadsRR = FALSE, de.method = "exactTest",
    BPPARAM = BiocParallel::bpparam()) {

    # Add names to assay.names vector
    if (is.null(names(assay.names))) {
        names(assay.names) <- c("logfc", "prob")[seq_len(length(assay.names))]
    }
    ## Check for unnamed vectors or missing names
    if (is.na(assay.names["logfc"])) assay.names[["logfc"]] <- "logfc"
    if (is.na(assay.names["prob"])) assay.names[["prob"]] <- "prob"

    ## Check that method is a valid option
    if (!de.method %in% c("exactTest", "glmQLFTest")) {
        stop("Invalid edgeR method for identifying DE peptides.")
    }

    edgeR_beads <- if (de.method == "exactTest") {
        .edgeRBeads(object, threshold.cpm, threshold.prevalence)
    } else {
        .edgeRBeadsQLF(object, threshold.cpm, threshold.prevalence)
    }
    common_disp <- edgeR_beads$common.dispersion
    tagwise_disp <- edgeR_beads$tagwise.dispersion
    trended_disp <- edgeR_beads$trended.dispersion

    ## Check whether assays will be overwritten
    beads_over <- .checkOverwrite(
        object[, object$group == getBeadsName()],
        assay.names
    )
    sample_over <- .checkOverwrite(
        object[, object$group != getBeadsName()],
        assay.names
    )
    msg <- if (beadsRR & any(beads_over | sample_over, na.rm = TRUE)) {
        paste0(
            "Values in the following assays will be overwritten: ",
            paste0(assay.names[beads_over | sample_over], collapse = ", ")
        )
    } else if (!beadsRR & any(sample_over, na.rm = TRUE)) {
        paste0(
            "Values in the following assays will be overwritten: ",
            paste0(assay.names[beads_over & sample_over], collapse = ", ")
        )
    } else {
        character(0)
    }

    if (length(msg) > 0) cli::cli_alert_warning(msg)

    ## Do beadsRR if necessary
    if (beadsRR) {
        object <- beadsRR(object,
            BPPARAM = BPPARAM,
            method = "edgeR",
            de.method = de.method,
            threshold.cpm, threshold.prevalence, assay.names
        )
    }

    ## Set-up output matrices ----------
    ## Make empty matrix for the cases where fc and prob do not exist
    empty_mat <- matrix(nrow = nrow(object), ncol = ncol(object))
    colnames(empty_mat) <- colnames(object)
    rownames(empty_mat) <- rownames(object)

    edgeR_fc <- if (assay.names[["logfc"]] %in% assayNames(object)) {
        assay(object, assay.names[["logfc"]])
    } else {
        empty_mat
    }

    edgeR_pval <- if (assay.names[["prob"]] %in% assayNames(object)) {
        assay(object, assay.names[["prob"]])
    } else {
        empty_mat
    }

    ## Run edgeR one-sample at a time ------------
    sample_names <- colnames(object[, object$group != getBeadsName()])
    beads_names <- colnames(object[, object$group == getBeadsName()])

    output <- if (de.method == "exactTest") {
        BiocParallel::bplapply(sample_names, function(sample) {
            edgeROne(
                object, sample, beads_names,
                common_disp, tagwise_disp, trended_disp
            )
        }, BPPARAM = BPPARAM)
    } else {
        BiocParallel::bplapply(sample_names, function(sample) {
            edgeROneQLF(
                object, sample, beads_names,
                common_disp, tagwise_disp, trended_disp
            )
        }, BPPARAM = BPPARAM)
    }

    # Unnest output items
    for (result in output) {
        edgeR_fc[, result$sample] <- result$logfc
        edgeR_pval[, result$sample] <- result$log10pval
    }

    ## append to object
    assay(object, assay.names[["logfc"]]) <- edgeR_fc
    assay(object, assay.names[["prob"]]) <- edgeR_pval

    object
}
