/// Password validation rules aligned with server policy.
class PasswordPolicy {
  PasswordPolicy._();

  static const int minLength = 8;
  static const int maxLength = 128;

  static final RegExp hasUppercase = RegExp(r'[A-Z]');
  static final RegExp hasLowercase = RegExp(r'[a-z]');
  static final RegExp hasDigit = RegExp(r'[0-9]');
  static final RegExp hasSpecial = RegExp(r'[!@#$%^&*()_+\-=\[\]{};:,.<>?/\\|`~]');

  /// A curated set of the most common weak passwords.
  /// Full top-10,000 list would be ~120 KB; this covers the top ~200
  /// most-frequently breached passwords.
  static const Set<String> commonPasswords = {
    // ── Top 50 ───────────────────────────────────────────────────────────
    '123456', 'password', '12345678', 'qwerty', '123456789',
    '12345', '1234', '111111', '1234567', 'sunshine',
    'qwerty123', 'iloveyou', 'princess', 'admin', 'welcome',
    '666666', 'abc123', 'football', '123123', 'monkey',
    '654321', r'!@#$%^&*', 'charlie', 'aa123456', 'donald',
    'password1', 'qwerty12345', '1234567890', 'letmein', 'password123',
    'dragon', 'master', 'hottie', 'loveme', 'starwars',
    'hello', 'freedom', 'whatever', 'trustno1', 'passw0rd',
    'qazwsx', '123321', '000000', '12345678910', 'qwertyuiop',
    'login', 'admin123', 'passwd', 'flower', 'batman',

    // ── Top 51-100 ───────────────────────────────────────────────────────
    'michael', 'shadow', 'sunshine1', 'baseball', 'access',
    'ashley', 'muster', 'pass', 'charlie1', 'solo',
    'swordfish', 'password!', 'thomas', 'aaaaaa', 'andrew',
    'jennifer', 'superman', 'asshole', 'godzilla', 'chicago',
    'midnight', 'summer', 'jordan', 'matrix', 'digital',
    'elizabeth', 'hunter', 'robert', 'matthew', 'ginger',
    'pepper', 'daniel', 'george', 'computer', 'amanda',
    'joshua', 'harley', 'hockey', 'tigger', 'andrea',
    'martin', 'amsterdam', 'richard', 'maverick', 'newyork',
    'jeffrey', 'dallas', 'thunder', 'alexander', 'eagle',

    // ── Variations commonly tested ───────────────────────────────────────
    '123456a', '123456b', '123456c', 'a123456', 'b123456',
    'password.', 'password2', 'password12', 'Password1', 'Password123',
    'pass1234', 'pass12345', 'qwerty1', 'qwerty12', 'qwerty1234',
    'abc1234', 'abc12345', 'letmein1', 'welcome1', 'admin1',
    'test123', 'test1234', 'test12345', 'temp123', 'temp1234',
    'changeme', 'changeme1', 'changeme123', 'default', 'default1',
    'P@ssw0rd', 'P@ssword', 'p@ssword', 'p@ssw0rd',
    'Passw0rd', 'passw0rd123', r'P@$$w0rd', r'P@55w0rd',

    // ── Keyboard walks ───────────────────────────────────────────────────
    'qwertz', 'asdfgh', 'asdfghjkl', 'zxcvbnm',
    'asdfghjkl;', 'zxcvbnm,.', '1qaz2wsx', '3edc4rfv',
    '1q2w3e4r', 'qweasd', 'qwe123', 'asd123', 'zxc123',
    '1qazxsw2', 'qazwsxedc', 'zaq12wsx',

    // ── Sequential / repeated chars ──────────────────────────────────────
    'abcdef', 'abcdefg', 'abcd1234', 'aaaa', 'bbbb',
    '1111', '2222', '3333', '4444', '5555',
    '7777', '8888', '9999', '121212', '131313',
    '112233', '111222', '1234abcd', 'abcd123',
  };

  static String? validate(String password) {
    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    if (password.length > maxLength) {
      return 'Password must be no more than $maxLength characters';
    }
    if (!hasUppercase.hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!hasLowercase.hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!hasDigit.hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    if (!hasSpecial.hasMatch(password)) {
      return 'Password must contain at least one special character';
    }
    if (commonPasswords.contains(password.toLowerCase())) {
      return 'This password is too common. Please choose a stronger password.';
    }
    return null;
  }
}
