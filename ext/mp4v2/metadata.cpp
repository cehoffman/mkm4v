#include "shared.h"
#include "metadata.h"

void _mp4v2_read_metadata(MP4V2Handles *handle) {
  VALUE self = handle->self;
  MP4FileHandle mp4v2 = handle->file;

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
  TAG_NUM16(genreType, genre_type);
  TAG_DATE(releaseDate, released);
  TAG_TOTAL(track, track, tracks);
  TAG_TOTAL(disk, disk, disks);
  TAG_NUM16(tempo, tempo);
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
  TAG_SET(category, category);
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
  TAG_NUM8(iTunesAccountType, account_type);
  TAG_NUM(iTunesCountry, country);
  TAG_NUM(cnID, cnID);
  TAG_NUM(atID, atID);
  TAG_NUM64(plID, plID);
  TAG_NUM(geID, geID);

  // Artwork, need to think on this one
  if (tags->artwork) {
    VALUE regex = rb_funcall(rb_cRegexp, rb_intern("new"), 1, rb_utf8_str("\\.[^\\.]+$"));
    char ext[12];
    VALUE artworks = rb_ary_new(), art;

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
      rb_ary_unshift(artworks, art = rb_funcall(rb_cArtwork, rb_intern("new"), 2, art, rb_str_new((const char*)tags->artwork[i].data, tags->artwork[i].size)));
    }

    SET(artwork, artworks);
  }

  MP4TagsFree(tags);
  handle->tags = NULL;

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
}

void _mp4v2_write_metadata(MP4V2Handles *handle) {
  VALUE self = handle->self;
  MP4FileHandle mp4v2 = handle->file;

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
  MODIFY_NUM16(GenreType, genre_type);
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
  MODIFY_STR(Category, category);
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

  if (type) {
    MODIFY(MediaType, &type);
  } else {
    MODIFY(MediaType, NULL);
  }

  index = GET(advisory);
  type = NULL;
  if (index == SYM("none")) {
    type = 0;
    MODIFY(ContentRating, &type);
  } else if (index == SYM("clean")) {
    type = 2;
    MODIFY(ContentRating, &type);
  } else if (index == SYM("explicit")) {
    type = 4;
    MODIFY(ContentRating, &type);
  } else {
    MODIFY(ContentRating, NULL);
  }

  MODIFY_BOOL(Gapless, gapless);

  MODIFY_DATE(PurchaseDate, purchased);
  MODIFY_STR(ITunesAccount, account);
  MODIFY_NUM8(ITunesAccountType, account_type);
  MODIFY_NUM(ITunesCountry, country);
  MODIFY_NUM(CNID, cnID);
  MODIFY_NUM(ATID, atID);
  MODIFY_NUM64(PLID, plID);
  MODIFY_NUM(GEID, geID);

  // Artwork yet again, blah
  VALUE artworks = GET(artwork);
  uint32_t count = 0;
  switch(TYPE(artworks)) {
    case T_ARRAY: // fall through to T_NIL to remove extra artwork
      RARRAY_ALL_INSTANCE(artworks, rb_cArtwork, artwork);

      count = RARRAY_LEN(artworks);
      for (uint32_t i = 0; i < count; i++) {
        VALUE artwork = rb_ary_entry(artworks, i);

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
    case T_NIL:
      // Delete any artwork that is left in file but not in list
      for (uint32_t i = count; i < tags->artworkCount; i++) {
        printf("Removing artwork at %d\n", i);
        MP4TagsRemoveArtwork(tags, i);
      }
      break;
    default:;
  }

  MP4TagsStore(tags, mp4v2);
  MP4TagsFree(tags);
  handle->tags = NULL;

  VALUE rating = GET(itmf_from_rating);
  if (TYPE(rating) == T_STRING) {
    rating = rb_encode_utf8(rating);

    DELETE_ITMF("com.apple.iTunes", "iTunEXTC");
    ADD_ITMF("com.apple.iTunes", "iTunEXTC", rating);
  } else {
    DELETE_ITMF("com.apple.iTunes", "iTunEXTC");
  }

  VALUE cast = GET(cast), directors = GET(directors), writers = GET(writers);
  VALUE codirectors = GET(codirectors), producers = GET(producers);
  if (cast != Qnil || directors != Qnil || writers != Qnil || codirectors != Qnil || producers != Qnil) {
    VALUE plist = rb_hash_new();

    MODIFY_PEOPLE(cast, cast);
    MODIFY_PEOPLE(directors, directors);
    MODIFY_PEOPLE(codirectors, codirectors);
    MODIFY_PEOPLE(screenwriters, writers);
    MODIFY_PEOPLE(producers, producers);
    plist = rb_encode_utf8(rb_funcall(plist, rb_intern("to_plist"), 0));

    DELETE_ITMF("com.apple.iTunes", "iTunMOVI");
    ADD_ITMF("com.apple.iTunes", "iTunMOVI", plist);
  } else {
    DELETE_ITMF("com.apple.iTunes", "iTunMOVI");
  }
}