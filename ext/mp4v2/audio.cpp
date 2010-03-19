#include "shared.h"

VALUE _mp4v2_audio_init(MP4FileHandle mp4v2, MP4TrackId track_id) {
  VALUE audio = rb_class_new_instance(0, NULL, rb_cAudio);

  audio = _mp4v2_track_init(audio, mp4v2, track_id);

  float volume;
  MP4GetTrackFloatProperty(mp4v2, track_id, "tkhd.volume", &volume);
  rb_ivar_set(audio, rb_intern("@volume"), DBL2NUM(volume));

  rb_ivar_set(audio, rb_intern("@channels"), INT2FIX(MP4GetTrackAudioChannels(mp4v2, track_id)));

  return audio;
}