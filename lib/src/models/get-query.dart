class GetOptsType {
  DateTime? ims;
  int? limit;
  String? topic;
  String? user;

  GetOptsType({
    this.ims,
    this.limit,
    this.topic,
    this.user,
  });

  static GetOptsType fromMessage(Map<String, dynamic> msg) {
    return GetOptsType(
      ims: msg['ims'] as DateTime?,
      limit: msg['limit'] as int?,
      topic: msg['topic'] as String?,
      user: msg['user'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    var map = {
      'ims': ims != null ? ims?.toIso8601String() : null,
      'limit': limit,
      'topic': topic,
      'user': user,
    };
    map.removeWhere((key, value) => value == null);
    return map;
  }
}

class GetDataType {
  int? since;
  int? before;
  int? limit;

  GetDataType({this.since, this.limit, this.before});

  static GetDataType fromMessage(Map<String, dynamic> msg) {
    return GetDataType(
      since: msg['since'] as int?,
      before: msg['before'] as int?,
      limit: msg['limit'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    var map = {
      'since': since,
      'before': before,
      'limit': limit,
    };
    map.removeWhere((key, value) => value == null);
    return map;
  }
}

class GetQuery {
  String? topic;
  bool? cred;
  bool? tags;
  String? what;
  GetOptsType? desc;
  GetOptsType? sub;
  GetDataType? data;
  GetDataType? del;

  GetQuery({
    this.topic,
    this.desc,
    this.sub,
    this.data,
    this.what,
    this.tags,
    this.cred,
    this.del,
  });

  static GetQuery fromMessage(Map<String, dynamic> msg) {
    return GetQuery(
      topic: msg['topic'] as String?,
      cred: msg['cred'] as bool?,
      what: msg['what'] as String?,
      data: msg['data'] != null ? GetDataType.fromMessage(msg['data'] as Map<String, dynamic>) : null,
      del: msg['del'] != null ? GetDataType.fromMessage(msg['del'] as Map<String, dynamic>) : null,
      desc: msg['desc'] != null ? GetOptsType.fromMessage(msg['desc'] as Map<String, dynamic>) : null,
      sub: msg['sub'] != null ? GetOptsType.fromMessage(msg['sub'] as Map<String, dynamic>) : null,
      tags: msg['tags'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    var map = {
      'topic':topic,
      'cred': cred,
      'what': what,
      'data': data != null ? data?.toMap() : null,
      'del': del != null ? del?.toMap() : null,
      'desc': desc != null ? desc?.toMap() : null,
      'sub': sub != null ? sub?.toMap() : null,
      'tags': tags,
    };
    map.removeWhere((key, value) => value == null);
    return map;
  }
}
