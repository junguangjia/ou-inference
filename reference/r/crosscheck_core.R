# Independent base-R numerical oracle for deterministic exact-OU fixtures.
# No add-on packages, simulated RNG agreement, or human verification is implied.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Usage: Rscript --vanilla crosscheck_core.R observations.csv output_directory")
input <- read.csv(args[1])
out <- args[2]
if (dir.exists(out)) stop("Output directory must be new")
dir.create(out, recursive = TRUE)
options(digits = 17)
ks <- c(0, 1e-10, .1, 1, 7)

coefs <- function(k, dt) {
  if (k == 0) return(list(phi = rep(1, length(dt)), b = dt, v = dt))
  list(phi = exp(-k * dt), b = -expm1(-k * dt) / k,
       v = -expm1(-2 * k * dt) / (2 * k))
}
ll <- function(x, t, k, a, s2) {
  q <- coefs(k, diff(t))
  sum(dnorm(tail(x, -1), q$phi * head(x, -1) + a * q$b, sqrt(s2 * q$v), log = TRUE))
}
prof <- function(x, t, k) {
  q <- coefs(k, diff(t)); r <- tail(x, -1) - q$phi * head(x, -1)
  a <- sum(q$b * r / q$v) / sum(q$b^2 / q$v)
  s2 <- mean((r - a * q$b)^2 / q$v)
  list(a = a, sigma2 = s2, loglik = ll(x, t, k, a, s2))
}
bounded_fit <- function(x, t) {
  cap <- 200 / (tail(t, 1) - t[1])
  grid <- c(0, exp(seq(log(cap * 1e-9), log(cap), length.out = 64)))
  vals <- vapply(grid, function(k) prof(x, t, k)$loglik, 0.)
  best <- max(vals)
  for (j in 2:(length(grid) - 1)) {
    if (vals[j] >= vals[j-1] && vals[j] >= vals[j+1]) {
      fit <- optimize(function(k) prof(x, t, k)$loglik,
                      c(grid[j-1], grid[j+1]), maximum = TRUE, tol = 1e-10)
      best <- max(best, fit$objective)
    }
  }
  best
}
direct_nuisance <- function(x, t, k) {
  q <- coefs(k, diff(t)); r <- tail(x, -1) - q$phi * head(x, -1)
  objective <- function(par) -ll(x, t, k, par[1], exp(par[2]))
  gradient <- function(par) {
    residual <- r - par[1] * q$b; s2 <- exp(par[2])
    c(-sum(q$b * residual / (s2 * q$v)),
      .5 * (length(r) - sum(residual^2 / (s2 * q$v))))
  }
  fit <- optim(c(-.2, log(.8)), objective, gradient, method = "BFGS",
               control = list(reltol = 1e-13, maxit = 2000))
  if (fit$convergence != 0) stop("Direct nuisance optimization failed")
  list(a = fit$par[1], sigma2 = exp(fit$par[2]), loglik = -fit$value,
       convergence = fit$convergence)
}

transitions <- profiles <- information <- direct <- list()
for (design in unique(input$design)) {
  d <- input[input$design == design, ]; x <- d$x; t <- d$t; dt <- diff(t)
  best <- bounded_fit(x, t)
  for (k in ks) {
    q <- coefs(k, dt)
    transitions[[length(transitions)+1]] <- data.frame(
      design = design, kappa = k, index = seq_along(dt),
      phi = q$phi, b = q$b, v = q$v,
      mean = q$phi * head(x, -1) + .3 * q$b, variance = .49 * q$v)
    p <- prof(x, t, k)
    profiles[[length(profiles)+1]] <- data.frame(
      design = design, kappa = k, a = p$a, sigma2 = p$sigma2, loglik = p$loglik,
      given_loglik = ll(x, t, k, .3, .49), lr = 2 * (best - p$loglik))
    nu <- direct_nuisance(x, t, k)
    direct[[length(direct)+1]] <- data.frame(design = design, kappa = k,
      a = nu$a, sigma2 = nu$sigma2, loglik = nu$loglik, convergence = nu$convergence)
    # Continuous KL is integrated from expected quadratic drift energy,
    # providing a different numerical route from the closed-form expression.
    T <- tail(t, 1) - t[1]
    continuous <- if (k == 0) 0 else integrate(function(s)
      k * (-expm1(-2*k*s)) / 4, 0, T, rel.tol = 1e-12, abs.tol = 1e-30)$value
    previous_variance <- if (k == 0) t[-length(t)] - t[1] else
      -expm1(-2*k*(t[-length(t)]-t[1])) / (2*k)
    u <- q$v / dt - 1
    var_part <- ifelse(abs(u) < 1e-5, u^2/2-u^3/3+u^4/4, u-log1p(u))
    discrete <- .5 * sum(var_part + expm1(-k*dt)^2 * previous_variance / dt)
    information[[length(information)+1]] <- data.frame(
      design = design, kappa = k, continuous = continuous, discrete = discrete,
      power = min(1, .05 + sqrt(continuous/2)))
  }
}
write.csv(do.call(rbind, transitions), file.path(out, "r_transition.csv"), row.names = FALSE)
write.csv(do.call(rbind, profiles), file.path(out, "r_profile.csv"), row.names = FALSE)
write.csv(do.call(rbind, information), file.path(out, "r_information.csv"), row.names = FALSE)
write.csv(do.call(rbind, direct), file.path(out, "r_direct_nuisance.csv"), row.names = FALSE)
writeLines(c(R.version.string, "Packages: base R only"), file.path(out, "r_version.txt"))
cat("R oracle completed: 200 transition rows, 10 profiles, 10 KL rows, 10 direct nuisance optimizations.\n")
