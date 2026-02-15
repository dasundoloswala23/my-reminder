import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import '../../domain/entities/user_entity.dart';

/// Abstract Auth Repository interface
abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<UserEntity> signInWithEmailPassword(String email, String password);
  Future<UserEntity> registerWithEmailPassword(String email, String password, String name);
  Future<UserEntity> signInWithGoogle();
  Future<UserEntity> signInWithApple();
  Future<void> signOut();
  Future<UserEntity?> getCurrentUserData();
  Future<void> updateUserProfile({String? name, String? email});
  bool get isAppleSignInAvailable;
  bool get isGoogleSignInAvailable;
}

/// Auth Repository Implementation
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  bool get isAppleSignInAvailable => Platform.isIOS || Platform.isMacOS;

  @override
  bool get isGoogleSignInAvailable => Platform.isAndroid || Platform.isIOS;

  @override
  Future<UserEntity> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Login failed: No user returned');
      }

      // Fetch user data from Firestore
      final userData = await getCurrentUserData();
      if (userData == null) {
        throw Exception('User data not found');
      }

      return userData;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<UserEntity> registerWithEmailPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Registration failed: No user returned');
      }

      // Create user document in Firestore
      final user = UserModel(
        uid: credential.user!.uid,
        email: email,
        name: name,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(user.toFirestore());

      // Update display name in Firebase Auth
      await credential.user!.updateDisplayName(name);

      return user.toEntity();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('Google Sign-In failed: No user returned');
      }

      // Create or update user in Firestore
      return await _createOrUpdateUserInFirestore(
        userCredential.user!,
        googleUser.displayName ?? 'User',
        googleUser.email,
      );
    } catch (e) {
      throw Exception('Google Sign-In failed: ${e.toString()}');
    }
  }

  @override
  Future<UserEntity> signInWithApple() async {
    try {
      // Generate nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request Apple Sign-In
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Create OAuth credential
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Sign in to Firebase with the Apple credential
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      if (userCredential.user == null) {
        throw Exception('Apple Sign-In failed: No user returned');
      }

      // Get name from Apple credential (only provided on first sign-in)
      String displayName = 'User';
      if (appleCredential.givenName != null || appleCredential.familyName != null) {
        displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
      } else if (userCredential.user!.displayName != null) {
        displayName = userCredential.user!.displayName!;
      }

      // Create or update user in Firestore
      return await _createOrUpdateUserInFirestore(
        userCredential.user!,
        displayName,
        appleCredential.email ?? userCredential.user!.email ?? '',
      );
    } catch (e) {
      throw Exception('Apple Sign-In failed: ${e.toString()}');
    }
  }

  Future<UserEntity> _createOrUpdateUserInFirestore(
    User firebaseUser,
    String name,
    String email,
  ) async {
    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();

    if (!doc.exists) {
      // Create new user document
      final user = UserModel(
        uid: firebaseUser.uid,
        email: email,
        name: name,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(firebaseUser.uid).set(user.toFirestore());

      // Update display name in Firebase Auth if not set
      if (firebaseUser.displayName == null || firebaseUser.displayName!.isEmpty) {
        await firebaseUser.updateDisplayName(name);
      }

      return user.toEntity();
    }

    return UserModel.fromFirestore(doc).toEntity();
  }

  @override
  Future<void> signOut() async {
    // Sign out from Google if signed in
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      // Create user document if it doesn't exist
      final newUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? 'User',
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(user.uid).set(newUser.toFirestore());
      return newUser.toEntity();
    }

    return UserModel.fromFirestore(doc).toEntity();
  }

  @override
  Future<void> updateUserProfile({String? name, String? email}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final updates = <String, dynamic>{};

    if (name != null) {
      await user.updateDisplayName(name);
      updates['name'] = name;
    }

    if (email != null) {
      await user.verifyBeforeUpdateEmail(email);
      updates['email'] = email;
    }

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(user.uid).update(updates);
    }
  }

  /// Generates a cryptographically secure random nonce
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Returns the sha256 hash of [input] in hex notation
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email');
      case 'wrong-password':
        return Exception('Incorrect password');
      case 'email-already-in-use':
        return Exception('Email is already registered');
      case 'weak-password':
        return Exception('Password is too weak');
      case 'invalid-email':
        return Exception('Invalid email address');
      case 'user-disabled':
        return Exception('This account has been disabled');
      default:
        return Exception(e.message ?? 'Authentication failed');
    }
  }
}

