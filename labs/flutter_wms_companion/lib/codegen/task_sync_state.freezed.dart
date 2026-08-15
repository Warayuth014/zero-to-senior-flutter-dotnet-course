// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_sync_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskSyncState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskSyncState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskSyncState()';
}


}

/// @nodoc
class $TaskSyncStateCopyWith<$Res>  {
$TaskSyncStateCopyWith(TaskSyncState _, $Res Function(TaskSyncState) __);
}


/// Adds pattern-matching-related methods to [TaskSyncState].
extension TaskSyncStatePatterns on TaskSyncState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SyncIdle value)?  idle,TResult Function( SyncRunning value)?  running,TResult Function( SyncFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SyncIdle() when idle != null:
return idle(_that);case SyncRunning() when running != null:
return running(_that);case SyncFailed() when failed != null:
return failed(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SyncIdle value)  idle,required TResult Function( SyncRunning value)  running,required TResult Function( SyncFailed value)  failed,}){
final _that = this;
switch (_that) {
case SyncIdle():
return idle(_that);case SyncRunning():
return running(_that);case SyncFailed():
return failed(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SyncIdle value)?  idle,TResult? Function( SyncRunning value)?  running,TResult? Function( SyncFailed value)?  failed,}){
final _that = this;
switch (_that) {
case SyncIdle() when idle != null:
return idle(_that);case SyncRunning() when running != null:
return running(_that);case SyncFailed() when failed != null:
return failed(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( int remaining)?  running,TResult Function( String commandId,  String message)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SyncIdle() when idle != null:
return idle();case SyncRunning() when running != null:
return running(_that.remaining);case SyncFailed() when failed != null:
return failed(_that.commandId,_that.message);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( int remaining)  running,required TResult Function( String commandId,  String message)  failed,}) {final _that = this;
switch (_that) {
case SyncIdle():
return idle();case SyncRunning():
return running(_that.remaining);case SyncFailed():
return failed(_that.commandId,_that.message);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( int remaining)?  running,TResult? Function( String commandId,  String message)?  failed,}) {final _that = this;
switch (_that) {
case SyncIdle() when idle != null:
return idle();case SyncRunning() when running != null:
return running(_that.remaining);case SyncFailed() when failed != null:
return failed(_that.commandId,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class SyncIdle extends TaskSyncState {
  const SyncIdle(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskSyncState.idle()';
}


}




/// @nodoc


class SyncRunning extends TaskSyncState {
  const SyncRunning({required this.remaining}): super._();
  

 final  int remaining;

/// Create a copy of TaskSyncState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncRunningCopyWith<SyncRunning> get copyWith => _$SyncRunningCopyWithImpl<SyncRunning>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncRunning&&(identical(other.remaining, remaining) || other.remaining == remaining));
}


@override
int get hashCode => Object.hash(runtimeType,remaining);

@override
String toString() {
  return 'TaskSyncState.running(remaining: $remaining)';
}


}

/// @nodoc
abstract mixin class $SyncRunningCopyWith<$Res> implements $TaskSyncStateCopyWith<$Res> {
  factory $SyncRunningCopyWith(SyncRunning value, $Res Function(SyncRunning) _then) = _$SyncRunningCopyWithImpl;
@useResult
$Res call({
 int remaining
});




}
/// @nodoc
class _$SyncRunningCopyWithImpl<$Res>
    implements $SyncRunningCopyWith<$Res> {
  _$SyncRunningCopyWithImpl(this._self, this._then);

  final SyncRunning _self;
  final $Res Function(SyncRunning) _then;

/// Create a copy of TaskSyncState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? remaining = null,}) {
  return _then(SyncRunning(
remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class SyncFailed extends TaskSyncState {
  const SyncFailed({required this.commandId, required this.message}): super._();
  

 final  String commandId;
 final  String message;

/// Create a copy of TaskSyncState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncFailedCopyWith<SyncFailed> get copyWith => _$SyncFailedCopyWithImpl<SyncFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncFailed&&(identical(other.commandId, commandId) || other.commandId == commandId)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,commandId,message);

@override
String toString() {
  return 'TaskSyncState.failed(commandId: $commandId, message: $message)';
}


}

/// @nodoc
abstract mixin class $SyncFailedCopyWith<$Res> implements $TaskSyncStateCopyWith<$Res> {
  factory $SyncFailedCopyWith(SyncFailed value, $Res Function(SyncFailed) _then) = _$SyncFailedCopyWithImpl;
@useResult
$Res call({
 String commandId, String message
});




}
/// @nodoc
class _$SyncFailedCopyWithImpl<$Res>
    implements $SyncFailedCopyWith<$Res> {
  _$SyncFailedCopyWithImpl(this._self, this._then);

  final SyncFailed _self;
  final $Res Function(SyncFailed) _then;

/// Create a copy of TaskSyncState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? commandId = null,Object? message = null,}) {
  return _then(SyncFailed(
commandId: null == commandId ? _self.commandId : commandId // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
