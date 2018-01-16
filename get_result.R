setwd("C:/Users/Matt/Dropbox/vaccine/simulation")
conf.cov = function(s1, TMLE.psi, psi.sd, true.psi, smooth.true.psi) {
  x = c(0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1)
  j = which(x == s1)
  nrep = nrow(TMLE.psi)
  lens = 1
  coverage.truth = numeric(nrep)
  coverage.smoothed = numeric(nrep)
  k = 1
  for (i in 1:nrep) {
        if (!is.na(TMLE.psi[i,j])) {
          lower.int = TMLE.psi[i,j] - qnorm(0.975)*psi.sd[i,j]
          higher.int = TMLE.psi[i,j] + qnorm(0.975)*psi.sd[i,j]
          if (true.psi[j] >= lower.int & true.psi[j] <= higher.int)
            coverage.truth[i] = 1
          if (smooth.true.psi[j]  >= lower.int & smooth.true.psi[j] <= higher.int)
            coverage.smoothed[i] = 1
        } 
  }
  cov.truth = mean(coverage.truth)
  cov.smooth = mean(coverage.smoothed)
  return(list(cov.truth=cov.truth, cov.smooth=cov.smooth, k=k-1))
}

# for fixed s1, plot confidence interval coverage
pdf("coverage_s1.pdf")
s1 = 0.6
hh = c(0.01, 0.025, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4)
par(cex.lab=1.4, cex.axis=1.4, cex.main=1.6)
plot(hh, hh, col="black", ylim=c(0.75,1), pch=19, xlab="Bandwidth (h)",
     ylab="Confidence Interval Coverage",bty="n", cex=1.5)
for (h in hh) {
  load( paste("h",h,"n5000nrep1000.Rda", sep="") )
  res = conf.cov(s1, TMLE.psi, psi.sd, true.psi, smooth.true.psi)
  if (h==0.05 | h == 0.15 ) res$cov.truth = res$cov.truth+0.001
  if (h == 0.01)  res$cov.truth = res$cov.truth-0.001
  points(h, res$cov.truth, col="red", pch=19, cex=1.5)
  points(h, res$cov.smooth, col="blue", pch=19, cex=1.5)
  abline(0.95, 0, lty=2)
}
legend("bottomright", c("True Parameter","Smoothed True Parameter"), 
       col=c("red", "blue"), pch=19, cex=1.5, bty="n")
dev.off()


# bias, variance, coverage for h = 0.2
load( paste("h",0.2,"n5000nrep1000.Rda", sep="") )
x =  c(0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9)
nrep = nrow(TMLE.psi)
lens = length(x)
bias.truth = matrix(0,nrep,lens)
bias.smoothed = matrix(0,nrep,lens)
coverage.truth = matrix(0,nrep,lens)
coverage.smoothed = matrix(0,nrep,lens)
for (i in 1:nrep) {
  for (j in 1:lens) {
    if (!is.na(psi.sd[i,j])) {
      bias.truth[i,j] = TMLE.psi[i,j] - true.psi[j]
      bias.smoothed[i,j] = TMLE.psi[i,j] - smooth.true.psi[j]
      lower.int = TMLE.psi[i,j] - qnorm(0.975)*psi.sd[i,j]
      higher.int = TMLE.psi[i,j] + qnorm(0.975)*psi.sd[i,j]
      if (true.psi[j] >= lower.int & true.psi[j] <= higher.int)
        coverage.truth[i,j] = 1
      if (smooth.true.psi[j]  >= lower.int & smooth.true.psi[j] <= higher.int)
        coverage.smoothed[i,j] = 1
    }
    else {
      bias.truth[i,j] = NA
      bias.smoothed[i,j] = NA
      coverage.truth[i,j]= NA
      coverage.smoothed[i,j] = NA
    }
  }
}

tab = rbind(apply(bias.truth, 2, function(x) mean(x, na.rm=T)),
      apply(bias.smoothed, 2, function(x) mean(x, na.rm=T)),
      apply(coverage.truth, 2,  function(x) mean(x, na.rm=T)),
      apply(coverage.smoothed, 2,  function(x) mean(x, na.rm=T)),
      apply(psi.sd, 2, function(x) mean(x, na.rm=T))[1:10],
      apply(TMLE.psi, 2, sd)[1:10] )

rownames(tab) = c("bias.truth", "bias.smooth", "cover.truth", "cover.smooth",
                  "se", "sampling se")
colnames(tab) = x
round(tab, digits=4)
library(xtable)
print(xtable(tab, type = "latex"), file = "table.tex")


# # plot average of the curves for h = 0.15
# load( paste("h",0.2,"n5000nrep1000.Rda", sep="") )
# est = apply(TMLE.psi, 2, mean)
# se = apply(psi.sd, 2, function(x) mean(x, na.rm=T))
# x = c(0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1)
# lower = est - qnorm(0.975)*se
# higher = est + qnorm(0.975)*se
# 
# plot(x, exp(smooth.true.psi), col="blue", ylim=c(0.2,0.8), cex=1.4, 
#      pch=19,xlab=expression(s[1]),ylab="Risk Ratio")
# points(x, exp(est), col="black",pch=19,cex=1.4 )
# legend("topright", c("Smoothed True Parameter", "Estimate"), col=c("blue", "black"), pch=19)
# epi=0.01
# for (j in 1:11) {
#   lines(c(x[j],x[j]),exp(c(lower[j], higher[j])),lwd=2)
#   lines(c(x[j]-epi,x[j]+epi),exp(rep(lower[j], 2)),lwd=2)
#   lines(c(x[j]-epi,x[j]+epi),exp(rep(higher[j], 2)),lwd=2)
# }
