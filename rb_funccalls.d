#!/usr/sbin/dtrace -Zqs
/*self int indent;*/

dtrace:::BEGIN
{
  printf("Starting to trace\n");
}

syscall:::entry
{
  @[execname] = count();
}

/*
ruby\*:::function-entry
{
  self->thread = 1;
}

ruby\*:::function-entry
/self->thread/
{
  self->indent += 2;
  printf("%*s", self->indent, " ");
  printf("=> %s->%s\n", copyinstr(arg0), copyinstr(arg1));
}

ruby\*:::function-return
/self->thread/
{
  printf("%*s", self->indent, " ");
  printf("<= %s->%s\n", copyinstr(arg0), copyinstr(arg1));
  self->indent -= 2;
}
*/

dtrace:::END
{
  printf("Finished tracing\n");
}
