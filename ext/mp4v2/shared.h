#ifndef SHARED_H_P1QMT0NA
#define SHARED_H_P1QMT0NA

#ifdef __cplusplus
  extern "C" {
#endif

#include <ruby.h>
#include <ruby/encoding.h>
#include <mp4v2/mp4v2.h>

extern VALUE rb_cMp4v2, rb_cArtwork, rb_cChapter, rb_cVideo, rb_cAudio, rb_cTrack;

// Ensure all pointers to allocated objects are at end of
// structure so literal initilizations sets pointers to NULL;
typedef struct MP4V2Handles_s {
  VALUE self;
  VALUE filename;
  bool optimize;
  MP4FileHandle file;
  MP4Tags *tags;
  MP4ItmfItemList *list;
  MP4Chapter_t *chapters;
} MP4V2Handles;

#define SET(attr, val) (rb_funcall(self, rb_intern(#attr "="), 1, val))
#define GET(obj) (rb_funcall(self, rb_intern(#obj), 0))

#define SYM(sym) (ID2SYM(rb_intern(sym)))

#define INSTANCE_OF(obj, klass, name) \
    if (rb_obj_is_instance_of(obj, klass) != Qtrue) { \
      rb_raise(rb_eTypeError, #name " should be an instance of %s", rb_class2name(klass)); \
    }

#define RARRAY_ALL_INSTANCE(array, klass, name) \
  for (int32_t i = RARRAY_LEN(array) - 1; i >= 0; i--) { \
    INSTANCE_OF(rb_ary_entry(array, i), klass, name); \
  }

void _mp4v2_read_metadata(MP4V2Handles *handle);
void _mp4v2_write_metadata(MP4V2Handles *handle);
void _mp4v2_read_chapters(MP4V2Handles *handle);
void _mp4v2_write_chapters(MP4V2Handles *handle);

VALUE _mp4v2_track_init(VALUE self, MP4FileHandle mp4v2, MP4TrackId track_id);
VALUE _mp4v2_video_init(MP4FileHandle mp4v2, MP4TrackId track_id);
VALUE _mp4v2_audio_init(MP4FileHandle mp4v2, MP4TrackId track_id);

extern rb_encoding *utf8_encoding;
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

#ifdef __cplusplus
  }
#endif

#endif /* end of include guard: SHARED_H_P1QMT0NA */
