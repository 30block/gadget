// docker-bake.hcl
// https://github.com/docker/metadata-action#bake-definition
target "docker-metadata-action" {}

target "build" {
  inherits = ["docker-metadata-action"]
  context = "./"
  dockerfile = "Dockerfile"
  platforms = [
    "linux/arm/v6",
    "linux/arm/v7",
    "linux/arm64",
  ]
}
