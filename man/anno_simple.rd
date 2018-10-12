\name{anno_simple}
\alias{anno_simple}
\title{
Simple Annotation
}
\description{
Simple Annotation
}
\usage{
anno_simple(x, col, na_col = "grey",
    which = c("column", "row"), border = FALSE, gp = gpar(col = NA),
    pch = NULL, pt_size = unit(1, "snpc")*0.8, pt_gp = gpar(),
    anno_simple_size = ht_opt$anno_simple_size,
    width = NULL, height = NULL)
}
\arguments{

  \item{x}{The value vector. The value can be a vector or a matrix. The length of the vector or the nrow of the matrix is taken as the number of the observations of the annotation. The value can be numeric or character and NA value is allowed.}
  \item{col}{Color that maps to \code{x}. If \code{x} is numeric and needs a continuous mapping, \code{col}  should be a color mapping function which accepts a vector of values and returns a vector of colors. Normally it is generated by \code{\link[circlize]{colorRamp2}}. If \code{x} is discrete (numeric or character) and needs a discrete color mapping, \code{col} should be a vector of  colors with levels in \code{x} as vector names. If \code{col} is not specified, the color mapping is randomly generated by \code{ComplexHeatmap:::default_col}.}
  \item{na_col}{Color for NA value.}
  \item{which}{Whether it is a column annotation or a row annotation?}
  \item{border}{Wether draw borders of the annotation region?}
  \item{gp}{Graphic parameters for grid borders. The \code{fill} parameter is disabled.}
  \item{pch}{Points/symbols that are added on top of the annotation grids. The value can be numeric or single letters. It can be a vector if \code{x} is a vector and a matrix if \code{x} is a matrix. No points are drawn if the corresponding values are NA.}
  \item{pt_size}{Size of the points/symbols. It should be a \code{\link[grid]{unit}} object. If \code{x} is a vector, the value of \code{pt_size} can be a vector, while if \code{x} is a matrix, \code{pt_size} can only be a single value.}
  \item{pt_gp}{Graphic parameters for points/symbols. The length setting is same as \code{pt_size}.}
  \item{width}{Width of the annotation. The value should be an absolute unit. Width is not allowed to be set for column annotation.}
  \item{height}{Height of the annotation. The value should be an absolute unit. Height is not allowed to be set for row annotation.}

}
\details{
The "simple annotation" is the most widely used annotation type which is heatmap-like, where
the grid colors correspond to the values. \code{\link{anno_simple}} also supports to add points/symbols
on top of the grids where the it can be normal point (when \code{pch} is set as numbers) or letters (when
\code{pch} is set as single letters).
}
\value{
An annotation function which can be used in \code{\link{HeatmapAnnotation}}.
}
\examples{
anno = anno_simple(1:10)
draw(anno, test = "a numeric vector")

anno = anno_simple(cbind(1:10, 10:1))
draw(anno, test = "a matrix")

anno = anno_simple(1:10, pch = c(1:4, NA, 6:8, NA, 10))
draw(anno, test = "pch has NA values")

anno = anno_simple(1:10, pch = c(rep("A", 5), rep(NA, 5)))
draw(anno, test = "pch has NA values")

pch = matrix(1:20, nc = 2)
pch[sample(length(pch), 10)] = NA
anno = anno_simple(cbind(1:10, 10:1), pch = pch)
draw(anno, test = "matrix, pch is a matrix with NA values")
}
