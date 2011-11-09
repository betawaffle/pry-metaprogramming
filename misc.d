#!/usr/sbin/dtrace -Cs
/*#pragma D option quiet*/

typedef VALUE (void *);

dtrace:::BEGIN { printf("Tracing on PID %d...\n", $target); }

pid$target:libruby*::entry
{
  @[probefunc] = count();
  /*
  trace(arg0);
  trace(arg1);
  trace(arg2);
  */
}

pid$target:libruby*:rb_raise:entry
{
  trace(arg0);
  trace(copyinstr(arg1));
}

pid$target:libruby*:rb_funcall:entry
{
  trace(arg0);
  ustack();
  /*trace(copyinstr(arg1));*/
}

/*
pid$target:libruby*::return
{
  printf("%x %d", arg0, arg1);
}
*/
