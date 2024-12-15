default:
  @just --list

build:
    bluebuild generate ./recipes/recipe.yml -o Containerfile
    bluebuild build ./recipes/recipe.yml
