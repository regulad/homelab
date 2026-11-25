locals {
  # The organization every resource here belongs to.
  organization = "regulad"

  # Where each build of Koala's programs checks the repository out, as Windows
  # writes the path, which the code mappings of koala and koala-vcam map from.
  # Sentry matches a stack root as a literal prefix of a frame's path,
  # backslashes and case included, and writes each \ as / only after replacing
  # it.
  koala_checkouts = {
    # Release builds, by .github/workflows/build.yml on GitHub's Windows runner.
    release = "D:\\a\\Koala\\Koala\\"
    # Development builds.
    development = "D:\\repositories\\Koala\\"
  }

  # Where each build of Warlock's programs checks the repository out, as Windows
  # writes the path, which the code mappings of warlock, warlock-extcap,
  # warlock-installer and warlockctl map from. Sentry matches a stack root as a
  # literal prefix of a frame's path, backslashes and case included, and writes
  # each \ as / only after replacing it.
  warlock_checkouts = {
    # Release builds, by .github/workflows/build.yml on GitHub's Windows runner.
    release = "D:\\a\\Warlock\\Warlock\\"
    # Development builds.
    development = "D:\\repositories\\Warlock\\"
  }

  # Where each build of tinyxnb's thumbnail handler and xnb2png checks the
  # repository out, as Windows writes the path, which tinyxnb's code mappings
  # map from, as Koala's and Warlock's do.
  tinyxnb_checkouts = {
    # Release builds, by .github/workflows/release.yml on GitHub's Windows runner.
    release = "D:\\a\\tinyxnb\\tinyxnb\\"
    # Development builds.
    development = "D:\\repositories\\tinyxnb\\"
  }
}
