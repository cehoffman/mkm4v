#include <ruby.h>
#include "MediaInfoDLL_Static.h"

// Since MediaInfo is a C++ it seems I must protect my ruby
// functions from C++ name mangling
extern "C"
{

static VALUE rb_cMediaInfo;

static void mediainfo_mark(void *mi) {

}

static void mediainfo_free(void *mi) {
  MediaInfo_Close(mi);
  MediaInfo_Delete(mi);
}

static VALUE mediainfo_alloc(VALUE klass) {
  void *mi = MediaInfo_New();
  MediaInfo_Option(mi, "CharSet", "UTF-8");

  return Data_Wrap_Struct(klass, mediainfo_mark, mediainfo_free, mi);
}

static VALUE mediainfo_init(VALUE self, VALUE filename) {
  if (NIL_P(filename)) {
    rb_raise(rb_eTypeError, "a filename must be specified");
  }

  VALUE name = rb_funcall(filename, rb_intern("to_s"), 0);

  // Make sure the file exists then open it
  if (rb_funcall(rb_cFile, rb_intern("exists?"), 1, name) == Qfalse) {
    rb_raise(rb_eTypeError, "file does not exist");
  }

  void *mi;
  Data_Get_Struct(self, void, mi);

  MediaInfo_Open(mi, RSTRING_PTR(name));

  return self;
}

static VALUE mediainfo_to_s(VALUE self) {
  void *mi;
  Data_Get_Struct(self, void, mi);

  return rb_str_new2(MediaInfo_Inform(mi, 0));
}

void Init_mediainfo() {
  rb_cMediaInfo = rb_define_class("MediaInfo", rb_cObject);
  rb_define_alloc_func(rb_cMediaInfo, mediainfo_alloc);

  // The typecast of the functions is necessary because of the C++ compiler
  rb_define_method(rb_cMediaInfo, "initialize", (VALUE (*)(...))mediainfo_init, 1);
  rb_define_method(rb_cMediaInfo, "to_s", (VALUE (*)(...))mediainfo_to_s, 0);
}

}