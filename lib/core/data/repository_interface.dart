/// Base class for all data repositories.
/// Using this pattern allows us to easily swap between a local dummy database
/// and a real remote API (like Supabase) in the future without changing the UI code.
abstract class RepositoryInterface<T> {
  /// Fetch a list of items
  Future<List<T>> getAll();

  /// Fetch a single item by its ID
  Future<T?> getById(String id);

  /// Create a new item
  Future<T> create(T item);

  /// Update an existing item
  Future<T> update(String id, T item);

  /// Delete an item by its ID
  Future<void> delete(String id);
}
