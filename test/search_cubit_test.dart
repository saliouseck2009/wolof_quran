import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/presentation/cubits/search_cubit.dart';

void main() {
  group('SearchCubit', () {
    late SearchCubit searchCubit;

    setUp(() {
      searchCubit = SearchCubit();
    });

    tearDown(() {
      searchCubit.close();
    });

    test('initial state is SearchInitial', () {
      expect(searchCubit.state, isA<SearchInitial>());
    });

    test('clearSearch emits SearchInitial', () {
      searchCubit.clearSearch();
      expect(searchCubit.state, isA<SearchInitial>());
    });

    test('searchWords with empty query emits SearchInitial', () {
      searchCubit.searchWords('');
      expect(searchCubit.state, isA<SearchInitial>());
    });

    test('searchWords with whitespace-only query emits SearchInitial', () {
      searchCubit.searchWords('   ');
      expect(searchCubit.state, isA<SearchInitial>());
    });
  });
}
