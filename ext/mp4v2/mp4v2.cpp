#include <ruby.h>
#include <mp4v2/mp4v2.h>

#ifdef __cplusplus
  extern "C" {
#endif

static VALUE rb_cMp4v2;

#define MP4V2(obj) (Check_Type(obj, T_DATA), (MP4FileHandle)DATA_PTR(obj))

static void mp4v2_mark(MP4FileHandle mp4v2) {
  
}

static void mp4v2_free(MP4FileHandle mp4v2) {
  if (mp4v2) {
    MP4Close(mp4v2);
  }
}

static VALUE mp4v2_alloc(VALUE klass) {
  void *mp4v2 = NULL;

  return Data_Wrap_Struct(klass, mp4v2_mark, mp4v2_free, mp4v2);
}

void Init_mp4v2() {
  rb_cMp4v2 = rb_define_class("Mp4v2", rb_cObject);
  rb_define_alloc_func(rb_cMp4v2, mp4v2_alloc);
}

#ifdef __cplusplus
  }
#endif