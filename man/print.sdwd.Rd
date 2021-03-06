\name{print.sdwd}
\alias{print.sdwd}
\title{print an sdwd object}
\description{
Print a summary of the \code{\link{sdwd}} solution paths.}
\usage{
\method{print}{sdwd}(x, digits=max(3, getOption("digits") - 3), ...)
}
\arguments{
  \item{x}{A fitted \code{\link{sdwd}} object.}
  \item{digits}{Specify the significant digits.}
  \item{\dots}{Additional print arguments.}
}
\details{
This function prints a two-column matrix with columns \code{Df} and \code{Lambda}, where the \code{Df} column exhibits the number of nonzero coefficients and the \code{Lambda} column displays the corresponding \code{lambda} value. This function is modified based on the \code{print} function from the \code{gcdnet} and the \code{glmnet} packages.
}
\value{
A two-column matrix with one column of the number of nonzero coefficients and a second column of \code{lambda} values.}

\author{Boxiang Wang and Hui Zou\cr
Maintainer: Boxiang Wang  \email{boxiang-wang@uiowa.edu}}
\references{
Wang, B. and Zou, H. (2016)
  ``Sparse Distance Weighted Discrimination", \emph{Journal of Computational and Graphical Statistics}, \bold{25}(3), 826--838.\cr
  \url{https://www.tandfonline.com/doi/full/10.1080/10618600.2015.1049700}\cr
  \cr
Yang, Y. and Zou, H. (2013)
``An Efficient Algorithm for Computing the HHSVM and Its Generalizations", 
  \emph{Journal of Computational and Graphical Statistics}, \bold{22}(2), 396--415.\cr
  \url{https://www.tandfonline.com/doi/full/10.1080/10618600.2012.680324}\cr
 \cr 
Friedman, J., Hastie, T., and Tibshirani, R. (2010), "Regularization paths for generalized
linear models via coordinate descent," \emph{Journal of Statistical Software}, \bold{33}(1), 1--22.\cr
\url{https://www.jstatsoft.org/v33/i01/paper}
\cr
}
 
 \seealso{\code{print.sdwd}, \code{predict.sdwd}, \code{coef.sdwd}, \code{plot.sdwd}, and \code{cv.sdwd}.}
 
\examples{
data(colon)
fit = sdwd(colon$x, colon$y)
print(fit)
}

