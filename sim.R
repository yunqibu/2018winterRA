## !!!! REMOVE parallel = TRUE before cluster
# different smooth.S1 for P1hat, P2hat, P3hat? P1star P2star P3star? Innfuluence function D1 D2 D3?
# P1hat<0:  rescaled smooth.S1 to 0~1, use binomial family
#     Warnings: In eval(expr, envir, enclos) : non-integer #successes in a binomial glm!
# Add in W S1 for data generation: extrapolated
#     cant find closed form for the integal
# sometimes P2hat is still 0, how to fix?

# No nested case-control sampling design yet
# 100% cross over rate for now
# Later include dropouts: Probability of random dropout after the immune response is measured of 0.10*(1.75/2).



#$ -S /usr/local/bin/Rscript
setwd("~/Desktop/Peter Gilbert/simulation")

args = commandArgs(TRUE)
h = as.numeric(args[[1]]) #.1~.5 bandwith
nv = as.numeric(args[[2]]) # trt 4200 ctl 3000
np = as.numeric(args[[3]])
corr_S1_W = as.numeric(args[[4]])
crossover_rate = as.numeric(args[[5]])
nrep = as.numeric(args[[6]]) 
library(SuperLearner)
library(mvtnorm)

generate.data = function(nv, np,  corr_S1_W) {
  logit = function(x) log(x/(1-x))
  expit = function(x) exp(x)/(1+exp(x))
  # treatment variable A
  A = c(rep(1,nv),rep(0,np)) # A = c(rep(1,n/2),rep(0,n/2))
  n = nv+np
  var_W = 1
  var_S1 = 1
  ws = rmvnorm(n, mean=rep(0.41,2),
               sigma=matrix(c( var_W ,corr_S1_W*sqrt(var_S1*var_W),
                               corr_S1_W*sqrt(var_S1*var_W), var_S1),2,2)) # ws = rmvnorm(n, mean=rep(0.41,2),sigma=matrix(c(0.55^2,0.55^2*0.5,0.55^2*0.5,0.55^2),2,2))
  # baseline covariate
  W = ws[,1]
  # post-treatment biomarker
  S1 = ws[,2]
  vaccine_efficacy = 0.75 # 0.5 for later
  betaW = -0.5
  betaS0 = -0.1
  betaS1 = -1
  ws.l = rmvnorm(10^6, mean=rep(0.41,2),
               sigma=matrix(c( var_W ,corr_S1_W*sqrt(var_S1*var_W),
                               corr_S1_W*sqrt(var_S1*var_W), var_S1),2,2)) # ws = rmvnorm(n, mean=rep(0.41,2),sigma=matrix(c(0.55^2,0.55^2*0.5,0.55^2*0.5,0.55^2),2,2))
  # baseline covariate
  W.l = ws.l[,1]
  # post-treatment biomarker
  S1.l = ws.l[,2]
  p0fun = function(x) mean(expit(x + betaW*W.l + betaS0*S1.l)-0.04*(1.75/2))
  beta0 = uniroot(p0fun,c(-100,100))$root
  p1fun = function(x) mean(expit(x + betaW*W.l + betaS1*S1.l)-0.04*(1.75/2)*(1-vaccine_efficacy))
  beta1 = uniroot(p1fun,c(-100,100))$root
  # beta0 = -1.2
  # beta1 = -1.8
  prob0 = numeric(n)
  prob1 = numeric(n)
  for (i in 1:n) {
    prob0[i] = expit(beta0 + betaW*W[i] + betaS0*S1[i]) 
    prob1[i] = expit(beta1 + betaW*W[i] + betaS1*S1[i]) 
  }
  Y0 = rbinom(n,1,prob0)
  Y1 = rbinom(n,1,prob1)
  Y = A*Y1 + (1-A)*Y0 
  S = ifelse(A==1, S1, ifelse(Y==0, S1, NA)) # 100% cross over rate for now
  observed = list(A=A, W=W, Y=Y, S1=S)
  unobserved = list(S1=S1,Y0=Y0,Y1=Y1)
  return(list(observed=observed, unobserved=unobserved))
}

