\name{grid.draw.Legends}
\alias{grid.draw.Legends}
\title{
Draw the Legends
}
\description{
Draw the Legends
}
\usage{
\method{grid.draw}{Legends}(x, recording = TRUE)
}
\arguments{

  \item{x}{The \code{\link[grid]{grob}} object returned by \code{\link{Legend}} or \code{\link{packLegend}}.}
  \item{recording}{Pass to \code{\link[grid]{grid.draw}}.}

}
\details{
This function is actually an S3 method of the \code{Legends} class for the \code{\link[grid]{grid.draw}}
general method. It applies \code{\link[grid]{grid.draw}} on the \code{grob} slot of the object.
}
\examples{
# There is no example
NULL
}
