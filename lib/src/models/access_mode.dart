/// This numeric value represents `N` or `n` access mode flag.
const int modeNone = 0x00;

/// This numeric value represents `J` access mode flag.
const int modeJoin = 0x01;

/// This numeric value represents `R` access mode flag.
const int modeRead = 0x02;

/// This numeric value represents `W` access mode flag.
const int modeWrite = 0x04;

/// This numeric value represents `P` access mode flag.
const int modePres = 0x08;

/// This numeric value represents `A` access mode flag.
const int modeApprove = 0x10;

/// This numeric value represents `S` access mode flag.
const int modeShare = 0x20;

/// This numeric value represents `D` access mode flag.
const int modeDelete = 0x40;

/// This numeric value represents `O` access mode flag.
const int modeOwner = 0x80;

/// This numeric value represents `invalid` access mode flag.
const int modeInvalid = 0x100000;

/// Bitmask for validating access modes
const int accessModePermissionsBitmask = modeJoin | modeRead | modeWrite | modePres | modeApprove | modeShare | modeDelete | modeOwner;

/// Access control is mostly usable for group topics. Its usability for me and P2P topics is
/// limited to managing presence notifications and banning uses from initiating or continuing P2P conversations.
class AccessMode {
  /// Permissions granted to user by topic's manager
  late int _given;

  /// User's desired permissions
  late int _want;

  /// Combination of want and given
  late int mode;

  int operator [](String other) {
    switch (other) {
      case 'mode':
        return mode;
      case 'want':
        return _want;
      case 'given':
        return _given;
      default:
        return 0;
    }
  }

  /// Create new instance by passing an `AccessMode` or `Map<String, dynamic>`
  AccessMode(dynamic acs) {
    if (acs != null) {
      _given = acs['given'] is int ? acs['given'] as int : (AccessMode.decode(acs['given']) ?? 0);
      _want = acs['want'] is int ? acs['want'] as int : (AccessMode.decode(acs['want']) ?? 0);

      if (acs['mode'] != null) {
        if (acs['mode'] is int) {
          mode = acs['mode'] as int;
        } else {
          mode = AccessMode.decode(acs['mode']) ?? 0;
        }
      } else {
        mode = _given & _want;
      }
    }
  }

  /// Decodes string access mode to integer
  static int? decode(dynamic mode) {
    if (mode == null) {
      return null;
    } else if (mode is int) {
      return mode & accessModePermissionsBitmask;
    } else if (mode == 'N' || mode == 'n') {
      return modeNone;
    }

    final bitmask = <String, int>{
      'J': modeJoin,
      'R': modeRead,
      'W': modeWrite,
      'P': modePres,
      'A': modeApprove,
      'S': modeShare,
      'D': modeDelete,
      'O': modeOwner,
    };

    var m0 = modeNone;

    if (mode != null) {
      final int length = mode.length as int;
      for (var i = 0; i < length; i++) {
        final String key = (mode[i] as String).toUpperCase();
        final int? bit = bitmask[key];
        if (bit == null) {
          // Unrecognized bit, skip.
          continue;
        }
        m0 |= bit;
      }
    }
    return m0;
  }

  /// Decodes integer access mode to string
  static String? encode(int val) {
    if (val == modeInvalid) {
      return null;
    } else if (val == modeNone) {
      return 'N';
    }

    final bitmask = ['J', 'R', 'W', 'P', 'A', 'S', 'D', 'O'];
    var res = '';

    for (var i = 0; i < bitmask.length; i++) {
      if ((val & (1 << i)) != 0) {
        res = res + bitmask[i];
      }
    }
    return res;
  }

  /// Updates mode with newly given permissions
  static int update(int val, String upd) {
    final action = upd[0];

    if (action == '+' || action == '-') {
      var val0 = val;

      // Split delta-string like '+ABC-DEF+Z' into an array of parts including + and -.
      var parts = upd.split(RegExp(r'([-+])'));
      var actions = upd.split(RegExp(r'\w+'));

      actions = actions.where((value) {
        return value != '';
      }).toList();

      parts = parts.where((value) {
        return value != '';
      }).toList();

      for (var i = 0; i < parts.length; i++) {
        final action = actions[i];
        final m0 = AccessMode.decode(parts[i]);
        if (m0 == modeInvalid) {
          return val;
        }
        if (m0 == null) {
          continue;
        }
        if (action == '+') {
          val0 |= m0;
        } else if (action == '-') {
          val0 &= ~m0;
        }
      }
      val = val0;
    } else {
      // The string is an explicit new value 'ABC' rather than delta.
      final val0 = AccessMode.decode(upd);
      if (val0 != modeInvalid) {
        val = val0 ?? 0;
      }
    }

    return val;
  }