DATA=NULL
estimate = function(dat, h=0.5, s1star) {
  A = dat$A
  W = dat$W
  S1 = dat$S1
  Y = dat$Y
  n = length(A)
  nv = sum(A)
  np = n-nv
  Kh = function(x) exp(-(x/h)^2/2)/sqrt(2*pi)/h
  
  ############ initial estimate ############
  SL.library <- c("SL.glm", "SL.glm.interaction", "SL.step", "SL.nnet", "SL.mean")
  smooth.S1 = Kh(S1-s1star)
  min.smooth.S1 = min(smooth.S1, na.rm=T)
  max.smooth.S1 = max(smooth.S1, na.rm=T)
  scaled.smooth.S1 = (smooth.S1-min.smooth.S1)/(max.smooth.S1-min.smooth.S1)
  P1hat = 0
  P2hat = 0
  P3hat = 0
  
  #S1|A=1,W 
  out=NULL
  hseq =  seq(0.1,1,0.1)
  for (h in hseq){
    print(h)
    Kh = function(x) exp(-(x/h)^2/2)/sqrt(2*pi)/h
    smooth.S1 = Kh(S1-s1star)
    min.smooth.S1 = min(smooth.S1, na.rm=T)
    max.smooth.S1 = max(smooth.S1, na.rm=T)
    scaled.smooth.S1 = (smooth.S1-min.smooth.S1)/(max.smooth.S1-min.smooth.S1)
    fit1 <- CV.SuperLearner(Y = scaled.smooth.S1[A==1], X = data.frame(W=W[A==1]), V=10, family = binomial(), 
                            SL.library = SL.library, method = "method.NNLS") 
    P1hat = fit1$SL.predict
    P1hat = P1hat*(max.smooth.S1-min.smooth.S1)+min.smooth.S1
    out=c(out,mean(-log(P1hat)))
    print(out)
  }
  h=hseq[which.min(out)]
  print(h)
  h1=h
  Kh = function(x) exp(-(x/h)^2/2)/sqrt(2*pi)/h
  smooth.S1 = Kh(S1-s1star)
  smooth.S1.1 = smooth.S1
  min.smooth.S1 = min(smooth.S1, na.rm=T)
  max.smooth.S1 = max(smooth.S1, na.rm=T)
  scaled.smooth.S1 = (smooth.S1-min.smooth.S1)/(max.smooth.S1-min.smooth.S1)
  fit1 <- SuperLearner(Y = scaled.smooth.S1[A==1], X = data.frame(W=W[A==1]), family = binomial(), 
                       SL.library = SL.library, method = "method.NNLS") 
  print(fit1)
  P1hat = predict(fit1, data.frame(W))$pred
  P1hat = P1hat*(max.smooth.S1-min.smooth.S1)+min.smooth.S1
  
  #Y=1,S1|A=1,W
  out=NULL
  hseq = c(seq(0.1,1,0.1))
  for (h in hseq){
    print(h)
    Kh = function(x) exp(-(x/h)^2/2)/sqrt(2*pi)/h
    smooth.S1 = Kh(S1-s1star)
    min.smooth.S1 = min(smooth.S1, na.rm=T)
    max.smooth.S1 = max(smooth.S1, na.rm=T)
    scaled.smooth.S1 = (smooth.S1-min.smooth.S1)/(max.smooth.S1-min.smooth.S1)
    fit1 <- CV.SuperLearner(Y = scaled.smooth.S1[A==1 & Y==1], X = data.frame(W=W[A==1 & Y==1]), family = binomial(), 
                            SL.library = SL.library, method = "method.NNLS") 
    fit2 <- SuperLearner(Y = Y[A==1], X = data.frame(W=W[A==1]), family = binomial(), 
                         SL.library = SL.library, method = "method.NNLS")
    P2hat = (fit1$SL.predict*(max.smooth.S1-min.smooth.S1)+min.smooth.S1)*predict(fit2,data.frame(W=W[A==1 & Y==1]))$pred
    out=c(out,mean(-log(P2hat)))
    print(out)
  }
  h=hseq[which.min(out)]
  h2=h
  Kh = function(x) exp(-(x/h)^2/2)/sqrt(2*pi)/h
  smooth.S1 = Kh(S1-s1star)
  smooth.S1.2 = smooth.S1
  min.smooth.S1 = min(smooth.S1, na.rm=T)
  max.smooth.S1 = max(smooth.S1, na.rm=T)
  scaled.smooth.S1 = (smooth.S1-min.smooth.S1)/(max.smooth.S1-min.smooth.S1)
  fit1 <- SuperLearner(Y = scaled.smooth.S1[A==1 & Y==1], X = data.frame(W=W[A==1 & Y==1]), family = binomial(), 
                       SL.library = SL.library, method = "method.NNLS")
  fit2 <- SuperLearner(Y = Y[A==1], X = data.frame(W=W[A==1]), family = binomial(), 
                       SL.library = SL.library, method = "method.NNLS")
  P2hat = (predict(fit1, data.frame(W=W))$pred*(max.smooth.S1-min.smooth.S1)+min.smooth.S1) * predict(fit2, data.frame(W=W))$pred
  
  
  #Y=0,S0^c|A=0,W
  out=NULL
  hseq = c(seq(0.1,1,0.1))
  for (h in hseq){
    print(h)
    Kh = function(x) exp(-(x/h)^2/2)/sqrt(2*pi)/h
    smooth.S1 = Kh(S1-s1star)
    min.smooth.S1 = min(smooth.S1, na.rm=T)
    max.smooth.S1 = max(smooth.S1, na.rm=T)
    scaled.smooth.S1 = (smooth.S1-min.smooth.S1)/(max.smooth.S1-min.smooth.S1)
    fit1 <- CV.SuperLearner(Y = scaled.smooth.S1[A==0 & Y==0], X = data.frame(W=W[A==0 & Y==0]), family = binomial(), 
                            SL.library = SL.library, method = "method.NNLS") 
    fit2 <- SuperLearner(Y = Y[A==0], X = data.frame(W=W[A==0]), family = binomial(), 
                         SL.library = SL.library, method = "method.NNLS")
    P3hat = (fit1$SL.predict*(max.smooth.S1-min.smooth.S1)+min.smooth.S1)*(1-predict(fit2,data.frame(W=W[A==0 & Y==0]))$pred) 
    
    out=c(out,mean(-log(P3hat)))
    print(out)
  }
  h=hseq[which.min(out)]
  h3=h
  Kh = function(x) exp(-(x/h)^2/2)/sqrt(2*pi)/h
  smooth.S1 = Kh(S1-s1star)
  smooth.S1.3= smooth.S1
  min.smooth.S1 = min(smooth.S1, na.rm=T)
  max.smooth.S1 = max(smooth.S1, na.rm=T)
  scaled.smooth.S1 = (smooth.S1-min.smooth.S1)/(max.smooth.S1-min.smooth.S1)
  fit1 <- SuperLearner(Y = scaled.smooth.S1[A==0 & Y==0], X = data.frame(W=W[A==0 & Y==0]), family = binomial(), 
                       SL.library = SL.library, method = "method.NNLS") # rescale smooth.S1 to range 0,1, switch gaussian to binomial
  fit2 <- SuperLearner(Y = Y[A==0], X = data.frame(W=W[A==0]), family = binomial(), 
                       SL.library = SL.library, method = "method.NNLS")
  P3hat = (predict(fit1, data.frame(W=W))$pred*(max.smooth.S1-min.smooth.S1)+min.smooth.S1) * (1-predict(fit2, data.frame(W=W))$pred) 
  
  
  #A=1|W
  fit = SuperLearner(Y = A, X = data.frame(W=W), family = binomial(), 
                     SL.library = SL.library, method = "method.NNLS")
  Ahat = as.vector(fit$SL.predict)
  
  #################### fluctuation #####################
  
  #missing for A=0 & Y=1
  h=h1
  smooth.S1 = smooth.S1.1
  smooth.S1.nomissing = ifelse(is.na(smooth.S1), 100, smooth.S1)
  smooth.S1.nomissing.1 = smooth.S1.nomissing
  fit1 = glm( smooth.S1.nomissing ~ 1, weights = (A==1)/Ahat, offset = log(P1hat), family = poisson())
  P1star =  fit1$fitted.values
  DATA=dat
  save(DATA, file=paste("iter",iter,"j",j,".Rda",sep=""))
  
  h=h2
  smooth.S1 = smooth.S1.2
  smooth.S1.nomissing = ifelse(is.na(smooth.S1), 100, smooth.S1)
  smooth.S1.nomissing.2 = smooth.S1.nomissing
  fit2 = glm( (Y==1)*smooth.S1.nomissing ~ 1, weights = (A==1)/Ahat, offset = log(P2hat), family=poisson())
  P2star = fit2$fitted.values
  
  h=h3
  smooth.S1 = smooth.S1.3
  smooth.S1.nomissing = ifelse(is.na(smooth.S1), 100, smooth.S1)
  smooth.S1.nomissing.3 = smooth.S1.nomissing
  fit3 = glm( (Y==0)*smooth.S1.nomissing ~ 1, weights = (A==0)/(1-Ahat), offset = log(P3hat), family=poisson())
  P3star = fit3$fitted.values
  
  ################### estimation #######################
  psi1 = mean(P1star)
  psi2 = mean(P2star)
  psi3 = mean(P3star)
  psi = log(psi2/(psi1-psi3))
  init.psi = log(mean(P2hat)/(mean(P1hat)-mean(P3hat)))
  
  ################### influence function/gradient ###############
  D1 = (A==1)/Ahat*(smooth.S1.nomissing.1 - P1star) + P1star - psi1
  D2 = (A==1)/Ahat*((Y==1)*smooth.S1.nomissing.2 - P2star) + P2star - psi2
  D3 = (A==0)/(1-Ahat)*((Y==0)*smooth.S1.nomissing.3 - P3star) + P3star - psi3
  g1 = -1/(psi1-psi3) # for target parameter log(RR)
  g2 = 1/psi2
  g3 = 1/(psi1-psi3)
  D = g1 * D1 + g2 * D2 + g3 * D3
  
  sd = sqrt(mean(D^2)/n)
  sd1 = sqrt(mean(D1^2)/n)
  sd2 = sqrt(mean(D2^2)/n)
  sd3 = sqrt(mean(D3^2)/n)
  
  return(list(psi=psi,sd=sd,psi1=psi1,psi2=psi2,psi3=psi3,sd1=sd1,sd2=sd2,sd3=sd3,init.psi=init.psi))
}

