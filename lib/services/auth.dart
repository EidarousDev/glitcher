import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/constants.dart';

Future<FirebaseUser> getCurrentUser() async {
  FirebaseUser currentUser = await Auth().getCurrentUser();
  return currentUser;
}

abstract class BaseAuth {
  Future<String> signInWithEmailAndPassword(String email, String password);
  Future<String> signIn(String email, String password);

  Future<String> signUp(String username, String email, String password);

  Future<String> currentUser();

  Future<FirebaseUser> getCurrentUser();

  Future<void> sendEmailVerification();

  Future<void> signOut();

  Future<bool> isEmailVerified();

  Future<void> changeEmail(String email);

  Future<void> changePassword(String password);

  Future<void> deleteUser();

  Future<void> sendPasswordResetMail(String email);

  Future<User> loadUserData();
}

class Auth implements BaseAuth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Future<String> signInWithEmailAndPassword(
      String email, String password) async {
    final FirebaseUser user = (await _firebaseAuth.signInWithEmailAndPassword(
            email: email, password: password))
        .user;
    return user?.uid;
  }

  @override
  Future<String> signIn(String email, String password) async {
    FirebaseUser user = (await _firebaseAuth.signInWithEmailAndPassword(
            email: email, password: password))
        .user;
    if (user.isEmailVerified) return user.uid;
    return null;
  }

  // ignore: missing_return
  Future<String> signUp(String username, String email, String password) async {
    FirebaseUser user = (await _firebaseAuth.createUserWithEmailAndPassword(
            email: email, password: password))
        .user;
    try {
      await user.sendEmailVerification();
      return user.uid;
    } catch (e) {
      print("An error occured while trying to send email        verification");
      print(e.message);
    }
  }

  @override
  Future<String> currentUser() async {
    final FirebaseUser user = await _firebaseAuth.currentUser();
    return user?.uid;
  }

  Future<FirebaseUser> getCurrentUser() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    return user;
  }

  Future<void> signOut() async {
    return _firebaseAuth.signOut();
  }

  Future<void> sendEmailVerification() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    user.sendEmailVerification();
  }

  Future<bool> isEmailVerified() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    return user.isEmailVerified;
  }

  @override
  Future<void> changeEmail(String email) async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    user.updateEmail(email).then((_) {
      print("Succesfull changed email");
    }).catchError((error) {
      print("email can't be changed" + error.toString());
    });
    return null;
  }

  @override
  Future<void> changePassword(String password) async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    user.updatePassword(password).then((_) {
      print("Succesfull changed password");
    }).catchError((error) {
      print("Password can't be changed" + error.toString());
    });
    return null;
  }

  @override
  Future<void> deleteUser() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
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

  Future<User> loadUserData() async {
    final FirebaseUser user = await auth.currentUser();
    final uid = user.uid;
    //print('currentUserID: $uid');
    // here you write the codes to input the data into firestore
    User loggedInUser = await DatabaseService.getUserWithId(uid);
    return loggedInUser;
  }
}
