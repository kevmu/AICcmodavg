##Goodness-of-fit test based on the chi-square
##chi-square
Nmix.chisq <- function(mod) {

  ##for N-mixtures models
  if(!identical(class(mod)[1], "unmarkedFitPCount") && !identical(class(mod)[1], "unmarkedFitPCO")) {
    stop("\nThis function is only appropriate for N-mixture models\n")
  }
  obs <- getData(mod)@y
  ##check if sites were removed from analysis
  sr <- mod@sitesRemoved
  if(length(sr) > 0) {    obs <- obs[-sr, , drop = FALSE] }
  fits <- fitted(mod)
  obs[is.na(fits)] <- NA
  chi.sq <- sum((obs - fits)^2/(fits * (1 - fits)), na.rm = TRUE) #added argument na.rm = TRUE when NA's occur
  return(chi.sq)
}


Nmix.gof.test <- function(mod, nsim = 5, plot.hist = TRUE){#more bootstrap samples are recommended (e.g., 1000, 5000, or 10 000)

  ##compute GOF P-value
  out <- parboot(mod, statistic = Nmix.chisq,
                 nsim = nsim)

  ##determine significance
  p.value <- sum(out@t.star >= out@t0)/nsim
  if(p.value == 0) {
    p.display <- paste("<", 1/nsim)
  } else {
    p.display = paste("=", round(p.value, digits = 4))
  }

  ##create plot
  if(plot.hist) {
    hist(out@t.star, main = expression(paste("Bootstrapped ", chi^2, " fit statistic (", nsim, " samples)", sep = "")),
       xlim = range(c(out@t.star, out@t0)), xlab = paste("Simulated statistic ", "(observed = ", round(out@t0, digits = 2), ")", sep = ""))
    title(main = bquote(paste(italic(P), .(p.display))), line = 0.5)
    abline(v = out@t0, lty = "dashed", col = "red")
  }
  
  ##estimate c-hat
  c.hat.est <- out@t0/mean(out@t.star)

  ##assemble result
  gof.out <- list(chi.square = out@t0, t.star = out@t.star,
                  p.value = p.value, c.hat.est = c.hat.est, nsim = nsim)
  class(gof.out) <- "Nmix.chisq"
  return(gof.out)  
}

print.Nmix.chisq <- function(x, digits.vals = 2, digits.chisq = 4, ...) {
  cat("\nChi-square goodness-of-fit for N-mixture model\n")
  cat("\nObserved chi-square statistic =", round(x$chi.square, digits = digits.chisq), "\n")
  if(length(x) > 2){
    cat("Number of bootstrap samples =", x$nsim)
    cat("\nP-value =", x$p.value)
    cat("\n\nQuantiles of bootstrapped statistics:\n")
    print(quantile(x$t.star), digits = digits.vals)
    cat("\nEstimate of c-hat =", round(x$c.hat.est, digits = digits.vals), "\n\n")
  }
}

