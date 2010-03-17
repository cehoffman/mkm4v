#include <ruby.h>
#include <mp4v2/mp4v2.h>

#ifdef __cplusplus
  extern "C" {
#endif

#include <ruby/encoding.h>

static VALUE rb_cMp4v2, rb_cArtwork;

#define MP4V2(obj) (Check_Type(obj, T_DATA), (MP4FileHandle)DATA_PTR(obj))

static VALUE mp4v2_artwork_save(VALUE self);

static VALUE rb_utf8_str(const char *str) {
  return rb_enc_str_new(str, strlen(str), rb_utf8_encoding());
}

static VALUE rb_encode_utf8(VALUE str) {
  return rb_funcall(str, rb_intern("encode"), 1, rb_const_get(rb_cEncoding, rb_intern("UTF_8")));
}

#define SET(attr, val) (rb_funcall(self, rb_intern(#attr "="), 1, val))
#define TAG_SET(tag, accessor) if (tags->tag) { SET(accessor, rb_utf8_str(tags->tag)); }
#define TAG_NUM(tag, accessor) if (tags->tag) { SET(accessor, INT2FIX(*tags->tag)); }
#define TAG_BOOL(tag, accessor, truth) \
  if (tags->tag) { \
    rb_ivar_set(self, rb_intern("@" #accessor), *tags->tag == truth ? Qtrue : Qfalse); \
    rb_funcall(self, rb_intern("instance_eval"), 1, rb_utf8_str("def " #accessor "?; @" #accessor " end")); \
  }

#define TAG_DATE(tag, accessor) \
  if (tags->tag) { \
    VALUE date = rb_const_get(rb_cObject, rb_intern("Date")), entry; \
    VALUE parsed = rb_funcall(date, rb_intern("_parse"), 2, rb_utf8_str(tags->tag), Qfalse); \
    parsed = rb_funcall(parsed, rb_intern("values_at"), 8, SYM("year"), SYM("mon"), SYM("mday"), SYM("hour"), SYM("min"), SYM("sec"), SYM("zone"), SYM("sec_fraction")); \
    \
    for (int i = RARRAY_LEN(parsed) - 1; i >= 0; i--) { \
      if (rb_ary_entry(parsed, i) == Qnil) { \
        rb_ary_store(parsed, i, INT2FIX(0)); \
      } \
    } \
    \
    rb_ary_store(parsed, 5, DBL2NUM(NUM2DBL(rb_ary_entry(parsed, 5)) + NUM2DBL(rb_ary_pop(parsed)))); \
    \
    SET(accessor, rb_apply(rb_const_get(rb_cObject, rb_intern("DateTime")), rb_intern("civil"), parsed)); \
  }

#define SYM(sym) (ID2SYM(rb_intern(sym)))

static VALUE mp4v2_init(VALUE self, VALUE filename) {
  if (NIL_P(filename)) {
    rb_raise(rb_eArgError, "a filename must be given");
  }

  VALUE name = rb_funcall(filename, rb_intern("to_s"), 0);

  // Make sure the file exists then open it
  if (rb_funcall(rb_cFile, rb_intern("exists?"), 1, name) == Qfalse) {
    rb_raise(rb_eArgError, "file does not exist - %s", RSTRING_PTR(name));
  }

  // Convert string to abosolute path utf8 for passing to lib
  name = rb_funcall(rb_cFile, rb_intern("absolute_path"), 1, name);
  name = rb_encode_utf8(name);
  rb_call_super(0, NULL);
  SET(file, rb_funcall(rb_const_get(rb_cObject, rb_intern("Pathname")), rb_intern("new"), 1, name));

  MP4FileHandle mp4v2 = MP4Read(RSTRING_PTR(name));
  if (mp4v2 == MP4_INVALID_FILE_HANDLE) {
    rb_raise(rb_eTypeError, "%s is not a valid mp4 file", RSTRING_PTR(name));
  }

  const MP4Tags *tags = MP4TagsAlloc();
  MP4TagsFetch(tags, mp4v2);

  TAG_SET(name, name);
  TAG_SET(artist, artist);
  TAG_SET(albumArtist, album_artist);
  TAG_SET(album, album);
  TAG_SET(grouping, grouping);
  TAG_SET(composer, composer);
  TAG_SET(comments, comments);
  TAG_SET(genre, genre);
  TAG_DATE(releaseDate, released);

  if (tags->track) {
    SET(track, INT2FIX(tags->track->index));
    SET(tracks, INT2FIX(tags->track->total));
  }

  if (tags->disk) {
    SET(disk, INT2FIX(tags->disk->index));
    SET(disks, INT2FIX(tags->disk->total));
  }

  TAG_NUM(tempo, tempo);
  TAG_BOOL(compilation, compilation, 1);
  TAG_SET(tvShow, show);
  TAG_SET(tvEpisodeID, episode_id);
  TAG_NUM(tvSeason, season);
  TAG_NUM(tvEpisode, episode);
  TAG_SET(tvNetwork, network);
  TAG_SET(description, description);
  TAG_SET(longDescription, long_description);
  TAG_SET(lyrics, lyrics);
  TAG_SET(copyright, copyright);
  TAG_SET(encodingTool, encoding_tool);
  TAG_SET(encodedBy, encoded_by);
  TAG_BOOL(podcast, podcast, 1);
  TAG_BOOL(hdVideo, hd, 1);

  if (tags->mediaType) {
    switch(*tags->mediaType) {
      case 0:
        SET(kind, SYM("music"));
        break;
      case 2:
        SET(kind, SYM("audiobook"));
        break;
      case 6:
        SET(kind, SYM("music_video"));
        break;
      case 9:
        SET(kind, SYM("movie"));
        break;
      case 10:
        SET(kind, SYM("tv"));
        break;
      case 11:
        SET(kind, SYM("booklet"));
        break;
      case 14:
        SET(kind, SYM("ringtone"));
        break;
      default:;
    }
  }

  if (tags->contentRating) {
    switch(*tags->contentRating) {
      case 0:
        SET(advisory, SYM("none"));
        break;
      case 2:
        SET(advisory, SYM("clean"));
        break;
      case 4:
        SET(advisory, SYM("explicit"));
        break;
      default:;
    }
  }

  TAG_BOOL(gapless, gapless, 1);

  TAG_DATE(purchaseDate, purchased);
  TAG_SET(iTunesAccount, account);
  TAG_NUM(cnID, cnID);

  // Artwork, need to think on this one
  if (tags->artwork) {
    VALUE regex = rb_funcall(rb_cRegexp, rb_intern("new"), 1, rb_utf8_str("\\.[^\\.]+$"));
    char ext[30];
    VALUE artworks = rb_ary_new(), art;//2(tags->artworkCount), art;

    for (int i = tags->artworkCount - 1; i >= 0; i--) {
      switch(tags->artwork[i].type) {
        case MP4_ART_BMP:
          sprintf(ext, ".%02d.bmp", i+1);
          break;
        case MP4_ART_GIF:
          sprintf(ext, ".%02d.gif", i+1);
          break;
        case MP4_ART_JPEG:
          sprintf(ext, ".%02d.jpg", i+1);
          break;
        case MP4_ART_PNG:
          sprintf(ext, ".%02d.png", i+1);
          break;
        default:
          sprintf(ext, ".%02d.unknown", i+1);
      }

      art = rb_funcall(name, rb_intern("sub"), 2, regex, rb_utf8_str(ext));
      rb_ary_unshift(artworks, art = rb_funcall(rb_cArtwork, rb_intern("new"), 1, art));
      rb_ivar_set(art, rb_intern("@source"), name);
      rb_ivar_set(art, rb_intern("@number"), INT2FIX(i));
      rb_define_singleton_method(art, "save", (VALUE (*)(...))mp4v2_artwork_save, 0);
    }

    SET(artwork, artworks);
  }

  MP4TagsFree(tags);

  MP4Close(mp4v2);

  return self;
}

static VALUE mp4v2_artwork_init(VALUE self, VALUE filename) {
  return self;
}

static VALUE mp4v2_artwork_save(VALUE self) {
  VALUE source = rb_ivar_get(self, rb_intern("@source"));

  if (rb_funcall(rb_cFile, rb_intern("exists?"), 1, source) == Qfalse) {
    rb_raise(rb_eIOError, "file does not exist - %s", RSTRING_PTR(source));
  }

  MP4FileHandle mp4v2 = MP4Read(RSTRING_PTR(source));
  if (mp4v2 == MP4_INVALID_FILE_HANDLE) {
    rb_raise(rb_eTypeError, "%s is not a valid mp4 file", RSTRING_PTR(source));
  }

  VALUE file = rb_funcall(rb_ivar_get(self, rb_intern("@file")), rb_intern("to_s"), 0);
  int number = FIX2INT(rb_ivar_get(self, rb_intern("@number")));

  // All ruby methods have been called so we are clear or exceptions happening in ruby
  const MP4Tags *tags = MP4TagsAlloc();
  MP4TagsFetch(tags, mp4v2);

  if (!tags->artwork || tags->artworkCount <= number) {
    MP4TagsFree(tags);
    MP4Close(mp4v2);
    rb_raise(rb_eStandardError, "this artwork doesn't exist in the source file %s", RSTRING_PTR(source));
  }

  FILE *artwork = fopen(RSTRING_PTR(file), "wb");

  if (!artwork) {
    MP4TagsFree(tags);
    MP4Close(mp4v2);
    rb_raise(rb_eIOError, "unable to open %s", RSTRING_PTR(file));
  }

  fwrite(tags->artwork[number].data, sizeof(uint8_t), tags->artwork[number].size, artwork);
  fclose(artwork);

  MP4TagsFree(tags);
  MP4Close(mp4v2);

  return file;
}

void Init_mp4v2() {
  rb_cMp4v2 = rb_define_class("Mp4v2", rb_const_get(rb_cObject, rb_intern("OpenStruct")));
  rb_define_method(rb_cMp4v2, "initialize", (VALUE (*)(...))mp4v2_init, 1);

  rb_cArtwork = rb_define_class_under(rb_cMp4v2, "Artwork", rb_cObject);
  rb_define_method(rb_cArtwork, "initialize", (VALUE (*)(...))mp4v2_artwork_init, 1);
}

#ifdef __cplusplus
  }
#endif