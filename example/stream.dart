import 'package:flutter_riverpod/flutter_riverpod.dart';

final streamMockProvider = StreamProvider<bool>((ref) async* {
  await Future.delayed(const Duration(seconds: 5), () {});
  yield false;
});
