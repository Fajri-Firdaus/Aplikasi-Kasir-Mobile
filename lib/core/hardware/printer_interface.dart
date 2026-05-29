abstract class POSPrinterInterface {
  /// Connects to the printer (e.g., via Bluetooth Mac Address or USB path)
  Future<bool> connect(String address);

  /// Disconnects from the current printer
  Future<void> disconnect();

  /// Checks if a printer is currently connected
  Future<bool> get isConnected;

  /// Prints a receipt based on receipt data
  /// This is a generic interface. The implementation will handle ESC/POS commands
  Future<bool> printReceipt(Map<String, dynamic> receiptData);
}
