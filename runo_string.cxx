
#include "runo_impl.hxx"

#ifdef HAVE_RUBY_IO_H
#include <ruby/io.h>
#endif

#include <rtl/textenc.h>
#include <osl/thread.h>

using rtl::OString;
using rtl::OUString;
using rtl::OUStringToOString;

namespace runo
{

OUString
asciiVALUE2OUString(VALUE str)
{
	Check_Type(str, T_STRING);
	return OUString(RSTRING_PTR(str), RSTRING_LEN(str), RTL_TEXTENCODING_ASCII_US);
}

VALUE
asciiOUString2VALUE(const OUString &str)
{
	OString o = OUStringToOString(str, RTL_TEXTENCODING_ASCII_US);
#ifdef HAVE_RUBY_ENCODING_H
	return rb_enc_str_new(o.getStr(), o.getLength(), rb_usascii_encoding());
#else
	return rb_str_new(o.getStr(), o.getLength());
#endif
}

#ifdef HAVE_RUBY_ENCODING_H
rtl_TextEncoding
Encoding2TextEncoding(VALUE encoding)
{
	rtl_TextEncoding ret;
	int index = rb_to_encoding_index(encoding);
	
	if (index == rb_enc_find_index("US-ASCII"))
		ret = RTL_TEXTENCODING_ASCII_US;
	else if (index == rb_enc_find_index("UTF-8"))
		ret = RTL_TEXTENCODING_UTF8;
	else if (index == rb_enc_find_index("EUC-JP"))
		ret = RTL_TEXTENCODING_EUC_JP;
	else if (index == rb_enc_find_index("Shift_JIS"))
		ret = RTL_TEXTENCODING_SHIFT_JIS;
	else if (index == rb_enc_find_index("Big5"))
		ret = RTL_TEXTENCODING_BIG5;
	else if (index == rb_enc_find_index("EUC-KR"))
		ret = RTL_TEXTENCODING_EUC_KR;
	else if (index == rb_enc_find_index("EUC-TW"))
		ret = RTL_TEXTENCODING_EUC_TW;
	else if (index == rb_enc_find_index("GB18030"))
		ret = RTL_TEXTENCODING_GB_18030;
	else if (index == rb_enc_find_index("GBK"))
		ret = RTL_TEXTENCODING_GBK;
	else if (index == rb_enc_find_index("ISO-8859-1"))
		ret = RTL_TEXTENCODING_ISO_8859_1;
	else if (index == rb_enc_find_index("ISO-8859-2"))
		ret = RTL_TEXTENCODING_ISO_8859_2;
	else if (index == rb_enc_find_index("ISO-8859-3"))
		ret = RTL_TEXTENCODING_ISO_8859_3;
	else if (index == rb_enc_find_index("ISO-8859-4"))
		ret = RTL_TEXTENCODING_ISO_8859_4;
	else if (index == rb_enc_find_index("ISO-8859-5"))
		ret = RTL_TEXTENCODING_ISO_8859_5;
	else if (index == rb_enc_find_index("ISO-8859-6"))
		ret = RTL_TEXTENCODING_ISO_8859_6;
	else if (index == rb_enc_find_index("ISO-8859-7"))
		ret = RTL_TEXTENCODING_ISO_8859_7;
	else if (index == rb_enc_find_index("ISO-8859-8"))
		ret = RTL_TEXTENCODING_ISO_8859_8;
	else if (index == rb_enc_find_index("ISO-8859-9"))
		ret = RTL_TEXTENCODING_ISO_8859_9;
	else if (index == rb_enc_find_index("ISO-8859-10"))
		ret = RTL_TEXTENCODING_ISO_8859_10;
	else if (index == rb_enc_find_index("ISO-8859-13"))
		ret = RTL_TEXTENCODING_ISO_8859_13;
	else if (index == rb_enc_find_index("ISO-8859-14"))
		ret = RTL_TEXTENCODING_ISO_8859_14;
	else if (index == rb_enc_find_index("ISO-8859-15"))
		ret = RTL_TEXTENCODING_ISO_8859_15;
	else if (index == rb_enc_find_index("KOI8-R"))
		ret = RTL_TEXTENCODING_KOI8_R;
	else if (index == rb_enc_find_index("KOI8-U"))
		ret = RTL_TEXTENCODING_KOI8_U;
	else if (index == rb_enc_find_index("Windows-1251"))
		ret = RTL_TEXTENCODING_MS_1251;
	else if (index == rb_enc_find_index("IBM437"))
		ret = RTL_TEXTENCODING_IBM_437 ;
	else if (index == rb_enc_find_index("IBM737"))
		ret = RTL_TEXTENCODING_IBM_737;
	else if (index == rb_enc_find_index("IBM775"))
		ret = RTL_TEXTENCODING_IBM_775;
	else if (index == rb_enc_find_index("IBM852"))
		ret = RTL_TEXTENCODING_IBM_852;
	else if (index == rb_enc_find_index("IBM852"))
		ret = RTL_TEXTENCODING_IBM_855;
	else if (index == rb_enc_find_index("IBM855"))
		ret = RTL_TEXTENCODING_IBM_857;
	else if (index == rb_enc_find_index("IBM857"))
		ret = RTL_TEXTENCODING_IBM_860;
	else if (index == rb_enc_find_index("IBM860"))
		ret = RTL_TEXTENCODING_IBM_861;
	else if (index == rb_enc_find_index("IBM861"))
		ret = RTL_TEXTENCODING_IBM_862;
	else if (index == rb_enc_find_index("IBM862"))
		ret = RTL_TEXTENCODING_IBM_863;
	else if (index == rb_enc_find_index("IBM863"))
		ret = RTL_TEXTENCODING_IBM_864;
	else if (index == rb_enc_find_index("IBM864"))
		ret = RTL_TEXTENCODING_IBM_865;
	else if (index == rb_enc_find_index("IBM865"))
		ret = RTL_TEXTENCODING_IBM_866;
	else if (index == rb_enc_find_index("IBM866"))
		ret = RTL_TEXTENCODING_IBM_869 ;
	else if (index == rb_enc_find_index("Windows-1258"))
		ret = RTL_TEXTENCODING_MS_1258;
	else if (index == rb_enc_find_index("macCentEuro"))
		ret = RTL_TEXTENCODING_APPLE_CENTEURO;
	else if (index == rb_enc_find_index("macCroatian"))
		ret = RTL_TEXTENCODING_APPLE_CROATIAN;
	else if (index == rb_enc_find_index("macCyrillic"))
		ret = RTL_TEXTENCODING_APPLE_CYRILLIC;
	else if (index == rb_enc_find_index("macGreek"))
		ret = RTL_TEXTENCODING_APPLE_GREEK;
	else if (index == rb_enc_find_index("macIceland"))
		ret = RTL_TEXTENCODING_APPLE_ICELAND;
	else if (index == rb_enc_find_index("macRoman"))
		ret = RTL_TEXTENCODING_APPLE_ROMAN;
	else if (index == rb_enc_find_index("macRomania"))
		ret = RTL_TEXTENCODING_APPLE_ROMANIAN;
	else if (index == rb_enc_find_index("macThai"))
		ret = RTL_TEXTENCODING_APPLE_THAI;
	else if (index == rb_enc_find_index("macTurkish"))
		ret = RTL_TEXTENCODING_APPLE_TURKISH;
	else if (index == rb_enc_find_index("stateless-ISO-2022-JP"))
		ret = RTL_TEXTENCODING_ISO_2022_JP;
	else if (index == rb_enc_find_index("GB2312"))
		ret = RTL_TEXTENCODING_GB_2312;
	else if (index == rb_enc_find_index("GB12345"))
		ret = RTL_TEXTENCODING_GBT_12345;
	else if (index == rb_enc_find_index("Windows-1252"))
		ret = RTL_TEXTENCODING_MS_1252;
	else if (index == rb_enc_find_index("Windows-1250"))
		ret = RTL_TEXTENCODING_MS_1250;
	else if (index == rb_enc_find_index("Windows-1253"))
		ret = RTL_TEXTENCODING_MS_1253;
	else if (index == rb_enc_find_index("Windows-1254"))
		ret = RTL_TEXTENCODING_MS_1254;
	else if (index == rb_enc_find_index("Windows-1255"))
		ret = RTL_TEXTENCODING_MS_1255;
	else if (index == rb_enc_find_index("Windows-1256"))
		ret = RTL_TEXTENCODING_MS_1256;
	else if (index == rb_enc_find_index("Windows-1257"))
		ret = RTL_TEXTENCODING_MS_1257;
	else if (index == rb_enc_find_index("MacJapanese"))
		ret = RTL_TEXTENCODING_APPLE_JAPANESE;
	else
		ret = RTL_TEXTENCODING_UTF8;
		
	return ret;
}
#else
rtl_TextEncoding
Encoding2TextEncoding(const char *enc)
{
	rtl_TextEncoding ret;
	if (strcmp(enc, "UTF8") == 0)
	{
		ret = RTL_TEXTENCODING_UTF8;
	}
	else if (strcmp(enc, "SJIS") == 0)
	{
		ret = RTL_TEXTENCODING_SHIFT_JIS;
	}
	else if (strcmp(enc, "EUC") == 0)
	{
		ret = RTL_TEXTENCODING_EUC_JP;
	}
	else
	{
		ret = RTL_TEXTENCODING_UTF8;
	}
	return ret;
}
#endif

static rtl_TextEncoding external_encoding;

VALUE
ustring2RString(const ::rtl::OUString &str)
{
#ifdef HAVE_RUBY_ENCODING_H
	//OString o = OUStringToOString(str, RTL_TEXTENCODING_UTF8);
	//return rb_enc_str_new(o.getStr(), o.getLength(), rb_utf8_encoding());
	OString o = OUStringToOString(str, external_encoding);
	return rb_enc_str_new(o.getStr(), o.getLength(), rb_default_external_encoding());
#else
	OString o = OUStringToOString(str, external_encoding);
	return rb_str_new(o.getStr(), o.getLength());
#endif
}

OUString
rbString2OUString(VALUE rbstr)
{
	Check_Type(rbstr, T_STRING);
#ifdef HAVE_RUBY_ENCODING_H
	//VALUE str = rb_funcall(rbstr, rb_intern("encode"), 1, rb_str_new2("UTF-8"));
	//return OUString(RSTRING_PTR(str), RSTRING_LEN(str), RTL_TEXTENCODING_UTF8);
	
	return OUString(RSTRING_PTR(rbstr), RSTRING_LEN(rbstr), Encoding2TextEncoding(rb_obj_encoding(rbstr)));
#else
	return OUString(RSTRING_PTR(rbstr), RSTRING_LEN(rbstr), external_encoding);
#endif
}

/*
void
set_external_encoding(VALUE encoding)
{
	external_encoding = Encoding2TextEncoding(encoding);
}
*/

void
init_external_encoding()
{
#ifdef HAVE_RUBY_ENCODING_H
	external_encoding = Encoding2TextEncoding(rb_enc_default_external());
#else
	external_encoding = Encoding2TextEncoding(rb_get_kcode());
#endif
}

VALUE
bytes2VALUE(const com::sun::star::uno::Sequence< sal_Int8 > &bytes)
{
#ifdef HAVE_RUBY_ENCODING_H
	return rb_enc_str_new((char*)bytes.getConstArray(), bytes.getLength(), rb_ascii8bit_encoding());
#else
	return rb_str_new((char*)bytes.getConstArray(), bytes.getLength());
#endif
}

}

