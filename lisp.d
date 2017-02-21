module lisp;
static import std.file;
import std.stdio : writeln;

unittest {
  import parser;
  Init();
  // -- test addition and basic nesting
  assert(Parse(q{ (+ 4 1) }) == 5);
  assert(Parse(q{ (+ -10 15) }) == 5);
  assert(Parse(q{ (+ (+ 1 (+ 1 1)) (+ (+ 0 1)(  + 1 0  ))) }) == 5);
  // -- test define
  assert(Parse(q{ (define n 1) (+ n n n) }) == 3);
  assert(Parse(q{ (define h 3) (define n 5) (+ n h) }) == 8);
  // -- test lambda
  assert(Parse(q{ (define add2 (lambda (base exp) (+ base exp)))
                  (add2 10 10)}) == 20);
  assert(Parse(q{ (define add2 (lambda (base exp) (+ base exp)))
                  (define n 19)
                  (define t 1)
                  (add2 n t)}) == 20);
  // -- test if
  assert(Parse(q{
    (if 1 10 20)
  }) == 10);
  assert(Parse(q{
    (if 0 10 20)
  }) == 20);
  // -- test car
  assert(Parse(q{
    (car (~ (10 20)))
  }) == 10);
  assert(Parse(q{
    (car (cdr (~ (10 20 30))))
  }) == 20);
  // -- test cdr
  assert(Parse(q{
    (car (cdr (~ (10 20))) )
  }) == 20);
  // -- test cons
  assert(Parse(q{
    (car (cdr (cdr (cons (~ (10 20)) (~ (30 40))) ) ))
  }) == 30);
  // -- test float
  assert(Parse(q{
    (+ 3.0f 0.14f)
  }) == 3.14f);
}
