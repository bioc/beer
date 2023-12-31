% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/brew.R
\name{.tidyInputsJAGS}
\alias{.tidyInputsJAGS}
\title{Clean inputs for JAGS parameters}
\usage{
.tidyInputsJAGS(jags.params)
}
\arguments{
\item{jags.params}{named list of JAGS parameters}
}
\value{
tidied list of JAGS parameters.
}
\description{
Tidy inputs related to `jags.params`. Supplies default values for
missing parameters and ensures that all required parameters are present.
}