truth = function(s1star) {
  logit = function(x) log(x/(1-x))
  expit = function(x) exp(x)/(1+exp(x))
  var_W = 1
  var_S1 = 1
  corr_S1_W = corr_S1_W
  vaccine_efficacy = 0.75 
  b1 = -0.5
  b2 = -1
  b3 = -0.1
  ws.l = rmvnorm(10^6, mean=rep(0.41,2),
                 sigma=matrix(c( var_W ,corr_S1_W*sqrt(var_S1*var_W),
                                 corr_S1_W*sqrt(var_S1*var_W), var_S1),2,2)) # ws = rmvnorm(n, mean=rep(0.41,2),sigma=matrix(c(0.55^2,0.55^2*0.5,0.55^2*0.5,0.55^2),2,2))
  W.l = ws.l[,1]
  S1.l = ws.l[,2]
  p0fun = function(x) mean(expit(x + b1*W.l + b3*S1.l)-0.04*(1.75/2))
  b00 = uniroot(p0fun,c(-100,100))$root
  p1fun = function(x) mean(expit(x + b1*W.l + b2*S1.l)-0.04*(1.75/2)*(1-vaccine_efficacy))
  b01 = uniroot(p1fun,c(-100,100))$root
  # b00 = -1.2
  # b01 = -1.8
  
  #W, S1
  mu = rep(0.41,2)
  var_W = 1
  var_S1 = 1
  corr_S1_W = 0.5
  sigma = matrix(c( var_W ,corr_S1_W*sqrt(var_S1*var_W),
                    corr_S1_W*sqrt(var_S1*var_W), var_S1),2,2)
  
  psi1 = dnorm(s1star,mean=mu[2],sd=sqrt(sigma[2,2]))
  #conditional distribution of W|S1
  muW = mu[1]+sigma[1,2]/sigma[2,2]*(s1star - mu[2])
  sigW = sigma[1,1] - sigma[1,2]^2/sigma[2,2]
  W = rnorm(10^6, mean=muW, sd=sqrt(sigW))
  
  psi2 = mean(expit(b01 + b1*W + b2*s1star)) * psi1
  psi3 = (1 - mean(expit(b00 + b1*W + b3*s1star))) * psi1
  psi = log(psi2/(psi1-psi3))
  return(list(psi=psi, psi1=psi1, psi2=psi2, psi3=psi3))
}

