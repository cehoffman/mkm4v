#include "shared.h"

enum {
  TRACK_DISABLED = 0,
  TRACK_ENABLED,
  TRACK_IN_MOVIE,
  TRACK_INPREVIEW = 4,
  TRACK_IN_POSER = 8
};

VALUE _mp4v2_track_init(VALUE self, MP4FileHandle mp4v2, MP4TrackId track_id) {
  //VALUE self = handle->self;//rb_class_new_instance(0, NULL, rb_cTrack);
  char *tmp;
  if (MP4GetTrackName(mp4v2, track_id, &tmp)) {
    rb_ivar_set(self, rb_intern("@name"), rb_utf8_str(tmp));
    free(tmp);
  }

  if ((tmp = (char *)MP4GetTrackMediaDataName(mp4v2, track_id))) {
    rb_ivar_set(self, rb_intern("@format"), rb_utf8_str(tmp));
  } else {
    rb_ivar_set(self, rb_intern("@formt"), rb_utf8_str("Unknown"));
  }

  uint64_t duration = MP4ConvertFromTrackDuration(mp4v2, track_id, MP4GetTrackDuration(mp4v2, track_id), MP4_MSECS_TIME_SCALE);
  VALUE stamp = rb_const_get(rb_cObject, rb_intern("Timestamp"));
  stamp = rb_funcall(stamp, rb_intern("new"), 1, DBL2NUM(duration/1000.0));
  rb_ivar_set(self, rb_intern("@duration"), stamp);

  uint32_t timescale = MP4GetTrackTimeScale(mp4v2, track_id);
  rb_ivar_set(self, rb_intern("@timescale"), ULONG2NUM(timescale));

  uint32_t bitrate = MP4GetTrackBitRate(mp4v2, track_id);
  rb_ivar_set(self, rb_intern("@bitrate"), ULONG2NUM(bitrate));

  char lang[4];
  if(MP4GetTrackLanguage(mp4v2, track_id, lang)) {
    SET(lang, rb_utf8_str(lang));
  } else {
    SET(lang, rb_utf8_str("und"));
  }

  char *name;
  if (MP4GetTrackName(mp4v2, track_id, &name)) {
    rb_ivar_set(self, rb_intern("@name"), rb_utf8_str(name));
    free(name); // possible leak here if above fails
  } else {
    rb_ivar_set(self, rb_intern("@name"), rb_utf8_str("Unknown"));
  }

  uint64_t flags;
  MP4GetTrackIntegerProperty(mp4v2, track_id, "tkhd.flags", &flags);
  rb_ivar_set(self, rb_intern("@enabled"), (flags & TRACK_ENABLED) ? Qtrue : Qfalse);

  MP4GetTrackIntegerProperty(mp4v2, track_id, "tkhd.alternate_group", &flags);
  rb_ivar_set(self, rb_intern("@group"), ULL2NUM(flags));

  return self;
}