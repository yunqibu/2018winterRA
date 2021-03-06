#$ -S /usr/local/bin/Rscript



# correlation between S1 and W  0.25, 0.5, 0.75
corr_S1_W = 0.75
# crossover rate of S in A=0 Y=0   0.25, 0.5, 1
crossover_rate_A0Y0 = 1
# crossover rate of S in A=1   0.25, 0.5, 1
crossover_rate_A1 = 1

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

betaW = -0.5
# betaS0 = -0.1 
betaS0 = -0.55 #-0.55 for null case
# betaS1 = -1 
betaS1 = -0.55 #-0.55 for null case
b1 = betaW
b2 = betaS1
b3 = betaS0

generate.data = function(nv, np,  corr_S1_W, crossover_rate_A0Y0, crossover_rate_A1) {
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
  #betaW = -0.5
  # betaS0 = -0.1 
  #betaS0 = -0.55 #-0.55 for null case
  # betaS1 = -1 
  #betaS1 = -0.55 #-0.55 for null case
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
    prob1[i] = expit(beta1 + betaW*W[i] + betaS1*S1[i]) # let betaS0=betaS1 for null case
  }
  Y0 = rbinom(n,1,prob0)
  Y1 = rbinom(n,1,prob1)
  # observed Y
  Y = A*Y1 + (1-A)*Y0 
  # S missing when A=0, Y=1 
  S = ifelse(A==1, S1, ifelse(Y==0, S1, NA)) 
  # Case-cohort sampling design for measuring S, with S 
  # measured in all A=1 subjects with Y=1 observed and in a simple 
  # random sample of A=1 subjects 
  temp = table(A=A, Y=Y)
  numA1Y1 = temp[2,2]
  numA1Y0 = temp[2,1]
  numA0Y0 = temp[1,1]
  # other A=1,Y=0 set to missing, indicators of missing S
  S.ind = sample(1:nv, floor((1-crossover_rate_A1)*nv), replace = FALSE)
  S[A==1][S.ind] <- NA
  S[A==1 & Y==1] <- S1[A==1 & Y==1] 
  # S missingness when A=0,Y=0 by crossover rate 25% 50% 75%
  S.ind = sample(1:numA0Y0, floor((1-crossover_rate_A0Y0)*numA0Y0), replace = FALSE)
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