smooth.truth = function(dat, h, s1star) {
  S1 = dat$S1
  Y0 = dat$Y0
  Y1 = dat$Y1
  n = length(S1)
  Kh = function(x) exp(-(x/h)^2/2)/sqrt(2*pi)/h
  SL.library <- c("SL.glm", "SL.glm.interaction", "SL.step", "SL.nnet", "SL.mean")
  smooth.S1 = Kh(S1-s1star)
  
  psi1 = mean(smooth.S1)
  psi2 = mean((Y1==1)*smooth.S1) 
  psi3 = mean((Y0==0)*smooth.S1)
  psi = log(psi2/(psi1-psi3))
  return(list(psi=psi, psi1=psi1, psi2=psi2, psi3=psi3))
}

############################################################
############################################################

s1 = seq(0,1,by=0.5)
lens = length(s1)
true.psi = numeric(lens)
true.psi1 = numeric(lens)
true.psi2 = numeric(lens)
true.psi3 = numeric(lens)
for (j in 1:lens) {
  out = truth(s1[j])
  true.psi[j] = out$psi
  true.psi1[j] = out$psi1
  true.psi2[j] = out$psi2
  true.psi3[j] = out$psi3
}

smooth.true.psi = matrix(NA, 1, lens)
smooth.true.psi1 = matrix(NA, 1, lens)
smooth.true.psi2 = matrix(NA, 1, lens)
smooth.true.psi3 = matrix(NA, 1, lens)

