\name{width.AnnotationFunction}
\alias{width.AnnotationFunction}
\title{
Width of the AnnotationFunction Object
}
\description{
Width of the AnnotationFunction Object
}
\usage{
\method{width}{AnnotationFunction}(x, ...)
}
\arguments{

  \item{x}{A \code{\link{AnnotationFunction-class}} object.}
  \item{...}{Other arguments}

}
\examples{
anno = anno_points(1:10)
width(anno)
anno = anno_points(1:10, which = "row")
width(anno)
}
