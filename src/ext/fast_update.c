#include <ruby.h>
#include <assert.h>

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
  int lambdas = 0;
  int lift_r = -1, lift_c = -1;
  int robot_dead = 0;

  for(r = 0; r < num_rows; r++) {
    rb_ary_store(output, r, Qnil);
  }

  for(r = num_rows - 1; r >= 0; r--) {
    row = rows[r];
    row_data = RSTRING_PTR(row);
    row_length = RSTRING_LEN(row);

    for(c = 0; c < row_length; c++) {
      switch(row_data[c]) {
      case '*':
        if(r + 1 < num_rows) {
          if(str_at(rows[r+1], c) == ' ') {
            set(map, output, r+1, c, '*');
            set(map, output, r,   c, ' ');
            if(r+2 < num_rows && str_at(rows[r+2], c) == 'R')
              robot_dead = 1;
          }

          if(str_at(rows[r+1], c) == '*') {
            if(c+1 < row_length &&
                  str_at(rows[r],   c+1) == ' ' &&
                  str_at(rows[r+1], c+1) == ' ') {
              set(map, output, r+1, c+1, '*');
              set(map, output, r,   c,   ' ');
              if(r+2 < num_rows && str_at(rows[r+2], c+1) == 'R')
                robot_dead = 1;
            } else
              if(c-1 >= 0 &&
                    str_at(rows[r],   c-1) == ' ' &&
                    str_at(rows[r+1], c-1) == ' ') {
                set(map, output, r+1, c-1, '*');
                set(map, output, r,   c,   ' ');
                if(r+2 < num_rows && str_at(rows[r+2], c-1) == 'R')
                  robot_dead = 1;
              }
          } else if(str_at(rows[r+1], c) == '\\') {
            if(c+1 < row_length &&
                  str_at(rows[r],   c+1) == ' ' &&
                  str_at(rows[r+1], c+1) == ' ') {
              set(map, output, r+1, c+1, '*');
              set(map, output, r,   c,   ' ');
              if(r+2 < num_rows && str_at(rows[r+2], c+1) == 'R')
                robot_dead = 1;
            }
          }
        }
        break;
      case 'L':
        lift_r = r;
        lift_c = c;
        break;
      case '\\':
        lambdas++;
        break;
      }
    }
  }

  if(lambdas == 0 && lift_r > -1) {
    set(map, output, lift_r, lift_c, 'O');
  }

  fill_unchanged(map, output);

  return rb_ary_new3(2, output, INT2FIX(robot_dead));
}

void destruct(VALUE array, int* x, int* y) {
  assert(RARRAY_LEN(array) == 2);

  *x = FIX2INT(RARRAY_PTR(array)[0]);
  *y = FIX2INT(RARRAY_PTR(array)[1]);
}

