import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:glitcher/models/user_model.dart' as user_model;
import 'package:glitcher/services/database_service.dart';

Future<User> getCurrentUser() async {
  User currentUser = await Auth().getCurrentUser();
  return currentUser;
}

abstract class BaseAuth {
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<String> signIn(String email, String password);

  Future<String> signUp(String username, String email, String password);

  Future<String> currentUser();

  Future<User> getCurrentUser();

  Future<void> sendEmailVerification();

  Future<void> signOut();

  Future<bool> isEmailVerified();

  Future<void> changeEmail(String email);

  Future<String> changePassword(String password);

  Future<void> deleteUser();

  Future<void> sendPasswordResetMail(String email);

  Future<user_model.User> loadUserData();
}

class Auth implements BaseAuth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    final User user = (await _firebaseAuth.signInWithEmailAndPassword(
            email: email, password: password))
        .user;
    return user;
  }

  @override
  Future<String> signIn(String email, String password) async {
    User user = (await _firebaseAuth.signInWithEmailAndPassword(
            email: email, password: password))
        .user;
    if (user.emailVerified) return user.uid;
    return null;
  }

  // ignore: missing_return
  Future<String> signUp(String username, String email, String password) async {
    User user;
    try {
      user = (await _firebaseAuth.createUserWithEmailAndPassword(
              email: email, password: password))
          .user;
    } catch (signUpError) {
      if (signUpError is PlatformException) {
        print('Sign up error: ${signUpError.code}');
        if (signUpError.code == 'ERROR_EMAIL_ALREADY_IN_USE') {
          return 'Email is already in use';
        } else if (signUpError.code == 'ERROR_WEAK_PASSWORD') {
          return 'Weak Password';
        } else if (signUpError.code == 'ERROR_INVALID_EMAIL') {
          return 'Invalid Email';
        } else {
          return 'sign_up_error';
        }
      }
    }

    try {
      await user.sendEmailVerification();
      return user.uid;
    } catch (e) {
      print("An error occurred while trying to send verification email");
      print(e.message);
    }
  }

  @override
  Future<String> currentUser() async {
    final User user = _firebaseAuth.currentUser;
    return user?.uid;
  }

  Future<User> getCurrentUser() async {
    User user = _firebaseAuth.currentUser;
    return user;
  }

  Future<void> signOut() async {
    return _firebaseAuth.signOut();
  }

  Future<void> sendEmailVerification() async {
    User user = _firebaseAuth.currentUser;
    user.sendEmailVerification();
  }

  Future<bool> isEmailVerified() async {
    User user = _firebaseAuth.currentUser;
    return user.emailVerified;
  }

  @override
  Future<void> changeEmail(String email) async {
    User user = _firebaseAuth.currentUser;
    user.updateEmail(email).then((_) {
      print("Succesfully changed email");
    }).catchError((error) {
      print("email can't be changed" + error.toString());
    });
    return null;
  }

  @override
  Future<String> changePassword(String password) async {
    try {
      User user = _firebaseAuth.currentUser;
      await user.updatePassword(password);
      print("Successfully changed password");
      return null;
    } catch (error) {
      print("Password can't be changed " + error.code);
      return error.code;
    }
  }

  @override
  Future<void> deleteUser() async {
    User user = _firebaseAuth.currentUser;
    user.delete().then((_) {
      print("Succesfull user deleted");
    }).catchError((error) {
      print("user can't be delete" + error.toString());
    });
    return null;
  }

  @override
  Future<void> sendPasswordResetMail(String email) async {
    print('===========>' + email);
    await _firebaseAuth.sendPasswordResetEmail(email: email);
    return null;
  }

  Future<user_model.User> loadUserData() async {
    final User user = _firebaseAuth.currentUser;

    final uid = user.uid;
    //print('currentUserID: $uid');
    // here you write the codes to input the data into firestore
    user_model.User loggedInUser =
        await DatabaseService.getUserWithId(uid, checkLocal: false);
    return loggedInUser;
  }
}
