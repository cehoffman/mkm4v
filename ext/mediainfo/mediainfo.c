#include <ruby.h>
#include "MediaInfoDLL_Static.h"
#include <ZenLib/CriticalSection.h>

// Since MediaInfo is a C++ library it seems I must protect my ruby
// functions from C++ name mangling
#ifdef __cplusplus
 extern "C" {
#endif

// Needs to be withing extern "C" for linking
#include <ruby/encoding.h>

static ZenLib::CriticalSection CS;

static VALUE rb_cMediaInfo;
static ID general;
static ID video;
static ID audio;
static ID text;
static ID chapters;
static ID image;
static ID menu;
static ID html;
static ID xml;

static VALUE rb_utf8_str(const char *str) {
  return rb_enc_str_new(str, strlen(str), rb_utf8_encoding());
}

static void mediainfo_mark(void *mi) {

}

static void mediainfo_free(void *mi) {
  MediaInfo_Close(mi);
  MediaInfo_Delete(mi);
}

static VALUE mediainfo_alloc(VALUE klass) {
  void *mi = MediaInfo_New();

  return Data_Wrap_Struct(klass, mediainfo_mark, mediainfo_free, mi);
}

static VALUE mediainfo_init(VALUE self, VALUE filename) {
  if (NIL_P(filename)) {
    rb_raise(rb_eArgError, "a filename must be given");
  }

  VALUE name = rb_funcall(filename, rb_intern("to_s"), 0);

  // Make sure the file exists then open it
  if (rb_funcall(rb_cFile, rb_intern("exists?"), 1, name) == Qfalse) {
    rb_raise(rb_eArgError, "file does not exist - %s", RSTRING_PTR(name));
  }

  void *mi;
  Data_Get_Struct(self, void, mi);
  name = rb_funcall(rb_cFile, rb_intern("absolute_path"), 1, name);

  // Convert string to utf8 for mediainfo consumption
  rb_funcall(name, rb_intern("encode!"), 1, rb_const_get(rb_cEncoding, rb_intern("UTF_8")));

  MediaInfo_Open(mi, RSTRING_PTR(name));

  VALUE tracks = rb_hash_new();

  VALUE iter = rb_ary_new();
  rb_ary_push(iter, rb_ary_new3(3, ID2SYM(video), rb_const_get(rb_cMediaInfo, rb_intern("VideoTrack")), ID2SYM(rb_intern("video"))));
  rb_ary_push(iter, rb_ary_new3(3, ID2SYM(audio), rb_const_get(rb_cMediaInfo, rb_intern("AudioTrack")), ID2SYM(rb_intern("audio"))));

  for (int i = RARRAY_LEN(iter) - 1; i >= 0; i--) {
    VALUE vals = rb_ary_entry(iter, i);
    int num = FIX2INT(rb_funcall(self, rb_intern("num_tracks"), 1, rb_ary_entry(vals, 0)));
    VALUE klass = rb_ary_entry(vals, 1);
    VALUE kind = rb_ary_new2(tracks);

    for (int k = 0; k < num; k++) {
      rb_ary_push(kind, rb_funcall(klass, rb_intern("new"), 2, self, INT2FIX(k)));
    }

    rb_hash_aset(tracks, rb_ary_entry(vals, 2), kind);
  }

  rb_ivar_set(self, rb_intern("@tracks"), tracks);

  return self;
}

static VALUE mediainfo_inform(VALUE self, VALUE sym) {
  void *mi;
  Data_Get_Struct(self, void, mi);

  ID kind = -1;

  if (rb_respond_to(sym, rb_intern("to_sym"))) {
    kind = rb_to_id(rb_funcall(sym, rb_intern("to_sym"), 0));
  }

  // Since this has a side effect of changing options
  // It needs to be locked until state is restored
  // Use the ZenLib CriticalSection since it is cross platform
  // and real real real easy to use.
  CS.Enter();
  if (html == kind) {
    MediaInfo_Option(mi, "Inform", "HTML");
  } else if (xml == kind) {
    MediaInfo_Option(mi, "Inform", "XML");
  }

  const char *inform = MediaInfo_Inform(mi, 0);
  MediaInfo_Option(mi, "Inform", "Normal");
  CS.Leave();

  return rb_funcall(rb_utf8_str(inform), rb_intern("gsub!"), 2, rb_utf8_str("\r"), rb_gv_get("$/"));
}

static VALUE mediainfo_to_s(VALUE self) {
  return mediainfo_inform(self, Qnil);
}

static MediaInfo_stream_C get_stream_id(VALUE sym) {
  MediaInfo_stream_C stream = MediaInfo_Stream_Max;
  ID kind = -1;

  if (rb_respond_to(sym, rb_intern("to_sym"))) {
    kind = rb_to_id(rb_funcall(sym, rb_intern("to_sym"), 0));
  }

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
  }

  return stream;
}

