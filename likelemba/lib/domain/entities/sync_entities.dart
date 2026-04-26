import 'package:likelemba/domain/entities/likelemba_group.dart';
import 'package:likelemba/domain/entities/transaction.dart';
import 'package:likelemba/domain/entities/user.dart';

class PushResult {
  final List<int> syncedIds;
  final List<int> failedIds;
  final List<Map<String, dynamic>> conflicts;
  PushResult({required this.syncedIds, required this.failedIds, required this.conflicts});
}

class SyncDelta {
  final List<Transaction> transactions;
  final List<User> memberUpdates;
  final List<LikelembaGroup> groupUpdates;
  SyncDelta({required this.transactions, required this.memberUpdates, required this.groupUpdates});
}