// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../eip7702.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Signer {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Signer);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Signer()';
}


}

/// @nodoc
class $SignerCopyWith<$Res>  {
$SignerCopyWith(Signer _, $Res Function(Signer) __);
}


/// Adds pattern-matching-related methods to [Signer].
extension SignerPatterns on Signer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RawSigner value)?  raw,TResult Function( EthSigner value)?  eth,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RawSigner() when raw != null:
return raw(_that);case EthSigner() when eth != null:
return eth(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RawSigner value)  raw,required TResult Function( EthSigner value)  eth,}){
final _that = this;
switch (_that) {
case RawSigner():
return raw(_that);case EthSigner():
return eth(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RawSigner value)?  raw,TResult? Function( EthSigner value)?  eth,}){
final _that = this;
switch (_that) {
case RawSigner() when raw != null:
return raw(_that);case EthSigner() when eth != null:
return eth(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Uint8List rawPrivateKey)?  raw,TResult Function( EthPrivateKey ethPrivateKey)?  eth,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RawSigner() when raw != null:
return raw(_that.rawPrivateKey);case EthSigner() when eth != null:
return eth(_that.ethPrivateKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Uint8List rawPrivateKey)  raw,required TResult Function( EthPrivateKey ethPrivateKey)  eth,}) {final _that = this;
switch (_that) {
case RawSigner():
return raw(_that.rawPrivateKey);case EthSigner():
return eth(_that.ethPrivateKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Uint8List rawPrivateKey)?  raw,TResult? Function( EthPrivateKey ethPrivateKey)?  eth,}) {final _that = this;
switch (_that) {
case RawSigner() when raw != null:
return raw(_that.rawPrivateKey);case EthSigner() when eth != null:
return eth(_that.ethPrivateKey);case _:
  return null;

}
}

}

/// @nodoc


class RawSigner implements Signer {
  const RawSigner(this.rawPrivateKey);
  

 final  Uint8List rawPrivateKey;

/// Create a copy of Signer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RawSignerCopyWith<RawSigner> get copyWith => _$RawSignerCopyWithImpl<RawSigner>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RawSigner&&const DeepCollectionEquality().equals(other.rawPrivateKey, rawPrivateKey));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(rawPrivateKey));

@override
String toString() {
  return 'Signer.raw(rawPrivateKey: $rawPrivateKey)';
}


}

/// @nodoc
abstract mixin class $RawSignerCopyWith<$Res> implements $SignerCopyWith<$Res> {
  factory $RawSignerCopyWith(RawSigner value, $Res Function(RawSigner) _then) = _$RawSignerCopyWithImpl;
@useResult
$Res call({
 Uint8List rawPrivateKey
});




}
/// @nodoc
class _$RawSignerCopyWithImpl<$Res>
    implements $RawSignerCopyWith<$Res> {
  _$RawSignerCopyWithImpl(this._self, this._then);

  final RawSigner _self;
  final $Res Function(RawSigner) _then;

/// Create a copy of Signer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? rawPrivateKey = null,}) {
  return _then(RawSigner(
null == rawPrivateKey ? _self.rawPrivateKey : rawPrivateKey // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}


}

/// @nodoc


class EthSigner implements Signer {
  const EthSigner(this.ethPrivateKey);
  

 final  EthPrivateKey ethPrivateKey;

/// Create a copy of Signer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EthSignerCopyWith<EthSigner> get copyWith => _$EthSignerCopyWithImpl<EthSigner>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EthSigner&&(identical(other.ethPrivateKey, ethPrivateKey) || other.ethPrivateKey == ethPrivateKey));
}


@override
int get hashCode => Object.hash(runtimeType,ethPrivateKey);

@override
String toString() {
  return 'Signer.eth(ethPrivateKey: $ethPrivateKey)';
}


}

/// @nodoc
abstract mixin class $EthSignerCopyWith<$Res> implements $SignerCopyWith<$Res> {
  factory $EthSignerCopyWith(EthSigner value, $Res Function(EthSigner) _then) = _$EthSignerCopyWithImpl;
@useResult
$Res call({
 EthPrivateKey ethPrivateKey
});




}
/// @nodoc
class _$EthSignerCopyWithImpl<$Res>
    implements $EthSignerCopyWith<$Res> {
  _$EthSignerCopyWithImpl(this._self, this._then);

  final EthSigner _self;
  final $Res Function(EthSigner) _then;

/// Create a copy of Signer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? ethPrivateKey = null,}) {
  return _then(EthSigner(
null == ethPrivateKey ? _self.ethPrivateKey : ethPrivateKey // ignore: cast_nullable_to_non_nullable
as EthPrivateKey,
  ));
}


}

// dart format on
