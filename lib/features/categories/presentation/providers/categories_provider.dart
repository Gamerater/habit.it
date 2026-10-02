import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../habits/presentation/providers/habits_provider.dart';
import '../../domain/category.dart';

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(habitRepositoryProvider).watchCategories();
});