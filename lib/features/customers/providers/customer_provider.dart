import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer.dart';
import '../data/customer_repository.dart';
import '../../auth/providers/auth_provider.dart';

class CustomerNotifier extends AsyncNotifier<List<Customer>> {
  late final CustomerRepository _repository;

  @override
  FutureOr<List<Customer>> build() async {
    _repository = ref.watch(customerRepositoryProvider);
    final storeId = ref.watch(activeStoreIdProvider);
    try {
      return await _repository.getAll(storeId: storeId);
    } catch (_) {
      return const [];
    }
  }

  Future<void> refresh() async {
    final storeId = ref.read(activeStoreIdProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getAll(storeId: storeId));
  }

  Future<Customer> addCustomer(String name, String phone, {String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty)
        ? storeId
        : ref.read(activeStoreIdProvider);
    final customer = await _repository.create(name, phone, storeId: activeStoreId);
    await refresh();
    return customer;
  }
}

final customerProvider = AsyncNotifierProvider<CustomerNotifier, List<Customer>>(CustomerNotifier.new);
