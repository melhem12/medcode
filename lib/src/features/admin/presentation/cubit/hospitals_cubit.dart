import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../auth/data/datasources/hospitals_remote_data_source.dart';
import '../../../auth/domain/entities/hospital.dart';

part 'hospitals_state.dart';

class HospitalsCubit extends Cubit<HospitalsState> {
  final HospitalsRemoteDataSource dataSource;

  HospitalsCubit({required this.dataSource}) : super(HospitalsInitial());

  Future<void> loadHospitals() async {
    emit(HospitalsLoading());
    try {
      final hospitals = await dataSource.getHospitals();
      emit(HospitalsLoaded(hospitals));
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      emit(HospitalsError(errorMessage));
    }
  }
}

