% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/example-mtcars.R
\name{lm_object}
\alias{lm_object}
\title{Linear Models}
\description{
See \code{\link[stats:lm]{stats::lm()}} for more info :)
}
\seealso{
Other example_datasets: 
\code{\link{mtcars_dataset}}
}
\concept{example_datasets}
\section{Output Columns:}{
\describe{
\item{coefficients}{a named vector of coefficients
\itemize{}
}
\item{residuals}{The residuals, that is response minus fitted values.
\itemize{}
}
\item{fitted.values}{The fitted mean values.
\itemize{}
}
\item{rank}{the numeric rank of the fitted linear model.
\itemize{}
}
\item{weights}{(only for weighted fits) the specified weights.
\itemize{}
}
\item{df.residual}{the residual degrees of freedom.
\itemize{}
}
\item{call}{the matched call.
\itemize{}
}
\item{terms}{the \code{\link[stats:terms]{stats::terms()}} object used.
\itemize{}
}
\item{contrasts}{(only where relevant) the contrasts used.
\itemize{}
}
\item{xlevels}{(only where relevant) a record of the levels of the factors used in fitting.
\itemize{}
}
\item{offset}{the offset used (missing if none were used).
\itemize{}
}
\item{y}{if requested, the response used.
\itemize{}
}
\item{x}{if requested, the model matrix used.
\itemize{}
}
\item{model}{if requested (the default), the model frame used.
\itemize{}
}
\item{na.action}{(where relevant) information returned by \code{\link[stats:model.frame]{stats::model.frame()}} on the special handling of NAs.
\itemize{}
}
}
}
