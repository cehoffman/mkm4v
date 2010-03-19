#include "shared.h"

#ifdef __cplusplus
  extern "C" {
#endif

VALUE rb_cMp4v2, rb_cArtwork, rb_cChapter, rb_cVideo, rb_cAudio, rb_cTrack;

#define MP4_IS_TEXT_TRACK_TYPE(type) (!strcasecmp(type, MP4_TEXT_TRACK_TYPE))

static VALUE ensure_close(MP4V2Handles *handle) {
  if (handle->chapters) {
    free(handle->chapters);
  }
  if (handle->list) {
    MP4ItmfItemListFree(handle->list);
  }
  if (handle->tags) {
    MP4TagsFree(handle->tags);
  }
  if (handle->file && handle->file != MP4_INVALID_FILE_HANDLE) {
    MP4Close(handle->file);
  }

  return handle->self;
}

static VALUE mp4v2_read(MP4V2Handles *handle) {
  VALUE self = handle->self;

  MP4FileHandle mp4v2 = handle->file = MP4Read(RSTRING_PTR(handle->filename));
  if (mp4v2 == MP4_INVALID_FILE_HANDLE) {
    rb_raise(rb_eArgError, "%s is not a valid mp4 file", RSTRING_PTR(handle->filename));
  }

  _mp4v2_metadata_read(handle);

  MP4Chapter_t *chaps = NULL;
  uint32_t count;
  MP4GetChapters(mp4v2, &chaps, &count, MP4ChapterTypeAny);
  handle->chapters = chaps;
  VALUE chapters = rb_ary_new2(count), chapter;
  VALUE rb_cChapter = rb_const_get(rb_cMp4v2, rb_intern("Chapter"));

  MP4Duration sum = 0;
  for (uint32_t i = 0; i < count; i++) {
    chapter = rb_funcall(rb_cChapter, rb_intern("new"), 2, DBL2NUM(sum/1000.0), rb_utf8_str(chaps[i].title));
    rb_ary_push(chapters, chapter);
    sum += chaps[i].duration;
  }
  SET(chapters, chapters);

  MP4Free(chaps);
  handle->chapters = NULL;

  // Generate information for each type of supported track
  count = MP4GetNumberOfTracks(mp4v2);
  MP4TrackId chapter_id = MP4_INVALID_TRACK_ID, track_id;
  for (uint32_t i = 0; i < count; i++) {
    track_id = MP4FindTrackId(mp4v2, i);
    if (MP4HaveTrackAtom(mp4v2, track_id, "tref.chap")) {
      MP4GetTrackIntegerProperty(mp4v2, track_id, "tref.chap.entries.trackId", (uint64_t *)&chapter_id);
      break;
    }
  }

  for (uint32_t i = 0; i < count; i++) {
    track_id = MP4FindTrackId(mp4v2, i);
    const char *type = MP4GetTrackType(mp4v2, track_id);

    if (MP4_IS_AUDIO_TRACK_TYPE(type)) {

    } else if (MP4_IS_VIDEO_TRACK_TYPE(type)) {
      VALUE video = _mp4v2_video_init(mp4v2, track_id);

      SET(video, video);

    } else if (MP4_IS_TEXT_TRACK_TYPE(type) && track_id != chapter_id) {

    }
  }

  MP4Close(mp4v2);
  handle->file = NULL;

  return self;
}

static VALUE mp4v2_reload(VALUE self) {
  VALUE file = GET(file);
  rb_funcall(self, rb_intern("clear"), 0);
  SET(file, file);

  file = rb_funcall(file, rb_intern("to_s"), 0);
  MP4V2Handles handle = { self, file };

  rb_ensure((VALUE (*)(...))mp4v2_read, (VALUE)&handle, (VALUE (*)(...))ensure_close, (VALUE)&handle);

  return self;
}

static VALUE mp4v2_init(VALUE self, VALUE filename) {
  VALUE name = rb_funcall(filename, rb_intern("to_s"), 0);

  // Convert string to abosolute path utf8 for passing to lib
  name = rb_funcall(rb_cFile, rb_intern("absolute_path"), 1, name);
  name = rb_encode_utf8(name);
  rb_call_super(0, NULL);
  SET(file, rb_funcall(rb_const_get(rb_cObject, rb_intern("Pathname")), rb_intern("new"), 1, name));

  MP4V2Handles handle = { self, name };

  rb_ensure((VALUE (*)(...))mp4v2_read, (VALUE)&handle, (VALUE (*)(...))ensure_close, (VALUE)&handle);

  return self;
}

static VALUE mp4v2_optimize(VALUE self) {
  VALUE path = rb_funcall(rb_funcall(self, rb_intern("file"), 0), rb_intern("to_s"), 0);
  VALUE tmppath = rb_str_cat(rb_str_dup(path), ".tmp", 4);

  if (MP4Optimize(RSTRING_PTR(path), RSTRING_PTR(tmppath))) {
    rb_funcall(rb_cFile, rb_intern("rename"), 2, tmppath, path);
  } else {
    rb_raise(rb_eIOError, "there was an error optimizing");
  }

  return Qtrue;
}

static VALUE mp4v2_modify_file(MP4V2Handles *handle) {
  VALUE self = handle->self;

  MP4FileHandle mp4v2 = handle->file = MP4Modify(RSTRING_PTR(handle->filename));
  if (mp4v2 == MP4_INVALID_FILE_HANDLE) {
    rb_raise(rb_eTypeError, "%s is not a valid mp4 file", RSTRING_PTR(handle->filename));
  }

  _mp4v2_metadata_write(handle);

  VALUE chapters = GET(chapters), chapter, title;
  double last_stamp = 0, stamp;
  MP4Chapter_t *chaps;
  uint32_t count = 0;
  switch(TYPE(chapters)) {
    case T_ARRAY:
      RARRAY_ALL_INSTANCE(chapters, rb_cChapter, chapter);

      // Make chapters go in order of timestamp
      rb_funcall(chapters, rb_intern("sort!"), 0);

      count = RARRAY_LEN(chapters);
      chaps = handle->chapters = ALLOC_N(MP4Chapter_t, count);
      for (uint32_t i = 0; i < count; i++) {
        // Calculate the duration of chapter from previous timestamp and current
        chapter = rb_ary_entry(chapters, i);
        stamp = NUM2DBL(rb_ivar_get(rb_ivar_get(chapter, rb_intern("@timestamp")), rb_intern("@seconds"))) * 1000.0;
        chaps[i].duration = stamp - last_stamp;
        last_stamp = stamp;

        // Get the title of the chapter
        title = rb_encode_utf8(rb_ivar_get(chapter, rb_intern("@title")));
        if (RSTRING_LEN(title) > MP4V2_CHAPTER_TITLE_MAX) {
          rb_raise(rb_eStandardError, "chapter title '%s' is too long, it should be at most %d bytes", RSTRING_PTR(title), MP4V2_CHAPTER_TITLE_MAX);
        }

        strncpy(chaps[i].title, RSTRING_PTR(title), RSTRING_LEN(title));
      }

      if (count > 0) {
        MP4SetChapters(mp4v2, chaps, count, MP4ChapterTypeAny);
      } else {
        MP4DeleteChapters(mp4v2, MP4ChapterTypeAny);
      }

      free(chaps);
      handle->chapters = NULL;
      break;
    case T_NIL:
      MP4DeleteChapters(mp4v2, MP4ChapterTypeAny);
      break;
    default:;
  }

  MP4Close(mp4v2);
  handle->file = NULL;

  if (handle->optimize) {
    mp4v2_optimize(self);
  }

  return self;
}

static VALUE mp4v2_save(VALUE self, VALUE args) {
  VALUE path, hash = rb_ary_pop(args);

  if (RARRAY_LEN(args) > 0) {
    path = rb_ary_shift(args);
  } else {
    path = rb_funcall(self, rb_intern("file"), 0);
  }

  path = rb_funcall(path, rb_intern("to_s"), 0);
  MP4V2Handles handle = { self, path, false };

  if (TYPE(hash) == T_HASH && rb_hash_aref(hash, SYM("optimize")) == Qtrue) {
    handle.optimize = true;
  }

  rb_ensure((VALUE (*)(...))mp4v2_modify_file, (VALUE)&handle, (VALUE (*)(...))ensure_close, (VALUE)&handle);

  return path;
}

void Init_mp4v2() {
  rb_cMp4v2 = rb_define_class("Mp4v2", rb_cHash);
  rb_define_method(rb_cMp4v2, "initialize", (VALUE (*)(...))mp4v2_init, 1);
  rb_define_method(rb_cMp4v2, "reload!", (VALUE (*)(...))mp4v2_reload, 0);
  rb_define_method(rb_cMp4v2, "save", (VALUE (*)(...))mp4v2_save, -2);
  rb_define_method(rb_cMp4v2, "optimize!", (VALUE (*)(...))mp4v2_optimize, 0);

  rb_cArtwork = rb_define_class_under(rb_cMp4v2, "Artwork", rb_cObject);
  rb_cChapter = rb_define_class_under(rb_cMp4v2, "Chapter", rb_cObject);
  rb_cVideo = rb_define_class_under(rb_cMp4v2, "Video", rb_cObject);
}

#ifdef __cplusplus
  }
#endif