import 'profile.dart';
import 'social.dart';

class TrainerStudent {
  final String id;
  final String trainerId;
  final String studentId;
  final String status;
  final DateTime createdAt;
  final FriendUser? student;

  const TrainerStudent({
    required this.id,
    required this.trainerId,
    required this.studentId,
    this.status = 'accepted',
    required this.createdAt,
    this.student,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  factory TrainerStudent.fromJson(Map<String, dynamic> json) {
    return TrainerStudent(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      studentId: json['student_id'] as String,
      status: json['status'] as String? ?? 'accepted',
      createdAt: DateTime.parse(json['created_at'] as String),
      student: json['student'] != null
          ? FriendUser.fromJson(Map<String, dynamic>.from(json['student'] as Map))
          : null,
    );
  }

  TrainerStudent copyWith({FriendUser? student}) {
    return TrainerStudent(
      id: id,
      trainerId: trainerId,
      studentId: studentId,
      status: status,
      createdAt: createdAt,
      student: student ?? this.student,
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
