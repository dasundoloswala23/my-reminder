import 'package:equatable/equatable.dart';

/// User Entity (Domain Layer)
class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String name;
  final DateTime createdAt;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.name,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [uid, email, name, createdAt];
}
