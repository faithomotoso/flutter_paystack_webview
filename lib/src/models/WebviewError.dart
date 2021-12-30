class WebViewError {
  static const String NAME_NOT_RESOLVED = "ERR_NAME_NOT_RESOLVED";
  static const String ADDRESS_UNREACHABLE = "ERR_ADDRESS_UNREACHABLE";
  static const String CONNECTION_ABORTED = "ERR_CONNECTION_ABORTED";

  // Check if the error from web view matches any of the listed ones
  // When true, trigger an error widget to display to the user to reload.
  static bool hasWebviewError(String errorDescription) {
    return errorDescription.contains(NAME_NOT_RESOLVED) ||
        errorDescription.contains(ADDRESS_UNREACHABLE) ||
        errorDescription.contains(CONNECTION_ABORTED);
  }
}
