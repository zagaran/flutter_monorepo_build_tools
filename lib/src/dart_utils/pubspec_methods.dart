String generatePubspecPath(String package) =>
    !package.contains('pubspec.yaml') ? '$package/pubspec.yaml' : package;
