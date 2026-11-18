# Adoption of the regulad team's projects, their custom domains and their
# environment variables, made by hand before this root. Removed after the
# apply that imports them. Each ID is <team>/<project>[/<domain or variable>].
locals {
  import_team = "team_JrB4YMLbrdINYpJ5RdhGyK3d"
  import_projects = {
    aporia_blue           = "prj_ZqgtkktAo9Avfk6EopDxaMcbWGap"
    battleship_visualizer = "prj_bE5VGFXvXffsTjjLNHvIkliubbQ5"
    github_readme_stats   = "prj_5sKcXWkG40XLfF9iLvPjuow7ekNE"
    ml4webedit            = "prj_DxJyFZbDQrpq5tQhVrYaqvZoDKxB"
    parkerwahle           = "prj_qR2XIoj5Eo1JPPGitKmiucbOVP0s"
    picture_triangulator  = "prj_0Hq8T2YV8sPjslnl62wc2GNlE09c"
    uulanding             = "prj_77aVjQbEHqYtJotcAi98NCghoaqa"
  }
}

import {
  to = vercel_project.aporia_blue
  id = "${local.import_team}/${local.import_projects.aporia_blue}"
}

import {
  to = vercel_project.battleship_visualizer
  id = "${local.import_team}/${local.import_projects.battleship_visualizer}"
}

import {
  to = vercel_project.github_readme_stats
  id = "${local.import_team}/${local.import_projects.github_readme_stats}"
}

import {
  to = vercel_project.ml4webedit
  id = "${local.import_team}/${local.import_projects.ml4webedit}"
}

import {
  to = vercel_project.parkerwahle
  id = "${local.import_team}/${local.import_projects.parkerwahle}"
}

import {
  to = vercel_project.picture_triangulator
  id = "${local.import_team}/${local.import_projects.picture_triangulator}"
}

import {
  to = vercel_project.uulanding
  id = "${local.import_team}/${local.import_projects.uulanding}"
}

import {
  to = vercel_project_domain.parkerwahle_regulad_xyz
  id = "${local.import_team}/${local.import_projects.parkerwahle}/regulad.xyz"
}

import {
  to = vercel_project_domain.parkerwahle_www_regulad_xyz
  id = "${local.import_team}/${local.import_projects.parkerwahle}/www.regulad.xyz"
}

import {
  to = vercel_project_domain.aporia_blue_aporia_blue
  id = "${local.import_team}/${local.import_projects.aporia_blue}/aporia.blue"
}

import {
  to = vercel_project_environment_variable.github_readme_stats_pat_1
  id = "${local.import_team}/${local.import_projects.github_readme_stats}/diWmjNRPVQw6nTOX"
}
