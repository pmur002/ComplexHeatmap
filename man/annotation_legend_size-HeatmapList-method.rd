\name{annotation_legend_size-HeatmapList-method}
\alias{annotation_legend_size,HeatmapList-method}
\alias{annotation_legend_size}
\title{
Size of the annotation legend viewport  


}
\description{
Size of the annotation legend viewport  


}
\usage{
\S4method{annotation_legend_size}{HeatmapList}(object, annotation_legend_list = list(), ...)
}
\arguments{

  \item{object}{a \code{\link{HeatmapList-class}} object}
  \item{annotation_legend_list}{a list of self-defined legend, should be wrapped into \code{\link[grid]{grob}} objects.}
  \item{...}{graphic parameters pass to \code{\link{color_mapping_legend,ColorMapping-method}}.}

}
\details{
This function is only for internal use.  


}
\value{
A \code{\link[grid]{unit}} object.  


}
\author{
Zuguang Gu <z.gu@dkfz.de>  


}