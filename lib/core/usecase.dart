abstract interface class UseCase<Out, In> {
  Future<Out> call(In params);
}

class NoParams {
  const NoParams();
}
