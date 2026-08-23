default:
  @just --list

generate:
  bluebuild generate ./recipes/recipe.yml -o Containerfile

build: generate
  bluebuild build ./recipes/recipe.yml

ignition:
  docker run --rm -i quay.io/coreos/butane:release \
    --strict --pretty < ignition/fedora-workstation.bu \
    > ignition/fedora-workstation.ign
