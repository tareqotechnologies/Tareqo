package com.tareqo.tareqo

import io.flutter.embedding.android.FlutterFragmentActivity

// ⚠️ Deve estender FlutterFragmentActivity (NÃO FlutterActivity): o plugin
// local_auth (local_auth_android) usa o BiometricPrompt do AndroidX, que
// exige uma FragmentActivity. Com FlutterActivity o authenticate() falha
// silenciosamente com PlatformException(no_fragment_activity) e o prompt
// de biometria nunca aparece (biometria "não ativa" em Configurações →
// Segurança).
class MainActivity : FlutterFragmentActivity()
