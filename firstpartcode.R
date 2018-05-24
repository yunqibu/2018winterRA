#$ -S /usr/local/bin/Rscript

# correlation between S1 and W
corr_S1_W = 0.75
# crossover rate of S
crossover_rate = 0

# setwd("~/Desktop/Peter Gilbert/2018winterRA/")
library(SuperLearner)
library(mvtnorm)
library(ks)

# Later include dropouts: Probability of random dropout after the immune response is measured of 0.10*(1.75/2).

# can't change 100 to Inf, use 10^10 instead

# bandwith
h = 0.1
# treatment, virus 
nv = 4200
# control, placebo
np = 3000


generate.data = function(nv, np,  corr_S1_W) {
  logit = function(x) log(x/(1-x))
  expit = function(x) exp(x)/(1+exp(x))
  # treatment variable A
  A = c(rep(1,nv),rep(0,np)) 
  # total number or subjects
  n = nv+np 
  # variance of W
  var_W = 1
  # variance of S1
  var_S1 = 1
  # generate W and S1 by a multinormal distribution
  ws = rmvnorm(n, mean=rep(0.41,2),
               sigma=matrix(c( var_W ,corr_S1_W*sqrt(var_S1*var_W),
                               corr_S1_W*sqrt(var_S1*var_W), var_S1),2,2)) 
  # baseline covariate W
  W = ws[,1]
  # post-treatment biomarker S1
  S1 = ws[,2]
  # Disease rate post marker measurement (from month 3 to month 24):
  #     P(Y=1|A=0) = 0.04*(1.75/2) for the placebo group (A=0) and
  #     P(Y=1|A=1) = 0.01*(1.75/2) for the vaccine group (A=1) (75% vaccine efficacy).
  # vaccine efficacy
  vaccine_efficacy = 0.75 # 0.5 for later
  betaW = -0.5
  betaS0 = -0.1
  betaS1 = -1
  # No mathematical form to calculate the coefficients, 
  # so done by large sample size 10^6 approximation to ensure the P(Y=1|Z=0), P(Y=1|Z=1) above
  ws.l = rmvnorm(10^6, mean=rep(0.41,2),
                 sigma=matrix(c( var_W ,corr_S1_W*sqrt(var_S1*var_W),
                                 corr_S1_W*sqrt(var_S1*var_W), var_S1),2,2)) 
  W.l = ws.l[,1]
  S1.l = ws.l[,2]
  # find the root by solving functions to calculate coefficents beta0, beta1
  p0fun = function(x) mean(expit(x + betaW*W.l + betaS0*S1.l)-0.04*(1.75/2))
  beta0 = uniroot(p0fun,c(-100,100))$root
  p1fun = function(x) mean(expit(x + betaW*W.l + betaS1*S1.l)-0.04*(1.75/2)*(1-vaccine_efficacy))
  beta1 = uniroot(p1fun,c(-100,100))$root
  # P(Y=1|A=0)
  prob0 = numeric(n)
  # P(Y=1|A=1) 
  prob1 = numeric(n)
  for (i in 1:n) {
    prob0[i] = expit(beta0 + betaW*W[i] + betaS0*S1[i]) 
    prob1[i] = expit(beta1 + betaW*W[i] + betaS1*S1[i]) 
  }
  Y0 = rbinom(n,1,prob0)
  Y1 = rbinom(n,1,prob1)
  # observed Y
  Y = A*Y1 + (1-A)*Y0 
  # S missing when A=0, Y=1 
  S = ifelse(A==1, S1, ifelse(Y==0, S1, NA)) 
  # Nested case-control sampling design for measuring S, with S 
  # measured in all A=1 subjects with Y=1 observed and in a simple 
  # random sample of A=1 subjects with Y=0 observed.  
  # The control:case ratio (i.e., Y=0:Y=1 ratio) could be set to 4 for the first simulations.
  k=4
  temp = table(A=A, Y=Y)
  numA1Y1 = temp[2,2]
  numA1Y0 = temp[2,1]
  numA0Y0 = temp[1,1]
  # S A=1,Y=1 : A=1,Y=0 = 1:K
  numA1Y0S = min(temp[2,2]*k, temp[2,1])
  # other A=1,Y=0 set to missing, indicators of missing S
  S.ind = sample(1:numA1Y0, numA1Y0-numA1Y0S, replace = FALSE)
  S[A==1&Y==0][S.ind] <- NA
  
  # S missingness when A=0,Y=0 by crossover rate 25% 50% 75%
  S.ind = sample(1:numA0Y0, floor((1-crossover_rate)*numA0Y0), replace = FALSE)
  S[A==0 & Y==0][S.ind] <- NA
  
  # Calculate the weight Pi for S
  # none missinngness of S
  delta = 1-is.na(S)
  # delta/P(delta=1|W,A,Y) is the weight
  Pi = delta
  # A=1 Y=1 Pi=1
  # A=0 Y=1 Pi=1
  Pi[A==0&Y==1] <- 1
  # A=1 Y=0 regress on W for P(delta=1|W,A,Y)
  fit <- glm (delta[A==1&Y==0] ~ W[A==1&Y==0], family = binomial) 
  Pi[A==1&Y==0] = delta[A==1&Y==0]/fit$fitted.values
  # A=0 Y=0 regress on W for P(delta=1|W,A,Y)
  fit <- glm (delta[A==0&Y==0] ~ W[A==0&Y==0], family = binomial) 
  Pi[A==0&Y==0] = delta[A==0&Y==0]/fit$fitted.values
  # observed variables
  observed = list(A=A, W=W, Y=Y, S1=S, Pi=Pi)
  # unobserved variables
  unobserved = list(S1=S1,Y0=Y0,Y1=Y1)
  return(list(observed=observed, unobserved=unobserved))
}