VALUE refresh_update(VALUE output, VALUE map, VALUE state) {
  VALUE* elems;
  int num_elems;

  VALUE* rows = RARRAY_PTR(map);
  int num_rows = RARRAY_LEN(map);

  VALUE row;
  char* row_data;

  int row_length, r, c, e;
  int lambdas = 0;

  VALUE rock_list = RARRAY_PTR(state)[0];
  VALUE lamb_list = RARRAY_PTR(state)[1];
  VALUE lift_pos =  RARRAY_PTR(state)[2];

  VALUE new_rock_list = rb_ary_new();
  VALUE new_lamb_list = rb_ary_new();

  elems = RARRAY_PTR(rock_list);
  num_elems = RARRAY_LEN(rock_list);

  for(e = num_elems - 1; e >= 0; e--) {
    destruct(elems[e], &r, &c);

    if(r + 1 < num_rows) {
      if(str_at(rows[r+1], c) == ' ') {
        set(map, output, r+1, c, '*');
        set(map, output, r,   c, ' ');

        rb_ary_push(new_rock_list,
                    rb_ary_new3(2, INT2FIX(r+1), INT2FIX(c)));
      }

      if(str_at(rows[r+1], c) == '*') {
        if(c+1 < row_length &&
              str_at(rows[r],   c+1) == ' ' &&
              str_at(rows[r+1], c+1) == ' ') {
          set(map, output, r+1, c+1, '*');
          set(map, output, r,   c,   ' ');

          rb_ary_push(new_rock_list,
                      rb_ary_new3(2, INT2FIX(r+1), INT2FIX(c+1)));
        } else
          if(c-1 >= 0 &&
                str_at(rows[r],   c-1) == ' ' &&
                str_at(rows[r+1], c-1) == ' ') {
            set(map, output, r+1, c-1, '*');
            set(map, output, r,   c,   ' ');

            rb_ary_push(new_rock_list,
                        rb_ary_new3(2, INT2FIX(r+1), INT2FIX(c-1)));
          }
      } else if(str_at(rows[r+1], c) == '\\') {
        if(c+1 < row_length &&
              str_at(rows[r],   c+1) == ' ' &&
              str_at(rows[r+1], c+1) == ' ') {
          set(map, output, r+1, c+1, '*');
          set(map, output, r,   c,   ' ');

          rb_ary_push(new_rock_list,
                      rb_ary_new3(2, INT2FIX(r+1), INT2FIX(c+1)));
        }
      }
    }
  }

  elems = RARRAY_PTR(lamb_list);
  num_elems = RARRAY_LEN(lamb_list);

  for(e = 0; e < num_elems; e++) {
    destruct(elems[e], &r, &c);

    if(str_at(rows[r],c) == '\\') {
      rb_ary_push(new_lamb_list, elems[e]);
      lambdas++;
    }
  }

  if(lambdas == 0 && lift_pos != Qnil) {
    destruct(lift_pos, &r, &c);
    set(map, output, r, c, 'O');
    lift_pos = Qnil;
  }

  fill_unchanged(map, output);

  return rb_ary_new3(2, output,
            rb_ary_new3(3, new_rock_list, new_lamb_list, lift_pos));
}

VALUE ultra_update(VALUE self, VALUE map, VALUE state) {
  map = rb_Array(map);

  int num_rows = RARRAY_LEN(map);
  VALUE output = rb_ary_new2(num_rows);

  VALUE* rows = RARRAY_PTR(map);
  VALUE row;
  char* row_data;
  int row_length, r, c;
  int lambdas = 0;
  int lift_r = -1, lift_c = -1;

  for(r = 0; r < num_rows; r++) {
    rb_ary_store(output, r, Qnil);
  }

  if(state != Qnil) return refresh_update(output, map, state);

  VALUE new_rock_list = rb_ary_new();
  VALUE new_lamb_list = rb_ary_new();
  VALUE lift_pos = Qnil;

  for(r = num_rows - 1; r >= 0; r--) {
    row = rows[r];
    row_data = RSTRING_PTR(row);
    row_length = RSTRING_LEN(row);

    for(c = 0; c < row_length; c++) {
      switch(row_data[c]) {
      case '*':
        if(r + 1 < num_rows) {
          if(str_at(rows[r+1], c) == ' ') {
            set(map, output, r+1, c, '*');
            set(map, output, r,   c, ' ');

            rb_ary_push(new_rock_list,
                        rb_ary_new3(2, INT2FIX(r+1), INT2FIX(c)));
          }

          if(str_at(rows[r+1], c) == '*') {
            if(c+1 < row_length &&
                  str_at(rows[r],   c+1) == ' ' &&
                  str_at(rows[r+1], c+1) == ' ') {
              set(map, output, r+1, c+1, '*');
              set(map, output, r,   c,   ' ');

              rb_ary_push(new_rock_list,
                          rb_ary_new3(2, INT2FIX(r+1), INT2FIX(c+1)));
            } else
              if(c-1 >= 0 &&
                    str_at(rows[r],   c-1) == ' ' &&
                    str_at(rows[r+1], c-1) == ' ') {
                set(map, output, r+1, c-1, '*');
                set(map, output, r,   c,   ' ');

                rb_ary_push(new_rock_list,
                            rb_ary_new3(2, INT2FIX(r+1), INT2FIX(c-1)));
              }
          } else if(str_at(rows[r+1], c) == '\\') {
            if(c+1 < row_length &&
                  str_at(rows[r],   c+1) == ' ' &&
                  str_at(rows[r+1], c+1) == ' ') {
              set(map, output, r+1, c+1, '*');
              set(map, output, r,   c,   ' ');

              rb_ary_push(new_rock_list,
                          rb_ary_new3(2, INT2FIX(r+1), INT2FIX(c+1)));
            }
          }
        }
        break;
      case 'L':
        lift_r = r;
        lift_c = c;
        break;
      case '\\':
          rb_ary_push(new_lamb_list,
                      rb_ary_new3(2, INT2FIX(r), INT2FIX(c)));
        lambdas++;
        break;
      }
    }
  }

  if(lambdas == 0 && lift_r > -1) {
    set(map, output, lift_r, lift_c, 'O');
    lift_pos = Qnil;
  } else if(lift_r > -1) {
    lift_pos = rb_ary_new3(2, INT2FIX(lift_r), INT2FIX(lift_c));
  }

  fill_unchanged(map, output);

  return rb_ary_new3(2, output,
            rb_ary_new3(3, new_rock_list, new_lamb_list, lift_pos));
}

