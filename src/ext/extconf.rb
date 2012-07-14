require 'mkmf'

$CFLAGS.gsub!(/-O\d/,"-O0") if ENV['DEBUG']

create_makefile "fast_update"