# DATA=NULL
estimate <- function(dat, h, s1star) {
  A = dat$A
  W = dat$W
  S1 = dat$S1
  Y = dat$Y
  Pi = dat$Pi
  n = length(A)
  nv = sum(A)
  np = n-nv
  # normal kernal function with banndwith h
  Kh = function(x) exp(-(x/h)^2/2)/sqrt(2*pi)/h
  
  ############ initial estimate ############
  SL.library <- c("SL.glm", "SL.glm.interaction", "SL.nnet", "SL.mean") 
  smooth.S1 = Kh(S1-s1star)
  P1hat = 0
  P2hat = 0
  P3hat = 0

  
  ###### Estimate the conditional density of P(S1=s1star|W) ##########
  # make a data frame of all the needed variables
  temp=as.data.frame(cbind(S1=S1,W=W,Pi=Pi,s1star=s1star))
  
  # indicators of those with A=1 and none missing S1
  ind <- A==1 & (!is.na(S1))
 
  
  # P(W) from kernal density estimation
  W.density <- kde(x=temp$W[ind], eval.points=temp$W) 
  # Get bandwith for S1
  S1.H <- kde(x=temp$S1[ind])$H
  # Get bandwith for W
  W.H <- W.density$H
  # P(S1=s1star,W) from kernal density estimation, use bandwith from above univariate kde
  W.S1.density <- kde(x=temp[ind,c("S1", "W")]  
                      ,eval.points = temp[,c("s1star", "W")] # estimate at s1star
                      ,w=temp$Pi[ind]
                      ,H=matrix(c(S1.H,0,0,W.H),2,2))
  # P(S1=s1star|W)= P(S1=s1star,W)/P(W)
  P1hat <- W.S1.density$estimate / W.density$estimate 
  
  
  # indicators of those with A=1 Y=1 and none missinng S1
  ind <- A==1 & Y==1 & (!is.na(S1))
  
  # P(W) from kernal density estimation
  W.density <- kde(x=temp$W[ind], eval.points=temp$W)
  # Get bandwith for S1
  S1.H <- kde(x=temp$S1[ind])$H
  # Get bandwith for W
  W.H <- W.density$H
  # P(S1=s1star,W) from kernal density estimation
  W.S1.density <- kde(x=temp[ind,c("S1", "W")]  
                      ,eval.points = temp[,c("s1star", "W")] 
                      ,w=temp$Pi[ind]
                      ,H=matrix(c(S1.H,0,0,W.H),2,2))
  
  fit2 <- SuperLearner(Y = Y[A==1],
                       X = data.frame(W=W[A==1]),
                       family = binomial(),
                       SL.library = SL.library, method = "method.NNLS")
  P2hat = (W.S1.density$estimate / W.density$estimate) * predict(fit2, data.frame(W=W))$pred
  
  
  
  # indicators of those with A=0 Y=0 and none missing S1
  ind <- A==0 & Y==0 & (!is.na(S1))
  # P(W) from kernal density estimation
  W.density <- kde(x=temp$W[ind], eval.points=temp$W)
  # Get bandwith for S1
  S1.H <- kde(x=temp$S1[ind])$H
  # Get bandwith for W
  W.H <- W.density$H
  # P(S1=s1star,W) from kernal density estimation
  W.S1.density <- kde(x=temp[ind,c("S1", "W")]  
                      ,eval.points = temp[,c("s1star", "W")] 
                      ,w=temp$Pi[ind]
                      ,H=matrix(c(S1.H,0,0,W.H),2,2))
  fit2 <- SuperLearner(Y = Y[A==0], 
                       X = data.frame(W=W[A==0]), 
                       family = binomial(), 
                       SL.library = SL.library, method = "method.NNLS")
  P3hat = (W.S1.density$estimate / W.density$estimate) * (1-predict(fit2, data.frame(W=W))$pred) 
  
  # A=1|W
  fit = SuperLearner(Y = A, X = data.frame(W=W), family = binomial(), 
                     SL.library = SL.library, method = "method.NNLS")
  Ahat = as.vector(fit$SL.predict)
  
  #################### fluctuation #####################
  
  # missing for A=0 & Y=1
  smooth.S1.nomissing = ifelse(is.na(smooth.S1), 100, smooth.S1) 
  # none missing S1|A by poisson regression with weight
  fit1 = glm(smooth.S1.nomissing~ -1+I(A==1), weights = Pi*(A==1)/Ahat, offset = log(P1hat), family = poisson()) # Add in our weights
  P1star =  fit1$fitted.values 
  # for Y=1, none missing S1|A by poisson regression with weight
  fit2 = glm((Y==1)*smooth.S1.nomissing ~ -1+I(A==1), weights = Pi*(A==1)/Ahat, offset = log(P2hat), family=poisson())
  P2star = fit2$fitted.values
  # for Y=0, none missing S1|A by poisson regression with weight
  fit3 = glm( (Y==0)*smooth.S1.nomissing ~ -1+I(A==0), weights = Pi*(A==0)/(1-Ahat), offset = log(P3hat), family=poisson())
  P3star = fit3$fitted.values
  
  
  ################### estimation #######################
  psi1 = mean(P1star)
  psi2 = mean(P2star)
  psi3 = mean(P3star)
  # psi=log(RR) 
  psi = log(psi2/(psi1-psi3))
  init.psi = log(mean(P2hat)/(mean(P1hat)-mean(P3hat))) 
  
  ################### influence function/gradient ###############
  D1 = Pi*((A==1)/Ahat*(smooth.S1.nomissing - P1star)) + P1star - psi1 
  D2 = Pi*((A==1)/Ahat*((Y==1)*smooth.S1.nomissing - P2star)) + P2star - psi2
  D3 = Pi*((A==0)/(1-Ahat)*((Y==0)*smooth.S1.nomissing - P3star)) + P3star - psi3
  g1 =-1/(psi1-psi3) # for target parameter log(RR)
  g2 = 1/psi2
  g3 = 1/(psi1-psi3)
  D = rowSums(cbind(g1 * D1 , g2 * D2 , g3 * D3), na.rm = T)
  # D = g1 * D1 + g2 * D2 + g3 * D3
  
  # standard error for psi psi1 psi2 psi3
  sd = sqrt(sum(D^2,na.rm=TRUE)/n/n) # mean over entire n, not just on zero
  sd1 = sqrt(sum(D1^2,na.rm=TRUE)/n/n)
  sd2 = sqrt(sum(D2^2,na.rm=TRUE)/n/n)
  sd3 = sqrt(sum(D3^2,na.rm=TRUE)/n/n)
  
  return(list(psi=psi,sd=sd,psi1=psi1,psi2=psi2,psi3=psi3,sd1=sd1,sd2=sd2,sd3=sd3,init.psi=init.psi,h=h))
}

