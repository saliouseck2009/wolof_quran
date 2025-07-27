import '../repositories/reciter_repository.dart';
import '../entities/reciter.dart';
import '../../core/usecases/usecase.dart';

/// Use case for getting all available reciters
class GetRecitersUseCase implements UseCase<List<Reciter>, NoParams> {
  final ReciterRepository repository;

  GetRecitersUseCase(this.repository);

  @override
  Future<List<Reciter>> call({required NoParams params}) async {
    return await repository.getReciters();
  }
}
