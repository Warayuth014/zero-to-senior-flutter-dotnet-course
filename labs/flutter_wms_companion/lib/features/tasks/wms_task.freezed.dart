// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wms_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WmsTask {

 String get id; String get from; String get to; TaskStatus get status;
/// Create a copy of WmsTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WmsTaskCopyWith<WmsTask> get copyWith => _$WmsTaskCopyWithImpl<WmsTask>(this as WmsTask, _$identity);

  /// Serializes this WmsTask to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WmsTask&&(identical(other.id, id) || other.id == id)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,from,to,status);

@override
String toString() {
  return 'WmsTask(id: $id, from: $from, to: $to, status: $status)';
}


}

/// @nodoc
abstract mixin class $WmsTaskCopyWith<$Res>  {
  factory $WmsTaskCopyWith(WmsTask value, $Res Function(WmsTask) _then) = _$WmsTaskCopyWithImpl;
@useResult
$Res call({
 String id, String from, String to, TaskStatus status
});




}
/// @nodoc
class _$WmsTaskCopyWithImpl<$Res>
    implements $WmsTaskCopyWith<$Res> {
  _$WmsTaskCopyWithImpl(this._self, this._then);

  final WmsTask _self;
  final $Res Function(WmsTask) _then;

/// Create a copy of WmsTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? from = null,Object? to = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [WmsTask].
extension WmsTaskPatterns on WmsTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WmsTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WmsTask() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WmsTask value)  $default,){
final _that = this;
switch (_that) {
case _WmsTask():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WmsTask value)?  $default,){
final _that = this;
switch (_that) {
case _WmsTask() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String from,  String to,  TaskStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WmsTask() when $default != null:
return $default(_that.id,_that.from,_that.to,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String from,  String to,  TaskStatus status)  $default,) {final _that = this;
switch (_that) {
case _WmsTask():
return $default(_that.id,_that.from,_that.to,_that.status);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String from,  String to,  TaskStatus status)?  $default,) {final _that = this;
switch (_that) {
case _WmsTask() when $default != null:
return $default(_that.id,_that.from,_that.to,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WmsTask implements WmsTask {
  const _WmsTask({required this.id, required this.from, required this.to, required this.status});
  factory _WmsTask.fromJson(Map<String, dynamic> json) => _$WmsTaskFromJson(json);

@override final  String id;
@override final  String from;
@override final  String to;
@override final  TaskStatus status;

/// Create a copy of WmsTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WmsTaskCopyWith<_WmsTask> get copyWith => __$WmsTaskCopyWithImpl<_WmsTask>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WmsTaskToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WmsTask&&(identical(other.id, id) || other.id == id)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,from,to,status);

@override
String toString() {
  return 'WmsTask(id: $id, from: $from, to: $to, status: $status)';
}


}

/// @nodoc
abstract mixin class _$WmsTaskCopyWith<$Res> implements $WmsTaskCopyWith<$Res> {
  factory _$WmsTaskCopyWith(_WmsTask value, $Res Function(_WmsTask) _then) = __$WmsTaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String from, String to, TaskStatus status
});




}
/// @nodoc
class __$WmsTaskCopyWithImpl<$Res>
    implements _$WmsTaskCopyWith<$Res> {
  __$WmsTaskCopyWithImpl(this._self, this._then);

  final _WmsTask _self;
  final $Res Function(_WmsTask) _then;

/// Create a copy of WmsTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? from = null,Object? to = null,Object? status = null,}) {
  return _then(_WmsTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskStatus,
  ));
}


}

// dart format on