# Approximated theortical truth of psi
truth = function(s1star) {
  logit = function(x) log(x/(1-x))
  expit = function(x) exp(x)/(1+exp(x))
  # Disease rate post marker measurement (from month 3 to month 24):
  #     P(Y=1|A=0) = 0.04*(1.75/2) for the placebo group (A=0) and
  #     P(Y=1|A=1) = 0.01*(1.75/2) for the vaccine group (A=1) (75% vaccine efficacy).
  var_W = 1
  var_S1 = 1
  corr_S1_W = corr_S1_W
  vaccine_efficacy = 0.75 
  b1 = -0.5
  b2 = -1
  b3 = -0.1
  # No mathematical form to calculate the coefficients, 
  # so done by large sample size 10^6 approximation to ensure the P(Y=1|Z=0), P(Y=1|Z=1) above
  ws.l = rmvnorm(10^6, mean=rep(0.41,2),
                 sigma=matrix(c( var_W ,corr_S1_W*sqrt(var_S1*var_W),
                                 corr_S1_W*sqrt(var_S1*var_W), var_S1),2,2)) 
  W.l = ws.l[,1]
  S1.l = ws.l[,2]
  # find the root by solving functions to calculate coefficents b00, b01
  p0fun = function(x) mean(expit(x + b1*W.l + b3*S1.l)-0.04*(1.75/2))
  b00 = uniroot(p0fun,c(-100,100))$root
  p1fun = function(x) mean(expit(x + b1*W.l + b2*S1.l)-0.04*(1.75/2)*(1-vaccine_efficacy))
  b01 = uniroot(p1fun,c(-100,100))$root
  
  #W, S1
  mu = rep(0.41,2)
  var_W = 1
  var_S1 = 1
  corr_S1_W = 0.5
  sigma = matrix(c( var_W ,corr_S1_W*sqrt(var_S1*var_W),
                    corr_S1_W*sqrt(var_S1*var_W), var_S1),2,2)
  
  psi1 = dnorm(s1star, mean=mu[2], sd=sqrt(sigma[2,2]))
  #conditional distribution of W|S1
  muW = mu[1]+sigma[1,2]/sigma[2,2]*(s1star - mu[2])
  sigW = sigma[1,1] - sigma[1,2]^2/sigma[2,2]
  W = rnorm(10^6, mean=muW, sd=sqrt(sigW))
  
  psi2 = mean(expit(b01 + b1*W + b2*s1star)) * psi1
  psi3 = (1 - mean(expit(b00 + b1*W + b3*s1star))) * psi1
  psi = log(psi2/(psi1-psi3))
  return(list(psi=psi, psi1=psi1, psi2=psi2, psi3=psi3))
}

