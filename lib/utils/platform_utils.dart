// Import condicional: usa dart:html en web, stub en Android/otros
export 'platform_utils_stub.dart'
    if (dart.library.html) 'platform_utils_web.dart';
