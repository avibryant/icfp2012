require 'mkmf'

$CFLAGS << " -O0"

create_makefile "fast_update"
