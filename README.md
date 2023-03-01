# Monorepo Build Tool

## Usage

1. `flutter pub get monorepo_build_tool`
2. `nano monorepo.yaml`
   1. see `monorepo.sample.yaml` for an example of how to configure
3. `flutter run monorepo_build_tool`


## Config
The Monorepo Build Tool is designed to be as configurable as is reasonably possible. Configuration options
are broadly divisible into two categories: Local Options, which define the behavior of the tool locally
e.g. sourcing files, helping to describe the structure of your file system, etc; and CI options,
which define values specific to whichever CI you are using.
