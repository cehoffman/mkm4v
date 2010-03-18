#include <ruby.h>
#include <mp4v2/mp4v2.h>

#ifdef __cplusplus
  extern "C" {
#endif

#include <ruby/encoding.h>

static VALUE rb_cMp4v2, rb_cArtwork;

#define MP4V2(obj) (Check_Type(obj, T_DATA), (MP4FileHandle)DATA_PTR(obj))

static VALUE mp4v2_artwork_save(VALUE self);
static VALUE mp4v2_artwork_data(VALUE self);

static inline VALUE rb_utf8_str(const char *str) {
  return rb_enc_str_new(str, strlen(str), rb_utf8_encoding());
}

static inline VALUE rb_encode_utf8(VALUE str) {
  return rb_funcall(str, rb_intern("encode"), 1, rb_const_get(rb_cEncoding, rb_intern("UTF_8")));
}

#define SET(attr, val) (rb_funcall(self, rb_intern(#attr "="), 1, val))
#define TAG_SET(tag, accessor) if (tags->tag) { SET(accessor, rb_utf8_str(tags->tag)); }
#define TAG_NUM(tag, accessor) if (tags->tag) { SET(accessor, INT2FIX(*tags->tag)); }
#define TAG_TOTAL(tag, idx, max) \
  if (tags->tag) { \
    SET(idx, INT2FIX(tags->tag->index)); \
    SET(max, INT2FIX(tags->tag->total)); \
  }
#define TAG_BOOL(tag, accessor, truth) \
  if (tags->tag) { \
    SET(accessor, *tags->tag == truth ? Qtrue : Qfalse); \
  } \
  rb_funcall(self, rb_intern("instance_eval"), 1, rb_utf8_str("def " #accessor "?; !!self." #accessor " end"));

#define TAG_DATE(tag, accessor) \
  if (tags->tag) { \
    VALUE date = rb_const_get(rb_cObject, rb_intern("Date")); \
    VALUE parsed = rb_funcall(date, rb_intern("_parse"), 2, rb_utf8_str(tags->tag), Qfalse); \
    \
    if (!RHASH_EMPTY_P(parsed)) { \
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
    } \
  }

#define TAG_PEOPLE(tag, accessor) \
  if ((val = rb_hash_aref(info, rb_utf8_str(#tag))) != Qnil) {\
    VALUE arr = rb_ary_new2(RARRAY_LEN(val)), key = rb_utf8_str("name");\
    for (int i = RARRAY_LEN(val) - 1; i >= 0; i--) {\
      rb_ary_unshift(arr, rb_hash_aref(rb_ary_entry(val, i), key));\
    } \
    \
    SET(accessor, arr); \
  } else { \
    SET(accessor, rb_ary_new()); \
  }

#define GET(obj) (rb_funcall(self, rb_intern(#obj), 0))
#define MODIFY(func, val) (MP4TagsSet ## func(tags, val))
#define MODIFY_STR(func, accessor) \
  { \
    VALUE data = GET(accessor); \
    if (data != Qnil) { \
      MODIFY(func, RSTRING_PTR(data)); \
    } else { \
      MODIFY(func, NULL); \
    } \
  }
#define MODIFY_NUMBITS(func, accessor, bits) \
  if (GET(accessor) != Qnil) { \
    uint ## bits ##_t num = (uint ## bits ##_t)NUM2LONG(GET(accessor)); \
    MODIFY(func, &num); \
  } else { \
    MODIFY(func, NULL); \
  }
#define MODIFY_NUM16(func, accessor) MODIFY_NUMBITS(func, accessor, 16)
#define MODIFY_NUM32(func, accessor) MODIFY_NUMBITS(func, accessor, 32)
#define MODIFY_NUM64(func, accessor) MODIFY_NUMBITS(func, accessor, 64)
#define MODIFY_NUM(...) MODIFY_NUM32(__VA_ARGS__)

#define MODIFY_TOTAL(func, idx, max) \
  { \
    VALUE index = rb_funcall(self, rb_intern(#idx), 0); \
    VALUE total = rb_funcall(self, rb_intern(#max), 0); \
    if (index != Qnil || total != Qnil) { \
      MP4Tag##func track; \
      \
      track.index = (index != Qnil) ? FIX2INT(index) : 0; \
      track.total = (total != Qnil) ? FIX2INT(total) : 0; \
      \
      MODIFY(func, &track); \
    } else { \
      MODIFY(func, NULL); \
    } \
  }

#define MODIFY_BOOL(func, accessor) \
  if (rb_funcall(self, rb_intern(#accessor "?"), 0) == Qtrue) { \
    uint8_t truth = 1; \
    MODIFY(func, &truth); \
  } else { \
    MODIFY(func, NULL); \
  }
#define MODIFY_DATE(func, accessor) \
  { \
    VALUE date = GET(accessor), rb_cDateTime = rb_const_get(rb_cObject, rb_intern("DateTime")); \
    if (rb_obj_is_kind_of(date, rb_cDateTime) == Qtrue) { \
      MODIFY(func, RSTRING_PTR(rb_funcall(date, rb_intern("strftime"), 1, rb_utf8_str("%Y-%m-%dT%H:%M:%SZ")))); \
    } else if (date == Qnil) { \
      MODIFY(func, NULL); \
    } else { \
      rb_raise(rb_eTypeError, #accessor " should be an instance of DateTime or nil"); \
    } \
  }
#define MODIFY_PEOPLE(tag, list) \
  if (TYPE(list) == T_ARRAY && RARRAY_LEN(list) > 0) { \
    VALUE key = rb_utf8_str("name"); \
    \
    for (int32_t i = RARRAY_LEN(list) - 1; i >= 0; i--) { \
      VALUE hash = rb_hash_new(), name = rb_ary_pop(list); \
      Check_Type(name, T_STRING); \
      rb_hash_aset(hash, key, name); \
      rb_ary_unshift(list, hash); \
    } \
    \
    rb_hash_aset(plist, rb_utf8_str(#tag), list); \
  }

#define SYM(sym) (ID2SYM(rb_intern(sym)))

typedef struct MP4V2Handles_s {
  VALUE self;
  VALUE filename;
  bool optimize;
  MP4FileHandle file;
  MP4Tags *tags;
  MP4ItmfItemList *list;
} MP4V2Handles;

static VALUE ensure_close(MP4V2Handles *handle) {
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

static VALUE mp4v2_read_metadata(MP4V2Handles *handle) {
  VALUE self = handle->self;

  MP4FileHandle mp4v2 = handle->file = MP4Read(RSTRING_PTR(handle->filename));
  if (mp4v2 == MP4_INVALID_FILE_HANDLE) {
    rb_raise(rb_eArgError, "%s is not a valid mp4 file", RSTRING_PTR(handle->filename));
  }

  handle->tags = (MP4Tags*)MP4TagsAlloc();
  const MP4Tags *tags = handle->tags;
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
  TAG_TOTAL(track, track, tracks);
  TAG_TOTAL(disk, disk, disks);
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
      case 1:
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
  TAG_NUM(atID, atID);
  TAG_NUM(plID, plID);
  TAG_NUM(geID, geID);

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

      art = rb_funcall(handle->filename, rb_intern("sub"), 2, regex, rb_utf8_str(ext));
      rb_ary_unshift(artworks, art = rb_funcall(rb_cArtwork, rb_intern("new"), 1, art));
      rb_ivar_set(art, rb_intern("@source"), handle->filename);
      rb_ivar_set(art, rb_intern("@number"), INT2FIX(i));
      rb_define_singleton_method(art, "save", (VALUE (*)(...))mp4v2_artwork_save, 0);
      rb_define_singleton_method(art, "data", (VALUE (*)(...))mp4v2_artwork_data, 0);
    }

    SET(artwork, artworks);
  }

  // Rating information
  MP4ItmfItemList *ratings = handle->list = MP4ItmfGetItemsByMeaning(mp4v2, "com.apple.iTunes", "iTunEXTC");
  if (ratings && ratings->size > 0 && ratings->elements->dataList.size > 0) {
    MP4ItmfData *data = &ratings->elements->dataList.elements[0];

    VALUE rating = rb_funcall(self, rb_intern("rating_from_itmf"), 1, rb_enc_str_new((const char*)data->value, data->valueSize, rb_utf8_encoding()));

    if (rating != Qnil) {
      SET(rating, rating);
    }

    MP4ItmfItemListFree(ratings);
    handle->list = NULL;
  }

  MP4ItmfItemList *plist = handle->list = MP4ItmfGetItemsByMeaning(mp4v2, "com.apple.iTunes", "iTunMOVI");
  if (plist && plist->size > 0 && plist->elements->dataList.size > 0) {
    MP4ItmfData *data = &plist->elements->dataList.elements[0];
    VALUE rb_cPlist = rb_const_get(rb_cObject, rb_intern("Plist")), val;

    if (rb_cPlist != Qnil) {
      VALUE info = rb_funcall(rb_cPlist, rb_intern("parse_xml"), 1, rb_enc_str_new((const char*)data->value, data->valueSize, rb_utf8_encoding()));

      TAG_PEOPLE(cast, cast);
      TAG_PEOPLE(directors, directors);
      TAG_PEOPLE(codirectors, codirectors);
      TAG_PEOPLE(producers, producers);
      TAG_PEOPLE(screenwriters, writers);
    }

    MP4ItmfItemListFree(plist);
    handle->list = NULL;
  }

  MP4TagsFree(tags);
  handle->tags = NULL;

  MP4Close(mp4v2);
  handle->file = NULL;

  return self;
}

static VALUE mp4v2_init(VALUE self, VALUE filename) {
  VALUE name = rb_funcall(filename, rb_intern("to_s"), 0);

  // Convert string to abosolute path utf8 for passing to lib
  name = rb_funcall(rb_cFile, rb_intern("absolute_path"), 1, name);
  name = rb_encode_utf8(name);
  rb_call_super(0, NULL);
  SET(file, rb_funcall(rb_const_get(rb_cObject, rb_intern("Pathname")), rb_intern("new"), 1, name));

  MP4V2Handles handle;
  handle.self = self;
  handle.filename = name;
  handle.file = NULL;
  handle.tags = NULL;
  handle.list = NULL;

  rb_ensure((VALUE (*)(...))mp4v2_read_metadata, (VALUE)&handle, (VALUE (*)(...))ensure_close, (VALUE)&handle);

  return self;
}

// static VALUE mp4v2_artwork_init(VALUE self, VALUE filename) {
//   return self;
// }

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

  handle->tags = (MP4Tags*)MP4TagsAlloc();
  const MP4Tags *tags = handle->tags;
  MP4TagsFetch(tags, mp4v2);

  MODIFY_STR(Name, name);
  MODIFY_STR(Artist, artist);
  MODIFY_STR(AlbumArtist, album_artist);
  MODIFY_STR(Album, album);
  MODIFY_STR(Grouping, grouping);
  MODIFY_STR(Composer, composer);
  MODIFY_STR(Comments, comments);
  MODIFY_STR(Genre, genre);
  MODIFY_DATE(ReleaseDate, released);
  MODIFY_TOTAL(Track, track, tracks);
  MODIFY_TOTAL(Disk, disk, disks);
  MODIFY_NUM16(Tempo, tempo);
  MODIFY_BOOL(Compilation, compilation);
  MODIFY_STR(TVShow, show);
  MODIFY_STR(TVEpisodeID, episode_id);
  MODIFY_NUM(TVSeason, season);
  MODIFY_NUM(TVEpisode, episode);
  MODIFY_STR(TVNetwork, network);
  MODIFY_STR(Description, description);
  MODIFY_STR(LongDescription, long_description);
  MODIFY_STR(Lyrics, lyrics);
  MODIFY_STR(Copyright, copyright);
  MODIFY_STR(EncodingTool, encoding_tool);
  MODIFY_STR(EncodedBy, encoded_by);
  MODIFY_BOOL(Podcast, podcast);
  MODIFY_BOOL(HDVideo, hd);

  VALUE index = GET(kind);
  uint8_t type = NULL;
  if (index == SYM("music")) {
    type = 1;
  } else if (index == SYM("audiobook")) {
    type = 2;
  } else if (index == SYM("music_video")) {
    type = 6;
  } else if (index == SYM("movie")) {
    type = 9;
  } else if (index == SYM("tv")) {
    type = 10;
  } else if (index == SYM("booklet")) {
    type = 11;
  } else if (index == SYM("ringtone")) {
    type = 14;
  }
  MODIFY(MediaType, &type);

  index = GET(advisory);
  type = NULL;
  if (index == SYM("none")) {
    type = 0;
  } else if (index == SYM("clean")) {
    type = 2;
  } else if (index == SYM("explicit")) {
    type = 4;
  }
  MODIFY(ContentRating, &type);

  MODIFY_BOOL(Gapless, gapless);

  MODIFY_DATE(PurchaseDate, purchased);
  MODIFY_STR(ITunesAccount, account);
  MODIFY_NUM(CNID, cnID);
  MODIFY_NUM(ATID, atID);
  MODIFY_NUM64(PLID, plID);
  MODIFY_NUM(GEID, geID);

  // Artwork yet again, blah
  VALUE artworks = GET(artwork);
  if (artworks != Qnil && TYPE(artworks) == T_ARRAY) {
    for (uint32_t i = 0; i < RARRAY_LEN(artworks); i++) {
      VALUE artwork = rb_ary_entry(artworks, i);
      if (rb_obj_is_instance_of(artwork, rb_cArtwork) == Qfalse) {
        rb_raise(rb_eTypeError, "invalid object in artwork list at index %d", i);
      }

      VALUE data = rb_funcall(artwork, rb_intern("data"), 0);
      if (TYPE(data) != T_STRING) {
        rb_raise(rb_eTypeError, "the data for artwork %d is not valid - it should be a binary packed string", i);
      }

      // Skip setting image if it is equal to the one already there
      if (tags->artworkCount > i &&
          RSTRING_LEN(data) == tags->artwork[i].size &&
          memcmp(tags->artwork[i].data, RSTRING_PTR(data), tags->artwork[i].size) == 0) {
        printf("Not modifying artwork %d\n", i);
        continue;
      }

      ID kind = SYM2ID(rb_funcall(artwork, rb_intern("format"), 0));
      MP4TagArtwork art;
      art.data = (void *)RSTRING_PTR(data);
      art.size = RSTRING_LEN(data);

      if (kind == rb_intern("jpeg")) {
        art.type = MP4_ART_JPEG;
      } else if (kind == rb_intern("png")) {
        art.type = MP4_ART_PNG;
      } else if (kind == rb_intern("bmp")) {
        art.type = MP4_ART_BMP;
      } else if (kind == rb_intern("gif")) {
        art.type = MP4_ART_GIF;
      } else {
        art.type = MP4_ART_UNDEFINED;
      }

      if (tags->artworkCount > i) {
        printf("Setting artwork at position %d\n", i);
        MP4TagsSetArtwork(tags, i, &art);
      } else {
        printf("Adding a new piece of artwork %d\n", i);
        MP4TagsAddArtwork(tags, &art);
      }
    }

    // Delete any artwork that is in file but not in array
    for (uint32_t i = RARRAY_LEN(artworks); i < tags->artworkCount; i++) {
      printf("Removing artwork at %d\n", i);
      MP4TagsRemoveArtwork(tags, i);
    }
  }

  MP4TagsStore(tags, mp4v2);
  MP4TagsFree(tags);
  handle->tags = NULL;

  MP4ItmfItemList *list = handle->list = MP4ItmfGetItemsByMeaning(mp4v2, "com.apple.iTunes", "iTunEXTC");
  if (list) {
    for (uint32_t i = 0; i < list->size; i++) {
      MP4ItmfRemoveItem(mp4v2, &list->elements[i]);
    }
  }
  MP4ItmfItemListFree(list);
  handle->list = NULL;

  VALUE rating = GET(itmf_from_rating);
  if (rating != Qnil && TYPE(rating) == T_STRING) {
    MP4ItmfItem *item = MP4ItmfItemAlloc("----", 1);
    item->mean = (char *)"com.apple.iTunes";
    item->name = (char *)"iTunEXTC";

    MP4ItmfData *data = &item->dataList.elements[0];
    data->typeCode = MP4_ITMF_BT_UTF8;
    data->valueSize = RSTRING_LEN(rating);
    data->value = (uint8_t *)RSTRING_PTR(rating);

    // This free's the allocated object above too
    MP4ItmfAddItem(mp4v2, item);
  }

  list = handle->list = MP4ItmfGetItemsByMeaning(mp4v2, "com.apple.iTunes", "iTunMOVI");
  if (list) {
    for (uint32_t i = 0; i < list->size; i++) {
      MP4ItmfRemoveItem(mp4v2, &list->elements[i]);
    }
  }
  MP4ItmfItemListFree(list);
  handle->list = NULL;

  VALUE cast = GET(cast), directors = GET(directors), writers = GET(writers);
  VALUE codirectors = GET(codirectors), producers = GET(producers);
  if (cast != Qnil || directors != Qnil || writers != Qnil || codirectors != Qnil || producers != Qnil) {
    VALUE plist = rb_hash_new();

    MODIFY_PEOPLE(cast, cast);
    MODIFY_PEOPLE(directors, directors);
    MODIFY_PEOPLE(codirectors, codirectors);
    MODIFY_PEOPLE(screenwriters, writers);
    MODIFY_PEOPLE(producers, producers);
    plist = rb_funcall(plist, rb_intern("to_plist"), 0);

    MP4ItmfItem *item = MP4ItmfItemAlloc("----", 1);
    item->mean = (char *)"com.apple.iTunes";
    item->name = (char *)"iTunMOVI";

    MP4ItmfData *data = &item->dataList.elements[0];
    data->typeCode = MP4_ITMF_BT_UTF8;
    data->valueSize = RSTRING_LEN(plist);
    data->value = (uint8_t *)RSTRING_PTR(plist);

    // This free's the allocated object above too
    MP4ItmfAddItem(mp4v2, item);
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

  MP4V2Handles handle;
  handle.self = self;
  handle.filename = path;
  handle.file = NULL;
  handle.tags = NULL;
  handle.list = NULL;
  handle.optimize = false;

  if (TYPE(hash) == T_HASH && rb_hash_aref(hash, SYM("optimize")) == Qtrue) {
    handle.optimize = true;
  }

  rb_ensure((VALUE (*)(...))mp4v2_modify_file, (VALUE)&handle, (VALUE (*)(...))ensure_close, (VALUE)&handle);

  return path;
}

static VALUE mp4v2_artwork_save(VALUE self) {
  VALUE source = rb_ivar_get(self, rb_intern("@source"));

  MP4FileHandle mp4v2 = MP4Read(RSTRING_PTR(source));
  if (mp4v2 == MP4_INVALID_FILE_HANDLE) {
    rb_raise(rb_eTypeError, "%s is not a valid mp4 file", RSTRING_PTR(source));
  }

  VALUE file = rb_funcall(rb_ivar_get(self, rb_intern("@file")), rb_intern("to_s"), 0);
  uint32_t number = FIX2UINT(rb_ivar_get(self, rb_intern("@number")));

  // All ruby methods have been called so we are clear of exceptions happening in ruby
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
    rb_raise(rb_eIOError, "unable to open %s for writing", RSTRING_PTR(file));
  }

  fwrite(tags->artwork[number].data, sizeof(uint8_t), tags->artwork[number].size, artwork);
  fclose(artwork);

  MP4TagsFree(tags);
  MP4Close(mp4v2);

  return file;
}

static VALUE mp4v2_artwork_data(VALUE self) {
  VALUE source = rb_ivar_get(self, rb_intern("@source"));

  MP4FileHandle mp4v2 = MP4Read(RSTRING_PTR(source));
  if (mp4v2 == MP4_INVALID_FILE_HANDLE) {
    rb_raise(rb_eTypeError, "%s is not a valid mp4 file", RSTRING_PTR(source));
  }

  uint32_t number = FIX2UINT(rb_ivar_get(self, rb_intern("@number")));

  // All ruby methods have been called so we are clear of exceptions happening in ruby
  const MP4Tags *tags = MP4TagsAlloc();
  MP4TagsFetch(tags, mp4v2);

  if (!tags->artwork || tags->artworkCount <= number) {
    MP4TagsFree(tags);
    MP4Close(mp4v2);
    rb_raise(rb_eStandardError, "this artwork doesn't exist in the source file %s", RSTRING_PTR(source));
  }

  VALUE data = rb_str_new((const char*)tags->artwork[number].data, tags->artwork[number].size);

  MP4TagsFree(tags);
  MP4Close(mp4v2);

  return data;
}

void Init_mp4v2() {
  rb_cMp4v2 = rb_define_class("Mp4v2", rb_const_get(rb_cObject, rb_intern("OpenStruct")));
  rb_define_method(rb_cMp4v2, "initialize", (VALUE (*)(...))mp4v2_init, 1);
  rb_define_method(rb_cMp4v2, "save", (VALUE (*)(...))mp4v2_save, -2);
  rb_define_method(rb_cMp4v2, "optimize!", (VALUE (*)(...))mp4v2_optimize, 0);

  rb_cArtwork = rb_define_class_under(rb_cMp4v2, "Artwork", rb_cObject);
  //rb_define_method(rb_cArtwork, "initialize", (VALUE (*)(...))mp4v2_artwork_init, 1);
}

#ifdef __cplusplus
  }
#endif