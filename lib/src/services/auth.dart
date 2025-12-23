import 'package:rxdart/rxdart.dart';

import 'package:tindarts_sdk/src/models/server-messages.dart';
import 'package:tindarts_sdk/src/models/auth-token.dart';

class AuthService {
  String? _userId;
  String? _lastLogin;
  AuthToken? _authToken;
  bool _authenticated = false;

  PublishSubject<OnLoginData> onLogin = PublishSubject<OnLoginData>();

  bool get isAuthenticated {
    return _authenticated;
  }

  AuthToken? get authToken {
    return _authToken;
  }

  String? get userId {
    return _userId;
  }

  String? get lastLogin {
    return _lastLogin;
  }

  void setLastLogin(String lastLogin) {
    _lastLogin = lastLogin;
  }

  void setAuthToken(AuthToken authToken) {
    _authToken = authToken;
  }

  void setUserId(String? userId) {
    _userId = userId;
  }

  void onLoginSuccessful(CtrlMessage? ctrl) {
    if (ctrl == null) {
      return;
    }

    final params = ctrl.params as Map<String, dynamic>?;
    if (params == null || params['user'] == null) {
      return;
    }

    _userId = params['user'] as String?;
    _authenticated = (ctrl.code ?? 0) >= 200 && (ctrl.code ?? 0) < 300;

    if (params['token'] != null && params['expires'] != null) {
      _authToken = AuthToken(params['token'] as String, DateTime.parse(params['expires'] as String));
    } else {
      _authToken = null;
    }

    final code = ctrl.code;
    final text = ctrl.text;
    if (code != null && text != null) {
      onLogin.add(OnLoginData(code, text));
    }
  }
}
