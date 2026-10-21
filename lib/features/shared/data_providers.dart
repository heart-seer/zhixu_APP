import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_repository.dart';

final localRepositoryProvider = ChangeNotifierProvider<AppRepository>(
  (ref) => LocalRepository.seeded(),
);
