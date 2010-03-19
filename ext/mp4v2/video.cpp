#include "shared.h"

VALUE _mp4v2_video_init(MP4FileHandle mp4v2, MP4TrackId track_id) {
  VALUE video = rb_class_new_instance(0, NULL, rb_cVideo);

  video = _mp4v2_track_init(video, mp4v2, track_id);

  uint32_t height = MP4GetTrackVideoHeight(mp4v2, track_id);
  uint32_t width = MP4GetTrackVideoWidth(mp4v2, track_id);
  rb_ivar_set(video, rb_intern("@height"), ULONG2NUM(height));
  rb_ivar_set(video, rb_intern("@width"), ULONG2NUM(width));

  return video;
}