VALUE move(VALUE self, VALUE map, VALUE row_n, VALUE col_n, VALUE dir) {
  map = rb_Array(map);

  int num_rows = RARRAY_LEN(map);
  VALUE output = rb_ary_new2(num_rows);

  VALUE* rows = RARRAY_PTR(map);
  VALUE row;
  char* row_data;
  int row_length, r, c, d;
  int lambdas = 0;
  int lift_r = -1, lift_c = -1;

  for(r = 0; r < num_rows; r++) {
    rb_ary_store(output, r, Qnil);
  }

  r = FIX2INT(row_n);
  c = FIX2INT(col_n);
  d = FIX2INT(dir);

  row = rows[r];
  row_data = RSTRING_PTR(row);
  row_length = RSTRING_LEN(row);

  switch(d) {
  case 0: // left
    if(c == 0) break;
    switch(row_data[c-1]) {
    case 'O':
      lambdas = -2;
    case '\\':
      lambdas++;
    case ' ':
    case '.':
      set(map, output, r, c-1, 'R');
      set(map, output, r, c,   ' ');
      c--;
      break;
    case '*':
      if(c > 1 && row_data[c-2] == ' ') {
        set(map, output, r, c-2, '*');
        set(map, output, r, c-1, 'R');
        set(map, output, r, c,   ' ');
        c--;
        break;
      }
    }
    break;
  case 1: // right
    if(c == row_length-1) break;
    switch(row_data[c+1]) {
    case 'O':
      lambdas = -2;
    case '\\':
      lambdas++;
    case ' ':
    case '.':
      set(map, output, r, c+1, 'R');
      set(map, output, r, c,   ' ');
      c++;
      break;
    case '*':
      if(c < row_length-2 && row_data[c+2] == ' ') {
        set(map, output, r, c+2, '*');
        set(map, output, r, c+1, 'R');
        set(map, output, r, c,   ' ');
        c++;
        break;
      }
    }
    break;
  case 2: // up
    if(r == 0) break;
    switch(str_at(rows[r-1],c)) {
    case 'O':
      lambdas = -2;
    case '\\':
      lambdas++;
    case ' ':
    case '.':
      set(map, output, r-1, c, 'R');
      set(map, output, r,   c, ' ');
      r--;
      break;
    }
    break;
  case 3: // down
    if(r >= num_rows-1) break;
    switch(str_at(rows[r+1],c)) {
    case 'O':
      lambdas = -2;
    case '\\':
      lambdas++;
    case ' ':
    case '.':
      set(map, output, r+1, c, 'R');
      set(map, output, r,   c, ' ');
      r++;
      break;
    }
    break;
  default:
    break;
  }

  fill_unchanged(map, output);

  return rb_ary_new3(3, output, INT2FIX(lambdas),
                     rb_ary_new3(2, INT2FIX(r), INT2FIX(c)));
}

void Init_fast_update() {
  VALUE mod = rb_define_module("FastUpdate");
  rb_define_singleton_method(mod, "update", update, 1);
  rb_define_singleton_method(mod, "ultra_update", ultra_update, 2);
  rb_define_singleton_method(mod, "move", move, 4);
}
