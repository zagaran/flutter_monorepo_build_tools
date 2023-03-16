# Flutter Monorepo Build Tools
 
1. `flutter pub get flutter_monorepo_build_tools`
2. `nano monorepo.yaml`
   1. see `monorepo.sample.yaml` for an example of how to configure

## Monorepo Build Tool

### Usage

`dart run flutter_monorepo_build_tools:monorepo_build_tool`

Re-run the tool whenever you add, rename, or remove a local package or if local package dependencies change.


### OOTB CI Support

At release, FMBT only contains out-of-the-box support for CircleCI using the `path-filtering` approach.

To configure your monorepo:

1. Create a source folder to contain your raw CircleCI config. This should include one `config.yml` file and as many `continue-config.yml` type files as you wish.
2. `config.yml` should look something like this: 
```yaml
version: 2.1

# this allows you to use CircleCI's dynamic configuration feature
setup: true

# the path-filtering orb is required to continue a pipeline based on
# the path of an updated fileset
orbs:
  path-filtering: circleci/path-filtering@0.1.1

workflows:
  # the always-run workflow is always triggered, regardless of the pipeline parameters.
  always-run:
    jobs:
      # the path-filtering/filter job determines which pipeline
      # parameters to update.
      - path-filtering/filter:
          name: check-updated-files
          # the mapping key will be automatically generated by flutter_monorepo_build_tools
          base-revision: master
          # this is the path of the configuration we should trigger once
          # path filtering and pipeline parameter value updates are
          # complete.
          config-path: .circleci/continue-config.yml
```
3. Create however many `continue-config.yml` type files you need for your use case. It is important
when naming workflows that they contain the name of your entrypoint directory. For example, if your workflow 
is related to an app `app`, it should be named something like `app_deploy`. For a full list of matching
globs, see `entrypointPermutations` in `circle_ci_update_manager.dart`.

### Known Limitations

#### Limited use of single quotation marks in values

Some string values are wrapped with single quotation marks in the output even when they are not 
in the source. We believe this is due to `json2yaml`, which this package uses. It is unclear
at this point whether it is possible to overcome this. We recommend that you run this tool on
your existing configuration and validate the output before committing to this tool.

If you have a line like this:

```yaml
- run: echo 'export PATH="$PATH:`pwd`/flutter/bin"' \>> $BASH_ENV
```

then you may have to refactor it into two lines, like so:

```yaml
- run: export PATH="$PATH:`pwd`/flutter/bin"
- run: echo "$PATH" \>> $BASH_ENV
```