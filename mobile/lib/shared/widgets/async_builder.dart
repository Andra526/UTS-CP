import 'package:flutter/material.dart';

import '../../core/errors/error_message.dart';
import 'app_error_view.dart';
import 'app_loading.dart';

/// Memuat data dari API: tampilkan loading, error (dengan tombol coba lagi),
/// lalu [builder] saat data siap. `reload` memuat ulang data.
class AsyncBuilder<T> extends StatefulWidget {
  final Future<T> Function() loader;
  final Widget Function(BuildContext context, T data, VoidCallback reload)
  builder;

  const AsyncBuilder({super.key, required this.loader, required this.builder});

  @override
  State<AsyncBuilder<T>> createState() => _AsyncBuilderState<T>();
}

class _AsyncBuilderState<T> extends State<AsyncBuilder<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  void _reload() {
    setState(() {
      _future = widget.loader();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppLoading();
        }
        if (snapshot.hasError) {
          return AppErrorView(
            message: errorMessage(snapshot.error),
            onRetry: _reload,
          );
        }
        return widget.builder(context, snapshot.data as T, _reload);
      },
    );
  }
}
