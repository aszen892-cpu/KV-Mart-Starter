import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const KvMartAdminApp());
}

class KvMartAdminApp extends StatelessWidget {
  const KvMartAdminApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'KV Mart Admin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B45)), useMaterial3: true),
        home: const AdminAuthGate(),
      );
}

class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, auth) {
          if (auth.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (auth.data == null) return const AdminLoginPage();
          return AdminRoleGate(user: auth.data!);
        },
      );
}

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({super.key});

  Future<void> _signIn(BuildContext context) async {
    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      } else {
        final account = await GoogleSignIn().signIn();
        if (account == null) return;
        final tokens = await account.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: tokens.accessToken,
          idToken: tokens.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.admin_panel_settings, size: 56),
                  const SizedBox(height: 12),
                  Text('KV Mart Admin', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  const Text('Sign in with an approved administrator account.'),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => _signIn(context),
                    icon: const Icon(Icons.login),
                    label: const Text('Continue with Google'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}

class AdminRoleGate extends StatelessWidget {
  const AdminRoleGate({super.key, required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Could not verify admin role: ${snapshot.error}')));
        }
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final role = snapshot.data!.data()?['role'];
        if (role != 'admin') {
          return Scaffold(
            appBar: AppBar(title: const Text('KV Mart Admin')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.lock_outline, size: 56),
                  const SizedBox(height: 12),
                  const Text('Access denied. This Google account is not an admin.'),
                  const SizedBox(height: 8),
                  const Text('A project owner must assign role = admin to this user in Firestore.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      if (!kIsWeb) await GoogleSignIn().signOut();
                      await FirebaseAuth.instance.signOut();
                    },
                    child: const Text('Sign out'),
                  ),
                ]),
              ),
            ),
          );
        }
        return const AdminDashboard();
      },
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('KV Mart Admin'),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              onPressed: () async {
                if (!kIsWeb) await GoogleSignIn().signOut();
                await FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Catalog overview', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('products').limit(100).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text('Error loading catalog: ${snapshot.error}');
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final products = snapshot.data!.docs;
                return Expanded(
                  child: products.isEmpty
                      ? const Center(child: Text('No products yet. Add products in Firestore to begin.'))
                      : ListView.separated(
                          itemCount: products.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final product = products[index].data();
                            return ListTile(
                              leading: const Icon(Icons.inventory_2_outlined),
                              title: Text('${product['name'] ?? 'Unnamed product'}'),
                              subtitle: Text('₹${product['price'] ?? '—'} · Stock ${product['stock'] ?? '—'} · ${product['isActive'] == true ? 'Active' : 'Inactive'}'),
                              trailing: Text(products[index].id, style: Theme.of(context).textTheme.labelSmall),
                            );
                          },
                        ),
                );
              },
            ),
          ]),
        ),
      );
}
