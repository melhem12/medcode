import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../auth/data/datasources/specialities_remote_data_source.dart';
import '../../../auth/domain/entities/speciality.dart';

part 'specialities_state.dart';

class SpecialitiesCubit extends Cubit<SpecialitiesState> {
  final SpecialitiesRemoteDataSource dataSource;

  SpecialitiesCubit({required this.dataSource}) : super(SpecialitiesInitial());

  Future<void> loadSpecialities() async {
    emit(SpecialitiesLoading());
    try {
      final specialities = await dataSource.getSpecialities();
      emit(SpecialitiesLoaded(specialities));
    } catch (e) {
      emit(SpecialitiesError(e.toString()));
    }
  }
}