# Truth from unobserved data of psi
smooth.truth = function(dat, h, s1star) {
  S1 = dat$S1
  Y0 = dat$Y0
  Y1 = dat$Y1
  n = length(S1)
  # normal kernal 
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
# give a sequence of s1
s1 = seq(0,1,by=0.1)
lens = length(s1)

# calculate the theortical truth of psi
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

# set up for truth of psi from unobserved data 
smooth.true.psi = matrix(NA, 1, lens)
smooth.true.psi1 = matrix(NA, 1, lens)
smooth.true.psi2 = matrix(NA, 1, lens)
smooth.true.psi3 = matrix(NA, 1, lens)
# band with h for each s1, derived from cv
hseq=c(0.5, 0.5, 0.6, 0.6, 0.6, 0.7, 0.7, 0.7, 0.8, 1.0, 1.0)
# gennerate a set of data
dat = generate.data(nv=nv, np=np, corr_S1_W=corr_S1_W)
# generate the saved file name before removing the aurguments
name = paste("firstpart","corr_S1_W:",corr_S1_W,"crossover_rate:",crossover_rate,".RData", sep="")
# remove the following variables, will be given when runninng cluster
rm(iter) 
rm(corr_S1_W) 
rm(crossover_rate) 
# save the whole image for cluster
save.image(file=name)
