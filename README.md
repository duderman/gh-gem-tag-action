# Gem auto-tag docker action

This action tags a commit with a version from your .gemspec file

## Inputs

### `github_token`

**Required** GitHub token with permissions to create tags and read commits

### `tag_prefix`

Tag prefix. F.e. if `tag_prefix` set to `v` and current version is `0.1` then the action will create a tag `v0.1`

## Outputs

### `tag`

Created tag name

### `url`

GitHub URL of the created tag

## Example usage

```yml
uses: BarnabeD/gh-gem-tag-action@v1
with:
  github_token: ${{ secrets.GITHUB_TOKEN }}
  tag_prefix: v
```
