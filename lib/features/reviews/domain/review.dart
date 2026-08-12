class Review {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;
  final int likesCount;
  final int dislikesCount;
  final int? userVote; // 1 for like, -1 for dislike, null for none

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    this.likesCount = 0,
    this.dislikesCount = 0,
    this.userVote,
  });

  // Helper to update the UI state locally without a full reload
  Review copyWith(
      {int? likesCount, int? dislikesCount, int? userVote, bool clearVote = false}) {
    return Review(
      id: id,
      userId: userId,
      userName: userName,
      content: content,
      createdAt: createdAt,
      likesCount: likesCount ?? this.likesCount,
      dislikesCount: dislikesCount ?? this.dislikesCount,
      userVote: clearVote ? null : (userVote ?? this.userVote),
    );
  }
}