estimate <- function(dat, h=0.1, s1star) {
  A = dat$A
  W = dat$W
  S1 = dat$S1
  Y = dat$Y
  Pi = dat$Pi
  n = length(A)
  nv = sum(A)
  np = n-nv
  Kh = function(x) exp(-(x/h)^2/2)/sqrt(2*pi)/h
  

  ########### initial estimate ############
  SL.library <- c("SL.glm", "SL.glm.interaction",  "SL.nnet", "SL.mean") 
  smooth.S1 = Kh(S1-s1star)
  min.smooth.S1 = min(smooth.S1, na.rm=T)
  max.smooth.S1 = max(smooth.S1, na.rm=T)
  scaled.smooth.S1 = (smooth.S1-min.smooth.S1)/(max.smooth.S1-min.smooth.S1)
  P1hat = 0
  P2hat = 0
  P3hat = 0
  
  
  smooth.S1 = Kh(S1-s1star)
  min.smooth.S1 = min(smooth.S1, na.rm=T)
  max.smooth.S1 = max(smooth.S1, na.rm=T)
  
  scaled.smooth.S1 = (smooth.S1-min.smooth.S1)/(max.smooth.S1-min.smooth.S1)
  fit1 <- SuperLearner(Y = scaled.smooth.S1[A==1&(!is.na(scaled.smooth.S1))],
                       X = data.frame(W=W[A==1&(!is.na(scaled.smooth.S1))]),
                       obsWeights = Pi[A==1&(!is.na(scaled.smooth.S1))],
                       family = binomial(),
                       SL.library = SL.library, method = "method.NNLS",
                       newX=data.frame(W))
  P1hat <- fit1$SL.predict[,1]
  P1hat <- P1hat*(max.smooth.S1-min.smooth.S1)+min.smooth.S1


  fit1 <- SuperLearner(Y = scaled.smooth.S1[A==1 & Y==1 & (!is.na(scaled.smooth.S1))],
                       X = data.frame(W=W[A==1 & Y==1 & (!is.na(scaled.smooth.S1))]),
                       obsWeights = Pi[A==1 & Y==1 & (!is.na(scaled.smooth.S1))],
                       family = binomial(),
                       SL.library = SL.library, method = "method.NNLS",
                       newX=data.frame(W))
  fit2 <- SuperLearner(Y = Y[A==1],
                       X = data.frame(W=W[A==1]),
                       family = binomial(),
                       SL.library = SL.library, method = "method.NNLS",
                       newX=data.frame(W))
  P2hat = (fit1$SL.predict[,1]*(max.smooth.S1-min.smooth.S1)+min.smooth.S1) * fit2$SL.predict[,1]


  fit1 <- SuperLearner(Y = scaled.smooth.S1[A==0 & Y==0 & (!is.na(scaled.smooth.S1))],
                       X = data.frame(W=W[A==0 & Y==0 & (!is.na(scaled.smooth.S1))]),
                       obsWeights = Pi[A==0 & Y==0 & (!is.na(scaled.smooth.S1))],
                       family = binomial(),
                       SL.library = SL.library, method = "method.NNLS",
                       newX=data.frame(W)) # rescale smooth.S1 to range 0,1, switch gaussian to binomial
  fit2 <- SuperLearner(Y = Y[A==0],
                       X = data.frame(W=W[A==0]),
                       family = binomial(),
                       SL.library = SL.library, method = "method.NNLS",
                       newX=data.frame(W))
  P3hat = (fit1$SL.predict[,1]*(max.smooth.S1-min.smooth.S1)+min.smooth.S1) * (1-fit1$SL.predict[,1])

  #A=1|W
  fit = SuperLearner(Y = A, X = data.frame(W=W), family = binomial(), 
                     SL.library = SL.library, method = "method.NNLS")
  Ahat = as.vector(fit$SL.predict)
  #inds = which(P1hat<P3hat)
  #P1hat[inds] <- P3hat[inds] <- (P1hat[inds] + P3hat[inds])/2
  #################### fluctuation #####################
  
  # missing for A=0 & Y=1
  smooth.S1.nomissing = ifelse(is.na(smooth.S1), 100, smooth.S1) # change 100 to Inf, add flag to check weight>0 non S1 missing 
  ###  replace ~ 1 to ~ A==1
  
  fit1 = glm(smooth.S1.nomissing~ 1, weights = Pi*(A==1)/Ahat, offset = log(P1hat), family = poisson()) # Add in our weights
  P1star =  fit1$fitted.values 
  ###  replace ~ 1 to ~ A==1,
  fit2 = glm((Y==1)*smooth.S1.nomissing ~  1, weights = Pi*(A==1)/Ahat, offset = log(P2hat), family=poisson())
  P2star = fit2$fitted.values
  ###  replace ~ 1 to ~ A==0
  fit3 = glm( (Y==0)*smooth.S1.nomissing ~  1, weights = Pi*(A==0)/(1-Ahat), offset = log(P3hat), family=poisson())
  P3star = fit3$fitted.values
  
  #inds = which(P1star<P3star)
  #P1star[inds] <- P3star[inds] <- (P1star[inds] + P3star[inds])/2
  ################### estimation #######################
  psi1 = mean(P1star)
  psi2 = mean(P2star)
  psi3 = mean(P3star)
  psi = log(psi2/(psi1-psi3))
  init.psi = log(mean(P2hat)/(mean(P1hat)-mean(P3hat))) # not used, if engative return NA as a warning
  # log(mean(P2hat)/(mean(P1hat)-mean(P3hat)))
  
  ################### influence function/gradient ###############
  D1 = Pi*((A==1)/Ahat*(smooth.S1.nomissing - P1star)) + P1star - psi1 # times the weight o the entire thing not seperate
  D2 = Pi*((A==1)/Ahat*((Y==1)*smooth.S1.nomissing - P2star)) + P2star - psi2
  D3 = Pi*((A==0)/(1-Ahat)*((Y==0)*smooth.S1.nomissing - P3star)) + P3star - psi3
  g1 =-1/(psi1-psi3) # for target parameter log(RR)
  g2 = 1/psi2
  g3 = 1/(psi1-psi3)
  D = rowSums(cbind(g1 * D1 , g2 * D2 , g3 * D3), na.rm = T)
  # D = g1 * D1 + g2 * D2 + g3 * D3
  
  sd = sqrt(sum(D^2,na.rm=TRUE)/n/n)# mean over entire n, not just on zero
  sd1 = sqrt(sum(D1^2,na.rm=TRUE)/n/n)
  sd2 = sqrt(sum(D2^2,na.rm=TRUE)/n/n)
  sd3 = sqrt(sum(D3^2,na.rm=TRUE)/n/n)
  
  return(list(psi=psi,sd=sd,psi1=psi1,psi2=psi2,psi3=psi3,sd1=sd1,sd2=sd2,sd3=sd3,init.psi=init.psi,h=h))
}

# Approximated theortical truth of psi
truth = function(s1star, corr_S1_W) {
  logit = function(x) log(x/(1-x))
  expit = function(x) exp(x)/(1+exp(x))
  # Disease rate post marker measurement (from month 3 to month 24):
  #     P(Y=1|A=0) = 0.04*(1.75/2) for the placebo group (A=0) and
  #     P(Y=1|A=1) = 0.01*(1.75/2) for the vaccine group (A=1) (75% vaccine efficacy).
  var_W = 1
  var_S1 = 1
  vaccine_efficacy = 0.75 
  #b1 = -0.5
  #b2 = -1
  #b3 = -0.1
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
  #corr_S1_W = 0.5
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

# band with h for each s1, derived from cv
#hseq=c(0.5, 0.5, 0.6, 0.6, 0.6, 0.7, 0.7, 0.7, 0.8, 1.0, 1.0)
hseq <- rep(.8, 11)
# gennerate a set of data
dat = generate.data(nv=nv, np=np, 
                    corr_S1_W=corr_S1_W, 
                    crossover_rate_A0Y0=crossover_rate_A0Y0, 
                    crossover_rate_A1=crossover_rate_A1)
# generate the saved file name before removing the aurguments
name = paste("nullfirstpart", "corr_S1_W:",corr_S1_W,
             "crossover_rate_A0Y0:",crossover_rate_A0Y0,"crossover_rate_A1:",crossover_rate_A1,".RData", sep="")
# remove the following variables, will be given when runninng cluster
rm(corr_S1_W) 
rm(crossover_rate_A0Y0) 
rm(crossover_rate_A1) 
# save the whole image for cluster
save.image(file=name)
