import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mockito/mockito.dart';
import 'package:user_repository/user_repository.dart';

import 'package:flutter_login/authentication/authentication.dart';
import 'package:flutter_login/login/bloc/login_bloc.dart';

class MockUserRepository extends Mock implements UserRepository {}

class MockAuthenticationBloc extends Mock implements AuthenticationBloc {}

void main() {
  LoginBloc loginBloc;
  MockUserRepository userRepository;
  MockAuthenticationBloc authenticationBloc;

  setUp(() {
    userRepository = MockUserRepository();
    authenticationBloc = MockAuthenticationBloc();
    loginBloc = LoginBloc(
      userRepository: userRepository,
      authenticationBloc: authenticationBloc,
    );
  });

  tearDown(() {
    loginBloc?.close();
    authenticationBloc?.close();
  });

  test('throws AssertionError when userRepository is null', () {
    expect(
      () => LoginBloc(
        userRepository: null,
        authenticationBloc: authenticationBloc,
      ),
      throwsAssertionError,
    );
  });

  test('throws AssertionError when authenticationBloc is null', () {
    expect(
      () => LoginBloc(
        userRepository: userRepository,
        authenticationBloc: null,
      ),
      throwsAssertionError,
    );
  });

  test('initial state is correct', () {
    expect(LoginInitial(), loginBloc.initialState);
  });

  test('close does not emit new states', () {
    expectLater(
      loginBloc,
      emitsInOrder([LoginInitial(), emitsDone]),
    );
    loginBloc.close();
  });

  group('LoginButtonPressed', () {
    blocTest(
      'emits [LoginInitial, LoginLoading, LoginInitial] and token on success',
      build: () {
        when(userRepository.authenticate(
          username: 'valid.username',
          password: 'valid.password',
        )).thenAnswer((_) => Future.value('token'));
        return loginBloc;
      },
      act: (bloc) => bloc.add(
        LoginButtonPressed(
          username: 'valid.username',
          password: 'valid.password',
        ),
      ),
      expect: [
        LoginInitial(),
        LoginLoading(),
        LoginInitial(),
      ],
      verify: () async {
        verify(authenticationBloc.add(LoggedIn(token: 'token'))).called(1);
      },
    );

    blocTest(
      'emits [LoginInitial, LoginLoading, LoginFailure] on failure',
      build: () {
        when(userRepository.authenticate(
          username: 'valid.username',
          password: 'valid.password',
        )).thenThrow(Exception('login-error'));
        return loginBloc;
      },
      act: (bloc) => bloc.add(
        LoginButtonPressed(
          username: 'valid.username',
          password: 'valid.password',
        ),
      ),
      expect: [
        LoginInitial(),
        LoginLoading(),
        LoginFailure(error: 'Exception: login-error'),
      ],
      verify: () async {
        verifyNever(authenticationBloc.add(any));
      },
    );
  });
}
