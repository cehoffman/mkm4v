#include <ruby.h>
#include <MediaInfoDLL/MediaInfoDLL_Static.h>
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
static VALUE track_types;
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

static VALUE rb_encode_utf8(VALUE str) {
  return rb_funcall(str, rb_intern("encode"), 1, rb_const_get(rb_cEncoding, rb_intern("UTF_8")));
}

static MediaInfo_stream_C get_stream(ID kind) {
  MediaInfo_stream_C stream = MediaInfo_Stream_Max;

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
  name = rb_encode_utf8(name);

  MediaInfo_Open(mi, RSTRING_PTR(name));

  VALUE tracks = rb_ary_new();
  rb_ivar_set(self, rb_intern("@tracks"), tracks);

  // Go over all the track types that are supported
  // For each one see if there is a class defined of the form
  // track name + Track, e.g. AudioTrack.  If there is for each
  // track of that type create a new instance of that class passing
  // in self and number of track being processed.
  for (int i = RARRAY_LEN(track_types) - 1; i >= 0; i--) {
    VALUE track_type = rb_ary_entry(track_types, i);
    VALUE klass = rb_str_cat(rb_funcall(rb_funcall(track_type, rb_intern("to_s"), 0), rb_intern("capitalize"), 0), "Track", 5);
    VALUE kind = rb_ary_new2(tracks);
    rb_ivar_set(self, rb_to_id(rb_str_concat(rb_utf8_str("@"), rb_funcall(track_type, rb_intern("to_s"), 0))), kind);

    if (rb_funcall(rb_cMediaInfo, rb_intern("const_defined?"), 1, klass) == Qtrue) {
      klass = rb_const_get(rb_cMediaInfo, rb_intern(RSTRING_PTR(klass)));
    } else {
      continue;
    }

    VALUE track;
    int num = MediaInfo_Count_Get(mi, get_stream(SYM2ID(track_type)), -1); // returns 0 on unknown tracks
    for (int k = 0; k < num; k++) {
      track = rb_funcall(klass, rb_intern("new"), 2, self, INT2FIX(k));
      rb_ary_push(tracks, track);
      rb_ary_push(kind, track);
    }
  }

  return self;
}

static VALUE mediainfo_inform(VALUE self, ID kind) {
  void *mi;
  Data_Get_Struct(self, void, mi);

  // Since this has a side effect of changing options
  // It needs to be locked until state is restored
  // Use the ZenLib CriticalSection since it is cross platform
  // and real real real easy to use.
  CS.Enter();

  if (html == kind) {
    MediaInfo_Option(mi, "Inform", "HTML");
  } else if (xml == kind) {
    MediaInfo_Option(mi, "Inform", "XML");
  } else {
    MediaInfo_Option(mi, "Inform", "Normal");
  }

  const char *inform = MediaInfo_Inform(mi, 0);

  CS.Leave();

  return rb_funcall(rb_utf8_str(inform), rb_intern("gsub"), 2, rb_utf8_str("\r"), rb_gv_get("$/"));
}

static VALUE mediainfo_to_html(VALUE self) {
  return mediainfo_inform(self, html);
}

static VALUE mediainfo_to_xml(VALUE self) {
  return mediainfo_inform(self, xml);
}

static VALUE mediainfo_to_s(VALUE self) {
  return mediainfo_inform(self, NULL);
}

// Type of Track, number of that track type, name of information to get
static VALUE mediainfo_track_info(VALUE self, VALUE stream, VALUE num, VALUE type) {
  if (TYPE(type) != T_STRING && TYPE(type) != T_FIXNUM) {
    rb_raise(rb_eTypeError, "'%s' should be a string or fixnum", RSTRING_PTR(rb_funcall(type, rb_intern("to_s"), 0)));
  }

  void *mi;
  Data_Get_Struct(self, void, mi);

  if (TYPE(stream) != T_SYMBOL && rb_respond_to(stream, rb_intern("to_sym"))) {
    stream = rb_funcall(stream, rb_intern("to_sym"), 0);
  }

  if (rb_funcall(track_types, rb_intern("include?"), 1, stream) == Qfalse) {
    rb_raise(rb_eArgError, "'%s' is not a valid stream", RSTRING_PTR(rb_funcall(stream, rb_intern("to_s"), 0)));
  }

  if (TYPE(type) == T_FIXNUM) {
    return rb_utf8_str(MediaInfo_GetI(mi, get_stream(SYM2ID(stream)), FIX2INT(num), FIX2INT(type), MediaInfo_Info_Text));
  } else {
    return rb_utf8_str(MediaInfo_Get(mi, get_stream(SYM2ID(stream)), FIX2INT(num), RSTRING_PTR(type), MediaInfo_Info_Text, MediaInfo_Info_Name));
  }
}

