import 'dart:async';

abstract class Action {
  bool _isDone = false;
  bool get isDone => _isDone;
  bool userCreated = true;

  void _run() {
    if (!isDone) {
      doAction();
      _isDone = true;
    }
  }

  void _unrun() {
    if (isDone) {
      undoAction();
      _isDone = false;
    }
  }

  void doAction();
  void undoAction();

  /// Triggered when this action is added to a history stack
  /// or run in reaction to a redo.
  void onSilentRegister() {}
}

class History {
  final List<Action> _stack = [];
  final _streamCtrl = StreamController<Action>.broadcast();
  int _actionsDone = 0;

  Stream<Action> get onChange => _streamCtrl.stream;
  Iterable<Action> get stack => _stack;
  int get positionInStack => _actionsDone;
  bool get canRedo => _actionsDone < _stack.length;

  void perform(Action a, [bool reversible = true]) {
    if (!reversible) {
      a._run();
    } else {
      _registerAction(a);
    }
  }

  void registerDoneAction(Action a) {
    if (a == null) return;

    a._isDone = true;
    _registerAction(a);
    if (a.userCreated) {
      a.onSilentRegister();
    }
  }

  void _registerAction(Action a) {
    if (_actionsDone < _stack.length) {
      _stack.removeRange(_actionsDone, _stack.length);
    }
    _stack.add(a);
    if (!a._isDone) {
      a._run();
    }
    _actionsDone++;
    _streamCtrl.add(a);
  }

  void undo() {
    if (_actionsDone > 0) {
      _stack[_actionsDone - 1]._unrun();
      _actionsDone--;
      _streamCtrl.add(null);
    }
  }

  void redo() {
    if (_actionsDone < _stack.length) {
      _stack[_actionsDone]._run();
      _actionsDone++;
      _streamCtrl.add(null);
    }
  }

  /// ♫ _In my brain I rearrange the letters on the page to spell your name._ ♫
  void erase() {
    if (_stack.isNotEmpty) {
      _actionsDone = 0;
      _stack.clear();
      _streamCtrl.add(null);
    }
  }
}

abstract class MultipleAction<T> extends Action {
  final Iterable<T> list;

  MultipleAction(this.list);

  void doSingle(T object);
  void undoSingle(T object);

  void _doAll() => list.forEach((t) => doSingle(t));
  void _undoAll() => list.forEach((t) => undoSingle(t));

  @override
  void doAction() => _doAll();

  @override
  void undoAction() => _undoAll();
}

abstract class AddRemoveAction<T> extends MultipleAction<T> {
  final bool forward;

  AddRemoveAction(this.forward, Iterable<T> list) : super(list);

  void _addAll() => list.forEach((t) => doSingle(t));
  void _removeAll() => list.forEach((t) => undoSingle(t));

  @override
  void doAction() {
    onBeforeExecute(forward);
    forward ? _addAll() : _removeAll();
    onExecuted(forward);
  }

  @override
  void undoAction() {
    onBeforeExecute(!forward);
    forward ? _removeAll() : _addAll();
    onExecuted(!forward);
  }

  void onBeforeExecute(bool forward) {}
  void onExecuted(bool forward) {}
}

abstract class SingleAddRemoveAction extends Action {
  final bool forward;

  SingleAddRemoveAction(this.forward);

  @override
  void doAction() {
    forward ? create() : delete();
    onExecuted(forward);
  }

  @override
  void undoAction() {
    forward ? delete() : create();
    onExecuted(!forward);
  }

  void create();
  void delete();
  void onExecuted(bool forward) {}
}