init.psi = matrix(NA, nrep, lens)

TMLE.psi = matrix(NA, nrep, lens)
TMLE.psi1 = matrix(NA, nrep, lens)
TMLE.psi2 = matrix(NA, nrep, lens)
TMLE.psi3 = matrix(NA, nrep, lens)

psi.sd = matrix(NA, nrep, lens)
psi.sd1 = matrix(NA, nrep, lens)
psi.sd2 = matrix(NA, nrep, lens)
psi.sd3 = matrix(NA, nrep, lens)

dat = generate.data(nv=nv, np=np, corr_S1_W=corr_S1_W)

# smooth true for a given h
for (j in 1:lens) {
  out.smooth = smooth.truth(dat=dat$unobs, h=h, s1star=s1[j])
  smooth.true.psi[1,j] = out.smooth$psi
  smooth.true.psi1[1,j] = out.smooth$psi1
  smooth.true.psi2[1,j] = out.smooth$psi2
  smooth.true.psi3[1,j] = out.smooth$psi3
}

for (iter in 1:nrep) {
  dat = generate.data(nv=nv, np=np,  corr_S1_W= corr_S1_W)
  obs = dat$observed
  unobs = dat$unobserved
  for (j in 1:lens) {
    print(c(iter,j))
    out.tmle = estimate(dat=obs, h=h, s1star=s1[j])
    print("done iter")
    TMLE.psi[iter,j] = out.tmle$psi
    TMLE.psi1[iter,j] = out.tmle$psi1
    TMLE.psi2[iter,j] = out.tmle$psi2
    TMLE.psi3[iter,j] = out.tmle$psi3

    psi.sd[iter,j] = out.tmle$sd
    psi.sd1[iter,j] = out.tmle$sd1
    psi.sd2[iter,j] = out.tmle$sd2
    psi.sd3[iter,j] = out.tmle$sd3
    
    init.psi[iter,j] = out.tmle$init.psi
  }
}

save(true.psi, true.psi1, true.psi2, true.psi3, 
     smooth.true.psi,  smooth.true.psi1,  smooth.true.psi2,  smooth.true.psi3, 
     TMLE.psi, TMLE.psi1, TMLE.psi2, TMLE.psi3, 
     init.psi, 
     psi.sd, psi.sd1, psi.sd2, psi.sd3, 
     file=paste("h",h,"n",n,"nrep",nrep,".Rda",sep=""))