static VALUE mediainfo_num_tracks(int argc, VALUE *argv, VALUE self) {
  MediaInfo_stream_C stream;
  int total = 0;
  void *mi;
  Data_Get_Struct(self, void, mi);

  if (argc < 1 || NIL_P(argv[0]) || (stream = get_stream_id(argv[0])) == MediaInfo_Stream_Max) {
    total += MediaInfo_Count_Get(mi, MediaInfo_Stream_General, -1);
    total += MediaInfo_Count_Get(mi, MediaInfo_Stream_Video, -1);
    total += MediaInfo_Count_Get(mi, MediaInfo_Stream_Audio, -1);
    total += MediaInfo_Count_Get(mi, MediaInfo_Stream_Text, -1);
    total += MediaInfo_Count_Get(mi, MediaInfo_Stream_Chapters, -1);
    total += MediaInfo_Count_Get(mi, MediaInfo_Stream_Image, -1);
    total += MediaInfo_Count_Get(mi, MediaInfo_Stream_Menu, -1);
  } else {
    total = MediaInfo_Count_Get(mi, stream, -1);
  }

  return INT2FIX(total);
}

// Type of Track, number of that track type, name of information to get
static VALUE mediainfo_track_info(VALUE self, VALUE sym, VALUE num, VALUE type) {
  Check_Type(type, T_STRING);

  void *mi;
  Data_Get_Struct(self, void, mi);

  return rb_utf8_str(MediaInfo_Get(mi, get_stream_id(sym), FIX2INT(num), RSTRING_PTR(type), MediaInfo_Info_Text, MediaInfo_Info_Name));
}

void Init_mediainfo() {
  // DLL interface option
  MediaInfo_Option(NULL, "CharSet", "UTF-8");

  // MediaInfo likes to connect to the internet, don't let it
  MediaInfo_Option(NULL, "Internet", "No");

  rb_cMediaInfo = rb_define_class("MediaInfo", rb_cObject);
  rb_define_alloc_func(rb_cMediaInfo, mediainfo_alloc);

  // The typecast of the functions is necessary because of the C++ compiler
  rb_define_method(rb_cMediaInfo, "initialize", (VALUE (*)(...))mediainfo_init, 1);
  rb_define_method(rb_cMediaInfo, "to_s", (VALUE (*)(...))mediainfo_to_s, 0);
  rb_define_method(rb_cMediaInfo, "inform", (VALUE (*)(...))mediainfo_inform, 1);
  rb_define_method(rb_cMediaInfo, "num_tracks", (VALUE (*)(...))mediainfo_num_tracks, -1);
  rb_define_method(rb_cMediaInfo, "track_info", (VALUE (*)(...))mediainfo_track_info, 3);

  // Stream types
  general = rb_intern("general");
  video = rb_intern("video");
  audio = rb_intern("audio");
  text = rb_intern("text");
  chapters = rb_intern("chapters");
  image = rb_intern("image");
  menu = rb_intern("menu");

  // Formats for inform
  html = rb_intern("html");
  xml = rb_intern("xml");
}

#ifdef __cplusplus
  }
#endif