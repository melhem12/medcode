part of 'user_bloc.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

class GetProfileEvent extends UserEvent {
  const GetProfileEvent();
}

class UpdateProfileEvent extends UserEvent {
  final Map<String, dynamic> payload;

  const UpdateProfileEvent(this.payload);

  @override
  List<Object> get props => [payload];
}

class UploadAvatarEvent extends UserEvent {
  final String filePath;

  const UploadAvatarEvent(this.filePath);

  @override
  List<Object> get props => [filePath];
}


















