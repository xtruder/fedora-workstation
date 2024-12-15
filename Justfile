default:
  @just --list

generate:
  bluebuild generate ./recipes/recipe.yml -o Containerfile

build: generate
  bluebuild build ./recipes/recipe.yml
