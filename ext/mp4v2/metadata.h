#ifndef METADATA_H_1UAPHLN4
#define METADATA_H_1UAPHLN4

int rb_protect_funcall(VALUE *result, VALUE receiver, ID function, int argc, ...);
int rb_protect_apply(VALUE *result, VALUE receiver, ID function, VALUE args);

#define TAG_SET(tag, accessor) if (tags->tag) { SET(accessor, rb_utf8_str(tags->tag)); }
#define _TAG_NUM(tag, accessor, converter) if (tags->tag) { SET(accessor, converter(*tags->tag)); }
#define TAG_NUM32(tag, accessor) _TAG_NUM(tag, accessor, ULONG2NUM)
#define TAG_NUM64(tag, accessor) _TAG_NUM(tag, accessor, ULL2NUM)
#define TAG_NUM8 TAG_NUM32
#define TAG_NUM16 TAG_NUM32
#define TAG_NUM TAG_NUM32
#define TAG_TOTAL(tag, idx, max) \
  if (tags->tag) { \
    if (tags->tag->index) { \
      SET(idx, INT2FIX(tags->tag->index)); \
    } \
    if (tags->tag->total) { \
      SET(max, INT2FIX(tags->tag->total)); \
    } \
  }
#define TAG_BOOL(tag, accessor, truth) \
  if (tags->tag) { \
    SET(accessor, *tags->tag == truth ? Qtrue : Qfalse); \
  } else { \
    SET(accessor, Qfalse); \
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
      if (rb_protect_apply(&date, rb_const_get(rb_cObject, rb_intern("DateTime")), rb_intern("civil"), parsed) == 0) { \
        SET(accessor, date); \
      } \
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

#define MODIFY(func, val) (MP4TagsSet ## func(tags, val))
#define MODIFY_STR(func, accessor) \
  { \
    VALUE data = GET(accessor); \
    \
    switch(TYPE(data)) { \
      case T_NIL: \
      case T_STRING: \
        break; \
      default: \
        if (rb_respond_to(data, rb_intern("to_str"))) { \
          data = rb_funcall(data, rb_intern("to_str"), 0); \
        } else if (rb_respond_to(data, rb_intern("to_s"))) { \
          data = rb_funcall(data, rb_intern("to_s"), 0); \
        } \
    } \
    \
    if (data != Qnil && TYPE(data) != T_STRING) { \
      rb_raise(rb_eTypeError, "can't convert " #accessor " to string"); \
    } \
    \
    if (data != Qnil) { \
      MODIFY(func, RSTRING_PTR(rb_encode_utf8(data))); \
    } else { \
      MODIFY(func, NULL); \
    } \
  }
#define MAXU8  0xFF
#define MAXU16 0xFFFF
#define MAXU32 0xFFFFFFFF
#define MAXU64 0xFFFFFFFFFFFFFFFF
#define MODIFY_NUMBITS(func, accessor, bits) \
  { \
    VALUE data = GET(accessor); \
    \
    switch(TYPE(data)) { \
      case T_NIL: \
      case T_FIXNUM: \
      case T_BIGNUM: \
        break; \
      default: \
        if (rb_respond_to(data, rb_intern("to_int"))) { \
          data = rb_funcall(data, rb_intern("to_int"), 0); \
        } else if (rb_respond_to(data, rb_intern("to_i"))) { \
          data = rb_funcall(data, rb_intern("to_i"), 0);\
        } \
    } \
    \
    if (data == Qnil) { \
      MODIFY(func, NULL); \
    } else if (TYPE(data) == T_FIXNUM || TYPE(data) == T_BIGNUM) { \
      uint64_t num = (uint64_t)NUM2ULL(data); \
      uint ## bits ## _t casted = (uint ## bits ## _t)num; \
      \
      if (num > (uint64_t)MAXU ## bits) { \
        rb_raise(rb_eRangeError, #accessor " max value is %llu", (uint64_t)MAXU ## bits); \
      } else { \
        MODIFY(func, &casted); \
      } \
    } else { \
      rb_raise(rb_eTypeError, "can't convert " #accessor " to integer"); \
    } \
  }
#define MODIFY_NUM8(func, accessor) MODIFY_NUMBITS(func, accessor, 8)
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
    \
    if (TYPE(date) == T_STRING && rb_protect_funcall(&date, rb_cDateTime, rb_intern("parse"), 1, date)) { \
      rb_raise(rb_eTypeError, "can't convert " #accessor " to DateTime"); \
    } \
    \
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
    VALUE key = rb_utf8_str("name"), tmp = rb_ary_dup(list); \
    \
    for (int32_t i = RARRAY_LEN(tmp) - 1; i >= 0; i--) { \
      VALUE hash = rb_hash_new(), name = rb_ary_pop(tmp); \
      Check_Type(name, T_STRING); \
      rb_hash_aset(hash, key, name); \
      rb_ary_unshift(tmp, hash); \
    } \
    \
    rb_hash_aset(plist, rb_utf8_str(#tag), tmp); \
  }

#define DELETE_ITMF(meaning, name) \
  { \
    MP4ItmfItemList *list = handle->list = MP4ItmfGetItemsByMeaning(mp4v2, meaning, name); \
    if (list) { \
      for (uint32_t i = 0; i < list->size; i++) { \
        MP4ItmfRemoveItem(mp4v2, &list->elements[i]); \
      } \
    } \
    MP4ItmfItemListFree(list); \
    handle->list = NULL; \
  }
#define ADD_ITMF(meaning, naming, val) \
  { \
    MP4ItmfItem *item = MP4ItmfItemAlloc("----", 1); \
    item->mean = (char *)meaning; \
    item->name = (char *)naming; \
    \
    MP4ItmfData *data = &item->dataList.elements[0]; \
    data->typeCode = MP4_ITMF_BT_UTF8; \
    data->valueSize = RSTRING_LEN(val); \
    data->value = (uint8_t *)RSTRING_PTR(val); \
    \
    MP4ItmfAddItem(mp4v2, item); \
  }
#endif /* end of include guard: METADATA_H_1UAPHLN4 */
