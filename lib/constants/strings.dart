class Strings {
  // App Strings - Those will be set anyway in the AppPage Class, so don't bother editing them from here
  static String packageName = 'com.eidarousdev.glitcher';
  static String appVersion = '1.0.0';
  static String appName = 'Glitcher';
  static String buildNumber = '1.0';
  static String appDescription = 'GLITCHER | #1 Social App for Gamers';

  // Generic strings
  static const String ok = 'OK';
  static const String cancel = 'Cancel';

  // Logout
  static const String logout = 'Logout';
  static const String logoutAreYouSure =
      'Are you sure that you want to logout?';
  static const String logoutFailed = 'Logout failed';

  // Sign In Page
  static const String signIn = 'Sign in';
  static const String signInWithEmailPassword =
      'Sign in with email and password';
  static const String signInWithEmailLink = 'Sign in with email link';
  static const String signInWithFacebook = 'Sign in with Facebook';
  static const String signInWithGoogle = 'Sign in with Google';
  static const String or = 'or';

  // Email & Password page
  static const String register = 'Register';
  static const String forgotPassword = 'Forgot password';
  static const String forgotPasswordQuestion = 'Forgot password?';
  static const String createAnAccount = 'Create an account';
  static const String needAnAccount = 'Need an account? Register';
  static const String haveAnAccount = 'Have an account? Sign in';
  static const String signInFailed = 'Sign in failed';
  static const String registrationFailed = 'Registration failed';
  static const String passwordResetFailed = 'Password reset failed';
  static const String sendResetLink = 'Send Reset Link';
  static const String backToSignIn = 'Back to sign in';
  static const String resetLinkSentTitle = 'Reset link sent';
  static const String resetLinkSentMessage =
      'Check your email to reset your password';
  static const String emailLabel = 'Email';
  static const String emailHint = 'test@test.com';
  static const String password8CharactersLabel = 'Password (8+ characters)';
  static const String passwordLabel = 'Password';
  static const String invalidEmailErrorText = 'Email is invalid';
  static const String invalidEmailEmpty = 'Email can\'t be empty';
  static const String invalidPasswordTooShort = 'Password is too short';
  static const String invalidPasswordEmpty = 'Password can\'t be empty';

  // Email link page
  static const String submitEmailAddressLink =
      'Submit your email address to receive an activation link.';
  static const String checkYourEmail = 'Check your email';

  static const String SAVE_IMAGE = 'Save Image';

  static String activationLinkSent(String email) =>
      'We have sent an activation link to $email';
  static const String errorSendingEmail = 'Error sending email';
  static const String sendActivationLink = 'Send activation link';
  static const String activationLinkError = 'Email activation error';
  static const String submitEmailAgain =
      'Please submit your email address again to receive a new activation link.';
  static const String userAlreadySignedIn =
      'Received an activation link but you are already signed in.';
  static const String isNotSignInWithEmailLinkMessage =
      'Invalid activation link';

  // Home page
  static const String homePage = 'Home Page';

  // Developer menu
  static const String developerMenu = 'Developer menu';
  static const String authenticationType = 'Authentication type';
  static const String firebase = 'Firebase';
  static const String mock = 'Mock';

  // Defaults Assets
  static const String default_profile_image =
      'assets/images/default_profile.png';
  static const String default_post_image = 'assets/images/default_profile.png';
  static const String default_group_image = 'assets/images/group_default.png';
  static const String like_sound = 'assets/sounds/like_sound.mp3';
  static const String dislike_sound = 'assets/sounds/dislikesfx.mp3';
  static const String swipe_up_to_reload =
      'assets/sounds/swipe_up_to_reload.mp3';
  String appFont = 'HelveticaNeuea';
  List<String> defaultProfilePics = [
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ6TaCLCqU4K0ieF27ayjl51NmitWaJAh_X0r1rLX4gMvOe0MDaYw&s',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTFDjXj1F8Ix-rRFgY_r3GerDoQwfiOMXVt-tZdv_Mcou_yIlUC&s',
    'http://www.azembelani.co.za/wp-content/uploads/2016/07/20161014_58006bf6e7079-3.png',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRzDG366qY7vXN2yng09wb517WTWqp-oua-mMsAoCadtncPybfQ&s',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTq7BgpG1CwOveQ_gEFgOJASWjgzHAgVfyozkIXk67LzN1jnj9I&s',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRPxjRIYT8pG0zgzKTilbko-MOv8pSnmO63M9FkOvfHoR9FvInm&s',
    'https://cdn5.f-cdn.com/contestentries/753244/11441006/57c152cc68857_thumb900.jpg',
    'https://cdn6.f-cdn.com/contestentries/753244/20994643/57c189b564237_thumb900.jpg'
  ];

  // About Us Page
  static const String about_us = 'About Glitcher';
  static const String privacy_policy = 'Privacy Policy';
  static const String cookie_use = 'Cookie use';
  static const String help_center = 'Help Center';
  static const legal_notices = 'Legal Notices';
  static const terms_of_service = 'Terms of Service';
  static const String settings = 'Settings';

  //Theme
  static const String lightTheme = "AvailableThemes.LIGHT_THEME";
}
