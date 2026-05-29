abstract class POSScannerInterface {
  /// Initializes the barcode scanner
  Future<void> initialize();

  /// Starts listening for barcode scans.
  /// Returns a stream of scanned barcode strings.
  Stream<String> get onBarcodeScanned;

  /// Disposes the scanner resources
  void dispose();
}
