# Independent base-R reference, not a claim of an independent human review.
# dX=(a-kappa X)dt+sigma dW. No add-on R packages or global installation.
args <- commandArgs(trailingOnly=TRUE)
if(length(args)!=3L) stop('Usage: Rscript --vanilla check_profile.R data.csv kappa.csv output.csv')
d <- read.csv(args[1]); ks <- read.csv(args[2])$kappa
dt <- diff(d$t); prev <- head(d$x,-1); nxt <- tail(d$x,-1)
if(any(dt<=0) || length(dt)<3) stop('Invalid times/data')
calc <- function(k) {
  if(k==0) { ph <- rep(1,length(dt)); b<-dt; v<-dt }
  else { ph<-exp(-k*dt); b<-(-expm1(-k*dt))/k; v<-(-expm1(-2*k*dt))/(2*k) }
  z<-nxt-ph*prev
  ah<-sum(b*z/v)/sum(b*b/v)
  s2<-mean((z-ah*b)^2/v)
  ll<-if(s2==0) Inf else sum(dnorm(nxt, mean=ph*prev+ah*b, sd=sqrt(s2*v), log=TRUE))
  data.frame(kappa=k,a=ah,sigma2=s2,loglik=ll)
}
write.csv(do.call(rbind,lapply(ks,calc)),args[3],row.names=FALSE)
cat(R.version.string,'\n'); print(sessionInfo())
