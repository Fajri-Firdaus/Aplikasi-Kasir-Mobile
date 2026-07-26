import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer.dart';
import '../data/customer_repository.dart';

class CustomerNotifier extends AsyncNotifier<List<Customer>> {
  late final CustomerRepository _repository;

  @override
  FutureOr<List<Customer>> build() async {
    _repository = ref.watch(customerRepositoryProvider);
    try {
      return await _repository.getAll();
    } catch (_) {
      return const [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getAll());
  }

  Future<Customer> addCustomer(String name, String phone) async {
    final customer = await _repository.create(name, phone);
    await refresh();
    return customer;
  }
}

final customerProvider = AsyncNotifierProvider<CustomerNotifier, List<Customer>>(CustomerNotifier.new);
