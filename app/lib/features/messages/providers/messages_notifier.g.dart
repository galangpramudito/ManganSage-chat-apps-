// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-conversation messages notifier — `family` by `conversationId`.
///
/// Mendukung:
/// - Initial load (page 1) di `build`.
/// - `loadMore` saat scroll ke atas.
/// - `sendMessage` — POST + append.
/// - `markAllRead` — POST + mutate state lokal (set isRead pada pesan diterima).

@ProviderFor(MessagesNotifier)
final messagesProvider = MessagesNotifierFamily._();

/// Per-conversation messages notifier — `family` by `conversationId`.
///
/// Mendukung:
/// - Initial load (page 1) di `build`.
/// - `loadMore` saat scroll ke atas.
/// - `sendMessage` — POST + append.
/// - `markAllRead` — POST + mutate state lokal (set isRead pada pesan diterima).
final class MessagesNotifierProvider
    extends $AsyncNotifierProvider<MessagesNotifier, MessagesState> {
  /// Per-conversation messages notifier — `family` by `conversationId`.
  ///
  /// Mendukung:
  /// - Initial load (page 1) di `build`.
  /// - `loadMore` saat scroll ke atas.
  /// - `sendMessage` — POST + append.
  /// - `markAllRead` — POST + mutate state lokal (set isRead pada pesan diterima).
  MessagesNotifierProvider._({
    required MessagesNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'messagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$messagesNotifierHash();

  @override
  String toString() {
    return r'messagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MessagesNotifier create() => MessagesNotifier();

  @override
  bool operator ==(Object other) {
    return other is MessagesNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messagesNotifierHash() => r'3f2e8b2c90d3150cf746365ea6b898e3a5ad14ac';

/// Per-conversation messages notifier — `family` by `conversationId`.
///
/// Mendukung:
/// - Initial load (page 1) di `build`.
/// - `loadMore` saat scroll ke atas.
/// - `sendMessage` — POST + append.
/// - `markAllRead` — POST + mutate state lokal (set isRead pada pesan diterima).

final class MessagesNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          MessagesNotifier,
          AsyncValue<MessagesState>,
          MessagesState,
          FutureOr<MessagesState>,
          int
        > {
  MessagesNotifierFamily._()
    : super(
        retry: null,
        name: r'messagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Per-conversation messages notifier — `family` by `conversationId`.
  ///
  /// Mendukung:
  /// - Initial load (page 1) di `build`.
  /// - `loadMore` saat scroll ke atas.
  /// - `sendMessage` — POST + append.
  /// - `markAllRead` — POST + mutate state lokal (set isRead pada pesan diterima).

  MessagesNotifierProvider call(int conversationId) =>
      MessagesNotifierProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'messagesProvider';
}

/// Per-conversation messages notifier — `family` by `conversationId`.
///
/// Mendukung:
/// - Initial load (page 1) di `build`.
/// - `loadMore` saat scroll ke atas.
/// - `sendMessage` — POST + append.
/// - `markAllRead` — POST + mutate state lokal (set isRead pada pesan diterima).

abstract class _$MessagesNotifier extends $AsyncNotifier<MessagesState> {
  late final _$args = ref.$arg as int;
  int get conversationId => _$args;

  FutureOr<MessagesState> build(int conversationId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<MessagesState>, MessagesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MessagesState>, MessagesState>,
              AsyncValue<MessagesState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
