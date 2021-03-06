% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/metrics.R
\name{auc}
\alias{auc}
\alias{auc.roc_cutpointr}
\alias{auc.cutpointr}
\title{Calculate AUC from a roc_cutpointr or cutpointr object}
\source{
Forked from the AUC package
}
\usage{
auc(x)

\method{auc}{roc_cutpointr}(x)

\method{auc}{cutpointr}(x)
}
\arguments{
\item{x}{Data frame resulting from the roc() or cutpointr() function.}
}
\value{
Numeric vector of AUC values
}
\description{
Calculate the area under the ROC curve using the trapezoidal rule.
}
