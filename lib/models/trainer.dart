import 'profile.dart';
import 'social.dart';

class TrainerStudent {
  final String id;
  final String trainerId;
  final String studentId;
  final DateTime createdAt;
  final FriendUser? student;

  const TrainerStudent({
    required this.id,
    required this.trainerId,
    required this.studentId,
    required this.createdAt,
    this.student,
  });

  factory TrainerStudent.fromJson(Map<String, dynamic> json) {
    return TrainerStudent(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      studentId: json['student_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      student: json['student'] != null
          ? FriendUser.fromJson(Map<String, dynamic>.from(json['student'] as Map))
          : null,
    );
  }
}

class StudentProfileView {
  final FriendUser user;
  final UserProfile profile;

  const StudentProfileView({
    required this.user,
    required this.profile,
  });
}

class MyTrainerView {
  final FriendUser trainer;
  final DateTime linkedAt;

  const MyTrainerView({
    required this.trainer,
    required this.linkedAt,
  });
}
