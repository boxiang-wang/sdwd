######################################################################
## These functions are minor modifications or directly
#   copied from the glmnet package:
## Jerome Friedman, Trevor Hastie, Robert Tibshirani
#   (2010).
## Regularization Paths for Generalized Linear Models via
#   Coordinate Descent.
##    Journal of Statistical Software, 33(1), 1-22.
##    URL http://www.jstatsoft.org/v33/i01/.

cvcompute = function(mat, foldid, nlams) {
  ## computes the weighted mean and SD within folds, and
  ##   hence the standard error of the mean
  nfolds = max(foldid)
  outmat = matrix(NA, nfolds, ncol(mat))
  good = matrix(0, nfolds, ncol(mat))
  mat[is.infinite(mat)] = NA
  for (i in seq(nfolds)) {
    mati = mat[foldid == i, ]
    outmat[i, ] = colMeans(mati, na.rm=TRUE)
    good[i, seq(nlams[i])] = 1
  }
  N = colSums(good)
  list(cvraw = outmat, N = N)
}

dwdloss = function(u) {
  ## DWD loss
  ifelse(u > 0.5, 0.25/u, 1 - u )
}

err = function(n, maxit, pmax) {
  if (n == 0) 
    msg = ""
  if (n > 0) {
    if (n < 7777) 
      msg = "Memory allocation error"
    if (n == 7777) 
      msg = "All used predictors have zero variance"
    if (n == 10000) 
      msg = "All penalty factors are <= 0"
    n = 1
    msg = paste("in sdwd fortran code -", msg)
  }
  if (n < 0) {
    if (n > -10000) 
      msg = paste0("Convergence for ", -n, "th lambda value not reached after maxit=", 
          maxit, " iterations; solutions for larger lambdas returned")
    if (n < -10000) 
      msg = paste0("Number of nonzero coefficients along the path exceeds pmax=", 
          pmax, " at ", -n - 10000, "th lambda value; solutions for larger lambdas returned")
    n = -1
    msg = paste("from sdwd fortran code -", msg)
  }
  list(n = n, msg = msg)
}

error.bars = function(x, upper, lower, width=0.02, 
    ...) {
  xlim = range(x)
  barw = diff(xlim) * width
  segments(x, upper, x, lower, ...)
  segments(x - barw, upper, x + barw, upper, ...)
  segments(x - barw, lower, x + barw, lower, ...)
  range(upper, lower)
}

getmin = function(lambda, cvm, cvsd) {
  cvmin = min(cvm)
  idmin = cvm <= cvmin
  lambda.min = max(lambda[idmin])
  cv.min = max(cvm[idmin])
  idmin = match(lambda.min, lambda)
  semin = (cvm + cvsd)[idmin]
  idmin = cvm <= semin
  lambda.1se = max(lambda[idmin])
  cv.1se = cvm[lambda == lambda.1se]  
  list(lambda.min = lambda.min, lambda.1se = lambda.1se, 
    cvm.min = cv.min, cvm.1se = cv.1se)
}

getoutput = function(fit, maxit, pmax, nvars, vnames) {
  nalam = fit$nalam
  nbeta = fit$nbeta[seq(nalam)]
  nbetamax = max(nbeta)
  lam = fit$alam[seq(nalam)]
  stepnames = paste("s", seq(nalam) - 1, sep = "")
  errmsg = err(fit$jerr, maxit, pmax)
  switch(paste(errmsg$n), `1` = stop(errmsg$msg, call. = FALSE), 
    `-1` = print(errmsg$msg, call. = FALSE))
  dd = c(nvars, nalam)
  if (nbetamax > 0) {
    beta = matrix(fit$beta[seq(pmax * nalam)], 
        pmax, nalam)[seq(nbetamax), , drop = FALSE]
    df = apply(abs(beta) > 0, 2, sum)
    ja = fit$ibeta[seq(nbetamax)]
    oja = order(ja)
    ja = rep(ja[oja], nalam)
    ibeta = cumsum(c(1, rep(nbetamax, nalam)))
    beta = new("dgCMatrix", Dim = dd, Dimnames = list(vnames, 
      stepnames), x = as.vector(beta[oja, ]), 
      p = as.integer(ibeta - 1), i = as.integer(ja - 1))
  } else {
    beta = zeromat(nvars, nalam, vnames, stepnames)
    df = rep(0, nalam)
  }
  b0 = fit$b0
  if (!is.null(b0)) {
    b0 = b0[seq(nalam)]
    names(b0) = stepnames
  }
  list(b0 = b0, beta = beta, df = df, dim = dd, lambda = lam)
}

lambda.interp = function(lambda, s) {
  ### lambda is the index sequence that is produced by the model 
  ### s is the new vector at which evaluations are required.
  ### the value is a vector of left and right indices, and a
  #   vector of fractions.
  ### the new values are interpolated bewteen the two using
  #   the fraction.
  ### Note: lambda decreases. you take:
  ### sfrac*left+(1-sfrac*right)
  if (length(lambda) == 1) {
    nums = length(s)
    left = rep(1, nums)
    right = left
    sfrac = rep(1, nums)
  } else {
    s[s > max(lambda)] = max(lambda)
    s[s < min(lambda)] = min(lambda)
    k = length(lambda)
    sfrac = (lambda[1] - s)/(lambda[1] - lambda[k])
    lambda = (lambda[1] - lambda)/(lambda[1] - lambda[k])
    coord = approx(lambda, seq(lambda), sfrac)$y
    left = floor(coord)
    right = ceiling(coord)
    sfrac = (sfrac - lambda[right])/(lambda[left] - lambda[right])
    sfrac[left == right] = 1
  }
  list(left = left, right = right, frac = sfrac)
}

lamfix = function(lam) {
  llam = log(lam)
  lam[1] = exp(2 * llam[2] - llam[3])
  lam
}

nonzero = function(beta, bystep=FALSE) {
  ns = ncol(beta)
  ##beta should be in 'dgCMatrix' format
  if (nrow(beta) == 1) {
    if (bystep) 
      apply(beta, 2, function(x) if (abs(x) > 0) 
          1 else NULL) else {
      if (any(abs(beta) > 0)) 
          1 else NULL
    }
  } else {
    beta = t(beta)
    which = diff(beta@p)
    which = seq(which)[which > 0]
    if (bystep) {
      nzel = function(x, which) if (any(x)) 
        which[x] else NULL
      beta = abs(as.matrix(beta[, which])) > 0
      if (ns == 1) 
        apply(beta, 2, nzel, which) else 
        apply(beta, 1, nzel, which)
    } else which
  }
}

zeromat = function(nvars, nalam, vnames, stepnames) {
  ca = rep(0, nalam)
  ia = seq(nalam + 1)
  ja = rep(1, nalam)
  dd = c(nvars, nalam)
  new("dgCMatrix", Dim=dd, Dimnames=list(vnames, stepnames), 
    x=as.vector(ca), p=as.integer(ia - 1), 
    i=as.integer(ja - 1))
} 