static VALUE set_options(void *mi, int argc, VALUE *args) {
  VALUE normalized = rb_ary_new2(argc);

  for (int i = 0; i < argc; i++) {
    rb_ary_push(normalized, args[i]);
  }

  normalized = rb_funcall(rb_funcall(normalized, rb_intern("flatten"), 0), rb_intern("compact"), 0);

  VALUE arg = Qnil;

  if (RARRAY_LEN(normalized) > 0) {
    arg = rb_ary_entry(normalized, 0);
  }

  // If it is a hash we are setting options
  if (rb_obj_is_instance_of(arg, rb_cHash) == Qtrue) {
    VALUE keys = rb_funcall(arg, rb_intern("keys"), 0);
    VALUE vals = rb_funcall(arg, rb_intern("values"), 0);
    VALUE opt, val;

    for (int i = RARRAY_LEN(keys) - 1; i >= 0; i--) {
      opt = rb_funcall(rb_ary_entry(keys, i), rb_intern("to_s"), 0);
      val = rb_funcall(rb_ary_entry(vals, i), rb_intern("to_s"), 0);
      MediaInfo_Option(mi, RSTRING_PTR(rb_encode_utf8(opt)), RSTRING_PTR(rb_encode_utf8(val)));
    }
  } else { // otherwise we are going to read options
    VALUE vals = rb_hash_new();
    VALUE opt, val;

    for (int i = RARRAY_LEN(normalized) - 1; i >= 0; i--) {
      opt = rb_encode_utf8(rb_funcall(rb_ary_entry(normalized, i), rb_intern("to_s"), 0));
      val = rb_utf8_str(MediaInfo_Option(mi, RSTRING_PTR(opt), ""));
      rb_hash_aset(vals, opt, rb_funcall(val, rb_intern("gsub"), 2, rb_utf8_str("\r"), rb_gv_get("$/")));
    }

    return vals;
  }

  return arg;
}

static VALUE mediainfo_options(int argc, VALUE *args, VALUE self) {
  void *mi;
  Data_Get_Struct(self, void, mi);
  return set_options(mi, argc, args);
}

static VALUE mediainfo_static_options(int argc, VALUE *args, VALUE self) {
  return set_options(NULL, argc, args);
}

void Init_mediainfo() {
  // DLL interface option
  MediaInfo_Option(NULL, "CharSet", "UTF-8");

  // MediaInfo likes to connect to the internet, don't let it
  MediaInfo_Option(NULL, "Internet", "No");

  // Tell MediaInfo about us, this will let us know of incompatibilities in
  // future versions when upgrading
  if (strlen(MediaInfo_Option(NULL, "Info_Version", "0.7.29;RubyBinding;0.1.0")) == 0) {
    rb_fatal("The compiled versions of MediaInfo is not compatible with the ruby bindings");
  }

  rb_cMediaInfo = rb_define_class("MediaInfo", rb_cObject);
  rb_define_alloc_func(rb_cMediaInfo, mediainfo_alloc);

  // The typecast of the functions is necessary because of the C++ compiler
  rb_define_method(rb_cMediaInfo, "initialize", (VALUE (*)(...))mediainfo_init, 1);
  rb_define_method(rb_cMediaInfo, "to_s", (VALUE (*)(...))mediainfo_to_s, 0);
  rb_define_method(rb_cMediaInfo, "to_html", (VALUE (*)(...))mediainfo_to_html, 0);
  rb_define_method(rb_cMediaInfo, "to_xml", (VALUE (*)(...))mediainfo_to_xml, 0);
  rb_define_method(rb_cMediaInfo, "track_info", (VALUE (*)(...))mediainfo_track_info, 3);
  rb_define_method(rb_cMediaInfo, "options", (VALUE (*)(...))mediainfo_options, -1);
  rb_define_singleton_method(rb_cMediaInfo, "options", (VALUE (*)(...))mediainfo_static_options, -1);

  // Define an accessor for the tracks
  rb_funcall(rb_cMediaInfo, rb_intern("attr_reader"), 1, ID2SYM(rb_intern("tracks")));

  // Stream types
  general = rb_intern("general");
  video = rb_intern("video");
  audio = rb_intern("audio");
  text = rb_intern("text");
  chapters = rb_intern("chapters");
  image = rb_intern("image");
  menu = rb_intern("menu");

  track_types = rb_ary_new3(7, ID2SYM(general), ID2SYM(video), ID2SYM(audio), ID2SYM(text), ID2SYM(chapters), ID2SYM(image), ID2SYM(menu));
  rb_define_const(rb_cMediaInfo, "TrackTypes", track_types);
  rb_apply(rb_cMediaInfo, rb_intern("attr_reader"), track_types);

  // Formats for inform
  html = rb_intern("html");
  xml = rb_intern("xml");
}

#ifdef __cplusplus
  }
#endif