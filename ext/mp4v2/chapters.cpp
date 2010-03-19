#include "shared.h"

void _mp4v2_read_chapters(MP4V2Handles *handle) {
  VALUE self = handle->self;
  MP4Chapter_t *chaps = NULL;
  uint32_t count;
  MP4GetChapters(handle->file, &chaps, &count, MP4ChapterTypeAny);
  handle->chapters = chaps;
  VALUE chapters = rb_ary_new2(count), chapter;

  MP4Duration sum = 0;
  for (uint32_t i = 0; i < count; i++) {
    chapter = rb_funcall(rb_cChapter, rb_intern("new"), 2, DBL2NUM(sum/1000.0), rb_utf8_str(chaps[i].title));
    rb_ary_push(chapters, chapter);
    sum += chaps[i].duration;
  }
  SET(chapters, chapters);

  MP4Free(chaps);
  handle->chapters = NULL;
}

void _mp4v2_write_chapters(MP4V2Handles *handle) {
  VALUE self = handle->self;
  MP4FileHandle mp4v2 = handle->file;
  VALUE chapters = rb_check_array_type(GET(chapters)), chapter, title;
  double last_stamp = 0, stamp;
  MP4Chapter_t *chaps;
  uint32_t count = 0;

  switch(TYPE(chapters)) {
    case T_ARRAY:
      RARRAY_ALL_INSTANCE(chapters, rb_cChapter, chapter);

      // Make chapters go in order of timestamp
      rb_ary_sort_bang(chapters);

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
}