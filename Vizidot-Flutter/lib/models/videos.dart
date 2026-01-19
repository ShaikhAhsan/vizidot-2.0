class Video {
  late String name;
  late String url;
  late String thumb;

  Video({required this.name, required this.url, required this.thumb});

  Map<String, dynamic> toMap() {
    return {'name': name, 'url': url, 'thumb': thumb};
  }

  Video.fromMap(Map<String, dynamic> videoMap)
      : name = videoMap["name"],
        url = videoMap["url"],
        thumb = videoMap["thumb"];
}

