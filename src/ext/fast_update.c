#include <ruby.h>


#define str_at(str, idx) RSTRING_PTR(str)[idx]

int set(VALUE cur, VALUE out, int r, int c, char n) {
  VALUE* rows = RARRAY_PTR(out);
  if(RARRAY_LEN(out) <= r) return 0;

  VALUE row = rows[r];

  if(row == Qnil) {
    row = rb_str_dup(RARRAY_PTR(cur)[r]);
    rb_str_modify(row);
    rb_ary_store(out, r, row);
  }

  if(RSTRING_LEN(row) <= c) return 0;

  RSTRING_PTR(row)[c] = n;

  return 1;
}

void fill_unchanged(VALUE map, VALUE out) {
  VALUE* mr = RARRAY_PTR(map);
  VALUE* or = RARRAY_PTR(out);
  int rows =  RARRAY_LEN(map);
  int r;

  for(r = 0; r < rows; r++) {
    if(or[r] == Qnil) rb_ary_store(out, r, mr[r]);
  }
}

VALUE update(VALUE self, VALUE map) {
  map = rb_Array(map);

  int num_rows = RARRAY_LEN(map);
  VALUE output = rb_ary_new2(num_rows);

  VALUE* rows = RARRAY_PTR(map);
  VALUE row;
  char* row_data;
  int row_length, r, c;

  for(r = 0; r < num_rows; r++) {
    rb_ary_store(output, r, Qnil);
  }

  for(r = 0; r < num_rows; r++) {
    row = rows[r];
    row_data = RSTRING_PTR(row);
    row_length = RSTRING_LEN(row);

    for(c = 0; c < row_length; c++) {
      switch(row_data[c]) {
      case ' ':
        break;
      case '*':
        if(r + 1 < num_rows) {
          if(str_at(rows[r+1], c) == ' ') {
            set(map, output, r+1, c, '*');
            set(map, output, r,   c, ' ');
          }
        }
        break;
      default:
        return Qnil;
      }
    }
  }

  fill_unchanged(map, output);

  return output;
}

void Init_fast_update() {
  VALUE mod = rb_define_module("FastUpdate");
  rb_define_singleton_method(mod, "update", update, 1);
}
