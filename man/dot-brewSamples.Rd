% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/brew.R
\name{.brewSamples}
\alias{.brewSamples}
\title{Run BEER for all samples}
\usage{
.brewSamples(
  object,
  sample.id,
  beads.id,
  se.matrix,
  prior.params,
  beads.prior,
  beads.args,
  jags.params,
  tmp.dir,
  BPPARAM
)
}
\arguments{
\item{object}{PhIPData object}

\item{sample.id}{vector of sample IDs to iterate over}

\item{beads.id}{vector of IDs corresponding to beads-only samples}

\item{se.matrix}{matrix indicating which peptides are clearly enriched}

\item{prior.params}{list of prior parameters}

\item{beads.prior}{data frame of beads-only prior parameters}

\item{beads.args}{named list of parameters supplied to estimating beads-only
prior parameters (a_0, b_0)}

\item{jags.params}{list of JAGS parameters}

\item{tmp.dir}{directory to store JAGS samples}

\item{BPPARAM}{\code{[BiocParallel::BiocParallelParam]} passed to
BiocParallel functions.}
}
\value{
vector of process id's for internal checking of whether functions
were parallelized correctly.
}
\description{
Encapsulated function to run each sample against all beads-only samples.
The code is wrapped in this smaller function to (1) modularize the code and
(2) make sure the cli output colors don't change.
}
