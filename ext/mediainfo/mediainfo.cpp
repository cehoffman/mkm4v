#include <ruby.h>
#include <MediaInfoDLL/MediaInfoDLL_Static.h>
#include <ZenLib/CriticalSection.h>

// Since MediaInfo is a C++ library it seems I must protect my ruby
// functions from C++ name mangling
#ifdef __cplusplus
 extern "C" {
#endif

// Needs to be within extern "C" for linking
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

#define MEDIAINFO(obj) (Check_Type(obj, T_DATA), (void *)DATA_PTR(obj))

rb_encoding *utf8_encoding = rb_utf8_encoding();
inline VALUE rb_utf8_str(const char *str) {
  return rb_enc_str_new(str, strlen(str), utf8_encoding);
}

#define UTF8_P(_obj) (ENC_TO_ENCINDEX(rb_enc_get(_obj)) == ENC_TO_ENCINDEX(utf8_encoding))
inline VALUE rb_encode_utf8(VALUE str) {
  if (!UTF8_P(str)) {
    str = rb_str_export_to_enc(str, utf8_encoding);
  }
  return str;
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
  void *mi = MEDIAINFO(self);
  VALUE name = rb_encode_utf8(rb_file_absolute_path(StringValue(filename), Qnil));

  if (!MediaInfo_Open(mi, RSTRING_PTR(name))) {
    rb_raise(rb_eIOError, "unable to open file - %s", RSTRING_PTR(name));
  }

  VALUE tracks = rb_ary_new();
  rb_ivar_set(self, rb_intern("@tracks"), tracks);

  // Go over all the track types that are supported
  // For each one see if there is a class defined of the form
  // track name + Track, e.g. AudioTrack.  If there is for each
  // track of that type create a new instance of that class passing
  // in self and number of track being processed.
  for (int i = RARRAY_LEN(track_types) - 1; i >= 0; i--) {
    VALUE track_type = rb_funcall(rb_ary_entry(track_types, i), rb_intern("to_s"), 0);
    VALUE klass = rb_str_cat(rb_funcall(track_type, rb_intern("capitalize"), 0), "Track", 5);
    VALUE kind = rb_ary_new();
    rb_ivar_set(self, rb_to_id(rb_str_concat(rb_utf8_str("@"), track_type)), kind);

    if (rb_const_defined(rb_cMediaInfo, rb_to_id(klass))) {
      klass = rb_const_get(rb_cMediaInfo, rb_intern(RSTRING_PTR(klass)));
    } else {
      continue;
    }

    VALUE track;
    int num = MediaInfo_Count_Get(mi, get_stream(rb_intern_str(track_type)), -1); // returns 0 on unknown tracks
    for (int k = 0; k < num; k++) {
      track = rb_funcall(klass, rb_intern("new"), 2, self, INT2FIX(k));
      rb_ary_push(tracks, track);
      rb_ary_push(kind, track);
    }
  }

  return self;
}

static VALUE mediainfo_inform(VALUE self, ID kind) {
  void *mi = MEDIAINFO(self);

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

  return rb_funcall(rb_funcall(rb_utf8_str(inform), rb_intern("gsub"), 2, rb_utf8_str("\r"), rb_gv_get("$/")), rb_intern("strip!"), 0);
}

static VALUE mediainfo_to_html(VALUE self) {
  return mediainfo_inform(self, html);
}

static VALUE mediainfo_to_xml(VALUE self) {
  VALUE str = rb_str_buf_new2("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
  rb_str_buf_cat2(str, RSTRING_PTR(rb_gv_get("$/")));
  rb_str_buf_cat2(str, "<Mediainfo version=\"0.7.55\">");
  rb_str_buf_cat2(str, RSTRING_PTR(rb_gv_get("$/")));
  rb_enc_associate(str, utf8_encoding);

  rb_str_buf_append(str, mediainfo_inform(self, xml));

  rb_str_buf_cat2(str, RSTRING_PTR(rb_gv_get("$/")));
  rb_str_buf_cat2(str, "</Mediainfo>");

  return str;
}

static VALUE mediainfo_to_s(VALUE self) {
  return mediainfo_inform(self, NULL);
}

// Type of Track, number of that track type, name of information to get
static VALUE mediainfo_track_info(int argc, VALUE *args, VALUE self) {
  if (argc < 3) {
    rb_raise(rb_eArgError, "wrong number of arguments(%d for 3 or 4)", argc);
  }

  VALUE stream = args[0], num = args[1], type = args[2];

  if (TYPE(type) != T_STRING && TYPE(type) != T_FIXNUM) {
    rb_raise(rb_eTypeError, "'%s' should be a string or fixnum", RSTRING_PTR(rb_funcall(type, rb_intern("inspect"), 0)));
  }

  if (TYPE(stream) != T_SYMBOL && rb_respond_to(stream, rb_intern("to_sym"))) {
    stream = rb_funcall(stream, rb_intern("to_sym"), 0);
  }

  if (rb_ary_includes(track_types, stream) == Qfalse) {
    rb_raise(rb_eArgError, "'%s' is not a valid stream", RSTRING_PTR(rb_funcall(stream, rb_intern("inspect"), 0)));
  }

  MediaInfo_info_C info = MediaInfo_Info_Text;
  if (argc >= 4) {
    ID get_info = rb_to_id(args[3]);
    if (rb_intern("name") == get_info) {
      info = MediaInfo_Info_Name;
    } else if (rb_intern("option") == get_info) {
      info = MediaInfo_Info_Options;
    } else if (rb_intern("measure") == get_info) {
      info = MediaInfo_Info_Measure;
    } else if (rb_intern("info") == get_info) {
      info = MediaInfo_Info_Info;
    } else if (rb_intern("howto") == get_info) {
      info = MediaInfo_Info_HowTo;
    }
  }

  if (TYPE(type) == T_FIXNUM) {
    return rb_utf8_str(MediaInfo_GetI(MEDIAINFO(self), get_stream(SYM2ID(stream)), FIX2INT(num), FIX2INT(type), info));
  } else {
    return rb_utf8_str(MediaInfo_Get(MEDIAINFO(self), get_stream(SYM2ID(stream)), FIX2INT(num), RSTRING_PTR(type), info, MediaInfo_Info_Name));
  }
}

static VALUE set_options(void *mi, VALUE args) {
  VALUE normalized = rb_funcall(args, rb_intern("compact"), 0);

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
      opt = rb_ary_entry(keys, i);
      val = rb_ary_entry(vals, i);
      MediaInfo_Option(mi, RSTRING_PTR(rb_encode_utf8(StringValue(opt))), RSTRING_PTR(rb_encode_utf8(StringValue(val))));
    }
  } else { // otherwise we are going to read options
    VALUE vals = rb_hash_new();
    VALUE opt, val;

    for (int i = RARRAY_LEN(normalized) - 1; i >= 0; i--) {
      opt = rb_ary_entry(normalized, i);
      opt = rb_encode_utf8(StringValue(opt));
      val = rb_utf8_str(MediaInfo_Option(mi, RSTRING_PTR(opt), ""));
      rb_hash_aset(vals, opt, rb_funcall(val, rb_intern("gsub"), 2, rb_utf8_str("\r"), rb_gv_get("$/")));
    }

    return vals;
  }

  return arg;
}