  /// Get diff from two modes
  static int diff(dynamic a1, dynamic a2) {
    final a1d = AccessMode.decode(a1) ?? 0;
    final a2d = AccessMode.decode(a2) ?? 0;

    if (a1d == modeInvalid || a2d == modeInvalid) {
      return modeInvalid;
    }
    return a1d & ~a2d;
  }

  /// Returns true if AccessNode has x flag
  ///
  /// side: `mode` / `want` / `given`
  static bool checkFlag(AccessMode val, String? side, int flag) {
    side ??= 'mode';
    final found = ['given', 'want', 'mode'].where((s) {
      return s == side;
    }).toList();

    if (found.isNotEmpty) {
      return ((val[side] & flag) != 0);
    }
    throw Exception('Invalid AccessMode component "$side"');
  }

  /// Returns encoded `mode`
  String? getMode() {
    return AccessMode.encode(mode);
  }

  AccessMode setMode(dynamic mode) {
    this.mode = AccessMode.decode(mode) ?? 0;
    return this;
  }

  AccessMode updateMode(String update) {
    mode = AccessMode.update(mode, update);
    return this;
  }

  /// Returns encoded `given`
  String? getGiven() {
    return AccessMode.encode(_given);
  }

  AccessMode setGiven(dynamic given) {
    _given = AccessMode.decode(given) ?? 0;
    return this;
  }

  AccessMode updateGiven(String update) {
    _given = AccessMode.update(_given, update);
    return this;
  }

  /// Returns encoded `want`
  String? getWant() {
    return AccessMode.encode(_want);
  }

  AccessMode setWant(dynamic want) {
    _want = AccessMode.decode(want) ?? 0;
    return this;
  }

  AccessMode updateWant(String update) {
    _want = AccessMode.update(_want, update);
    return this;
  }

  /// What user `want` that is not `given`
  String? getMissing() {
    return AccessMode.encode(_want & ~_given);
  }

  /// What permission is `given` and user does not `want`
  String? getExcessive() {
    return AccessMode.encode(_given & ~_want);
  }

  AccessMode updateAll(AccessMode? val) {
    if (val != null) {
      final g = val.getGiven();
      if (g != null) {
        updateGiven(g);
      }

      final w = val.getWant();
      if (w != null) {
        updateWant(w);
      }
      mode = _given & _want;
    }
    return this;
  }

  bool isOwner(String side) {
    return AccessMode.checkFlag(this, side, modeOwner);
  }

  bool isPresencer(String? side) {
    return AccessMode.checkFlag(this, side, modePres);
  }

  bool isMuted(String? side) {
    return !isPresencer(side);
  }

  /// Can this user subscribe on topic?
  bool isJoiner(String side) {
    return AccessMode.checkFlag(this, side, modeJoin);
  }

  bool isReader(String side) {
    return AccessMode.checkFlag(this, side, modeRead);
  }

  bool isWriter(String side) {
    return AccessMode.checkFlag(this, side, modeWrite);
  }

  bool isApprover(String side) {
    return AccessMode.checkFlag(this, side, modeApprove);
  }

  bool isAdmin(String side) {
    return isOwner(side) || isApprover(side);
  }

  bool isSharer(String side) {
    return isAdmin(side) || AccessMode.checkFlag(this, side, modeShare);
  }

  bool isDeleter(String side) {
    return AccessMode.checkFlag(this, side, modeDelete);
  }

  @override
  String toString() {
    return '{"mode": "${AccessMode.encode(mode) ?? 'invalid'}", "given": "${AccessMode.encode(_given) ?? 'invalid'}", "want": "${AccessMode.encode(_want) ?? 'invalid'}"}';
  }

  Map<String, String> jsonHelper() {
    return {
      'mode': AccessMode.encode(mode) ?? 'invalid',
      'given': AccessMode.encode(_given) ?? 'invalid',
      'want': AccessMode.encode(_want) ?? 'invalid',
    };
  }
}
