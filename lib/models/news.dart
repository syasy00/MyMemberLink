class News {
  String? newsId;
  String? newsTitle;
  String? newsDetails;
  String? newsDate;
  int likes = 0; // Default to 0
  bool likedByUser = false; // Tracks if the user liked the news

  News({
    this.newsId,
    this.newsTitle,
    this.newsDetails,
    this.newsDate,
    this.likes = 0,
    this.likedByUser = false,
  });

  News.fromJson(Map<String, dynamic> json) {
  newsId = json['news_id']?.toString(); // Ensure it's a string
  newsTitle = json['news_title'];
  newsDetails = json['news_details'];
  newsDate = json['news_date'];
  likes = int.tryParse(json['likes'].toString()) ?? 0; // Convert to int safely
  likedByUser = json['liked_by_user'] ?? false; // Default to false
}


  Map<String, dynamic> toJson() {
    return {
      'news_id': newsId,
      'news_title': newsTitle,
      'news_details': newsDetails,
      'news_date': newsDate,
      'likes': likes,
      'liked_by_user': likedByUser,
    };
  }
}
