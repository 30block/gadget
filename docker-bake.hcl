target "default" {
  context = "./"
  dockerfile = "Dockerfile"
  platforms = [
    "linux/arm64",
    "linux/arm/v6",
    "linux/arm/v7",
  ]
}
