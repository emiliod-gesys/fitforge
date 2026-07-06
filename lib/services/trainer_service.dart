import '../models/profile.dart';
import '../models/social.dart';
import '../models/trainer.dart';
import 'social_service.dart';
import 'supabase_service.dart';

class TrainerService {
  final _client = SupabaseService.client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<TrainerStudent>> getStudents() async {
    final uid = _userId;
    if (uid == null) return [];

    final data = await _client
        .from('trainer_students')
        .select()
        .eq('trainer_id', uid)
        .order('created_at', ascending: false);

    final rows = (data as List)
        .map((r) => TrainerStudent.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();

    if (rows.isEmpty) return rows;

    final studentIds = rows.map((r) => r.studentId).toList();
    final profilesData = await _client
        .from('profiles')
        .select('id, display_name, avatar_url, email, total_xp')
        .inFilter('id', studentIds);

    final profiles = {
      for (final p in profilesData as List)
        (p as Map)['id'] as String: FriendUser.fromJson(Map<String, dynamic>.from(p)),
    };

    return rows
        .map(
          (r) => TrainerStudent(
            id: r.id,
            trainerId: r.trainerId,
            studentId: r.studentId,
            createdAt: r.createdAt,
            student: profiles[r.studentId],
          ),
        )
        .toList();
  }

  /// Amigos aceptados que aún no son alumnos (y no son entrenadores).
  Future<List<FriendUser>> getAddableFriends(SocialService socialService) async {
    final uid = _userId;
    if (uid == null) return [];

    final friendships = await socialService.getFriendships();
    final students = await getStudents();
    final studentIds = students.map((s) => s.studentId).toSet();

    final friends = friendships
        .where((f) => f.status == FriendshipStatus.accepted)
        .map((f) => f.friendFor(uid))
        .where((f) => !studentIds.contains(f.id))
        .toList();

    if (friends.isEmpty) return friends;

    final profileData = await _client
        .from('profiles')
        .select('id, user_type')
        .inFilter('id', friends.map((f) => f.id).toList());

    final trainerIds = {
      for (final p in profileData as List)
        if ((p as Map)['user_type'] == 'trainer') p['id'] as String,
    };

    return friends.where((f) => !trainerIds.contains(f.id)).toList();
  }

  Future<void> addStudent(String studentId) async {
    await _client.rpc('add_trainer_student', params: {'p_student_id': studentId});
  }

  Future<void> removeStudent(String studentId) async {
    await _client.rpc('remove_trainer_student', params: {'p_student_id': studentId});
  }

  Future<StudentProfileView?> getStudentProfile(String studentId) async {
    final uid = _userId;
    if (uid == null) return null;

    final link = await _client
        .from('trainer_students')
        .select('id')
        .eq('trainer_id', uid)
        .eq('student_id', studentId)
        .maybeSingle();

    if (link == null) return null;

    final profileData = await _client.from('profiles').select().eq('id', studentId).maybeSingle();
    if (profileData == null) return null;

    final profile = UserProfile.fromJson(Map<String, dynamic>.from(profileData));
    final user = FriendUser.fromJson({
      'id': studentId,
      'display_name': profileData['display_name'],
      'avatar_url': profileData['avatar_url'],
      'email': profileData['email'],
      'total_xp': profileData['total_xp'],
    });

    return StudentProfileView(user: user, profile: profile);
  }

  Future<MyTrainerView?> getMyTrainer() async {
    final uid = _userId;
    if (uid == null) return null;

    final link = await _client
        .from('trainer_students')
        .select('trainer_id, created_at')
        .eq('student_id', uid)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (link == null) return null;

    final trainerId = link['trainer_id'] as String;
    final profileData = await _client
        .from('profiles')
        .select('id, display_name, avatar_url, email, total_xp')
        .eq('id', trainerId)
        .maybeSingle();

    if (profileData == null) return null;

    return MyTrainerView(
      trainer: FriendUser.fromJson(Map<String, dynamic>.from(profileData)),
      linkedAt: DateTime.parse(link['created_at'] as String),
    );
  }
}
