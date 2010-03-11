#include <ruby.h>
#include "MediaInfoDLL_Static.h"

// Since MediaInfo is a C++ it seems I must protect my ruby
// functions from C++ name mangling
extern "C"
{

static VALUE rb_cMediaInfo;
static ID general;
static ID video;
static ID audio;
static ID text;
static ID chapters;
static ID image;
static ID menu;
static ID max;

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

static MediaInfo_stream_C get_stream_id(VALUE sym) {
  MediaInfo_stream_C stream;
  ID kind = rb_to_id(sym);

  if (kind == general) {
    stream = MediaInfo_Stream_General;
  } else if (kind == video) {
    stream = MediaInfo_Stream_Video;
  } else if (kind == audio) {
    stream = MediaInfo_Stream_Audio;
  } else if (kind == text) {
    stream = MediaInfo_Stream_Text;
  } else if (kind == chapters) {
    stream = MediaInfo_Stream_Chapters;
  } else if (kind == image) {
    stream = MediaInfo_Stream_Image;
  } else if (kind == menu) {
    stream = MediaInfo_Stream_Menu;
  } else {
    stream = MediaInfo_Stream_Max;
  }

  return stream;
}

static VALUE mediainfo_tracks(VALUE self, VALUE sym) {
  void *mi;
  Data_Get_Struct(self, void, mi);

  return INT2FIX(MediaInfo_Count_Get(mi, get_stream_id(sym), -1));
}

static VALUE mediainfo_track_info(VALUE self, VALUE sym, VALUE num, VALUE type, VALUE kind) {
  Check_Type(type, T_STRING);

  void *mi;
  Data_Get_Struct(self, void, mi);

  VALUE hash = rb_hash_new();
  ID info = rb_to_id(kind);
  MediaInfo_info_C info_kind;
  MediaInfo_stream_C stream = get_stream_id(sym);
  int stream_id = FIX2INT(num);
  int pos = MediaInfo_Count_Get(mi, stream, stream_id);

  if (rb_intern("name") == info) {
    info_kind = MediaInfo_Info_Name;
  } else if (rb_intern("text") == info) {
    info_kind = MediaInfo_Info_Text;
  } else if (rb_intern("measure") == info) {
    info_kind = MediaInfo_Info_Measure;
  } else if (rb_intern("options") == info) {
    info_kind = MediaInfo_Info_Options;
  } else if (rb_intern("name_text") == info) {
    info_kind = MediaInfo_Info_Name_Text;
  } else if (rb_intern("measure_text") == info) {
    info_kind = MediaInfo_Info_Measure_Text;
  } else if (rb_intern("info") == info) {
    info_kind = MediaInfo_Info_Info;
  } else {
    info_kind = MediaInfo_Info_HowTo;
  }

  rb_hash_aset(hash, rb_funcall(rb_funcall(type, rb_intern("downcase"), 0), rb_intern("to_sym"), 0), rb_str_new2(MediaInfo_Get(mi, stream, stream_id, RSTRING_PTR(type), info_kind, (MediaInfo_info_C)0)));

  return hash;
}

void Init_mediainfo() {
  rb_cMediaInfo = rb_define_class("MediaInfo", rb_cObject);
  rb_define_alloc_func(rb_cMediaInfo, mediainfo_alloc);

  // The typecast of the functions is necessary because of the C++ compiler
  rb_define_method(rb_cMediaInfo, "initialize", (VALUE (*)(...))mediainfo_init, 1);
  rb_define_method(rb_cMediaInfo, "to_s", (VALUE (*)(...))mediainfo_to_s, 0);
  rb_define_method(rb_cMediaInfo, "tracks", (VALUE (*)(...))mediainfo_tracks, 1);
  rb_define_method(rb_cMediaInfo, "track_info", (VALUE (*)(...))mediainfo_track_info, 4);

  // Stream types
  general = rb_intern("general");
  video = rb_intern("video");
  audio = rb_intern("audio");
  text = rb_intern("text");
  chapters = rb_intern("chapters");
  image = rb_intern("image");
  menu = rb_intern("menu");
}

}