static VALUE mediainfo_options(VALUE self, VALUE args) {
  return set_options(MEDIAINFO(self), args);
}

static VALUE mediainfo_static_options(VALUE self, VALUE args) {
  return set_options(NULL, args);
}

static VALUE mediainfo_open(VALUE self) {
  VALUE file = rb_funcall(self, rb_intern("file"), 0);
  file = rb_encode_utf8(StringValue(file));
  if (!MediaInfo_Open(MEDIAINFO(self), RSTRING_PTR(file))) {
    rb_raise(rb_eIOError, "unable to open file - %s", RSTRING_PTR(file));
  }

  return self;
}

static VALUE mediainfo_close(VALUE self) {
  MediaInfo_Close(MEDIAINFO(self));
  return self;
}

void Init_mediainfo() {
  // DLL interface option
  MediaInfo_Option(NULL, "CharSet", "UTF-8");

  // MediaInfo likes to connect to the internet, don't let it
  MediaInfo_Option(NULL, "Internet", "No");

  // Tell MediaInfo about us, this will let us know of incompatibilities in
  // future versions when upgrading
  if (strlen(MediaInfo_Option(NULL, "Info_Version", "0.7.55;RubyBinding;0.1.0")) == 0) {
    rb_fatal("The compiled versions of MediaInfo is not compatible with the ruby bindings");
  }

  rb_cMediaInfo = rb_define_class("MediaInfo", rb_cObject);
  rb_define_alloc_func(rb_cMediaInfo, mediainfo_alloc);

  // The typecast of the functions is necessary because of the C++ compiler
  rb_define_method(rb_cMediaInfo, "initialize", (VALUE (*)(...))mediainfo_init, 1);
  rb_define_method(rb_cMediaInfo, "to_s", (VALUE (*)(...))mediainfo_to_s, 0);
  rb_define_method(rb_cMediaInfo, "to_html", (VALUE (*)(...))mediainfo_to_html, 0);
  rb_define_method(rb_cMediaInfo, "to_xml", (VALUE (*)(...))mediainfo_to_xml, 0);
  rb_define_method(rb_cMediaInfo, "track_info", (VALUE (*)(...))mediainfo_track_info, -1);
  rb_define_method(rb_cMediaInfo, "options", (VALUE (*)(...))mediainfo_options, -2);
  rb_define_method(rb_cMediaInfo, "open", (VALUE (*)(...))mediainfo_open, 0);
  rb_define_method(rb_cMediaInfo, "close", (VALUE (*)(...))mediainfo_close, 0);
  rb_define_singleton_method(rb_cMediaInfo, "options", (VALUE (*)(...))mediainfo_static_options, -2);

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
