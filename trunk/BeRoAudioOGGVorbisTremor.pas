(********************************************************************
 *                                                                  *
 * THIS FILE IS PART OF THE OggVorbis 'TREMOR' CODEC SOURCE CODE.   *
 *                                                                  *
 * USE, DISTRIBUTION AND REPRODUCTION OF THIS LIBRARY SOURCE IS     *
 * GOVERNED BY A BSD-STYLE SOURCE LICENSE INCLUDED WITH THIS SOURCE *
 * IN 'COPYING'. PLEASE READ THESE TERMS BEFORE DISTRIBUTING.       *
 *                                                                  *
 * THE OggVorbis 'TREMOR' SOURCE CODE IS (C) COPYRIGHT 1994-2003    *
 * BY THE Xiph.Org FOUNDATION http://www.xiph.org/                  *
 *                                                                  *
 ********************************************************************
 *                                                                  *
 * Pascal port by Benjamin 'BeRo' Rosseaux                          *
 *                                                                  *
 * The ported code, additional code and modifications of the ported *
 * code are licensed under the same BSD-style like TREMOR itself.   *
 *                                                                  *
 * Additional code + modified code (C) Copyright 2012-2014 by       *
 * Benjamin 'BeRo' Rosseaux                                         *
 *                                                                  *  
 ********************************************************************
 *                                                                  *
 * The port is a mixture of the low-memory-branch and the normal    *
 * branch of the original TREMOR C-sources, or better said, it is   *
 * based on the low-memory-branch with some bugfixes from the       *
 * normal main SVN trunk branch of TREMOR                           *
 *                                                                  *
 ********************************************************************)
unit BeRoAudioOGGVorbisTremor;
{$ifdef fpc}
 {$mode delphi}
 {$ifdef cpui386}
  {$define cpu386}
 {$endif}
 {$ifdef cpu386}
  {$asmmode intel}
 {$endif}
 {$ifdef cpuamd64}
  {$asmmode intel}
 {$endif}
 {$ifdef fpc_little_endian}
  {$define little_endian}
 {$else}
  {$ifdef fpc_big_endian}
   {$define big_endian}
  {$endif}
 {$endif}
 {$ifdef fpc_has_internal_sar}
  {$define HasSAR}
 {$endif}
 {-$pic off}
 {$define caninline}
 {$ifdef FPC_HAS_TYPE_EXTENDED}
  {$define HAS_TYPE_EXTENDED}
 {$else}
  {$undef HAS_TYPE_EXTENDED}
 {$endif}
 {$ifdef FPC_HAS_TYPE_DOUBLE}
  {$define HAS_TYPE_DOUBLE}
 {$else}
  {$undef HAS_TYPE_DOUBLE}
 {$endif}
 {$ifdef FPC_HAS_TYPE_SINGLE}
  {$define HAS_TYPE_SINGLE}
 {$else}
  {$undef HAS_TYPE_SINGLE}
 {$endif}
{$else}
 {$realcompatibility off}
 {$localsymbols on}
 {$define little_endian}
 {$ifndef cpu64}
  {$define cpu32}
 {$endif}
 {$define delphi} 
 {$undef HasSAR}
 {$define UseDIV}
 {$define HAS_TYPE_EXTENDED}
 {$define HAS_TYPE_DOUBLE}
 {$define HAS_TYPE_SINGLE}
{$endif}
{$ifdef cpu386}
 {$define cpux86}
{$endif}
{$ifdef cpuamd64}
 {$define cpux86}
{$endif}
{$ifdef win32}
 {$define windows}
{$endif}
{$ifdef win64}
 {$define windows}
{$endif}
{$ifdef wince}
 {$define windows}
{$endif}
{$ifdef windows}
 {$define win}
{$endif}
{$ifdef sdl20}
 {$define sdl}
{$endif}
{$rangechecks off}
{$extendedsyntax on}
{$writeableconst on}
{$hints off}
{$booleval off}
{$typedaddress off}
{$stackframes off}
{$varstringchecks on}
{$typeinfo on}
{$overflowchecks off}
{$longstrings on}
{$openstrings on}
{$ifndef HAS_TYPE_DOUBLE}
 {$error No double floating point precision}
{$endif}
{$ifdef fpc}
 {$define caninline}
{$else}
 {$undef caninline}
 {$ifdef ver180}
  {$define caninline}
 {$else}
  {$ifdef conditionalexpressions}
   {$if compilerversion>=18}
    {$define caninline}
   {$ifend}
  {$endif}
 {$endif}
{$endif}

interface

const OGG_SUCCESS=0;

      OGG_HOLE=-10;
      OGG_SPAN=-11;
      OGG_EVERSION=-12;
      OGG_ESERIAL=-123;
      OGG_EINVAL=-14;
      OGG_EEOS=-15;

      OV_FALSE=-1;
      OV_EOF=-2;
      OV_HOLE=-3;

      OV_EREAD=-128;
      OV_EFAULT=-129;
      OV_EIMPL=-130;
      OV_EINVAL=-131;
      OV_ENOTVORBIS=-132;
      OV_EBADHEADER=-133;
      OV_EVERSION=-134;
      OV_ENOTAUDIO=-135;
      OV_EBADPACKET=-136;
      OV_EBADLINK=-137;
      OV_ENOSEEK=-138;

      WORD_ALIGN=8;

      VIF_POSIT=63;
      VIF_CLASS=16;
      VIF_PARTS=31;

      VI_TRANSFORMB=1;
      VI_WINDOWB=1;
      VI_TIMEB=1;
      VI_FLOORB=2;
      VI_RESB=3;
      VI_MAPB=1;

      LSP_FRACBITS=14;

      FROMdB_LOOKUP_SZ=35;
      FROMdB2_LOOKUP_SZ=32;
      FROMdB_SHIFT=5;
      FROMdB2_SHIFT=3;
      FROMdB2_MASK=31;

      SEEK_SET=0;
      SEEK_CUR=1;
      SEEK_END=2;

      errno:longint=0;

      FROMdB_LOOKUP:array[0..FROMdB_LOOKUP_SZ-1] of longint=(
       $003fffff,$0028619b,$00197a96,$0010137a,$000a24b0,$00066666,$000409c3,$00028c42,
       $00019b8c,$000103ab,$0000a3d7,$00006760,$0000413a,$00002928,$000019f8,$00001062,
       $00000a56,$00000686,$0000041e,$00000299,$000001a3,$00000109,$000000a7,$00000069,
       $00000042,$0000002a,$0000001a,$00000011,$0000000b,$00000007,$00000004,$00000003,
       $00000002,$00000001,$00000001
      );

      FROMdB2_LOOKUP:array[0..FROMdB2_LOOKUP_SZ-1] of longint=(
       $000001fc,$000001f5,$000001ee,$000001e7,$000001e0,$000001d9,$000001d2,$000001cc,
       $000001c5,$000001bf,$000001b8,$000001b2,$000001ac,$000001a6,$000001a0,$0000019a,
       $00000194,$0000018e,$00000188,$00000183,$0000017d,$00000178,$00000172,$0000016d,
       $00000168,$00000163,$0000015e,$00000159,$00000154,$0000014f,$0000014a,$00000145
      );

      INVSQ_LOOKUP_I_SHIFT=10;
      INVSQ_LOOKUP_I_MASK=1023;

      INVSQ_LOOKUP_I:array[0..64] of longint=(
       92682,91966,91267,90583,89915,89261,88621,87995,87381,86781,86192,85616,85051,84497,83953,83420,
       82897,82384,81880,81385,80899,80422,79953,79492,79039,78594,78156,77726,77302,76885,76475,76072,
       75674,75283,74898,74519,74146,73778,73415,73058,72706,72359,72016,71679,71347,71019,70695,70376,
       70061,69750,69444,69141,68842,68548,68256,67969,67685,67405,67128,66855,66585,66318,66054,65794,
       65536
      );

      INVSQ_LOOKUP_IDel:array[0..63] of longint=(
       716,699,684,668,654,640,626,614,600,589,576,565,554,544,533,523,
       513,504,495,486,477,469,461,453,445,438,430,424,417,410,403,398,
       391,385,379,373,368,363,357,352,347,343,337,332,328,324,319,315,
       311,306,303,299,294,292,287,284,280,277,273,270,267,264,260,258
      );                                                              

      COS_LOOKUP_I_SHIFT=9;
      COS_LOOKUP_I_MASK=511;
      COS_LOOKUP_I_SZ=128;

      COS_LOOKUP_I:array[0..COS_LOOKUP_I_SZ] of longint=(
        16384,   16379,   16364,   16340,
        16305,   16261,   16207,   16143,
        16069,   15986,   15893,   15791,
        15679,   15557,   15426,   15286,
        15137,   14978,   14811,   14635,
        14449,   14256,   14053,   13842,
        13623,   13395,   13160,   12916,
        12665,   12406,   12140,   11866,
        11585,   11297,   11003,   10702,
        10394,   10080,    9760,    9434,
         9102,    8765,    8423,    8076,
         7723,    7366,    7005,    6639,
         6270,    5897,    5520,    5139,
         4756,    4370,    3981,    3590,
         3196,    2801,    2404,    2006,
         1606,    1205,     804,     402,
            0,    -401,    -803,   -1204,
        -1605,   -2005,   -2403,   -2800,
        -3195,   -3589,   -3980,   -4369,
        -4755,   -5138,   -5519,   -5896,
        -6269,   -6638,   -7004,   -7365,
        -7722,   -8075,   -8422,   -8764,
        -9101,   -9433,   -9759,  -10079,
       -10393,  -10701,  -11002,  -11296,
       -11584,  -11865,  -12139,  -12405,
       -12664,  -12915,  -13159,  -13394,
       -13622,  -13841,  -14052,  -14255,
       -14448,  -14634,  -14810,  -14977,
       -15136,  -15285,  -15425,  -15556,
       -15678,  -15790,  -15892,  -15985,
       -16068,  -16142,  -16206,  -16260,
       -16304,  -16339,  -16363,  -16378,
       -16383
     );

     ADJUST_SQRT2:array[0..1] of longint=(8192,5792);

     barklook:array[0..27] of longint=(0,100,200,301,405,516,635,766,912,1077,1263,1476,1720,2003,2333,2721,
                                       3184,3742,4428,5285,6376,7791,9662,12181,15624,20397,27087,36554);

     MLOOP_1:array[0..63] of byte=( 0,10,11,11,12,12,12,12,13,13,13,13,13,13,13,13,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,
                                   15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15);

     MLOOP_2:array[0..63] of byte=(0,4,5,5,6,6,6,6,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
                                   9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9);

     MLOOP_3:array[0..7] of byte=(0,1,2,2,3,3,3,3);

     floor1_rangedB=140;

     cPI3_8=$30fbc54d;
     cPI2_8=$5a82799a;
     cPI1_8=$7641af3d;

     CHUNKSIZE=1024;

     NOTOPEN=0;
     PARTOPEN=1;
     OPENED=2;
     STREAMSET=3;
     INITSET=4;

     vwin64:array[0..31] of longint=($001f0003,$01168c98,$030333c8,$05dfe3a4,
                                     $09a49562,$0e45df18,$13b47ef2,$19dcf676,
                                     $20a74d83,$27f7137c,$2fabb05a,$37a1105a,
                                     $3fb0ab28,$47b2dcd1,$4f807bc6,$56f48e70,
                                     $5dedfc79,$64511653,$6a08cfff,$6f079328,
                                     $734796f4,$76cab7f2,$7999d6e8,$7bc3cf9f,
                                     $7d5c20c1,$7e7961df,$7f33a567,$7fa2e1d0,
                                     $7fdd78a5,$7ff6ec6d,$7ffed0e9,$7ffffc3f);

     vwin128:array[0..63] of longint=($0007c04d,$0045bb89,$00c18b87,$017ae294,
                                      $02714a4e,$03a4217a,$05129952,$06bbb24f,
                                      $089e38a1,$0ab8c073,$0d09a228,$0f8ef6bd,
                                      $12469488,$152e0c7a,$1842a81c,$1b81686d,
                                      $1ee705d9,$226ff15d,$26185705,$29dc21cc,
                                      $2db700fe,$31a46f08,$359fb9c1,$39a40c0c,
                                      $3dac78b6,$41b40674,$45b5bcb0,$49acb109,
                                      $4d94152b,$516744bd,$5521d320,$58bf98a5,
                                      $5c3cbef4,$5f95cc5d,$62c7add7,$65cfbf64,
                                      $68abd2ba,$6b5a3405,$6dd9acab,$7029840d,
                                      $72497e38,$7439d8ac,$75fb4532,$778ee30a,
                                      $78f6367e,$7a331f1a,$7b47cccd,$7c36b416,
                                      $7d028192,$7dae0d18,$7e3c4caa,$7eb04763,
                                      $7f0d08a7,$7f5593b7,$7f8cd7d5,$7fb5a513,
                                      $7fd2a1fc,$7fe64212,$7ff2bd4c,$7ffa0890,
                                      $7ffdcf39,$7fff6dac,$7fffed01,$7fffffc4);

     vwin256:array[0..127] of longint=($0001f018,$00117066,$00306e9e,$005ee5f1,
                                       $009ccf26,$00ea208b,$0146cdea,$01b2c87f,
                                       $022dfedf,$02b85ced,$0351cbbd,$03fa317f,
                                       $04b17167,$05776b90,$064bfcdc,$072efedd,
                                       $082047b4,$091fa9f1,$0a2cf477,$0b47f25d,
                                       $0c706ad2,$0da620ff,$0ee8d3ef,$10383e75,
                                       $11941716,$12fc0ff6,$146fd6c8,$15ef14c2,
                                       $17796e8e,$190e844f,$1aadf196,$1c574d6e,
                                       $1e0a2a62,$1fc61688,$218a9b9c,$23573f12,
                                       $252b823d,$2706e269,$28e8d913,$2ad0dc0e,
                                       $2cbe5dc1,$2eb0cd60,$30a79733,$32a224d5,
                                       $349fdd8b,$36a02690,$38a2636f,$3aa5f65e,
                                       $3caa409e,$3eaea2df,$40b27da6,$42b531b8,
                                       $44b62086,$46b4ac99,$48b03a05,$4aa82ed5,
                                       $4c9bf37d,$4e8af349,$50749ccb,$52586246,
                                       $5435ba1c,$560c1f31,$57db1152,$59a21591,
                                       $5b60b6a3,$5d168535,$5ec31839,$60660d36,
                                       $61ff0886,$638db595,$6511c717,$668af734,
                                       $67f907b0,$695bc207,$6ab2f787,$6bfe815a,
                                       $6d3e4090,$6e721e16,$6f9a0ab5,$70b5fef8,
                                       $71c5fb16,$72ca06cd,$73c2313d,$74ae90b2,
                                       $758f4275,$76646a85,$772e335c,$77eccda0,
                                       $78a06fd7,$79495613,$79e7c19c,$7a7bf894,
                                       $7b064596,$7b86f757,$7bfe6044,$7c6cd615,
                                       $7cd2b16e,$7d304d71,$7d860756,$7dd43e06,
                                       $7e1b51ad,$7e5ba355,$7e95947e,$7ec986bb,
                                       $7ef7db4a,$7f20f2b9,$7f452c7f,$7f64e6a7,
                                       $7f807d71,$7f984aff,$7faca700,$7fbde662,
                                       $7fcc5b04,$7fd85372,$7fe21a99,$7fe9f791,
                                       $7ff02d58,$7ff4fa9e,$7ff89990,$7ffb3faa,
                                       $7ffd1d8b,$7ffe5ecc,$7fff29e0,$7fff9ff3,
                                       $7fffdcd2,$7ffff6d6,$7ffffed0,$7ffffffc);

     vwin512:array[0..255] of longint=($00007c06,$00045c32,$000c1c62,$0017bc4c,
                                       $00273b7a,$003a9955,$0051d51c,$006cede7,
                                       $008be2a9,$00aeb22a,$00d55b0d,$00ffdbcc,
                                       $012e32b6,$01605df5,$01965b85,$01d02939,
                                       $020dc4ba,$024f2b83,$02945ae6,$02dd5004,
                                       $032a07d3,$037a7f19,$03ceb26e,$04269e37,
                                       $04823eab,$04e18fcc,$05448d6d,$05ab3329,
                                       $06157c68,$0683645e,$06f4e607,$0769fc25,
                                       $07e2a146,$085ecfbc,$08de819f,$0961b0cc,
                                       $09e856e3,$0a726d46,$0affed1d,$0b90cf4c,
                                       $0c250c79,$0cbc9d0b,$0d577926,$0df598aa,
                                       $0e96f337,$0f3b8026,$0fe3368f,$108e0d42,
                                       $113bfaca,$11ecf56b,$12a0f324,$1357e9ac,
                                       $1411ce70,$14ce9698,$158e3702,$1650a444,
                                       $1715d2aa,$17ddb638,$18a842aa,$19756b72,
                                       $1a4523b9,$1b175e62,$1bec0e04,$1cc324f0,
                                       $1d9c9532,$1e78508a,$1f564876,$20366e2e,
                                       $2118b2a2,$21fd0681,$22e35a37,$23cb9dee,
                                       $24b5c18e,$25a1b4c0,$268f66f1,$277ec74e,
                                       $286fc4cc,$29624e23,$2a5651d7,$2b4bbe34,
                                       $2c428150,$2d3a8913,$2e33c332,$2f2e1d35,
                                       $30298478,$3125e62d,$32232f61,$33214cfc,
                                       $34202bc2,$351fb85a,$361fdf4f,$37208d10,
                                       $3821adf7,$39232e49,$3a24fa3c,$3b26fdf6,
                                       $3c292593,$3d2b5d29,$3e2d90c8,$3f2fac7f,
                                       $40319c5f,$41334c81,$4234a905,$43359e16,
                                       $443617f3,$453602eb,$46354b65,$4733dde1,
                                       $4831a6ff,$492e937f,$4a2a9045,$4b258a5f,
                                       $4c1f6f06,$4d182ba2,$4e0fadce,$4f05e35b,
                                       $4ffaba53,$50ee20fd,$51e005e1,$52d057ca,
                                       $53bf05ca,$54abff3b,$559733c7,$56809365,
                                       $57680e62,$584d955d,$59311952,$5a128b96,
                                       $5af1dddd,$5bcf023a,$5ca9eb27,$5d828b81,
                                       $5e58d68d,$5f2cbffc,$5ffe3be9,$60cd3edf,
                                       $6199bdda,$6263ae45,$632b0602,$63efbb66,
                                       $64b1c53f,$65711ad0,$662db3d7,$66e7888d,
                                       $679e91a5,$6852c84e,$69042635,$69b2a582,
                                       $6a5e40dd,$6b06f36c,$6bacb8d2,$6c4f8d30,
                                       $6cef6d26,$6d8c55d4,$6e2644d4,$6ebd3840,
                                       $6f512ead,$6fe2272e,$7070214f,$70fb1d17,
                                       $71831b06,$72081c16,$728a21b5,$73092dc8,
                                       $738542a6,$73fe631b,$74749261,$74e7d421,
                                       $75582c72,$75c59fd5,$76303333,$7697ebdd,
                                       $76fccf85,$775ee443,$77be308a,$781abb2e,
                                       $78748b59,$78cba88e,$79201aa7,$7971e9cd,
                                       $79c11e79,$7a0dc170,$7a57dbc2,$7a9f76c1,
                                       $7ae49c07,$7b27556b,$7b67ad02,$7ba5ad1b,
                                       $7be1603a,$7c1ad118,$7c520a9e,$7c8717e1,
                                       $7cba0421,$7ceadac3,$7d19a74f,$7d46756e,
                                       $7d7150e5,$7d9a4592,$7dc15f69,$7de6aa71,
                                       $7e0a32c0,$7e2c0479,$7e4c2bc7,$7e6ab4db,
                                       $7e87abe9,$7ea31d24,$7ebd14be,$7ed59edd,
                                       $7eecc7a3,$7f029b21,$7f17255a,$7f2a723f,
                                       $7f3c8daa,$7f4d835d,$7f5d5f00,$7f6c2c1b,
                                       $7f79f617,$7f86c83a,$7f92ada2,$7f9db146,
                                       $7fa7ddf3,$7fb13e46,$7fb9dcb0,$7fc1c36c,
                                       $7fc8fc83,$7fcf91c7,$7fd58cd2,$7fdaf702,
                                       $7fdfd979,$7fe43d1c,$7fe82a8b,$7febaa29,
                                       $7feec412,$7ff1801c,$7ff3e5d6,$7ff5fc86,
                                       $7ff7cb29,$7ff9586f,$7ffaaaba,$7ffbc81e,
                                       $7ffcb660,$7ffd7af3,$7ffe1afa,$7ffe9b42,
                                       $7fff0047,$7fff4e2f,$7fff88c9,$7fffb390,
                                       $7fffd1a6,$7fffe5d7,$7ffff296,$7ffff9fd,
                                       $7ffffdcd,$7fffff6d,$7fffffed,$7fffffff);

     vwin1024:array[0..511] of longint=($00001f02,$0001170e,$00030724,$0005ef40,
                                        $0009cf59,$000ea767,$0014775e,$001b3f2e,
                                        $0022fec8,$002bb618,$00356508,$00400b81,
                                        $004ba968,$00583ea0,$0065cb0a,$00744e84,
                                        $0083c8ea,$00943a14,$00a5a1da,$00b80010,
                                        $00cb5488,$00df9f10,$00f4df76,$010b1584,
                                        $01224101,$013a61b2,$01537759,$016d81b6,
                                        $01888087,$01a47385,$01c15a69,$01df34e6,
                                        $01fe02b1,$021dc377,$023e76e7,$02601ca9,
                                        $0282b466,$02a63dc1,$02cab85d,$02f023d6,
                                        $03167fcb,$033dcbd3,$03660783,$038f3270,
                                        $03b94c29,$03e4543a,$04104a2e,$043d2d8b,
                                        $046afdd5,$0499ba8c,$04c9632d,$04f9f734,
                                        $052b7615,$055ddf46,$05913237,$05c56e53,
                                        $05fa9306,$06309fb6,$066793c5,$069f6e93,
                                        $06d82f7c,$0711d5d9,$074c60fe,$0787d03d,
                                        $07c422e4,$0801583e,$083f6f91,$087e681f,
                                        $08be4129,$08fef9ea,$0940919a,$0983076d,
                                        $09c65a92,$0a0a8a38,$0a4f9585,$0a957b9f,
                                        $0adc3ba7,$0b23d4b9,$0b6c45ee,$0bb58e5a,
                                        $0bffad0f,$0c4aa11a,$0c966982,$0ce3054d,
                                        $0d30737b,$0d7eb308,$0dcdc2eb,$0e1da21a,
                                        $0e6e4f83,$0ebfca11,$0f1210ad,$0f652238,
                                        $0fb8fd91,$100da192,$10630d11,$10b93ee0,
                                        $111035cb,$1167f09a,$11c06e13,$1219acf5,
                                        $1273abfb,$12ce69db,$1329e54a,$13861cf3,
                                        $13e30f80,$1440bb97,$149f1fd8,$14fe3ade,
                                        $155e0b40,$15be8f92,$161fc662,$1681ae38,
                                        $16e4459b,$17478b0b,$17ab7d03,$181019fb,
                                        $18756067,$18db4eb3,$1941e34a,$19a91c92,
                                        $1a10f8ea,$1a7976af,$1ae29439,$1b4c4fda,
                                        $1bb6a7e2,$1c219a9a,$1c8d2649,$1cf9492e,
                                        $1d660188,$1dd34d8e,$1e412b74,$1eaf996a,
                                        $1f1e959b,$1f8e1e2f,$1ffe3146,$206ecd01,
                                        $20dfef78,$215196c2,$21c3c0f0,$22366c10,
                                        $22a9962a,$231d3d45,$23915f60,$2405fa7a,
                                        $247b0c8c,$24f09389,$25668d65,$25dcf80c,
                                        $2653d167,$26cb175e,$2742c7d0,$27bae09e,
                                        $28335fa2,$28ac42b3,$292587a5,$299f2c48,
                                        $2a192e69,$2a938bd1,$2b0e4247,$2b894f8d,
                                        $2c04b164,$2c806588,$2cfc69b2,$2d78bb9a,
                                        $2df558f4,$2e723f6f,$2eef6cbb,$2f6cde83,
                                        $2fea9270,$30688627,$30e6b74e,$31652385,
                                        $31e3c86b,$3262a39e,$32e1b2b8,$3360f352,
                                        $33e06303,$345fff5e,$34dfc5f8,$355fb462,
                                        $35dfc82a,$365ffee0,$36e0560f,$3760cb43,
                                        $37e15c05,$386205df,$38e2c657,$39639af5,
                                        $39e4813e,$3a6576b6,$3ae678e3,$3b678547,
                                        $3be89965,$3c69b2c1,$3ceacedc,$3d6beb37,
                                        $3ded0557,$3e6e1abb,$3eef28e6,$3f702d5a,
                                        $3ff1259a,$40720f29,$40f2e789,$4173ac3f,
                                        $41f45ad0,$4274f0c2,$42f56b9a,$4375c8e0,
                                        $43f6061d,$447620db,$44f616a5,$4575e509,
                                        $45f58994,$467501d6,$46f44b62,$477363cb,
                                        $47f248a6,$4870f78e,$48ef6e1a,$496da9e8,
                                        $49eba897,$4a6967c8,$4ae6e521,$4b641e47,
                                        $4be110e5,$4c5dbaa7,$4cda193f,$4d562a5f,
                                        $4dd1ebbd,$4e4d5b15,$4ec87623,$4f433aa9,
                                        $4fbda66c,$5037b734,$50b16acf,$512abf0e,
                                        $51a3b1c5,$521c40ce,$52946a06,$530c2b50,
                                        $53838292,$53fa6db8,$5470eab3,$54e6f776,
                                        $555c91fc,$55d1b844,$56466851,$56baa02f,
                                        $572e5deb,$57a19f98,$58146352,$5886a737,
                                        $58f8696d,$5969a81c,$59da6177,$5a4a93b4,
                                        $5aba3d0f,$5b295bcb,$5b97ee30,$5c05f28d,
                                        $5c736738,$5ce04a8d,$5d4c9aed,$5db856c1,
                                        $5e237c78,$5e8e0a89,$5ef7ff6f,$5f6159b0,
                                        $5fca17d4,$6032386e,$6099ba15,$61009b69,
                                        $6166db11,$61cc77b9,$62317017,$6295c2e7,
                                        $62f96eec,$635c72f1,$63becdc8,$64207e4b,
                                        $6481835a,$64e1dbde,$654186c8,$65a0830e,
                                        $65fecfb1,$665c6bb7,$66b95630,$67158e30,
                                        $677112d7,$67cbe34b,$6825feb9,$687f6456,
                                        $68d81361,$69300b1e,$69874ada,$69ddd1ea,
                                        $6a339fab,$6a88b382,$6add0cdb,$6b30ab2a,
                                        $6b838dec,$6bd5b4a6,$6c271ee2,$6c77cc36,
                                        $6cc7bc3d,$6d16ee9b,$6d6562fb,$6db31911,
                                        $6e001099,$6e4c4955,$6e97c311,$6ee27d9f,
                                        $6f2c78d9,$6f75b4a2,$6fbe30e4,$7005ed91,
                                        $704ceaa1,$70932816,$70d8a5f8,$711d6457,
                                        $7161634b,$71a4a2f3,$71e72375,$7228e500,
                                        $7269e7c8,$72aa2c0a,$72e9b209,$73287a12,
                                        $73668476,$73a3d18f,$73e061bc,$741c3566,
                                        $74574cfa,$7491a8ee,$74cb49be,$75042fec,
                                        $753c5c03,$7573ce92,$75aa882f,$75e08979,
                                        $7615d313,$764a65a7,$767e41e5,$76b16884,
                                        $76e3da40,$771597dc,$7746a221,$7776f9dd,
                                        $77a69fe6,$77d59514,$7803da49,$7831706a,
                                        $785e5861,$788a9320,$78b6219c,$78e104cf,
                                        $790b3dbb,$7934cd64,$795db4d5,$7985f51d,
                                        $79ad8f50,$79d48486,$79fad5de,$7a208478,
                                        $7a45917b,$7a69fe12,$7a8dcb6c,$7ab0fabb,
                                        $7ad38d36,$7af5841a,$7b16e0a3,$7b37a416,
                                        $7b57cfb8,$7b7764d4,$7b9664b6,$7bb4d0b0,
                                        $7bd2aa14,$7beff23b,$7c0caa7f,$7c28d43c,
                                        $7c4470d2,$7c5f81a5,$7c7a081a,$7c940598,
                                        $7cad7b8b,$7cc66b5e,$7cded680,$7cf6be64,
                                        $7d0e247b,$7d250a3c,$7d3b711c,$7d515a95,
                                        $7d66c822,$7d7bbb3c,$7d903563,$7da43814,
                                        $7db7c4d0,$7dcadd16,$7ddd826a,$7defb64d,
                                        $7e017a44,$7e12cfd3,$7e23b87f,$7e3435cc,
                                        $7e444943,$7e53f467,$7e6338c0,$7e7217d5,
                                        $7e80932b,$7e8eac49,$7e9c64b7,$7ea9bdf8,
                                        $7eb6b994,$7ec35910,$7ecf9def,$7edb89b6,
                                        $7ee71de9,$7ef25c09,$7efd4598,$7f07dc16,
                                        $7f122103,$7f1c15dc,$7f25bc1f,$7f2f1547,
                                        $7f3822cd,$7f40e62b,$7f4960d6,$7f519443,
                                        $7f5981e7,$7f612b31,$7f689191,$7f6fb674,
                                        $7f769b45,$7f7d416c,$7f83aa51,$7f89d757,
                                        $7f8fc9df,$7f958348,$7f9b04ef,$7fa0502e,
                                        $7fa56659,$7faa48c7,$7faef8c7,$7fb377a7,
                                        $7fb7c6b3,$7fbbe732,$7fbfda67,$7fc3a196,
                                        $7fc73dfa,$7fcab0ce,$7fcdfb4a,$7fd11ea0,
                                        $7fd41c00,$7fd6f496,$7fd9a989,$7fdc3bff,
                                        $7fdead17,$7fe0fdee,$7fe32f9d,$7fe54337,
                                        $7fe739ce,$7fe9146c,$7fead41b,$7fec79dd,
                                        $7fee06b2,$7fef7b94,$7ff0d97b,$7ff22158,
                                        $7ff35417,$7ff472a3,$7ff57de0,$7ff676ac,
                                        $7ff75de3,$7ff8345a,$7ff8fae4,$7ff9b24b,
                                        $7ffa5b58,$7ffaf6cd,$7ffb8568,$7ffc07e2,
                                        $7ffc7eed,$7ffceb38,$7ffd4d6d,$7ffda631,
                                        $7ffdf621,$7ffe3dd8,$7ffe7dea,$7ffeb6e7,
                                        $7ffee959,$7fff15c4,$7fff3ca9,$7fff5e80,
                                        $7fff7bc0,$7fff94d6,$7fffaa2d,$7fffbc29,
                                        $7fffcb29,$7fffd786,$7fffe195,$7fffe9a3,
                                        $7fffeffa,$7ffff4dd,$7ffff889,$7ffffb37,
                                        $7ffffd1a,$7ffffe5d,$7fffff29,$7fffffa0,
                                        $7fffffdd,$7ffffff7,$7fffffff,$7fffffff);

     vwin2048:array[0..1023] of longint=($000007c0,$000045c4,$0000c1ca,$00017bd3,
                                         $000273de,$0003a9eb,$00051df9,$0006d007,
                                         $0008c014,$000aee1e,$000d5a25,$00100428,
                                         $0012ec23,$00161216,$001975fe,$001d17da,
                                         $0020f7a8,$00251564,$0029710c,$002e0a9e,
                                         $0032e217,$0037f773,$003d4ab0,$0042dbca,
                                         $0048aabe,$004eb788,$00550224,$005b8a8f,
                                         $006250c5,$006954c1,$0070967e,$007815f9,
                                         $007fd32c,$0087ce13,$009006a9,$00987ce9,
                                         $00a130cc,$00aa224f,$00b3516b,$00bcbe1a,
                                         $00c66856,$00d0501a,$00da755f,$00e4d81f,
                                         $00ef7853,$00fa55f4,$010570fc,$0110c963,
                                         $011c5f22,$01283232,$0134428c,$01409027,
                                         $014d1afb,$0159e302,$0166e831,$01742a82,
                                         $0181a9ec,$018f6665,$019d5fe5,$01ab9663,
                                         $01ba09d6,$01c8ba34,$01d7a775,$01e6d18d,
                                         $01f63873,$0205dc1e,$0215bc82,$0225d997,
                                         $02363350,$0246c9a3,$02579c86,$0268abed,
                                         $0279f7cc,$028b801a,$029d44c9,$02af45ce,
                                         $02c1831d,$02d3fcaa,$02e6b269,$02f9a44c,
                                         $030cd248,$03203c4f,$0333e255,$0347c44b,
                                         $035be225,$03703bd5,$0384d14d,$0399a280,
                                         $03aeaf5e,$03c3f7d9,$03d97be4,$03ef3b6e,
                                         $0405366a,$041b6cc8,$0431de78,$04488b6c,
                                         $045f7393,$047696dd,$048df53b,$04a58e9b,
                                         $04bd62ee,$04d57223,$04edbc28,$050640ed,
                                         $051f0060,$0537fa70,$05512f0a,$056a9e1e,
                                         $05844798,$059e2b67,$05b84978,$05d2a1b8,
                                         $05ed3414,$06080079,$062306d3,$063e470f,
                                         $0659c119,$067574dd,$06916247,$06ad8941,
                                         $06c9e9b8,$06e68397,$070356c8,$07206336,
                                         $073da8cb,$075b2772,$0778df15,$0796cf9c,
                                         $07b4f8f3,$07d35b01,$07f1f5b1,$0810c8eb,
                                         $082fd497,$084f189e,$086e94e9,$088e495e,
                                         $08ae35e6,$08ce5a68,$08eeb6cc,$090f4af8,
                                         $093016d3,$09511a44,$09725530,$0993c77f,
                                         $09b57115,$09d751d8,$09f969ae,$0a1bb87c,
                                         $0a3e3e26,$0a60fa91,$0a83eda2,$0aa7173c,
                                         $0aca7743,$0aee0d9b,$0b11da28,$0b35dccc,
                                         $0b5a156a,$0b7e83e5,$0ba3281f,$0bc801fa,
                                         $0bed1159,$0c12561c,$0c37d025,$0c5d7f55,
                                         $0c83638d,$0ca97cae,$0ccfca97,$0cf64d2a,
                                         $0d1d0444,$0d43efc7,$0d6b0f92,$0d926383,
                                         $0db9eb79,$0de1a752,$0e0996ee,$0e31ba29,
                                         $0e5a10e2,$0e829af6,$0eab5841,$0ed448a2,
                                         $0efd6bf4,$0f26c214,$0f504ade,$0f7a062e,
                                         $0fa3f3df,$0fce13cd,$0ff865d2,$1022e9ca,
                                         $104d9f8e,$107886f9,$10a39fe5,$10ceea2c,
                                         $10fa65a6,$1126122d,$1151ef9a,$117dfdc5,
                                         $11aa3c87,$11d6abb6,$12034b2c,$12301ac0,
                                         $125d1a48,$128a499b,$12b7a891,$12e536ff,
                                         $1312f4bb,$1340e19c,$136efd75,$139d481e,
                                         $13cbc16a,$13fa692f,$14293f40,$14584371,
                                         $14877597,$14b6d585,$14e6630d,$15161e04,
                                         $1546063b,$15761b85,$15a65db3,$15d6cc99,
                                         $16076806,$16382fcd,$166923bf,$169a43ab,
                                         $16cb8f62,$16fd06b5,$172ea973,$1760776b,
                                         $1792706e,$17c49449,$17f6e2cb,$18295bc3,
                                         $185bfeff,$188ecc4c,$18c1c379,$18f4e452,
                                         $19282ea4,$195ba23c,$198f3ee6,$19c3046e,
                                         $19f6f2a1,$1a2b094a,$1a5f4833,$1a93af28,
                                         $1ac83df3,$1afcf460,$1b31d237,$1b66d744,
                                         $1b9c034e,$1bd15621,$1c06cf84,$1c3c6f40,
                                         $1c72351e,$1ca820e6,$1cde3260,$1d146953,
                                         $1d4ac587,$1d8146c3,$1db7eccd,$1deeb76c,
                                         $1e25a667,$1e5cb982,$1e93f085,$1ecb4b33,
                                         $1f02c953,$1f3a6aaa,$1f722efb,$1faa160b,
                                         $1fe21f9e,$201a4b79,$2052995d,$208b0910,
                                         $20c39a53,$20fc4cea,$21352097,$216e151c,
                                         $21a72a3a,$21e05fb5,$2219b54d,$22532ac3,
                                         $228cbfd8,$22c6744d,$230047e2,$233a3a58,
                                         $23744b6d,$23ae7ae3,$23e8c878,$242333ec,
                                         $245dbcfd,$24986369,$24d326f1,$250e0750,
                                         $25490446,$25841d90,$25bf52ec,$25faa417,
                                         $263610cd,$267198cc,$26ad3bcf,$26e8f994,
                                         $2724d1d6,$2760c451,$279cd0c0,$27d8f6e0,
                                         $2815366a,$28518f1b,$288e00ac,$28ca8ad8,
                                         $29072d5a,$2943e7eb,$2980ba45,$29bda422,
                                         $29faa53c,$2a37bd4a,$2a74ec07,$2ab2312b,
                                         $2aef8c6f,$2b2cfd8b,$2b6a8437,$2ba8202c,
                                         $2be5d120,$2c2396cc,$2c6170e7,$2c9f5f29,
                                         $2cdd6147,$2d1b76fa,$2d599ff7,$2d97dbf5,
                                         $2dd62aab,$2e148bcf,$2e52ff16,$2e918436,
                                         $2ed01ae5,$2f0ec2d9,$2f4d7bc6,$2f8c4562,
                                         $2fcb1f62,$300a097a,$3049035f,$30880cc6,
                                         $30c72563,$31064cea,$3145830f,$3184c786,
                                         $31c41a03,$32037a39,$3242e7dc,$3282629f,
                                         $32c1ea36,$33017e53,$33411ea9,$3380caec,
                                         $33c082ce,$34004602,$34401439,$347fed27,
                                         $34bfd07e,$34ffbdf0,$353fb52e,$357fb5ec,
                                         $35bfbfda,$35ffd2aa,$363fee0f,$368011b9,
                                         $36c03d5a,$370070a4,$3740ab48,$3780ecf7,
                                         $37c13562,$3801843a,$3841d931,$388233f7,
                                         $38c2943d,$3902f9b4,$3943640d,$3983d2f8,
                                         $39c44626,$3a04bd48,$3a45380e,$3a85b62a,
                                         $3ac6374a,$3b06bb20,$3b47415c,$3b87c9ae,
                                         $3bc853c7,$3c08df57,$3c496c0f,$3c89f99f,
                                         $3cca87b6,$3d0b1605,$3d4ba43d,$3d8c320e,
                                         $3dccbf27,$3e0d4b3a,$3e4dd5f6,$3e8e5f0c,
                                         $3ecee62b,$3f0f6b05,$3f4fed49,$3f906ca8,
                                         $3fd0e8d2,$40116177,$4051d648,$409246f6,
                                         $40d2b330,$41131aa7,$41537d0c,$4193da10,
                                         $41d43162,$421482b4,$4254cdb7,$4295121b,
                                         $42d54f91,$431585ca,$4355b477,$4395db49,
                                         $43d5f9f1,$44161021,$44561d8a,$449621dd,
                                         $44d61ccc,$45160e08,$4555f544,$4595d230,
                                         $45d5a47f,$46156be3,$4655280e,$4694d8b2,
                                         $46d47d82,$4714162f,$4753a26d,$479321ef,
                                         $47d29466,$4811f987,$48515104,$48909a91,
                                         $48cfd5e1,$490f02a7,$494e2098,$498d2f66,
                                         $49cc2ec7,$4a0b1e6f,$4a49fe11,$4a88cd62,
                                         $4ac78c18,$4b0639e6,$4b44d683,$4b8361a2,
                                         $4bc1dafa,$4c004241,$4c3e972c,$4c7cd970,
                                         $4cbb08c5,$4cf924e1,$4d372d7a,$4d752247,
                                         $4db30300,$4df0cf5a,$4e2e870f,$4e6c29d6,
                                         $4ea9b766,$4ee72f78,$4f2491c4,$4f61de02,
                                         $4f9f13ec,$4fdc333b,$50193ba8,$50562ced,
                                         $509306c3,$50cfc8e5,$510c730d,$514904f6,
                                         $51857e5a,$51c1def5,$51fe2682,$523a54bc,
                                         $52766961,$52b2642c,$52ee44d9,$532a0b26,
                                         $5365b6d0,$53a14793,$53dcbd2f,$54181760,
                                         $545355e5,$548e787d,$54c97ee6,$550468e1,
                                         $553f362c,$5579e687,$55b479b3,$55eeef70,
                                         $5629477f,$566381a1,$569d9d97,$56d79b24,
                                         $57117a0a,$574b3a0a,$5784dae9,$57be5c69,
                                         $57f7be4d,$5831005a,$586a2254,$58a32400,
                                         $58dc0522,$5914c57f,$594d64de,$5985e305,
                                         $59be3fba,$59f67ac3,$5a2e93e9,$5a668af2,
                                         $5a9e5fa6,$5ad611ce,$5b0da133,$5b450d9d,
                                         $5b7c56d7,$5bb37ca9,$5bea7ede,$5c215d41,
                                         $5c58179d,$5c8eadbe,$5cc51f6f,$5cfb6c7c,
                                         $5d3194b2,$5d6797de,$5d9d75cf,$5dd32e51,
                                         $5e08c132,$5e3e2e43,$5e737551,$5ea8962d,
                                         $5edd90a7,$5f12648e,$5f4711b4,$5f7b97ea,
                                         $5faff702,$5fe42ece,$60183f20,$604c27cc,
                                         $607fe8a6,$60b38180,$60e6f22f,$611a3a89,
                                         $614d5a62,$61805190,$61b31fe9,$61e5c545,
                                         $62184179,$624a945d,$627cbdca,$62aebd98,
                                         $62e0939f,$63123fba,$6343c1c1,$6375198f,
                                         $63a646ff,$63d749ec,$64082232,$6438cfad,
                                         $64695238,$6499a9b3,$64c9d5f9,$64f9d6ea,
                                         $6529ac63,$65595643,$6588d46a,$65b826b8,
                                         $65e74d0e,$6616474b,$66451552,$6673b704,
                                         $66a22c44,$66d074f4,$66fe90f8,$672c8033,
                                         $675a428a,$6787d7e1,$67b5401f,$67e27b27,
                                         $680f88e1,$683c6934,$68691c05,$6895a13e,
                                         $68c1f8c7,$68ee2287,$691a1e68,$6945ec54,
                                         $69718c35,$699cfdf5,$69c8417f,$69f356c0,
                                         $6a1e3da3,$6a48f615,$6a738002,$6a9ddb5a,
                                         $6ac80808,$6af205fd,$6b1bd526,$6b457575,
                                         $6b6ee6d8,$6b982940,$6bc13c9f,$6bea20e5,
                                         $6c12d605,$6c3b5bf1,$6c63b29c,$6c8bd9fb,
                                         $6cb3d200,$6cdb9aa0,$6d0333d0,$6d2a9d86,
                                         $6d51d7b7,$6d78e25a,$6d9fbd67,$6dc668d3,
                                         $6dece498,$6e1330ad,$6e394d0c,$6e5f39ae,
                                         $6e84f68d,$6eaa83a2,$6ecfe0ea,$6ef50e5e,
                                         $6f1a0bfc,$6f3ed9bf,$6f6377a4,$6f87e5a8,
                                         $6fac23c9,$6fd03206,$6ff4105c,$7017becc,
                                         $703b3d54,$705e8bf5,$7081aaaf,$70a49984,
                                         $70c75874,$70e9e783,$710c46b2,$712e7605,
                                         $7150757f,$71724523,$7193e4f6,$71b554fd,
                                         $71d6953e,$71f7a5bd,$72188681,$72393792,
                                         $7259b8f5,$727a0ab2,$729a2cd2,$72ba1f5d,
                                         $72d9e25c,$72f975d8,$7318d9db,$73380e6f,
                                         $735713a0,$7375e978,$73949003,$73b3074c,
                                         $73d14f61,$73ef684f,$740d5222,$742b0ce9,
                                         $744898b1,$7465f589,$74832381,$74a022a8,
                                         $74bcf30e,$74d994c3,$74f607d8,$75124c5f,
                                         $752e6268,$754a4a05,$7566034b,$75818e4a,
                                         $759ceb16,$75b819c4,$75d31a66,$75eded12,
                                         $760891dc,$762308da,$763d5221,$76576dc8,
                                         $76715be4,$768b1c8c,$76a4afd9,$76be15e0,
                                         $76d74ebb,$76f05a82,$7709394d,$7721eb35,
                                         $773a7054,$7752c8c4,$776af49f,$7782f400,
                                         $779ac701,$77b26dbd,$77c9e851,$77e136d8,
                                         $77f8596f,$780f5032,$78261b3f,$783cbab2,
                                         $78532eaa,$78697745,$787f94a0,$789586db,
                                         $78ab4e15,$78c0ea6d,$78d65c03,$78eba2f7,
                                         $7900bf68,$7915b179,$792a7949,$793f16fb,
                                         $79538aaf,$7967d488,$797bf4a8,$798feb31,
                                         $79a3b846,$79b75c0a,$79cad6a1,$79de282e,
                                         $79f150d5,$7a0450bb,$7a172803,$7a29d6d3,
                                         $7a3c5d50,$7a4ebb9f,$7a60f1e6,$7a73004a,
                                         $7a84e6f2,$7a96a604,$7aa83da7,$7ab9ae01,
                                         $7acaf73a,$7adc1979,$7aed14e6,$7afde9a8,
                                         $7b0e97e8,$7b1f1fcd,$7b2f8182,$7b3fbd2d,
                                         $7b4fd2f9,$7b5fc30f,$7b6f8d98,$7b7f32bd,
                                         $7b8eb2a9,$7b9e0d85,$7bad437d,$7bbc54b9,
                                         $7bcb4166,$7bda09ae,$7be8adbc,$7bf72dbc,
                                         $7c0589d8,$7c13c23d,$7c21d716,$7c2fc88f,
                                         $7c3d96d5,$7c4b4214,$7c58ca78,$7c66302d,
                                         $7c737362,$7c809443,$7c8d92fc,$7c9a6fbc,
                                         $7ca72aaf,$7cb3c404,$7cc03be8,$7ccc9288,
                                         $7cd8c814,$7ce4dcb9,$7cf0d0a5,$7cfca406,
                                         $7d08570c,$7d13e9e5,$7d1f5cbf,$7d2aafca,
                                         $7d35e335,$7d40f72e,$7d4bebe4,$7d56c188,
                                         $7d617848,$7d6c1054,$7d7689db,$7d80e50e,
                                         $7d8b221b,$7d954133,$7d9f4286,$7da92643,
                                         $7db2ec9b,$7dbc95bd,$7dc621da,$7dcf9123,
                                         $7dd8e3c6,$7de219f6,$7deb33e2,$7df431ba,
                                         $7dfd13af,$7e05d9f2,$7e0e84b4,$7e171424,
                                         $7e1f8874,$7e27e1d4,$7e302074,$7e384487,
                                         $7e404e3c,$7e483dc4,$7e501350,$7e57cf11,
                                         $7e5f7138,$7e66f9f4,$7e6e6979,$7e75bff5,
                                         $7e7cfd9a,$7e842298,$7e8b2f22,$7e922366,
                                         $7e98ff97,$7e9fc3e4,$7ea6707f,$7ead0598,
                                         $7eb38360,$7eb9ea07,$7ec039bf,$7ec672b7,
                                         $7ecc9521,$7ed2a12c,$7ed8970a,$7ede76ea,
                                         $7ee440fd,$7ee9f573,$7eef947d,$7ef51e4b,
                                         $7efa930d,$7efff2f2,$7f053e2b,$7f0a74e8,
                                         $7f0f9758,$7f14a5ac,$7f19a013,$7f1e86bc,
                                         $7f2359d8,$7f281995,$7f2cc623,$7f315fb1,
                                         $7f35e66e,$7f3a5a8a,$7f3ebc33,$7f430b98,
                                         $7f4748e7,$7f4b7450,$7f4f8e01,$7f539629,
                                         $7f578cf5,$7f5b7293,$7f5f4732,$7f630b00,
                                         $7f66be2b,$7f6a60df,$7f6df34b,$7f71759b,
                                         $7f74e7fe,$7f784aa0,$7f7b9daf,$7f7ee156,
                                         $7f8215c3,$7f853b22,$7f88519f,$7f8b5967,
                                         $7f8e52a6,$7f913d87,$7f941a36,$7f96e8df,
                                         $7f99a9ad,$7f9c5ccb,$7f9f0265,$7fa19aa5,
                                         $7fa425b5,$7fa6a3c1,$7fa914f3,$7fab7974,
                                         $7fadd16f,$7fb01d0d,$7fb25c78,$7fb48fd9,
                                         $7fb6b75a,$7fb8d323,$7fbae35d,$7fbce831,
                                         $7fbee1c7,$7fc0d047,$7fc2b3d9,$7fc48ca5,
                                         $7fc65ad3,$7fc81e88,$7fc9d7ee,$7fcb872a,
                                         $7fcd2c63,$7fcec7bf,$7fd05966,$7fd1e17c,
                                         $7fd36027,$7fd4d58d,$7fd641d3,$7fd7a51e,
                                         $7fd8ff94,$7fda5157,$7fdb9a8e,$7fdcdb5b,
                                         $7fde13e2,$7fdf4448,$7fe06caf,$7fe18d3b,
                                         $7fe2a60e,$7fe3b74b,$7fe4c114,$7fe5c38b,
                                         $7fe6bed2,$7fe7b30a,$7fe8a055,$7fe986d4,
                                         $7fea66a7,$7feb3ff0,$7fec12cd,$7fecdf5f,
                                         $7feda5c5,$7fee6620,$7fef208d,$7fefd52c,
                                         $7ff0841c,$7ff12d7a,$7ff1d164,$7ff26ff9,
                                         $7ff30955,$7ff39d96,$7ff42cd9,$7ff4b739,
                                         $7ff53cd4,$7ff5bdc5,$7ff63a28,$7ff6b217,
                                         $7ff725af,$7ff7950a,$7ff80043,$7ff86773,
                                         $7ff8cab4,$7ff92a21,$7ff985d1,$7ff9dddf,
                                         $7ffa3262,$7ffa8374,$7ffad12c,$7ffb1ba1,
                                         $7ffb62ec,$7ffba723,$7ffbe85c,$7ffc26b0,
                                         $7ffc6233,$7ffc9afb,$7ffcd11e,$7ffd04b1,
                                         $7ffd35c9,$7ffd647b,$7ffd90da,$7ffdbafa,
                                         $7ffde2f0,$7ffe08ce,$7ffe2ca7,$7ffe4e8e,
                                         $7ffe6e95,$7ffe8cce,$7ffea94a,$7ffec41b,
                                         $7ffedd52,$7ffef4ff,$7fff0b33,$7fff1ffd,
                                         $7fff336e,$7fff4593,$7fff567d,$7fff663a,
                                         $7fff74d8,$7fff8265,$7fff8eee,$7fff9a81,
                                         $7fffa52b,$7fffaef8,$7fffb7f5,$7fffc02d,
                                         $7fffc7ab,$7fffce7c,$7fffd4a9,$7fffda3e,
                                         $7fffdf44,$7fffe3c6,$7fffe7cc,$7fffeb60,
                                         $7fffee8a,$7ffff153,$7ffff3c4,$7ffff5e3,
                                         $7ffff7b8,$7ffff94b,$7ffffaa1,$7ffffbc1,
                                         $7ffffcb2,$7ffffd78,$7ffffe19,$7ffffe9a,
                                         $7ffffeff,$7fffff4e,$7fffff89,$7fffffb3,
                                         $7fffffd2,$7fffffe6,$7ffffff3,$7ffffffa,
                                         $7ffffffe,$7fffffff,$7fffffff,$7fffffff);

     vwin4096:array[0..2047] of longint=($000001f0,$00001171,$00003072,$00005ef5,
                                         $00009cf8,$0000ea7c,$00014780,$0001b405,
                                         $0002300b,$0002bb91,$00035698,$0004011e,
                                         $0004bb25,$000584ac,$00065db3,$0007463a,
                                         $00083e41,$000945c7,$000a5ccc,$000b8350,
                                         $000cb954,$000dfed7,$000f53d8,$0010b857,
                                         $00122c55,$0013afd1,$001542ca,$0016e541,
                                         $00189735,$001a58a7,$001c2995,$001e09ff,
                                         $001ff9e6,$0021f948,$00240826,$00262680,
                                         $00285454,$002a91a3,$002cde6c,$002f3aaf,
                                         $0031a66b,$003421a0,$0036ac4f,$00394675,
                                         $003bf014,$003ea92a,$004171b7,$004449bb,
                                         $00473135,$004a2824,$004d2e8a,$00504463,
                                         $005369b2,$00569e74,$0059e2aa,$005d3652,
                                         $0060996d,$00640bf9,$00678df7,$006b1f66,
                                         $006ec045,$00727093,$00763051,$0079ff7d,
                                         $007dde16,$0081cc1d,$0085c991,$0089d671,
                                         $008df2bc,$00921e71,$00965991,$009aa41a,
                                         $009efe0c,$00a36766,$00a7e028,$00ac6850,
                                         $00b0ffde,$00b5a6d1,$00ba5d28,$00bf22e4,
                                         $00c3f802,$00c8dc83,$00cdd065,$00d2d3a8,
                                         $00d7e64a,$00dd084c,$00e239ac,$00e77a69,
                                         $00ecca83,$00f229f9,$00f798ca,$00fd16f5,
                                         $0102a479,$01084155,$010ded89,$0113a913,
                                         $011973f3,$011f4e27,$012537af,$012b308a,
                                         $013138b7,$01375035,$013d7702,$0143ad1f,
                                         $0149f289,$01504741,$0156ab44,$015d1e92,
                                         $0163a12a,$016a330b,$0170d433,$017784a3,
                                         $017e4458,$01851351,$018bf18e,$0192df0d,
                                         $0199dbcd,$01a0e7cd,$01a8030c,$01af2d89,
                                         $01b66743,$01bdb038,$01c50867,$01cc6fd0,
                                         $01d3e670,$01db6c47,$01e30153,$01eaa593,
                                         $01f25907,$01fa1bac,$0201ed81,$0209ce86,
                                         $0211beb8,$0219be17,$0221cca2,$0229ea56,
                                         $02321733,$023a5337,$02429e60,$024af8af,
                                         $02536220,$025bdab3,$02646267,$026cf93a,
                                         $02759f2a,$027e5436,$0287185d,$028feb9d,
                                         $0298cdf4,$02a1bf62,$02aabfe5,$02b3cf7b,
                                         $02bcee23,$02c61bdb,$02cf58a2,$02d8a475,
                                         $02e1ff55,$02eb693e,$02f4e230,$02fe6a29,
                                         $03080127,$0311a729,$031b5c2d,$03252031,
                                         $032ef334,$0338d534,$0342c630,$034cc625,
                                         $0356d512,$0360f2f6,$036b1fce,$03755b99,
                                         $037fa655,$038a0001,$0394689a,$039ee020,
                                         $03a9668f,$03b3fbe6,$03bea024,$03c95347,
                                         $03d4154d,$03dee633,$03e9c5f9,$03f4b49b,
                                         $03ffb219,$040abe71,$0415d9a0,$042103a5,
                                         $042c3c7d,$04378428,$0442daa2,$044e3fea,
                                         $0459b3fd,$046536db,$0470c880,$047c68eb,
                                         $0488181a,$0493d60b,$049fa2bc,$04ab7e2a,
                                         $04b76854,$04c36137,$04cf68d1,$04db7f21,
                                         $04e7a424,$04f3d7d8,$05001a3b,$050c6b4a,
                                         $0518cb04,$05253966,$0531b66e,$053e421a,
                                         $054adc68,$05578555,$05643cdf,$05710304,
                                         $057dd7c1,$058abb15,$0597acfd,$05a4ad76,
                                         $05b1bc7f,$05beda14,$05cc0635,$05d940dd,
                                         $05e68a0b,$05f3e1bd,$060147f0,$060ebca1,
                                         $061c3fcf,$0629d176,$06377194,$06452027,
                                         $0652dd2c,$0660a8a2,$066e8284,$067c6ad1,
                                         $068a6186,$069866a1,$06a67a1e,$06b49bfc,
                                         $06c2cc38,$06d10acf,$06df57bf,$06edb304,
                                         $06fc1c9d,$070a9487,$07191abe,$0727af40,
                                         $0736520b,$0745031c,$0753c270,$07629004,
                                         $07716bd6,$078055e2,$078f4e26,$079e549f,
                                         $07ad694b,$07bc8c26,$07cbbd2e,$07dafc5f,
                                         $07ea49b7,$07f9a533,$08090ed1,$0818868c,
                                         $08280c62,$0837a051,$08474255,$0856f26b,
                                         $0866b091,$08767cc3,$088656fe,$08963f3f,
                                         $08a63584,$08b639c8,$08c64c0a,$08d66c45,
                                         $08e69a77,$08f6d69d,$090720b3,$091778b7,
                                         $0927dea5,$0938527a,$0948d433,$095963cc,
                                         $096a0143,$097aac94,$098b65bb,$099c2cb6,
                                         $09ad0182,$09bde41a,$09ced47d,$09dfd2a5,
                                         $09f0de90,$0a01f83b,$0a131fa3,$0a2454c3,
                                         $0a359798,$0a46e820,$0a584656,$0a69b237,
                                         $0a7b2bc0,$0a8cb2ec,$0a9e47ba,$0aafea24,
                                         $0ac19a29,$0ad357c3,$0ae522ef,$0af6fbab,
                                         $0b08e1f1,$0b1ad5c0,$0b2cd712,$0b3ee5e5,
                                         $0b510234,$0b632bfd,$0b75633b,$0b87a7eb,
                                         $0b99fa08,$0bac5990,$0bbec67e,$0bd140cf,
                                         $0be3c87e,$0bf65d89,$0c08ffeb,$0c1bafa1,
                                         $0c2e6ca6,$0c4136f6,$0c540e8f,$0c66f36c,
                                         $0c79e588,$0c8ce4e1,$0c9ff172,$0cb30b37,
                                         $0cc6322c,$0cd9664d,$0ceca797,$0cfff605,
                                         $0d135193,$0d26ba3d,$0d3a2fff,$0d4db2d5,
                                         $0d6142ba,$0d74dfac,$0d8889a5,$0d9c40a1,
                                         $0db0049d,$0dc3d593,$0dd7b380,$0deb9e60,
                                         $0dff962f,$0e139ae7,$0e27ac85,$0e3bcb05,
                                         $0e4ff662,$0e642e98,$0e7873a2,$0e8cc57d,
                                         $0ea12423,$0eb58f91,$0eca07c2,$0ede8cb1,
                                         $0ef31e5b,$0f07bcba,$0f1c67cb,$0f311f88,
                                         $0f45e3ee,$0f5ab4f7,$0f6f92a0,$0f847ce3,
                                         $0f9973bc,$0fae7726,$0fc3871e,$0fd8a39d,
                                         $0fedcca1,$10030223,$1018441f,$102d9291,
                                         $1042ed74,$105854c3,$106dc879,$10834892,
                                         $1098d508,$10ae6dd8,$10c412fc,$10d9c46f,
                                         $10ef822d,$11054c30,$111b2274,$113104f5,
                                         $1146f3ac,$115cee95,$1172f5ab,$118908e9,
                                         $119f284a,$11b553ca,$11cb8b62,$11e1cf0f,
                                         $11f81ecb,$120e7a90,$1224e25a,$123b5624,
                                         $1251d5e9,$126861a3,$127ef94e,$12959ce3,
                                         $12ac4c5f,$12c307bb,$12d9cef2,$12f0a200,
                                         $130780df,$131e6b8a,$133561fa,$134c642c,
                                         $1363721a,$137a8bbe,$1391b113,$13a8e214,
                                         $13c01eba,$13d76702,$13eebae5,$14061a5e,
                                         $141d8567,$1434fbfb,$144c7e14,$14640bae,
                                         $147ba4c1,$14934949,$14aaf941,$14c2b4a2,
                                         $14da7b67,$14f24d8a,$150a2b06,$152213d5,
                                         $153a07f1,$15520755,$156a11fb,$158227dd,
                                         $159a48f5,$15b2753d,$15caacb1,$15e2ef49,
                                         $15fb3d01,$161395d2,$162bf9b6,$164468a8,
                                         $165ce2a1,$1675679c,$168df793,$16a69280,
                                         $16bf385c,$16d7e922,$16f0a4cc,$17096b54,
                                         $17223cb4,$173b18e5,$1753ffe2,$176cf1a5,
                                         $1785ee27,$179ef562,$17b80750,$17d123eb,
                                         $17ea4b2d,$18037d10,$181cb98d,$1836009e,
                                         $184f523c,$1868ae63,$1882150a,$189b862c,
                                         $18b501c4,$18ce87c9,$18e81836,$1901b305,
                                         $191b582f,$193507ad,$194ec17a,$1968858f,
                                         $198253e5,$199c2c75,$19b60f3a,$19cffc2d,
                                         $19e9f347,$1a03f482,$1a1dffd7,$1a381540,
                                         $1a5234b5,$1a6c5e31,$1a8691ac,$1aa0cf21,
                                         $1abb1687,$1ad567da,$1aefc311,$1b0a2826,
                                         $1b249712,$1b3f0fd0,$1b599257,$1b741ea1,
                                         $1b8eb4a7,$1ba95462,$1bc3fdcd,$1bdeb0de,
                                         $1bf96d91,$1c1433dd,$1c2f03bc,$1c49dd27,
                                         $1c64c017,$1c7fac85,$1c9aa269,$1cb5a1be,
                                         $1cd0aa7c,$1cebbc9c,$1d06d816,$1d21fce4,
                                         $1d3d2aff,$1d586260,$1d73a2fe,$1d8eecd4,
                                         $1daa3fda,$1dc59c09,$1de1015a,$1dfc6fc5,
                                         $1e17e743,$1e3367cd,$1e4ef15b,$1e6a83e7,
                                         $1e861f6a,$1ea1c3da,$1ebd7133,$1ed9276b,
                                         $1ef4e67c,$1f10ae5e,$1f2c7f0a,$1f485879,
                                         $1f643aa2,$1f80257f,$1f9c1908,$1fb81536,
                                         $1fd41a00,$1ff02761,$200c3d4f,$20285bc3,
                                         $204482b7,$2060b221,$207ce9fb,$20992a3e,
                                         $20b572e0,$20d1c3dc,$20ee1d28,$210a7ebe,
                                         $2126e895,$21435aa6,$215fd4ea,$217c5757,
                                         $2198e1e8,$21b57493,$21d20f51,$21eeb21b,
                                         $220b5ce7,$22280fb0,$2244ca6c,$22618d13,
                                         $227e579f,$229b2a06,$22b80442,$22d4e649,
                                         $22f1d015,$230ec19d,$232bbad9,$2348bbc1,
                                         $2365c44c,$2382d474,$239fec30,$23bd0b78,
                                         $23da3244,$23f7608b,$24149646,$2431d36c,
                                         $244f17f5,$246c63da,$2489b711,$24a71193,
                                         $24c47358,$24e1dc57,$24ff4c88,$251cc3e2,
                                         $253a425e,$2557c7f4,$2575549a,$2592e848,
                                         $25b082f7,$25ce249e,$25ebcd34,$26097cb2,
                                         $2627330e,$2644f040,$2662b441,$26807f07,
                                         $269e5089,$26bc28c1,$26da07a4,$26f7ed2b,
                                         $2715d94d,$2733cc02,$2751c540,$276fc500,
                                         $278dcb39,$27abd7e2,$27c9eaf3,$27e80463,
                                         $28062429,$28244a3e,$28427697,$2860a92d,
                                         $287ee1f7,$289d20eb,$28bb6603,$28d9b134,
                                         $28f80275,$291659c0,$2934b709,$29531a49,
                                         $29718378,$298ff28b,$29ae677b,$29cce23e,
                                         $29eb62cb,$2a09e91b,$2a287523,$2a4706dc,
                                         $2a659e3c,$2a843b39,$2aa2ddcd,$2ac185ec,
                                         $2ae0338f,$2afee6ad,$2b1d9f3c,$2b3c5d33,
                                         $2b5b208b,$2b79e939,$2b98b734,$2bb78a74,
                                         $2bd662ef,$2bf5409d,$2c142374,$2c330b6b,
                                         $2c51f87a,$2c70ea97,$2c8fe1b9,$2caeddd6,
                                         $2ccddee7,$2cece4e1,$2d0befbb,$2d2aff6d,
                                         $2d4a13ec,$2d692d31,$2d884b32,$2da76de4,
                                         $2dc69540,$2de5c13d,$2e04f1d0,$2e2426f0,
                                         $2e436095,$2e629eb4,$2e81e146,$2ea1283f,
                                         $2ec07398,$2edfc347,$2eff1742,$2f1e6f80,
                                         $2f3dcbf8,$2f5d2ca0,$2f7c916f,$2f9bfa5c,
                                         $2fbb675d,$2fdad869,$2ffa4d76,$3019c67b,
                                         $3039436f,$3058c448,$307848fc,$3097d183,
                                         $30b75dd3,$30d6ede2,$30f681a6,$31161917,
                                         $3135b42b,$315552d8,$3174f514,$31949ad7,
                                         $31b44417,$31d3f0ca,$31f3a0e6,$32135462,
                                         $32330b35,$3252c555,$327282b7,$32924354,
                                         $32b20720,$32d1ce13,$32f19823,$33116546,
                                         $33313573,$3351089f,$3370dec2,$3390b7d1,
                                         $33b093c3,$33d0728f,$33f05429,$3410388a,
                                         $34301fa7,$34500977,$346ff5ef,$348fe506,
                                         $34afd6b3,$34cfcaeb,$34efc1a5,$350fbad7,
                                         $352fb678,$354fb47d,$356fb4dd,$358fb78e,
                                         $35afbc86,$35cfc3bc,$35efcd25,$360fd8b8,
                                         $362fe66c,$364ff636,$3670080c,$36901be5,
                                         $36b031b7,$36d04978,$36f0631e,$37107ea0,
                                         $37309bf3,$3750bb0e,$3770dbe6,$3790fe73,
                                         $37b122aa,$37d14881,$37f16fee,$381198e8,
                                         $3831c365,$3851ef5a,$38721cbe,$38924b87,
                                         $38b27bac,$38d2ad21,$38f2dfde,$391313d8,
                                         $39334906,$39537f5d,$3973b6d4,$3993ef60,
                                         $39b428f9,$39d46393,$39f49f25,$3a14dba6,
                                         $3a35190a,$3a555748,$3a759657,$3a95d62c,
                                         $3ab616be,$3ad65801,$3af699ed,$3b16dc78,
                                         $3b371f97,$3b576341,$3b77a76c,$3b97ec0d,
                                         $3bb8311b,$3bd8768b,$3bf8bc55,$3c19026d,
                                         $3c3948ca,$3c598f62,$3c79d62b,$3c9a1d1b,
                                         $3cba6428,$3cdaab48,$3cfaf271,$3d1b3999,
                                         $3d3b80b6,$3d5bc7be,$3d7c0ea8,$3d9c5569,
                                         $3dbc9bf7,$3ddce248,$3dfd2852,$3e1d6e0c,
                                         $3e3db36c,$3e5df866,$3e7e3cf2,$3e9e8106,
                                         $3ebec497,$3edf079b,$3eff4a09,$3f1f8bd7,
                                         $3f3fccfa,$3f600d69,$3f804d1a,$3fa08c02,
                                         $3fc0ca19,$3fe10753,$400143a7,$40217f0a,
                                         $4041b974,$4061f2da,$40822b32,$40a26272,
                                         $40c29891,$40e2cd83,$41030140,$412333bd,
                                         $414364f1,$416394d2,$4183c355,$41a3f070,
                                         $41c41c1b,$41e4464a,$42046ef4,$42249610,
                                         $4244bb92,$4264df72,$428501a5,$42a52222,
                                         $42c540de,$42e55dd0,$430578ed,$4325922d,
                                         $4345a985,$4365beeb,$4385d255,$43a5e3ba,
                                         $43c5f30f,$43e6004b,$44060b65,$44261451,
                                         $44461b07,$44661f7c,$448621a7,$44a6217d,
                                         $44c61ef6,$44e61a07,$450612a6,$452608ca,
                                         $4545fc69,$4565ed79,$4585dbf1,$45a5c7c6,
                                         $45c5b0ef,$45e59761,$46057b15,$46255bfe,
                                         $46453a15,$4665154f,$4684eda2,$46a4c305,
                                         $46c4956e,$46e464d3,$4704312b,$4723fa6c,
                                         $4743c08d,$47638382,$47834344,$47a2ffc9,
                                         $47c2b906,$47e26ef2,$48022183,$4821d0b1,
                                         $48417c71,$486124b9,$4880c981,$48a06abe,
                                         $48c00867,$48dfa272,$48ff38d6,$491ecb8a,
                                         $493e5a84,$495de5b9,$497d6d22,$499cf0b4,
                                         $49bc7066,$49dbec2e,$49fb6402,$4a1ad7db,
                                         $4a3a47ad,$4a59b370,$4a791b1a,$4a987ea1,
                                         $4ab7ddfd,$4ad73924,$4af6900c,$4b15e2ad,
                                         $4b3530fc,$4b547af1,$4b73c082,$4b9301a6,
                                         $4bb23e53,$4bd17681,$4bf0aa25,$4c0fd937,
                                         $4c2f03ae,$4c4e297f,$4c6d4aa3,$4c8c670f,
                                         $4cab7eba,$4cca919c,$4ce99fab,$4d08a8de,
                                         $4d27ad2c,$4d46ac8b,$4d65a6f3,$4d849c5a,
                                         $4da38cb7,$4dc27802,$4de15e31,$4e003f3a,
                                         $4e1f1b16,$4e3df1ba,$4e5cc31e,$4e7b8f3a,
                                         $4e9a5603,$4eb91771,$4ed7d37b,$4ef68a18,
                                         $4f153b3f,$4f33e6e7,$4f528d08,$4f712d97,
                                         $4f8fc88e,$4fae5de1,$4fcced8a,$4feb777f,
                                         $5009fbb6,$50287a28,$5046f2cc,$50656598,
                                         $5083d284,$50a23988,$50c09a9a,$50def5b1,
                                         $50fd4ac7,$511b99d0,$5139e2c5,$5158259e,
                                         $51766251,$519498d6,$51b2c925,$51d0f334,
                                         $51ef16fb,$520d3473,$522b4b91,$52495c4e,
                                         $526766a2,$52856a83,$52a367e9,$52c15ecd,
                                         $52df4f24,$52fd38e8,$531b1c10,$5338f892,
                                         $5356ce68,$53749d89,$539265eb,$53b02788,
                                         $53cde257,$53eb964f,$54094369,$5426e99c,
                                         $544488df,$5462212c,$547fb279,$549d3cbe,
                                         $54babff4,$54d83c12,$54f5b110,$55131ee7,
                                         $5530858d,$554de4fc,$556b3d2a,$55888e11,
                                         $55a5d7a8,$55c319e7,$55e054c7,$55fd883f,
                                         $561ab447,$5637d8d8,$5654f5ea,$56720b75,
                                         $568f1971,$56ac1fd7,$56c91e9e,$56e615c0,
                                         $57030534,$571fecf2,$573cccf3,$5759a530,
                                         $577675a0,$57933e3c,$57affefd,$57ccb7db,
                                         $57e968ce,$580611cf,$5822b2d6,$583f4bdd,
                                         $585bdcdb,$587865c9,$5894e69f,$58b15f57,
                                         $58cdcfe9,$58ea384e,$5906987d,$5922f071,
                                         $593f4022,$595b8788,$5977c69c,$5993fd57,
                                         $59b02bb2,$59cc51a6,$59e86f2c,$5a04843c,
                                         $5a2090d0,$5a3c94e0,$5a589065,$5a748359,
                                         $5a906db4,$5aac4f70,$5ac82884,$5ae3f8ec,
                                         $5affc09f,$5b1b7f97,$5b3735cd,$5b52e33a,
                                         $5b6e87d8,$5b8a239f,$5ba5b689,$5bc1408f,
                                         $5bdcc1aa,$5bf839d5,$5c13a907,$5c2f0f3b,
                                         $5c4a6c6a,$5c65c08d,$5c810b9e,$5c9c4d97,
                                         $5cb78670,$5cd2b623,$5ceddcaa,$5d08f9ff,
                                         $5d240e1b,$5d3f18f8,$5d5a1a8f,$5d7512da,
                                         $5d9001d3,$5daae773,$5dc5c3b5,$5de09692,
                                         $5dfb6004,$5e162004,$5e30d68d,$5e4b8399,
                                         $5e662721,$5e80c11f,$5e9b518e,$5eb5d867,
                                         $5ed055a4,$5eeac940,$5f053334,$5f1f937b,
                                         $5f39ea0f,$5f5436ea,$5f6e7a06,$5f88b35d,
                                         $5fa2e2e9,$5fbd08a6,$5fd7248d,$5ff13698,
                                         $600b3ec2,$60253d05,$603f315b,$60591bc0,
                                         $6072fc2d,$608cd29e,$60a69f0b,$60c06171,
                                         $60da19ca,$60f3c80f,$610d6c3d,$6127064d,
                                         $6140963a,$615a1bff,$61739797,$618d08fc,
                                         $61a67029,$61bfcd1a,$61d91fc8,$61f2682f,
                                         $620ba64a,$6224da13,$623e0386,$6257229d,
                                         $62703754,$628941a6,$62a2418e,$62bb3706,
                                         $62d4220a,$62ed0296,$6305d8a3,$631ea42f,
                                         $63376533,$63501bab,$6368c793,$638168e5,
                                         $6399ff9e,$63b28bb8,$63cb0d2f,$63e383ff,
                                         $63fbf022,$64145195,$642ca853,$6444f457,
                                         $645d359e,$64756c22,$648d97e0,$64a5b8d3,
                                         $64bdcef6,$64d5da47,$64eddabf,$6505d05c,
                                         $651dbb19,$65359af2,$654d6fe3,$656539e7,
                                         $657cf8fb,$6594ad1b,$65ac5643,$65c3f46e,
                                         $65db8799,$65f30fc0,$660a8ce0,$6621fef3,
                                         $663965f7,$6650c1e7,$666812c1,$667f5880,
                                         $66969320,$66adc29e,$66c4e6f7,$66dc0026,
                                         $66f30e28,$670a10fa,$67210898,$6737f4ff,
                                         $674ed62b,$6765ac19,$677c76c5,$6793362c,
                                         $67a9ea4b,$67c0931f,$67d730a3,$67edc2d6,
                                         $680449b3,$681ac538,$68313562,$68479a2d,
                                         $685df396,$6874419b,$688a8438,$68a0bb6a,
                                         $68b6e72e,$68cd0782,$68e31c63,$68f925cd,
                                         $690f23be,$69251633,$693afd29,$6950d89e,
                                         $6966a88f,$697c6cf8,$699225d9,$69a7d32d,
                                         $69bd74f3,$69d30b27,$69e895c8,$69fe14d2,
                                         $6a138844,$6a28f01b,$6a3e4c54,$6a539ced,
                                         $6a68e1e4,$6a7e1b37,$6a9348e3,$6aa86ae6,
                                         $6abd813d,$6ad28be7,$6ae78ae2,$6afc7e2b,
                                         $6b1165c0,$6b26419f,$6b3b11c7,$6b4fd634,
                                         $6b648ee6,$6b793bda,$6b8ddd0e,$6ba27281,
                                         $6bb6fc31,$6bcb7a1b,$6bdfec3e,$6bf45299,
                                         $6c08ad29,$6c1cfbed,$6c313ee4,$6c45760a,
                                         $6c59a160,$6c6dc0e4,$6c81d493,$6c95dc6d,
                                         $6ca9d86f,$6cbdc899,$6cd1acea,$6ce5855f,
                                         $6cf951f7,$6d0d12b1,$6d20c78c,$6d347087,
                                         $6d480da0,$6d5b9ed6,$6d6f2427,$6d829d94,
                                         $6d960b1a,$6da96cb9,$6dbcc270,$6dd00c3c,
                                         $6de34a1f,$6df67c16,$6e09a221,$6e1cbc3f,
                                         $6e2fca6e,$6e42ccaf,$6e55c300,$6e68ad60,
                                         $6e7b8bd0,$6e8e5e4d,$6ea124d8,$6eb3df70,
                                         $6ec68e13,$6ed930c3,$6eebc77d,$6efe5242,
                                         $6f10d111,$6f2343e9,$6f35aacb,$6f4805b5,
                                         $6f5a54a8,$6f6c97a2,$6f7ecea4,$6f90f9ae,
                                         $6fa318be,$6fb52bd6,$6fc732f4,$6fd92e19,
                                         $6feb1d44,$6ffd0076,$700ed7ad,$7020a2eb,
                                         $7032622f,$7044157a,$7055bcca,$70675821,
                                         $7078e77e,$708a6ae2,$709be24c,$70ad4dbd,
                                         $70bead36,$70d000b5,$70e1483d,$70f283cc,
                                         $7103b363,$7114d704,$7125eead,$7136fa60,
                                         $7147fa1c,$7158ede4,$7169d5b6,$717ab193,
                                         $718b817d,$719c4573,$71acfd76,$71bda988,
                                         $71ce49a8,$71deddd7,$71ef6617,$71ffe267,
                                         $721052ca,$7220b73e,$72310fc6,$72415c62,
                                         $72519d14,$7261d1db,$7271faba,$728217b1,
                                         $729228c0,$72a22dea,$72b22730,$72c21491,
                                         $72d1f611,$72e1cbaf,$72f1956c,$7301534c,
                                         $7311054d,$7320ab72,$733045bc,$733fd42d,
                                         $734f56c5,$735ecd86,$736e3872,$737d9789,
                                         $738ceacf,$739c3243,$73ab6de7,$73ba9dbe,
                                         $73c9c1c8,$73d8da08,$73e7e67f,$73f6e72e,
                                         $7405dc17,$7414c53c,$7423a29f,$74327442,
                                         $74413a26,$744ff44d,$745ea2b9,$746d456c,
                                         $747bdc68,$748a67ae,$7498e741,$74a75b23,
                                         $74b5c356,$74c41fdb,$74d270b6,$74e0b5e7,
                                         $74eeef71,$74fd1d57,$750b3f9a,$7519563c,
                                         $75276140,$753560a8,$75435477,$75513cae,
                                         $755f1951,$756cea60,$757aafdf,$758869d1,
                                         $75961837,$75a3bb14,$75b1526a,$75bede3c,
                                         $75cc5e8d,$75d9d35f,$75e73cb5,$75f49a91,
                                         $7601ecf6,$760f33e6,$761c6f65,$76299f74,
                                         $7636c417,$7643dd51,$7650eb24,$765ded93,
                                         $766ae4a0,$7677d050,$7684b0a4,$7691859f,
                                         $769e4f45,$76ab0d98,$76b7c09c,$76c46852,
                                         $76d104bf,$76dd95e6,$76ea1bc9,$76f6966b,
                                         $770305d0,$770f69fb,$771bc2ef,$772810af,
                                         $7734533e,$77408aa0,$774cb6d7,$7758d7e8,
                                         $7764edd5,$7770f8a2,$777cf852,$7788ece8,
                                         $7794d668,$77a0b4d5,$77ac8833,$77b85085,
                                         $77c40dce,$77cfc013,$77db6756,$77e7039b,
                                         $77f294e6,$77fe1b3b,$7809969c,$7815070e,
                                         $78206c93,$782bc731,$783716ea,$78425bc3,
                                         $784d95be,$7858c4e1,$7863e92d,$786f02a8,
                                         $787a1156,$78851539,$78900e56,$789afcb1,
                                         $78a5e04d,$78b0b92f,$78bb875b,$78c64ad4,
                                         $78d1039e,$78dbb1be,$78e65537,$78f0ee0e,
                                         $78fb7c46,$7905ffe4,$791078ec,$791ae762,
                                         $79254b4a,$792fa4a7,$7939f380,$794437d7,
                                         $794e71b0,$7958a111,$7962c5fd,$796ce078,
                                         $7976f087,$7980f62f,$798af173,$7994e258,
                                         $799ec8e2,$79a8a515,$79b276f7,$79bc3e8b,
                                         $79c5fbd6,$79cfaedc,$79d957a2,$79e2f62c,
                                         $79ec8a7f,$79f6149f,$79ff9492,$7a090a5a,
                                         $7a1275fe,$7a1bd781,$7a252ee9,$7a2e7c39,
                                         $7a37bf77,$7a40f8a7,$7a4a27ce,$7a534cf0,
                                         $7a5c6813,$7a65793b,$7a6e806d,$7a777dad,
                                         $7a807100,$7a895a6b,$7a9239f4,$7a9b0f9e,
                                         $7aa3db6f,$7aac9d6b,$7ab55597,$7abe03f9,
                                         $7ac6a895,$7acf4370,$7ad7d48f,$7ae05bf6,
                                         $7ae8d9ac,$7af14db5,$7af9b815,$7b0218d2,
                                         $7b0a6ff2,$7b12bd78,$7b1b016a,$7b233bce,
                                         $7b2b6ca7,$7b3393fc,$7b3bb1d1,$7b43c62c,
                                         $7b4bd111,$7b53d286,$7b5bca90,$7b63b935,
                                         $7b6b9e78,$7b737a61,$7b7b4cf3,$7b831634,
                                         $7b8ad629,$7b928cd8,$7b9a3a45,$7ba1de77,
                                         $7ba97972,$7bb10b3c,$7bb893d9,$7bc01350,
                                         $7bc789a6,$7bcef6e0,$7bd65b03,$7bddb616,
                                         $7be5081c,$7bec511c,$7bf3911b,$7bfac81f,
                                         $7c01f62c,$7c091b49,$7c10377b,$7c174ac7,
                                         $7c1e5532,$7c2556c4,$7c2c4f80,$7c333f6c,
                                         $7c3a268e,$7c4104ec,$7c47da8a,$7c4ea76f,
                                         $7c556ba1,$7c5c2724,$7c62d9fe,$7c698435,
                                         $7c7025cf,$7c76bed0,$7c7d4f40,$7c83d723,
                                         $7c8a567f,$7c90cd5a,$7c973bb9,$7c9da1a2,
                                         $7ca3ff1b,$7caa542a,$7cb0a0d3,$7cb6e51e,
                                         $7cbd210f,$7cc354ac,$7cc97ffc,$7ccfa304,
                                         $7cd5bdc9,$7cdbd051,$7ce1daa3,$7ce7dcc3,
                                         $7cedd6b8,$7cf3c888,$7cf9b238,$7cff93cf,
                                         $7d056d51,$7d0b3ec5,$7d110830,$7d16c99a,
                                         $7d1c8306,$7d22347c,$7d27de00,$7d2d7f9a,
                                         $7d33194f,$7d38ab24,$7d3e351f,$7d43b748,
                                         $7d4931a2,$7d4ea435,$7d540f06,$7d59721b,
                                         $7d5ecd7b,$7d64212a,$7d696d2f,$7d6eb190,
                                         $7d73ee53,$7d79237e,$7d7e5117,$7d837723,
                                         $7d8895a9,$7d8dacae,$7d92bc3a,$7d97c451,
                                         $7d9cc4f9,$7da1be39,$7da6b017,$7dab9a99,
                                         $7db07dc4,$7db5599e,$7dba2e2f,$7dbefb7b,
                                         $7dc3c189,$7dc8805e,$7dcd3802,$7dd1e879,
                                         $7dd691ca,$7ddb33fb,$7ddfcf12,$7de46315,
                                         $7de8f00a,$7ded75f8,$7df1f4e3,$7df66cd3,
                                         $7dfaddcd,$7dff47d7,$7e03aaf8,$7e080735,
                                         $7e0c5c95,$7e10ab1e,$7e14f2d5,$7e1933c1,
                                         $7e1d6de8,$7e21a150,$7e25cdff,$7e29f3fc,
                                         $7e2e134c,$7e322bf5,$7e363dfd,$7e3a496b,
                                         $7e3e4e45,$7e424c90,$7e464454,$7e4a3595,
                                         $7e4e205a,$7e5204aa,$7e55e289,$7e59b9ff,
                                         $7e5d8b12,$7e6155c7,$7e651a24,$7e68d831,
                                         $7e6c8ff2,$7e70416e,$7e73ecac,$7e7791b0,
                                         $7e7b3082,$7e7ec927,$7e825ba6,$7e85e804,
                                         $7e896e48,$7e8cee77,$7e906899,$7e93dcb2,
                                         $7e974aca,$7e9ab2e5,$7e9e150b,$7ea17141,
                                         $7ea4c78e,$7ea817f7,$7eab6283,$7eaea737,
                                         $7eb1e61a,$7eb51f33,$7eb85285,$7ebb8019,
                                         $7ebea7f4,$7ec1ca1d,$7ec4e698,$7ec7fd6d,
                                         $7ecb0ea1,$7ece1a3a,$7ed1203f,$7ed420b6,
                                         $7ed71ba4,$7eda110f,$7edd00ff,$7edfeb78,
                                         $7ee2d081,$7ee5b01f,$7ee88a5a,$7eeb5f36,
                                         $7eee2eba,$7ef0f8ed,$7ef3bdd3,$7ef67d73,
                                         $7ef937d3,$7efbecf9,$7efe9ceb,$7f0147ae,
                                         $7f03ed4a,$7f068dc4,$7f092922,$7f0bbf69,
                                         $7f0e50a1,$7f10dcce,$7f1363f7,$7f15e622,
                                         $7f186355,$7f1adb95,$7f1d4ee9,$7f1fbd57,
                                         $7f2226e4,$7f248b96,$7f26eb74,$7f294683,
                                         $7f2b9cc9,$7f2dee4d,$7f303b13,$7f328322,
                                         $7f34c680,$7f370533,$7f393f40,$7f3b74ad,
                                         $7f3da581,$7f3fd1c1,$7f41f972,$7f441c9c,
                                         $7f463b43,$7f48556d,$7f4a6b21,$7f4c7c64,
                                         $7f4e893c,$7f5091ae,$7f5295c1,$7f54957a,
                                         $7f5690e0,$7f5887f7,$7f5a7ac5,$7f5c6951,
                                         $7f5e53a0,$7f6039b8,$7f621b9e,$7f63f958,
                                         $7f65d2ed,$7f67a861,$7f6979ba,$7f6b46ff,
                                         $7f6d1034,$7f6ed560,$7f709687,$7f7253b1,
                                         $7f740ce1,$7f75c21f,$7f777370,$7f7920d8,
                                         $7f7aca5f,$7f7c7008,$7f7e11db,$7f7fafdd,
                                         $7f814a13,$7f82e082,$7f847331,$7f860224,
                                         $7f878d62,$7f8914f0,$7f8a98d4,$7f8c1912,
                                         $7f8d95b0,$7f8f0eb5,$7f908425,$7f91f605,
                                         $7f93645c,$7f94cf2f,$7f963683,$7f979a5d,
                                         $7f98fac4,$7f9a57bb,$7f9bb14a,$7f9d0775,
                                         $7f9e5a41,$7f9fa9b4,$7fa0f5d3,$7fa23ea4,
                                         $7fa3842b,$7fa4c66f,$7fa60575,$7fa74141,
                                         $7fa879d9,$7fa9af42,$7faae182,$7fac109e,
                                         $7fad3c9a,$7fae657d,$7faf8b4c,$7fb0ae0b,
                                         $7fb1cdc0,$7fb2ea70,$7fb40420,$7fb51ad5,
                                         $7fb62e95,$7fb73f64,$7fb84d48,$7fb95846,
                                         $7fba6062,$7fbb65a2,$7fbc680c,$7fbd67a3,
                                         $7fbe646d,$7fbf5e70,$7fc055af,$7fc14a31,
                                         $7fc23bf9,$7fc32b0d,$7fc41773,$7fc5012e,
                                         $7fc5e844,$7fc6ccba,$7fc7ae94,$7fc88dd8,
                                         $7fc96a8a,$7fca44af,$7fcb1c4c,$7fcbf167,
                                         $7fccc403,$7fcd9425,$7fce61d3,$7fcf2d11,
                                         $7fcff5e3,$7fd0bc4f,$7fd1805a,$7fd24207,
                                         $7fd3015c,$7fd3be5d,$7fd47910,$7fd53178,
                                         $7fd5e79b,$7fd69b7c,$7fd74d21,$7fd7fc8e,
                                         $7fd8a9c8,$7fd954d4,$7fd9fdb5,$7fdaa471,
                                         $7fdb490b,$7fdbeb89,$7fdc8bef,$7fdd2a42,
                                         $7fddc685,$7fde60be,$7fdef8f0,$7fdf8f20,
                                         $7fe02353,$7fe0b58d,$7fe145d3,$7fe1d428,
                                         $7fe26091,$7fe2eb12,$7fe373b0,$7fe3fa6f,
                                         $7fe47f53,$7fe50260,$7fe5839b,$7fe60308,
                                         $7fe680ab,$7fe6fc88,$7fe776a4,$7fe7ef02,
                                         $7fe865a7,$7fe8da97,$7fe94dd6,$7fe9bf68,
                                         $7fea2f51,$7fea9d95,$7feb0a39,$7feb7540,
                                         $7febdeae,$7fec4687,$7fecaccf,$7fed118b,
                                         $7fed74be,$7fedd66c,$7fee3698,$7fee9548,
                                         $7feef27e,$7fef4e3f,$7fefa88e,$7ff0016f,
                                         $7ff058e7,$7ff0aef8,$7ff103a6,$7ff156f6,
                                         $7ff1a8eb,$7ff1f988,$7ff248d2,$7ff296cc,
                                         $7ff2e37a,$7ff32edf,$7ff378ff,$7ff3c1de,
                                         $7ff4097e,$7ff44fe5,$7ff49515,$7ff4d911,
                                         $7ff51bde,$7ff55d7f,$7ff59df7,$7ff5dd4a,
                                         $7ff61b7b,$7ff6588d,$7ff69485,$7ff6cf65,
                                         $7ff70930,$7ff741eb,$7ff77998,$7ff7b03b,
                                         $7ff7e5d7,$7ff81a6f,$7ff84e06,$7ff880a1,
                                         $7ff8b241,$7ff8e2ea,$7ff912a0,$7ff94165,
                                         $7ff96f3d,$7ff99c2b,$7ff9c831,$7ff9f354,
                                         $7ffa1d95,$7ffa46f9,$7ffa6f81,$7ffa9731,
                                         $7ffabe0d,$7ffae416,$7ffb0951,$7ffb2dbf,
                                         $7ffb5164,$7ffb7442,$7ffb965d,$7ffbb7b8,
                                         $7ffbd854,$7ffbf836,$7ffc175f,$7ffc35d3,
                                         $7ffc5394,$7ffc70a5,$7ffc8d09,$7ffca8c2,
                                         $7ffcc3d4,$7ffcde3f,$7ffcf809,$7ffd1132,
                                         $7ffd29be,$7ffd41ae,$7ffd5907,$7ffd6fc9,
                                         $7ffd85f9,$7ffd9b97,$7ffdb0a7,$7ffdc52b,
                                         $7ffdd926,$7ffdec99,$7ffdff88,$7ffe11f4,
                                         $7ffe23e0,$7ffe354f,$7ffe4642,$7ffe56bc,
                                         $7ffe66bf,$7ffe764e,$7ffe856a,$7ffe9416,
                                         $7ffea254,$7ffeb026,$7ffebd8e,$7ffeca8f,
                                         $7ffed72a,$7ffee362,$7ffeef38,$7ffefaaf,
                                         $7fff05c9,$7fff1087,$7fff1aec,$7fff24f9,
                                         $7fff2eb1,$7fff3816,$7fff4128,$7fff49eb,
                                         $7fff5260,$7fff5a88,$7fff6266,$7fff69fc,
                                         $7fff714b,$7fff7854,$7fff7f1a,$7fff859f,
                                         $7fff8be3,$7fff91ea,$7fff97b3,$7fff9d41,
                                         $7fffa296,$7fffa7b3,$7fffac99,$7fffb14b,
                                         $7fffb5c9,$7fffba15,$7fffbe31,$7fffc21d,
                                         $7fffc5dc,$7fffc96f,$7fffccd8,$7fffd016,
                                         $7fffd32d,$7fffd61c,$7fffd8e7,$7fffdb8d,
                                         $7fffde0f,$7fffe071,$7fffe2b1,$7fffe4d2,
                                         $7fffe6d5,$7fffe8bb,$7fffea85,$7fffec34,
                                         $7fffedc9,$7fffef45,$7ffff0aa,$7ffff1f7,
                                         $7ffff330,$7ffff453,$7ffff562,$7ffff65f,
                                         $7ffff749,$7ffff823,$7ffff8ec,$7ffff9a6,
                                         $7ffffa51,$7ffffaee,$7ffffb7e,$7ffffc02,
                                         $7ffffc7a,$7ffffce7,$7ffffd4a,$7ffffda3,
                                         $7ffffdf4,$7ffffe3c,$7ffffe7c,$7ffffeb6,
                                         $7ffffee8,$7fffff15,$7fffff3c,$7fffff5e,
                                         $7fffff7b,$7fffff95,$7fffffaa,$7fffffbc,
                                         $7fffffcb,$7fffffd7,$7fffffe2,$7fffffea,
                                         $7ffffff0,$7ffffff5,$7ffffff9,$7ffffffb,
                                         $7ffffffd,$7ffffffe,$7fffffff,$7fffffff,
                                         $7fffffff,$7fffffff,$7fffffff,$7fffffff);

     vwin8192:array[0..4095] of longint=($0000007c,$0000045c,$00000c1d,$000017bd,
                                         $0000273e,$00003a9f,$000051e0,$00006d02,
                                         $00008c03,$0000aee5,$0000d5a7,$00010049,
                                         $00012ecb,$0001612d,$00019770,$0001d193,
                                         $00020f96,$00025178,$0002973c,$0002e0df,
                                         $00032e62,$00037fc5,$0003d509,$00042e2c,
                                         $00048b30,$0004ec13,$000550d7,$0005b97a,
                                         $000625fe,$00069661,$00070aa4,$000782c8,
                                         $0007fecb,$00087eae,$00090271,$00098a14,
                                         $000a1597,$000aa4f9,$000b383b,$000bcf5d,
                                         $000c6a5f,$000d0941,$000dac02,$000e52a3,
                                         $000efd23,$000fab84,$00105dc3,$001113e3,
                                         $0011cde2,$00128bc0,$00134d7e,$0014131b,
                                         $0014dc98,$0015a9f4,$00167b30,$0017504a,
                                         $00182945,$0019061e,$0019e6d7,$001acb6f,
                                         $001bb3e6,$001ca03c,$001d9071,$001e8485,
                                         $001f7c79,$0020784b,$002177fc,$00227b8c,
                                         $002382fb,$00248e49,$00259d76,$0026b081,
                                         $0027c76b,$0028e234,$002a00dc,$002b2361,
                                         $002c49c6,$002d7409,$002ea22a,$002fd42a,
                                         $00310a08,$003243c5,$00338160,$0034c2d9,
                                         $00360830,$00375165,$00389e78,$0039ef6a,
                                         $003b4439,$003c9ce6,$003df971,$003f59da,
                                         $0040be20,$00422645,$00439247,$00450226,
                                         $004675e3,$0047ed7e,$004968f5,$004ae84b,
                                         $004c6b7d,$004df28d,$004f7d7a,$00510c44,
                                         $00529eeb,$00543570,$0055cfd1,$00576e0f,
                                         $00591029,$005ab621,$005c5ff5,$005e0da6,
                                         $005fbf33,$0061749d,$00632de4,$0064eb06,
                                         $0066ac05,$006870e0,$006a3998,$006c062b,
                                         $006dd69b,$006faae6,$0071830d,$00735f10,
                                         $00753eef,$007722a9,$00790a3f,$007af5b1,
                                         $007ce4fe,$007ed826,$0080cf29,$0082ca08,
                                         $0084c8c2,$0086cb57,$0088d1c7,$008adc11,
                                         $008cea37,$008efc37,$00911212,$00932bc7,
                                         $00954957,$00976ac2,$00999006,$009bb925,
                                         $009de61e,$00a016f1,$00a24b9e,$00a48425,
                                         $00a6c086,$00a900c0,$00ab44d4,$00ad8cc2,
                                         $00afd889,$00b22829,$00b47ba2,$00b6d2f5,
                                         $00b92e21,$00bb8d26,$00bdf004,$00c056ba,
                                         $00c2c149,$00c52fb1,$00c7a1f1,$00ca180a,
                                         $00cc91fb,$00cf0fc5,$00d19166,$00d416df,
                                         $00d6a031,$00d92d5a,$00dbbe5b,$00de5333,
                                         $00e0ebe3,$00e3886b,$00e628c9,$00e8ccff,
                                         $00eb750c,$00ee20f0,$00f0d0ab,$00f3843d,
                                         $00f63ba5,$00f8f6e4,$00fbb5fa,$00fe78e5,
                                         $01013fa7,$01040a3f,$0106d8ae,$0109aaf2,
                                         $010c810c,$010f5afb,$011238c0,$01151a5b,
                                         $0117ffcb,$011ae910,$011dd62a,$0120c719,
                                         $0123bbdd,$0126b476,$0129b0e4,$012cb126,
                                         $012fb53c,$0132bd27,$0135c8e6,$0138d879,
                                         $013bebdf,$013f031a,$01421e28,$01453d0a,
                                         $01485fbf,$014b8648,$014eb0a4,$0151ded2,
                                         $015510d4,$015846a8,$015b8050,$015ebdc9,
                                         $0161ff15,$01654434,$01688d24,$016bd9e6,
                                         $016f2a7b,$01727ee1,$0175d718,$01793321,
                                         $017c92fc,$017ff6a7,$01835e24,$0186c972,
                                         $018a3890,$018dab7f,$0191223f,$01949ccf,
                                         $01981b2f,$019b9d5f,$019f235f,$01a2ad2f,
                                         $01a63acf,$01a9cc3e,$01ad617c,$01b0fa8a,
                                         $01b49767,$01b83813,$01bbdc8d,$01bf84d6,
                                         $01c330ee,$01c6e0d4,$01ca9488,$01ce4c0b,
                                         $01d2075b,$01d5c679,$01d98964,$01dd501d,
                                         $01e11aa3,$01e4e8f6,$01e8bb17,$01ec9104,
                                         $01f06abd,$01f44844,$01f82996,$01fc0eb5,
                                         $01fff7a0,$0203e456,$0207d4d9,$020bc926,
                                         $020fc140,$0213bd24,$0217bcd4,$021bc04e,
                                         $021fc793,$0223d2a3,$0227e17d,$022bf421,
                                         $02300a90,$023424c8,$023842ca,$023c6495,
                                         $02408a2a,$0244b389,$0248e0b0,$024d11a0,
                                         $02514659,$02557eda,$0259bb24,$025dfb35,
                                         $02623f0f,$026686b1,$026ad21a,$026f214b,
                                         $02737443,$0277cb02,$027c2588,$028083d5,
                                         $0284e5e9,$02894bc2,$028db562,$029222c8,
                                         $029693f4,$029b08e6,$029f819d,$02a3fe19,
                                         $02a87e5b,$02ad0261,$02b18a2c,$02b615bb,
                                         $02baa50f,$02bf3827,$02c3cf03,$02c869a3,
                                         $02cd0807,$02d1aa2d,$02d65017,$02daf9c4,
                                         $02dfa734,$02e45866,$02e90d5b,$02edc612,
                                         $02f2828b,$02f742c6,$02fc06c3,$0300ce80,
                                         $030599ff,$030a6940,$030f3c40,$03141302,
                                         $0318ed84,$031dcbc6,$0322adc8,$0327938a,
                                         $032c7d0c,$03316a4c,$03365b4d,$033b500c,
                                         $03404889,$034544c6,$034a44c0,$034f4879,
                                         $03544ff0,$03595b24,$035e6a16,$03637cc5,
                                         $03689331,$036dad5a,$0372cb40,$0377ece2,
                                         $037d1240,$03823b5a,$03876830,$038c98c1,
                                         $0391cd0e,$03970516,$039c40d8,$03a18055,
                                         $03a6c38d,$03ac0a7f,$03b1552b,$03b6a390,
                                         $03bbf5af,$03c14b88,$03c6a519,$03cc0263,
                                         $03d16366,$03d6c821,$03dc3094,$03e19cc0,
                                         $03e70ca2,$03ec803d,$03f1f78e,$03f77296,
                                         $03fcf155,$040273cb,$0407f9f7,$040d83d9,
                                         $04131170,$0418a2bd,$041e37c0,$0423d077,
                                         $04296ce4,$042f0d04,$0434b0da,$043a5863,
                                         $044003a0,$0445b290,$044b6534,$04511b8b,
                                         $0456d595,$045c9352,$046254c1,$046819e1,
                                         $046de2b4,$0473af39,$04797f6e,$047f5355,
                                         $04852aec,$048b0635,$0490e52d,$0496c7d6,
                                         $049cae2e,$04a29836,$04a885ed,$04ae7753,
                                         $04b46c68,$04ba652b,$04c0619d,$04c661bc,
                                         $04cc658a,$04d26d04,$04d8782c,$04de8701,
                                         $04e49983,$04eaafb0,$04f0c98a,$04f6e710,
                                         $04fd0842,$05032d1e,$050955a6,$050f81d8,
                                         $0515b1b5,$051be53d,$05221c6e,$05285748,
                                         $052e95cd,$0534d7fa,$053b1dd0,$0541674e,
                                         $0547b475,$054e0544,$055459bb,$055ab1d9,
                                         $05610d9e,$05676d0a,$056dd01c,$057436d5,
                                         $057aa134,$05810f38,$058780e2,$058df631,
                                         $05946f25,$059aebbe,$05a16bfa,$05a7efdb,
                                         $05ae775f,$05b50287,$05bb9152,$05c223c0,
                                         $05c8b9d0,$05cf5382,$05d5f0d6,$05dc91cc,
                                         $05e33663,$05e9de9c,$05f08a75,$05f739ee,
                                         $05fded07,$0604a3c0,$060b5e19,$06121c11,
                                         $0618dda8,$061fa2dd,$06266bb1,$062d3822,
                                         $06340831,$063adbde,$0641b328,$06488e0e,
                                         $064f6c91,$06564eaf,$065d346a,$06641dc0,
                                         $066b0ab1,$0671fb3d,$0678ef64,$067fe724,
                                         $0686e27f,$068de173,$0694e400,$069bea27,
                                         $06a2f3e6,$06aa013d,$06b1122c,$06b826b3,
                                         $06bf3ed1,$06c65a86,$06cd79d1,$06d49cb3,
                                         $06dbc32b,$06e2ed38,$06ea1adb,$06f14c13,
                                         $06f880df,$06ffb940,$0706f535,$070e34bd,
                                         $071577d9,$071cbe88,$072408c9,$072b569d,
                                         $0732a802,$0739fcf9,$07415582,$0748b19b,
                                         $07501145,$0757747f,$075edb49,$076645a3,
                                         $076db38c,$07752503,$077c9a09,$0784129e,
                                         $078b8ec0,$07930e70,$079a91ac,$07a21876,
                                         $07a9a2cc,$07b130ad,$07b8c21b,$07c05714,
                                         $07c7ef98,$07cf8ba6,$07d72b3f,$07dece62,
                                         $07e6750e,$07ee1f43,$07f5cd01,$07fd7e48,
                                         $08053316,$080ceb6d,$0814a74a,$081c66af,
                                         $0824299a,$082bf00c,$0833ba03,$083b8780,
                                         $08435882,$084b2d09,$08530514,$085ae0a3,
                                         $0862bfb6,$086aa24c,$08728865,$087a7201,
                                         $08825f1e,$088a4fbe,$089243de,$089a3b80,
                                         $08a236a2,$08aa3545,$08b23767,$08ba3d09,
                                         $08c2462a,$08ca52c9,$08d262e7,$08da7682,
                                         $08e28d9c,$08eaa832,$08f2c645,$08fae7d4,
                                         $09030cdf,$090b3566,$09136168,$091b90e5,
                                         $0923c3dc,$092bfa4d,$09343437,$093c719b,
                                         $0944b277,$094cf6cc,$09553e99,$095d89dd,
                                         $0965d899,$096e2acb,$09768073,$097ed991,
                                         $09873625,$098f962e,$0997f9ac,$09a0609e,
                                         $09a8cb04,$09b138dd,$09b9aa29,$09c21ee8,
                                         $09ca9719,$09d312bc,$09db91d0,$09e41456,
                                         $09ec9a4b,$09f523b1,$09fdb087,$0a0640cc,
                                         $0a0ed47f,$0a176ba2,$0a200632,$0a28a42f,
                                         $0a31459a,$0a39ea72,$0a4292b5,$0a4b3e65,
                                         $0a53ed80,$0a5ca006,$0a6555f7,$0a6e0f51,
                                         $0a76cc16,$0a7f8c44,$0a884fda,$0a9116d9,
                                         $0a99e140,$0aa2af0e,$0aab8043,$0ab454df,
                                         $0abd2ce1,$0ac60849,$0acee716,$0ad7c948,
                                         $0ae0aedf,$0ae997d9,$0af28437,$0afb73f7,
                                         $0b04671b,$0b0d5da0,$0b165788,$0b1f54d0,
                                         $0b285579,$0b315983,$0b3a60ec,$0b436bb5,
                                         $0b4c79dd,$0b558b63,$0b5ea048,$0b67b88a,
                                         $0b70d429,$0b79f324,$0b83157c,$0b8c3b30,
                                         $0b95643f,$0b9e90a8,$0ba7c06c,$0bb0f38a,
                                         $0bba2a01,$0bc363d1,$0bcca0f9,$0bd5e17a,
                                         $0bdf2552,$0be86c81,$0bf1b706,$0bfb04e2,
                                         $0c045613,$0c0daa99,$0c170274,$0c205da3,
                                         $0c29bc25,$0c331dfb,$0c3c8323,$0c45eb9e,
                                         $0c4f576a,$0c58c688,$0c6238f6,$0c6baeb5,
                                         $0c7527c3,$0c7ea421,$0c8823cd,$0c91a6c8,
                                         $0c9b2d10,$0ca4b6a6,$0cae4389,$0cb7d3b8,
                                         $0cc16732,$0ccafdf8,$0cd49809,$0cde3564,
                                         $0ce7d609,$0cf179f7,$0cfb212e,$0d04cbad,
                                         $0d0e7974,$0d182a83,$0d21ded8,$0d2b9673,
                                         $0d355154,$0d3f0f7b,$0d48d0e6,$0d529595,
                                         $0d5c5d88,$0d6628be,$0d6ff737,$0d79c8f2,
                                         $0d839dee,$0d8d762c,$0d9751aa,$0da13068,
                                         $0dab1266,$0db4f7a3,$0dbee01e,$0dc8cbd8,
                                         $0dd2bace,$0ddcad02,$0de6a272,$0df09b1e,
                                         $0dfa9705,$0e049627,$0e0e9883,$0e189e19,
                                         $0e22a6e8,$0e2cb2f0,$0e36c230,$0e40d4a8,
                                         $0e4aea56,$0e55033b,$0e5f1f56,$0e693ea7,
                                         $0e73612c,$0e7d86e5,$0e87afd3,$0e91dbf3,
                                         $0e9c0b47,$0ea63dcc,$0eb07383,$0ebaac6b,
                                         $0ec4e883,$0ecf27cc,$0ed96a44,$0ee3afea,
                                         $0eedf8bf,$0ef844c2,$0f0293f2,$0f0ce64e,
                                         $0f173bd6,$0f21948a,$0f2bf069,$0f364f72,
                                         $0f40b1a5,$0f4b1701,$0f557f86,$0f5feb32,
                                         $0f6a5a07,$0f74cc02,$0f7f4124,$0f89b96b,
                                         $0f9434d8,$0f9eb369,$0fa9351e,$0fb3b9f7,
                                         $0fbe41f3,$0fc8cd11,$0fd35b51,$0fddecb2,
                                         $0fe88134,$0ff318d6,$0ffdb397,$10085177,
                                         $1012f275,$101d9691,$10283dca,$1032e81f,
                                         $103d9591,$1048461e,$1052f9c5,$105db087,
                                         $10686a62,$10732756,$107de763,$1088aa87,
                                         $109370c2,$109e3a14,$10a9067c,$10b3d5f9,
                                         $10bea88b,$10c97e31,$10d456eb,$10df32b8,
                                         $10ea1197,$10f4f387,$10ffd889,$110ac09b,
                                         $1115abbe,$112099ef,$112b8b2f,$11367f7d,
                                         $114176d9,$114c7141,$11576eb6,$11626f36,
                                         $116d72c1,$11787957,$118382f6,$118e8f9e,
                                         $11999f4f,$11a4b208,$11afc7c7,$11bae08e,
                                         $11c5fc5a,$11d11b2c,$11dc3d02,$11e761dd,
                                         $11f289ba,$11fdb49b,$1208e27e,$12141362,
                                         $121f4748,$122a7e2d,$1235b812,$1240f4f6,
                                         $124c34d9,$125777b9,$1262bd96,$126e0670,
                                         $12795245,$1284a115,$128ff2e0,$129b47a5,
                                         $12a69f63,$12b1fa19,$12bd57c7,$12c8b86c,
                                         $12d41c08,$12df829a,$12eaec21,$12f6589d,
                                         $1301c80c,$130d3a6f,$1318afc4,$1324280b,
                                         $132fa344,$133b216d,$1346a286,$1352268e,
                                         $135dad85,$1369376a,$1374c43c,$138053fb,
                                         $138be6a5,$13977c3b,$13a314bc,$13aeb026,
                                         $13ba4e79,$13c5efb5,$13d193d9,$13dd3ae4,
                                         $13e8e4d6,$13f491ad,$1400416a,$140bf40b,
                                         $1417a98f,$142361f7,$142f1d41,$143adb6d,
                                         $14469c7a,$14526067,$145e2734,$1469f0df,
                                         $1475bd69,$14818cd0,$148d5f15,$14993435,
                                         $14a50c31,$14b0e708,$14bcc4b8,$14c8a542,
                                         $14d488a5,$14e06edf,$14ec57f1,$14f843d9,
                                         $15043297,$1510242b,$151c1892,$15280fcd,
                                         $153409dc,$154006bc,$154c066e,$155808f1,
                                         $15640e44,$15701666,$157c2157,$15882f16,
                                         $15943fa2,$15a052fb,$15ac691f,$15b8820f,
                                         $15c49dc8,$15d0bc4c,$15dcdd98,$15e901ad,
                                         $15f52888,$1601522b,$160d7e93,$1619adc1,
                                         $1625dfb3,$16321469,$163e4be2,$164a861d,
                                         $1656c31a,$166302d8,$166f4555,$167b8a92,
                                         $1687d28e,$16941d47,$16a06abe,$16acbaf0,
                                         $16b90ddf,$16c56388,$16d1bbeb,$16de1708,
                                         $16ea74dd,$16f6d56a,$170338ae,$170f9ea8,
                                         $171c0758,$172872bd,$1734e0d6,$174151a2,
                                         $174dc520,$175a3b51,$1766b432,$17732fc4,
                                         $177fae05,$178c2ef4,$1798b292,$17a538dd,
                                         $17b1c1d4,$17be4d77,$17cadbc5,$17d76cbc,
                                         $17e4005e,$17f096a7,$17fd2f98,$1809cb31,
                                         $1816696f,$18230a53,$182faddc,$183c5408,
                                         $1848fcd8,$1855a849,$1862565d,$186f0711,
                                         $187bba64,$18887057,$189528e9,$18a1e418,
                                         $18aea1e3,$18bb624b,$18c8254e,$18d4eaeb,
                                         $18e1b321,$18ee7df1,$18fb4b58,$19081b57,
                                         $1914edec,$1921c317,$192e9ad6,$193b7529,
                                         $19485210,$19553189,$19621393,$196ef82e,
                                         $197bdf59,$1988c913,$1995b55c,$19a2a432,
                                         $19af9595,$19bc8983,$19c97ffd,$19d67900,
                                         $19e3748e,$19f072a3,$19fd7341,$1a0a7665,
                                         $1a177c10,$1a248440,$1a318ef4,$1a3e9c2c,
                                         $1a4babe7,$1a58be24,$1a65d2e2,$1a72ea20,
                                         $1a8003de,$1a8d201a,$1a9a3ed5,$1aa7600c,
                                         $1ab483bf,$1ac1a9ee,$1aced297,$1adbfdba,
                                         $1ae92b56,$1af65b69,$1b038df4,$1b10c2f5,
                                         $1b1dfa6b,$1b2b3456,$1b3870b5,$1b45af87,
                                         $1b52f0ca,$1b60347f,$1b6d7aa4,$1b7ac339,
                                         $1b880e3c,$1b955bad,$1ba2ab8b,$1baffdd5,
                                         $1bbd528a,$1bcaa9a9,$1bd80332,$1be55f24,
                                         $1bf2bd7d,$1c001e3d,$1c0d8164,$1c1ae6ef,
                                         $1c284edf,$1c35b932,$1c4325e7,$1c5094fe,
                                         $1c5e0677,$1c6b7a4f,$1c78f086,$1c86691b,
                                         $1c93e40d,$1ca1615c,$1caee107,$1cbc630c,
                                         $1cc9e76b,$1cd76e23,$1ce4f733,$1cf2829a,
                                         $1d001057,$1d0da06a,$1d1b32d1,$1d28c78c,
                                         $1d365e9a,$1d43f7f9,$1d5193a9,$1d5f31aa,
                                         $1d6cd1f9,$1d7a7497,$1d881982,$1d95c0ba,
                                         $1da36a3d,$1db1160a,$1dbec422,$1dcc7482,
                                         $1dda272b,$1de7dc1a,$1df59350,$1e034ccb,
                                         $1e11088a,$1e1ec68c,$1e2c86d1,$1e3a4958,
                                         $1e480e20,$1e55d527,$1e639e6d,$1e7169f1,
                                         $1e7f37b2,$1e8d07b0,$1e9ad9e8,$1ea8ae5b,
                                         $1eb68507,$1ec45dec,$1ed23908,$1ee0165b,
                                         $1eedf5e4,$1efbd7a1,$1f09bb92,$1f17a1b6,
                                         $1f258a0d,$1f337494,$1f41614b,$1f4f5032,
                                         $1f5d4147,$1f6b3489,$1f7929f7,$1f872192,
                                         $1f951b56,$1fa31744,$1fb1155b,$1fbf159a,
                                         $1fcd17ff,$1fdb1c8b,$1fe9233b,$1ff72c0f,
                                         $20053706,$20134420,$2021535a,$202f64b4,
                                         $203d782e,$204b8dc6,$2059a57c,$2067bf4e,
                                         $2075db3b,$2083f943,$20921964,$20a03b9e,
                                         $20ae5fef,$20bc8657,$20caaed5,$20d8d967,
                                         $20e7060e,$20f534c7,$21036592,$2111986e,
                                         $211fcd59,$212e0454,$213c3d5d,$214a7873,
                                         $2158b594,$2166f4c1,$217535f8,$21837938,
                                         $2191be81,$21a005d0,$21ae4f26,$21bc9a81,
                                         $21cae7e0,$21d93743,$21e788a8,$21f5dc0e,
                                         $22043174,$221288da,$2220e23e,$222f3da0,
                                         $223d9afe,$224bfa58,$225a5bac,$2268bef9,
                                         $2277243f,$22858b7d,$2293f4b0,$22a25fda,
                                         $22b0ccf8,$22bf3c09,$22cdad0d,$22dc2002,
                                         $22ea94e8,$22f90bbe,$23078482,$2315ff33,
                                         $23247bd1,$2332fa5b,$23417acf,$234ffd2c,
                                         $235e8173,$236d07a0,$237b8fb4,$238a19ae,
                                         $2398a58c,$23a7334d,$23b5c2f1,$23c45477,
                                         $23d2e7dd,$23e17d22,$23f01446,$23fead47,
                                         $240d4825,$241be4dd,$242a8371,$243923dd,
                                         $2447c622,$24566a3e,$24651031,$2473b7f8,
                                         $24826194,$24910d03,$249fba44,$24ae6957,
                                         $24bd1a39,$24cbccea,$24da816a,$24e937b7,
                                         $24f7efcf,$2506a9b3,$25156560,$252422d6,
                                         $2532e215,$2541a31a,$255065e4,$255f2a74,
                                         $256df0c7,$257cb8dd,$258b82b4,$259a4e4c,
                                         $25a91ba4,$25b7eaba,$25c6bb8e,$25d58e1e,
                                         $25e46269,$25f3386e,$2602102d,$2610e9a4,
                                         $261fc4d3,$262ea1b7,$263d8050,$264c609e,
                                         $265b429e,$266a2650,$26790bb3,$2687f2c6,
                                         $2696db88,$26a5c5f7,$26b4b213,$26c39fda,
                                         $26d28f4c,$26e18067,$26f0732b,$26ff6796,
                                         $270e5da7,$271d555d,$272c4eb7,$273b49b5,
                                         $274a4654,$27594495,$27684475,$277745f4,
                                         $27864910,$27954dc9,$27a4541e,$27b35c0d,
                                         $27c26596,$27d170b7,$27e07d6f,$27ef8bbd,
                                         $27fe9ba0,$280dad18,$281cc022,$282bd4be,
                                         $283aeaeb,$284a02a7,$28591bf2,$286836cb,
                                         $28775330,$28867120,$2895909b,$28a4b19e,
                                         $28b3d42a,$28c2f83d,$28d21dd5,$28e144f3,
                                         $28f06d94,$28ff97b8,$290ec35d,$291df082,
                                         $292d1f27,$293c4f4a,$294b80eb,$295ab407,
                                         $2969e89e,$29791eaf,$29885639,$29978f3b,
                                         $29a6c9b3,$29b605a0,$29c54302,$29d481d7,
                                         $29e3c21e,$29f303d6,$2a0246fd,$2a118b94,
                                         $2a20d198,$2a301909,$2a3f61e6,$2a4eac2c,
                                         $2a5df7dc,$2a6d44f4,$2a7c9374,$2a8be359,
                                         $2a9b34a2,$2aaa8750,$2ab9db60,$2ac930d1,
                                         $2ad887a3,$2ae7dfd3,$2af73962,$2b06944e,
                                         $2b15f096,$2b254e38,$2b34ad34,$2b440d89,
                                         $2b536f34,$2b62d236,$2b72368d,$2b819c38,
                                         $2b910336,$2ba06b86,$2bafd526,$2bbf4015,
                                         $2bceac53,$2bde19de,$2bed88b5,$2bfcf8d7,
                                         $2c0c6a43,$2c1bdcf7,$2c2b50f3,$2c3ac635,
                                         $2c4a3cbd,$2c59b488,$2c692d97,$2c78a7e7,
                                         $2c882378,$2c97a049,$2ca71e58,$2cb69da4,
                                         $2cc61e2c,$2cd59ff0,$2ce522ed,$2cf4a723,
                                         $2d042c90,$2d13b334,$2d233b0d,$2d32c41a,
                                         $2d424e5a,$2d51d9cc,$2d61666e,$2d70f440,
                                         $2d808340,$2d90136e,$2d9fa4c7,$2daf374c,
                                         $2dbecafa,$2dce5fd1,$2dddf5cf,$2ded8cf4,
                                         $2dfd253d,$2e0cbeab,$2e1c593b,$2e2bf4ed,
                                         $2e3b91c0,$2e4b2fb1,$2e5acec1,$2e6a6eee,
                                         $2e7a1037,$2e89b29b,$2e995618,$2ea8faad,
                                         $2eb8a05a,$2ec8471c,$2ed7eef4,$2ee797df,
                                         $2ef741dc,$2f06eceb,$2f16990a,$2f264639,
                                         $2f35f475,$2f45a3bd,$2f555412,$2f650570,
                                         $2f74b7d8,$2f846b48,$2f941fbe,$2fa3d53a,
                                         $2fb38bbb,$2fc3433f,$2fd2fbc5,$2fe2b54c,
                                         $2ff26fd3,$30022b58,$3011e7db,$3021a55a,
                                         $303163d4,$30412348,$3050e3b5,$3060a519,
                                         $30706773,$30802ac3,$308fef06,$309fb43d,
                                         $30af7a65,$30bf417d,$30cf0985,$30ded27a,
                                         $30ee9c5d,$30fe672b,$310e32e3,$311dff85,
                                         $312dcd0f,$313d9b80,$314d6ad7,$315d3b12,
                                         $316d0c30,$317cde31,$318cb113,$319c84d4,
                                         $31ac5974,$31bc2ef1,$31cc054b,$31dbdc7f,
                                         $31ebb48e,$31fb8d74,$320b6733,$321b41c7,
                                         $322b1d31,$323af96e,$324ad67e,$325ab45f,
                                         $326a9311,$327a7291,$328a52e0,$329a33fb,
                                         $32aa15e1,$32b9f892,$32c9dc0c,$32d9c04d,
                                         $32e9a555,$32f98b22,$330971b4,$33195909,
                                         $3329411f,$333929f6,$3349138c,$3358fde1,
                                         $3368e8f2,$3378d4c0,$3388c147,$3398ae89,
                                         $33a89c82,$33b88b32,$33c87a98,$33d86ab2,
                                         $33e85b80,$33f84d00,$34083f30,$34183210,
                                         $3428259f,$343819db,$34480ec3,$34580455,
                                         $3467fa92,$3477f176,$3487e902,$3497e134,
                                         $34a7da0a,$34b7d384,$34c7cda0,$34d7c85e,
                                         $34e7c3bb,$34f7bfb7,$3507bc50,$3517b985,
                                         $3527b756,$3537b5c0,$3547b4c3,$3557b45d,
                                         $3567b48d,$3577b552,$3587b6aa,$3597b895,
                                         $35a7bb12,$35b7be1e,$35c7c1b9,$35d7c5e1,
                                         $35e7ca96,$35f7cfd6,$3607d5a0,$3617dbf3,
                                         $3627e2cd,$3637ea2d,$3647f212,$3657fa7b,
                                         $36680366,$36780cd2,$368816bf,$3698212b,
                                         $36a82c14,$36b83779,$36c8435a,$36d84fb4,
                                         $36e85c88,$36f869d2,$37087793,$371885c9,
                                         $37289473,$3738a38f,$3748b31d,$3758c31a,
                                         $3768d387,$3778e461,$3788f5a7,$37990759,
                                         $37a91975,$37b92bf9,$37c93ee4,$37d95236,
                                         $37e965ed,$37f97a08,$38098e85,$3819a363,
                                         $3829b8a2,$3839ce3f,$3849e43a,$3859fa91,
                                         $386a1143,$387a284f,$388a3fb4,$389a5770,
                                         $38aa6f83,$38ba87ea,$38caa0a5,$38dab9b2,
                                         $38ead311,$38faecbf,$390b06bc,$391b2107,
                                         $392b3b9e,$393b5680,$394b71ac,$395b8d20,
                                         $396ba8dc,$397bc4dd,$398be124,$399bfdae,
                                         $39ac1a7a,$39bc3788,$39cc54d5,$39dc7261,
                                         $39ec902a,$39fcae2f,$3a0ccc70,$3a1ceaea,
                                         $3a2d099c,$3a3d2885,$3a4d47a5,$3a5d66f9,
                                         $3a6d8680,$3a7da63a,$3a8dc625,$3a9de63f,
                                         $3aae0688,$3abe26fe,$3ace47a0,$3ade686d,
                                         $3aee8963,$3afeaa82,$3b0ecbc7,$3b1eed32,
                                         $3b2f0ec2,$3b3f3075,$3b4f524a,$3b5f7440,
                                         $3b6f9656,$3b7fb889,$3b8fdada,$3b9ffd46,
                                         $3bb01fce,$3bc0426e,$3bd06526,$3be087f6,
                                         $3bf0aada,$3c00cdd4,$3c10f0e0,$3c2113fe,
                                         $3c31372d,$3c415a6b,$3c517db7,$3c61a110,
                                         $3c71c475,$3c81e7e4,$3c920b5c,$3ca22edc,
                                         $3cb25262,$3cc275ee,$3cd2997e,$3ce2bd11,
                                         $3cf2e0a6,$3d03043b,$3d1327cf,$3d234b61,
                                         $3d336ef0,$3d43927a,$3d53b5ff,$3d63d97c,
                                         $3d73fcf1,$3d84205c,$3d9443bd,$3da46711,
                                         $3db48a58,$3dc4ad91,$3dd4d0ba,$3de4f3d1,
                                         $3df516d7,$3e0539c9,$3e155ca6,$3e257f6d,
                                         $3e35a21d,$3e45c4b4,$3e55e731,$3e660994,
                                         $3e762bda,$3e864e03,$3e96700d,$3ea691f7,
                                         $3eb6b3bf,$3ec6d565,$3ed6f6e8,$3ee71845,
                                         $3ef7397c,$3f075a8c,$3f177b73,$3f279c30,
                                         $3f37bcc2,$3f47dd27,$3f57fd5f,$3f681d68,
                                         $3f783d40,$3f885ce7,$3f987c5c,$3fa89b9c,
                                         $3fb8baa7,$3fc8d97c,$3fd8f819,$3fe9167e,
                                         $3ff934a8,$40095296,$40197049,$40298dbd,
                                         $4039aaf2,$4049c7e7,$4059e49a,$406a010a,
                                         $407a1d36,$408a391d,$409a54bd,$40aa7015,
                                         $40ba8b25,$40caa5ea,$40dac063,$40eada90,
                                         $40faf46e,$410b0dfe,$411b273d,$412b402a,
                                         $413b58c4,$414b710a,$415b88fa,$416ba093,
                                         $417bb7d5,$418bcebe,$419be54c,$41abfb7e,
                                         $41bc1153,$41cc26ca,$41dc3be2,$41ec5099,
                                         $41fc64ef,$420c78e1,$421c8c6f,$422c9f97,
                                         $423cb258,$424cc4b2,$425cd6a2,$426ce827,
                                         $427cf941,$428d09ee,$429d1a2c,$42ad29fb,
                                         $42bd3959,$42cd4846,$42dd56bf,$42ed64c3,
                                         $42fd7252,$430d7f6a,$431d8c0a,$432d9831,
                                         $433da3dd,$434daf0d,$435db9c0,$436dc3f5,
                                         $437dcdab,$438dd6df,$439ddf92,$43ade7c1,
                                         $43bdef6c,$43cdf691,$43ddfd2f,$43ee0345,
                                         $43fe08d2,$440e0dd4,$441e124b,$442e1634,
                                         $443e198f,$444e1c5a,$445e1e95,$446e203e,
                                         $447e2153,$448e21d5,$449e21c0,$44ae2115,
                                         $44be1fd1,$44ce1df4,$44de1b7d,$44ee186a,
                                         $44fe14ba,$450e106b,$451e0b7e,$452e05ef,
                                         $453dffbf,$454df8eb,$455df173,$456de956,
                                         $457de092,$458dd726,$459dcd10,$45adc251,
                                         $45bdb6e5,$45cdaacd,$45dd9e06,$45ed9091,
                                         $45fd826a,$460d7392,$461d6407,$462d53c8,
                                         $463d42d4,$464d3129,$465d1ec6,$466d0baa,
                                         $467cf7d3,$468ce342,$469ccdf3,$46acb7e7,
                                         $46bca11c,$46cc8990,$46dc7143,$46ec5833,
                                         $46fc3e5f,$470c23c6,$471c0867,$472bec40,
                                         $473bcf50,$474bb196,$475b9311,$476b73c0,
                                         $477b53a1,$478b32b4,$479b10f6,$47aaee67,
                                         $47bacb06,$47caa6d1,$47da81c7,$47ea5be7,
                                         $47fa3530,$480a0da1,$4819e537,$4829bbf3,
                                         $483991d3,$484966d6,$48593afb,$48690e3f,
                                         $4878e0a3,$4888b225,$489882c4,$48a8527e,
                                         $48b82153,$48c7ef41,$48d7bc47,$48e78863,
                                         $48f75396,$49071ddc,$4916e736,$4926afa2,
                                         $4936771f,$49463dac,$49560347,$4965c7ef,
                                         $49758ba4,$49854e63,$4995102c,$49a4d0fe,
                                         $49b490d7,$49c44fb6,$49d40d9a,$49e3ca82,
                                         $49f3866c,$4a034159,$4a12fb45,$4a22b430,
                                         $4a326c19,$4a4222ff,$4a51d8e1,$4a618dbd,
                                         $4a714192,$4a80f45f,$4a90a623,$4aa056dd,
                                         $4ab0068b,$4abfb52c,$4acf62c0,$4adf0f44,
                                         $4aeebab9,$4afe651c,$4b0e0e6c,$4b1db6a9,
                                         $4b2d5dd1,$4b3d03e2,$4b4ca8dd,$4b5c4cbf,
                                         $4b6bef88,$4b7b9136,$4b8b31c8,$4b9ad13d,
                                         $4baa6f93,$4bba0ccb,$4bc9a8e2,$4bd943d7,
                                         $4be8dda9,$4bf87658,$4c080de1,$4c17a444,
                                         $4c27397f,$4c36cd92,$4c46607b,$4c55f239,
                                         $4c6582cb,$4c75122f,$4c84a065,$4c942d6c,
                                         $4ca3b942,$4cb343e6,$4cc2cd57,$4cd25594,
                                         $4ce1dc9c,$4cf1626d,$4d00e707,$4d106a68,
                                         $4d1fec8f,$4d2f6d7a,$4d3eed2a,$4d4e6b9d,
                                         $4d5de8d1,$4d6d64c5,$4d7cdf79,$4d8c58eb,
                                         $4d9bd11a,$4dab4804,$4dbabdaa,$4dca3209,
                                         $4dd9a520,$4de916ef,$4df88774,$4e07f6ae,
                                         $4e17649c,$4e26d13c,$4e363c8f,$4e45a692,
                                         $4e550f44,$4e6476a4,$4e73dcb2,$4e83416c,
                                         $4e92a4d1,$4ea206df,$4eb16796,$4ec0c6f5,
                                         $4ed024fa,$4edf81a5,$4eeedcf3,$4efe36e5,
                                         $4f0d8f79,$4f1ce6ad,$4f2c3c82,$4f3b90f4,
                                         $4f4ae405,$4f5a35b1,$4f6985fa,$4f78d4dc,
                                         $4f882257,$4f976e6a,$4fa6b914,$4fb60254,
                                         $4fc54a28,$4fd49090,$4fe3d58b,$4ff31917,
                                         $50025b33,$50119bde,$5020db17,$503018dd,
                                         $503f552f,$504e900b,$505dc971,$506d0160,
                                         $507c37d7,$508b6cd3,$509aa055,$50a9d25b,
                                         $50b902e4,$50c831ef,$50d75f7b,$50e68b87,
                                         $50f5b612,$5104df1a,$5114069f,$51232ca0,
                                         $5132511a,$5141740f,$5150957b,$515fb55f,
                                         $516ed3b8,$517df087,$518d0bca,$519c257f,
                                         $51ab3da7,$51ba543f,$51c96947,$51d87cbd,
                                         $51e78ea1,$51f69ef1,$5205adad,$5214bad3,
                                         $5223c662,$5232d05a,$5241d8b9,$5250df7d,
                                         $525fe4a7,$526ee835,$527dea26,$528cea78,
                                         $529be92c,$52aae63f,$52b9e1b0,$52c8db80,
                                         $52d7d3ac,$52e6ca33,$52f5bf15,$5304b251,
                                         $5313a3e5,$532293d0,$53318212,$53406ea8,
                                         $534f5993,$535e42d2,$536d2a62,$537c1043,
                                         $538af475,$5399d6f6,$53a8b7c4,$53b796e0,
                                         $53c67447,$53d54ffa,$53e429f6,$53f3023b,
                                         $5401d8c8,$5410ad9c,$541f80b5,$542e5213,
                                         $543d21b5,$544bef9a,$545abbc0,$54698627,
                                         $54784ece,$548715b3,$5495dad6,$54a49e35,
                                         $54b35fd0,$54c21fa6,$54d0ddb5,$54df99fd,
                                         $54ee547c,$54fd0d32,$550bc41d,$551a793d,
                                         $55292c91,$5537de16,$55468dce,$55553bb6,
                                         $5563e7cd,$55729213,$55813a87,$558fe127,
                                         $559e85f2,$55ad28e9,$55bbca08,$55ca6950,
                                         $55d906c0,$55e7a257,$55f63c13,$5604d3f4,
                                         $561369f8,$5621fe1f,$56309067,$563f20d1,
                                         $564daf5a,$565c3c02,$566ac6c7,$56794faa,
                                         $5687d6a8,$56965bc1,$56a4def4,$56b36040,
                                         $56c1dfa4,$56d05d1f,$56ded8af,$56ed5255,
                                         $56fbca0f,$570a3fdc,$5718b3bc,$572725ac,
                                         $573595ad,$574403bd,$57526fdb,$5760da07,
                                         $576f423f,$577da883,$578c0cd1,$579a6f29,
                                         $57a8cf8a,$57b72df2,$57c58a61,$57d3e4d6,
                                         $57e23d50,$57f093cd,$57fee84e,$580d3ad1,
                                         $581b8b54,$5829d9d8,$5838265c,$584670dd,
                                         $5854b95c,$5862ffd8,$5871444f,$587f86c1,
                                         $588dc72c,$589c0591,$58aa41ed,$58b87c40,
                                         $58c6b489,$58d4eac7,$58e31ef9,$58f1511f,
                                         $58ff8137,$590daf40,$591bdb3a,$592a0524,
                                         $59382cfc,$594652c2,$59547675,$59629815,
                                         $5970b79f,$597ed513,$598cf071,$599b09b7,
                                         $59a920e5,$59b735f9,$59c548f4,$59d359d2,
                                         $59e16895,$59ef753b,$59fd7fc4,$5a0b882d,
                                         $5a198e77,$5a2792a0,$5a3594a9,$5a43948e,
                                         $5a519251,$5a5f8df0,$5a6d876a,$5a7b7ebe,
                                         $5a8973ec,$5a9766f2,$5aa557d0,$5ab34685,
                                         $5ac1330f,$5acf1d6f,$5add05a3,$5aeaebaa,
                                         $5af8cf84,$5b06b12f,$5b1490ab,$5b226df7,
                                         $5b304912,$5b3e21fc,$5b4bf8b2,$5b59cd35,
                                         $5b679f84,$5b756f9e,$5b833d82,$5b91092e,
                                         $5b9ed2a3,$5bac99e0,$5bba5ee3,$5bc821ac,
                                         $5bd5e23a,$5be3a08c,$5bf15ca1,$5bff1679,
                                         $5c0cce12,$5c1a836c,$5c283686,$5c35e760,
                                         $5c4395f7,$5c51424c,$5c5eec5e,$5c6c942b,
                                         $5c7a39b4,$5c87dcf7,$5c957df3,$5ca31ca8,
                                         $5cb0b915,$5cbe5338,$5ccbeb12,$5cd980a1,
                                         $5ce713e5,$5cf4a4dd,$5d023387,$5d0fbfe4,
                                         $5d1d49f2,$5d2ad1b1,$5d38571f,$5d45da3c,
                                         $5d535b08,$5d60d981,$5d6e55a7,$5d7bcf78,
                                         $5d8946f5,$5d96bc1c,$5da42eec,$5db19f65,
                                         $5dbf0d86,$5dcc794e,$5dd9e2bd,$5de749d1,
                                         $5df4ae8a,$5e0210e7,$5e0f70e7,$5e1cce8a,
                                         $5e2a29ce,$5e3782b4,$5e44d93a,$5e522d5f,
                                         $5e5f7f23,$5e6cce85,$5e7a1b85,$5e876620,
                                         $5e94ae58,$5ea1f42a,$5eaf3797,$5ebc789d,
                                         $5ec9b73c,$5ed6f372,$5ee42d41,$5ef164a5,
                                         $5efe999f,$5f0bcc2f,$5f18fc52,$5f262a09,
                                         $5f335553,$5f407e2f,$5f4da49d,$5f5ac89b,
                                         $5f67ea29,$5f750946,$5f8225f2,$5f8f402b,
                                         $5f9c57f2,$5fa96d44,$5fb68023,$5fc3908c,
                                         $5fd09e7f,$5fdda9fc,$5feab302,$5ff7b990,
                                         $6004bda5,$6011bf40,$601ebe62,$602bbb09,
                                         $6038b534,$6045ace4,$6052a216,$605f94cb,
                                         $606c8502,$607972b9,$60865df2,$609346aa,
                                         $60a02ce1,$60ad1096,$60b9f1c9,$60c6d079,
                                         $60d3aca5,$60e0864d,$60ed5d70,$60fa320d,
                                         $61070424,$6113d3b4,$6120a0bc,$612d6b3c,
                                         $613a3332,$6146f89f,$6153bb82,$61607bd9,
                                         $616d39a5,$6179f4e5,$6186ad98,$619363bd,
                                         $61a01753,$61acc85b,$61b976d3,$61c622bc,
                                         $61d2cc13,$61df72d8,$61ec170c,$61f8b8ad,
                                         $620557ba,$6211f434,$621e8e18,$622b2568,
                                         $6237ba21,$62444c44,$6250dbd0,$625d68c4,
                                         $6269f320,$62767ae2,$6283000b,$628f829a,
                                         $629c028e,$62a87fe6,$62b4faa2,$62c172c2,
                                         $62cde844,$62da5b29,$62e6cb6e,$62f33915,
                                         $62ffa41c,$630c0c83,$63187248,$6324d56d,
                                         $633135ef,$633d93ce,$6349ef0b,$635647a3,
                                         $63629d97,$636ef0e6,$637b418f,$63878f92,
                                         $6393daef,$63a023a4,$63ac69b1,$63b8ad15,
                                         $63c4edd1,$63d12be3,$63dd674b,$63e9a008,
                                         $63f5d61a,$64020980,$640e3a39,$641a6846,
                                         $642693a5,$6432bc56,$643ee258,$644b05ab,
                                         $6457264e,$64634441,$646f5f83,$647b7814,
                                         $64878df3,$6493a120,$649fb199,$64abbf5f,
                                         $64b7ca71,$64c3d2ce,$64cfd877,$64dbdb69,
                                         $64e7dba6,$64f3d92b,$64ffd3fa,$650bcc11,
                                         $6517c16f,$6523b415,$652fa402,$653b9134,
                                         $65477bad,$6553636a,$655f486d,$656b2ab3,
                                         $65770a3d,$6582e70a,$658ec11a,$659a986d,
                                         $65a66d00,$65b23ed5,$65be0deb,$65c9da41,
                                         $65d5a3d7,$65e16aac,$65ed2ebf,$65f8f011,
                                         $6604aea1,$66106a6e,$661c2377,$6627d9be,
                                         $66338d40,$663f3dfd,$664aebf5,$66569728,
                                         $66623f95,$666de53b,$6679881b,$66852833,
                                         $6690c583,$669c600b,$66a7f7ca,$66b38cc0,
                                         $66bf1eec,$66caae4f,$66d63ae6,$66e1c4b3,
                                         $66ed4bb4,$66f8cfea,$67045153,$670fcfef,
                                         $671b4bbe,$6726c4bf,$67323af3,$673dae58,
                                         $67491eee,$67548cb5,$675ff7ab,$676b5fd2,
                                         $6776c528,$678227ad,$678d8761,$6798e443,
                                         $67a43e52,$67af958f,$67bae9f9,$67c63b8f,
                                         $67d18a52,$67dcd640,$67e81f59,$67f3659d,
                                         $67fea90c,$6809e9a5,$68152768,$68206254,
                                         $682b9a68,$6836cfa6,$6842020b,$684d3199,
                                         $68585e4d,$68638829,$686eaf2b,$6879d354,
                                         $6884f4a2,$68901316,$689b2eb0,$68a6476d,
                                         $68b15d50,$68bc7056,$68c78080,$68d28dcd,
                                         $68dd983e,$68e89fd0,$68f3a486,$68fea65d,
                                         $6909a555,$6914a16f,$691f9aa9,$692a9104,
                                         $69358480,$6940751b,$694b62d5,$69564daf,
                                         $696135a7,$696c1abe,$6976fcf3,$6981dc46,
                                         $698cb8b6,$69979243,$69a268ed,$69ad3cb4,
                                         $69b80d97,$69c2db96,$69cda6b0,$69d86ee5,
                                         $69e33436,$69edf6a1,$69f8b626,$6a0372c5,
                                         $6a0e2c7e,$6a18e350,$6a23973c,$6a2e4840,
                                         $6a38f65d,$6a43a191,$6a4e49de,$6a58ef42,
                                         $6a6391be,$6a6e3151,$6a78cdfa,$6a8367ba,
                                         $6a8dfe90,$6a98927c,$6aa3237d,$6aadb194,
                                         $6ab83cc0,$6ac2c500,$6acd4a55,$6ad7ccbf,
                                         $6ae24c3c,$6aecc8cd,$6af74271,$6b01b929,
                                         $6b0c2cf4,$6b169dd1,$6b210bc1,$6b2b76c2,
                                         $6b35ded6,$6b4043fc,$6b4aa632,$6b55057a,
                                         $6b5f61d3,$6b69bb3d,$6b7411b7,$6b7e6541,
                                         $6b88b5db,$6b930385,$6b9d4e3f,$6ba79607,
                                         $6bb1dadf,$6bbc1cc6,$6bc65bbb,$6bd097bf,
                                         $6bdad0d0,$6be506f0,$6bef3a1d,$6bf96a58,
                                         $6c0397a0,$6c0dc1f5,$6c17e957,$6c220dc6,
                                         $6c2c2f41,$6c364dc9,$6c40695c,$6c4a81fc,
                                         $6c5497a7,$6c5eaa5d,$6c68ba1f,$6c72c6eb,
                                         $6c7cd0c3,$6c86d7a6,$6c90db92,$6c9adc8a,
                                         $6ca4da8b,$6caed596,$6cb8cdab,$6cc2c2ca,
                                         $6cccb4f2,$6cd6a424,$6ce0905e,$6cea79a1,
                                         $6cf45fee,$6cfe4342,$6d0823a0,$6d120105,
                                         $6d1bdb73,$6d25b2e8,$6d2f8765,$6d3958ea,
                                         $6d432777,$6d4cf30a,$6d56bba5,$6d608147,
                                         $6d6a43f0,$6d7403a0,$6d7dc056,$6d877a13,
                                         $6d9130d6,$6d9ae4a0,$6da4956f,$6dae4345,
                                         $6db7ee20,$6dc19601,$6dcb3ae7,$6dd4dcd3,
                                         $6dde7bc4,$6de817bb,$6df1b0b6,$6dfb46b7,
                                         $6e04d9bc,$6e0e69c7,$6e17f6d5,$6e2180e9,
                                         $6e2b0801,$6e348c1d,$6e3e0d3d,$6e478b62,
                                         $6e51068a,$6e5a7eb7,$6e63f3e7,$6e6d661b,
                                         $6e76d552,$6e80418e,$6e89aacc,$6e93110f,
                                         $6e9c7454,$6ea5d49d,$6eaf31e9,$6eb88c37,
                                         $6ec1e389,$6ecb37de,$6ed48936,$6eddd790,
                                         $6ee722ee,$6ef06b4d,$6ef9b0b0,$6f02f315,
                                         $6f0c327c,$6f156ee6,$6f1ea852,$6f27dec1,
                                         $6f311232,$6f3a42a5,$6f43701a,$6f4c9a91,
                                         $6f55c20a,$6f5ee686,$6f680803,$6f712682,
                                         $6f7a4203,$6f835a86,$6f8c700b,$6f958291,
                                         $6f9e921a,$6fa79ea4,$6fb0a830,$6fb9aebd,
                                         $6fc2b24c,$6fcbb2dd,$6fd4b06f,$6fddab03,
                                         $6fe6a299,$6fef9730,$6ff888c9,$70017763,
                                         $700a62ff,$70134b9c,$701c313b,$702513dc,
                                         $702df37e,$7036d021,$703fa9c6,$7048806d,
                                         $70515415,$705a24bf,$7062f26b,$706bbd17,
                                         $707484c6,$707d4976,$70860b28,$708ec9dc,
                                         $70978591,$70a03e48,$70a8f400,$70b1a6bb,
                                         $70ba5677,$70c30335,$70cbacf5,$70d453b6,
                                         $70dcf77a,$70e59840,$70ee3607,$70f6d0d1,
                                         $70ff689d,$7107fd6b,$71108f3b,$71191e0d,
                                         $7121a9e2,$712a32b9,$7132b892,$713b3b6e,
                                         $7143bb4c,$714c382d,$7154b211,$715d28f7,
                                         $71659ce0,$716e0dcc,$71767bbb,$717ee6ac,
                                         $71874ea1,$718fb399,$71981594,$71a07493,
                                         $71a8d094,$71b1299a,$71b97fa2,$71c1d2af,
                                         $71ca22bf,$71d26fd2,$71dab9ea,$71e30106,
                                         $71eb4526,$71f3864a,$71fbc472,$7203ff9e,
                                         $720c37cf,$72146d05,$721c9f3f,$7224ce7e,
                                         $722cfac2,$7235240b,$723d4a59,$72456dad,
                                         $724d8e05,$7255ab63,$725dc5c7,$7265dd31,
                                         $726df1a0,$72760315,$727e1191,$72861d12,
                                         $728e259a,$72962b28,$729e2dbd,$72a62d59,
                                         $72ae29fc,$72b623a5,$72be1a56,$72c60e0e,
                                         $72cdfece,$72d5ec95,$72ddd764,$72e5bf3b,
                                         $72eda41a,$72f58601,$72fd64f1,$730540e9,
                                         $730d19e9,$7314eff3,$731cc305,$73249321,
                                         $732c6046,$73342a75,$733bf1ad,$7343b5ef,
                                         $734b773b,$73533591,$735af0f2,$7362a95d,
                                         $736a5ed3,$73721153,$7379c0df,$73816d76,
                                         $73891719,$7390bdc7,$73986181,$73a00247,
                                         $73a7a01a,$73af3af8,$73b6d2e4,$73be67dc,
                                         $73c5f9e1,$73cd88f3,$73d51513,$73dc9e40,
                                         $73e4247c,$73eba7c5,$73f3281c,$73faa582,
                                         $74021ff7,$7409977b,$74110c0d,$74187daf,
                                         $741fec61,$74275822,$742ec0f3,$743626d5,
                                         $743d89c7,$7444e9c9,$744c46dd,$7453a101,
                                         $745af837,$74624c7f,$74699dd8,$7470ec44,
                                         $747837c2,$747f8052,$7486c5f5,$748e08ac,
                                         $74954875,$749c8552,$74a3bf43,$74aaf648,
                                         $74b22a62,$74b95b90,$74c089d2,$74c7b52a,
                                         $74cedd97,$74d6031a,$74dd25b2,$74e44561,
                                         $74eb6226,$74f27c02,$74f992f5,$7500a6ff,
                                         $7507b820,$750ec659,$7515d1aa,$751cda14,
                                         $7523df96,$752ae231,$7531e1e5,$7538deb2,
                                         $753fd89a,$7546cf9b,$754dc3b7,$7554b4ed,
                                         $755ba33e,$75628eaa,$75697732,$75705cd5,
                                         $75773f95,$757e1f71,$7584fc6a,$758bd67f,
                                         $7592adb2,$75998203,$75a05371,$75a721fe,
                                         $75adeda9,$75b4b673,$75bb7c5c,$75c23f65,
                                         $75c8ff8d,$75cfbcd6,$75d6773f,$75dd2ec8,
                                         $75e3e373,$75ea953f,$75f1442d,$75f7f03d,
                                         $75fe996f,$76053fc5,$760be33d,$761283d8,
                                         $76192197,$761fbc7b,$76265482,$762ce9af,
                                         $76337c01,$763a0b78,$76409814,$764721d7,
                                         $764da8c1,$76542cd1,$765aae08,$76612c67,
                                         $7667a7ee,$766e209d,$76749675,$767b0975,
                                         $7681799f,$7687e6f3,$768e5170,$7694b918,
                                         $769b1deb,$76a17fe9,$76a7df13,$76ae3b68,
                                         $76b494ea,$76baeb98,$76c13f74,$76c7907c,
                                         $76cddeb3,$76d42a18,$76da72ab,$76e0b86d,
                                         $76e6fb5e,$76ed3b7f,$76f378d0,$76f9b352,
                                         $76ffeb05,$77061fe8,$770c51fe,$77128145,
                                         $7718adbf,$771ed76c,$7724fe4c,$772b225f,
                                         $773143a7,$77376223,$773d7dd3,$774396ba,
                                         $7749acd5,$774fc027,$7755d0af,$775bde6f,
                                         $7761e965,$7767f193,$776df6fa,$7773f998,
                                         $7779f970,$777ff681,$7785f0cd,$778be852,
                                         $7791dd12,$7797cf0d,$779dbe43,$77a3aab6,
                                         $77a99465,$77af7b50,$77b55f79,$77bb40e0,
                                         $77c11f85,$77c6fb68,$77ccd48a,$77d2aaec,
                                         $77d87e8d,$77de4f6f,$77e41d92,$77e9e8f5,
                                         $77efb19b,$77f57782,$77fb3aad,$7800fb1a,
                                         $7806b8ca,$780c73bf,$78122bf7,$7817e175,
                                         $781d9438,$78234440,$7828f18f,$782e9c25,
                                         $78344401,$7839e925,$783f8b92,$78452b46,
                                         $784ac844,$7850628b,$7855fa1c,$785b8ef8,
                                         $7861211e,$7866b090,$786c3d4d,$7871c757,
                                         $78774ead,$787cd351,$78825543,$7887d483,
                                         $788d5111,$7892caef,$7898421c,$789db69a,
                                         $78a32868,$78a89787,$78ae03f8,$78b36dbb,
                                         $78b8d4d1,$78be393a,$78c39af6,$78c8fa06,
                                         $78ce566c,$78d3b026,$78d90736,$78de5b9c,
                                         $78e3ad58,$78e8fc6c,$78ee48d7,$78f3929b,
                                         $78f8d9b7,$78fe1e2c,$79035ffb,$79089f24,
                                         $790ddba8,$79131587,$79184cc2,$791d8159,
                                         $7922b34d,$7927e29e,$792d0f4d,$7932395a,
                                         $793760c6,$793c8591,$7941a7bd,$7946c749,
                                         $794be435,$7950fe84,$79561634,$795b2b47,
                                         $79603dbc,$79654d96,$796a5ad4,$796f6576,
                                         $79746d7e,$797972eb,$797e75bf,$798375f9,
                                         $7988739b,$798d6ea5,$79926717,$79975cf2,
                                         $799c5037,$79a140e6,$79a62f00,$79ab1a85,
                                         $79b00376,$79b4e9d3,$79b9cd9d,$79beaed4,
                                         $79c38d79,$79c8698d,$79cd4310,$79d21a03,
                                         $79d6ee66,$79dbc03a,$79e08f7f,$79e55c36,
                                         $79ea265f,$79eeedfc,$79f3b30c,$79f87590,
                                         $79fd3589,$7a01f2f7,$7a06addc,$7a0b6636,
                                         $7a101c08,$7a14cf52,$7a198013,$7a1e2e4d,
                                         $7a22da01,$7a27832f,$7a2c29d7,$7a30cdfa,
                                         $7a356f99,$7a3a0eb4,$7a3eab4c,$7a434561,
                                         $7a47dcf5,$7a4c7207,$7a510498,$7a5594a9,
                                         $7a5a223a,$7a5ead4d,$7a6335e0,$7a67bbf6,
                                         $7a6c3f8f,$7a70c0ab,$7a753f4b,$7a79bb6f,
                                         $7a7e3519,$7a82ac48,$7a8720fe,$7a8b933b,
                                         $7a9002ff,$7a94704b,$7a98db20,$7a9d437e,
                                         $7aa1a967,$7aa60cd9,$7aaa6dd7,$7aaecc61,
                                         $7ab32877,$7ab7821b,$7abbd94b,$7ac02e0a,
                                         $7ac48058,$7ac8d035,$7acd1da3,$7ad168a1,
                                         $7ad5b130,$7ad9f751,$7ade3b05,$7ae27c4c,
                                         $7ae6bb27,$7aeaf796,$7aef319a,$7af36934,
                                         $7af79e64,$7afbd12c,$7b00018a,$7b042f81,
                                         $7b085b10,$7b0c8439,$7b10aafc,$7b14cf5a,
                                         $7b18f153,$7b1d10e8,$7b212e1a,$7b2548e9,
                                         $7b296155,$7b2d7761,$7b318b0b,$7b359c55,
                                         $7b39ab3f,$7b3db7cb,$7b41c1f8,$7b45c9c8,
                                         $7b49cf3b,$7b4dd251,$7b51d30b,$7b55d16b,
                                         $7b59cd70,$7b5dc71b,$7b61be6d,$7b65b366,
                                         $7b69a608,$7b6d9653,$7b718447,$7b756fe5,
                                         $7b79592e,$7b7d4022,$7b8124c3,$7b850710,
                                         $7b88e70a,$7b8cc4b3,$7b90a00a,$7b947911,
                                         $7b984fc8,$7b9c242f,$7b9ff648,$7ba3c612,
                                         $7ba79390,$7bab5ec1,$7baf27a5,$7bb2ee3f,
                                         $7bb6b28e,$7bba7493,$7bbe344e,$7bc1f1c1,
                                         $7bc5acec,$7bc965cf,$7bcd1c6c,$7bd0d0c3,
                                         $7bd482d4,$7bd832a1,$7bdbe02a,$7bdf8b70,
                                         $7be33473,$7be6db34,$7bea7fb4,$7bee21f4,
                                         $7bf1c1f3,$7bf55fb3,$7bf8fb35,$7bfc9479,
                                         $7c002b7f,$7c03c04a,$7c0752d8,$7c0ae32b,
                                         $7c0e7144,$7c11fd23,$7c1586c9,$7c190e36,
                                         $7c1c936c,$7c20166b,$7c239733,$7c2715c6,
                                         $7c2a9224,$7c2e0c4e,$7c318444,$7c34fa07,
                                         $7c386d98,$7c3bdef8,$7c3f4e26,$7c42bb25,
                                         $7c4625f4,$7c498e95,$7c4cf507,$7c50594c,
                                         $7c53bb65,$7c571b51,$7c5a7913,$7c5dd4aa,
                                         $7c612e17,$7c64855b,$7c67da76,$7c6b2d6a,
                                         $7c6e7e37,$7c71ccdd,$7c75195e,$7c7863ba,
                                         $7c7babf1,$7c7ef206,$7c8235f7,$7c8577c6,
                                         $7c88b774,$7c8bf502,$7c8f306f,$7c9269bd,
                                         $7c95a0ec,$7c98d5fe,$7c9c08f2,$7c9f39cb,
                                         $7ca26887,$7ca59528,$7ca8bfb0,$7cabe81d,
                                         $7caf0e72,$7cb232af,$7cb554d4,$7cb874e2,
                                         $7cbb92db,$7cbeaebe,$7cc1c88d,$7cc4e047,
                                         $7cc7f5ef,$7ccb0984,$7cce1b08,$7cd12a7b,
                                         $7cd437dd,$7cd74330,$7cda4c74,$7cdd53aa,
                                         $7ce058d3,$7ce35bef,$7ce65cff,$7ce95c04,
                                         $7cec58ff,$7cef53f0,$7cf24cd7,$7cf543b7,
                                         $7cf8388f,$7cfb2b60,$7cfe1c2b,$7d010af1,
                                         $7d03f7b2,$7d06e26f,$7d09cb29,$7d0cb1e0,
                                         $7d0f9696,$7d12794b,$7d1559ff,$7d1838b4,
                                         $7d1b156a,$7d1df022,$7d20c8dd,$7d239f9b,
                                         $7d26745e,$7d294725,$7d2c17f1,$7d2ee6c4,
                                         $7d31b39f,$7d347e81,$7d37476b,$7d3a0e5f,
                                         $7d3cd35d,$7d3f9665,$7d425779,$7d451699,
                                         $7d47d3c6,$7d4a8f01,$7d4d484b,$7d4fffa3,
                                         $7d52b50c,$7d556885,$7d581a0f,$7d5ac9ac,
                                         $7d5d775c,$7d60231f,$7d62ccf6,$7d6574e3,
                                         $7d681ae6,$7d6abeff,$7d6d612f,$7d700178,
                                         $7d729fd9,$7d753c54,$7d77d6e9,$7d7a6f9a,
                                         $7d7d0666,$7d7f9b4f,$7d822e55,$7d84bf79,
                                         $7d874ebc,$7d89dc1e,$7d8c67a1,$7d8ef144,
                                         $7d91790a,$7d93fef2,$7d9682fd,$7d99052d,
                                         $7d9b8581,$7d9e03fb,$7da0809b,$7da2fb62,
                                         $7da57451,$7da7eb68,$7daa60a8,$7dacd413,
                                         $7daf45a9,$7db1b56a,$7db42357,$7db68f71,
                                         $7db8f9b9,$7dbb6230,$7dbdc8d6,$7dc02dac,
                                         $7dc290b3,$7dc4f1eb,$7dc75156,$7dc9aef4,
                                         $7dcc0ac5,$7dce64cc,$7dd0bd07,$7dd31379,
                                         $7dd56821,$7dd7bb01,$7dda0c1a,$7ddc5b6b,
                                         $7ddea8f7,$7de0f4bd,$7de33ebe,$7de586fc,
                                         $7de7cd76,$7dea122e,$7dec5525,$7dee965a,
                                         $7df0d5d0,$7df31386,$7df54f7e,$7df789b8,
                                         $7df9c235,$7dfbf8f5,$7dfe2dfa,$7e006145,
                                         $7e0292d5,$7e04c2ac,$7e06f0cb,$7e091d32,
                                         $7e0b47e1,$7e0d70db,$7e0f981f,$7e11bdaf,
                                         $7e13e18a,$7e1603b3,$7e182429,$7e1a42ed,
                                         $7e1c6001,$7e1e7b64,$7e209518,$7e22ad1d,
                                         $7e24c375,$7e26d81f,$7e28eb1d,$7e2afc70,
                                         $7e2d0c17,$7e2f1a15,$7e31266a,$7e333115,
                                         $7e353a1a,$7e374177,$7e39472e,$7e3b4b3f,
                                         $7e3d4dac,$7e3f4e75,$7e414d9a,$7e434b1e,
                                         $7e4546ff,$7e474140,$7e4939e0,$7e4b30e2,
                                         $7e4d2644,$7e4f1a09,$7e510c30,$7e52fcbc,
                                         $7e54ebab,$7e56d900,$7e58c4bb,$7e5aaedd,
                                         $7e5c9766,$7e5e7e57,$7e6063b2,$7e624776,
                                         $7e6429a5,$7e660a3f,$7e67e945,$7e69c6b8,
                                         $7e6ba299,$7e6d7ce7,$7e6f55a5,$7e712cd3,
                                         $7e730272,$7e74d682,$7e76a904,$7e7879f9,
                                         $7e7a4962,$7e7c173f,$7e7de392,$7e7fae5a,
                                         $7e817799,$7e833f50,$7e85057f,$7e86ca27,
                                         $7e888d49,$7e8a4ee5,$7e8c0efd,$7e8dcd91,
                                         $7e8f8aa1,$7e914630,$7e93003c,$7e94b8c8,
                                         $7e966fd4,$7e982560,$7e99d96e,$7e9b8bfe,
                                         $7e9d3d10,$7e9eeca7,$7ea09ac2,$7ea24762,
                                         $7ea3f288,$7ea59c35,$7ea7446a,$7ea8eb27,
                                         $7eaa906c,$7eac343c,$7eadd696,$7eaf777b,
                                         $7eb116ed,$7eb2b4eb,$7eb45177,$7eb5ec91,
                                         $7eb7863b,$7eb91e74,$7ebab53e,$7ebc4a99,
                                         $7ebdde87,$7ebf7107,$7ec1021b,$7ec291c3,
                                         $7ec42001,$7ec5acd5,$7ec7383f,$7ec8c241,
                                         $7eca4adb,$7ecbd20d,$7ecd57da,$7ecedc41,
                                         $7ed05f44,$7ed1e0e2,$7ed3611d,$7ed4dff6,
                                         $7ed65d6d,$7ed7d983,$7ed95438,$7edacd8f,
                                         $7edc4586,$7eddbc20,$7edf315c,$7ee0a53c,
                                         $7ee217c1,$7ee388ea,$7ee4f8b9,$7ee6672f,
                                         $7ee7d44c,$7ee94012,$7eeaaa80,$7eec1397,
                                         $7eed7b59,$7eeee1c6,$7ef046df,$7ef1aaa5,
                                         $7ef30d18,$7ef46e39,$7ef5ce09,$7ef72c88,
                                         $7ef889b8,$7ef9e599,$7efb402c,$7efc9972,
                                         $7efdf16b,$7eff4818,$7f009d79,$7f01f191,
                                         $7f03445f,$7f0495e4,$7f05e620,$7f073516,
                                         $7f0882c5,$7f09cf2d,$7f0b1a51,$7f0c6430,
                                         $7f0daccc,$7f0ef425,$7f103a3b,$7f117f11,
                                         $7f12c2a5,$7f1404fa,$7f15460f,$7f1685e6,
                                         $7f17c47f,$7f1901db,$7f1a3dfb,$7f1b78e0,
                                         $7f1cb28a,$7f1deafa,$7f1f2231,$7f20582f,
                                         $7f218cf5,$7f22c085,$7f23f2de,$7f252401,
                                         $7f2653f0,$7f2782ab,$7f28b032,$7f29dc87,
                                         $7f2b07aa,$7f2c319c,$7f2d5a5e,$7f2e81f0,
                                         $7f2fa853,$7f30cd88,$7f31f18f,$7f33146a,
                                         $7f343619,$7f35569c,$7f3675f6,$7f379425,
                                         $7f38b12c,$7f39cd0a,$7f3ae7c0,$7f3c0150,
                                         $7f3d19ba,$7f3e30fe,$7f3f471e,$7f405c1a,
                                         $7f416ff3,$7f4282a9,$7f43943e,$7f44a4b2,
                                         $7f45b405,$7f46c239,$7f47cf4e,$7f48db45,
                                         $7f49e61f,$7f4aefdc,$7f4bf87e,$7f4d0004,
                                         $7f4e0670,$7f4f0bc2,$7f500ffb,$7f51131c,
                                         $7f521525,$7f531618,$7f5415f4,$7f5514bb,
                                         $7f56126e,$7f570f0c,$7f580a98,$7f590511,
                                         $7f59fe78,$7f5af6ce,$7f5bee14,$7f5ce44a,
                                         $7f5dd972,$7f5ecd8b,$7f5fc097,$7f60b296,
                                         $7f61a389,$7f629370,$7f63824e,$7f647021,
                                         $7f655ceb,$7f6648ad,$7f673367,$7f681d19,
                                         $7f6905c6,$7f69ed6d,$7f6ad40f,$7f6bb9ad,
                                         $7f6c9e48,$7f6d81e0,$7f6e6475,$7f6f460a,
                                         $7f70269d,$7f710631,$7f71e4c6,$7f72c25c,
                                         $7f739ef4,$7f747a8f,$7f75552e,$7f762ed1,
                                         $7f770779,$7f77df27,$7f78b5db,$7f798b97,
                                         $7f7a605a,$7f7b3425,$7f7c06fa,$7f7cd8d9,
                                         $7f7da9c2,$7f7e79b7,$7f7f48b8,$7f8016c5,
                                         $7f80e3e0,$7f81b009,$7f827b40,$7f834588,
                                         $7f840edf,$7f84d747,$7f859ec1,$7f86654d,
                                         $7f872aec,$7f87ef9e,$7f88b365,$7f897641,
                                         $7f8a3832,$7f8af93a,$7f8bb959,$7f8c7890,
                                         $7f8d36df,$7f8df448,$7f8eb0ca,$7f8f6c67,
                                         $7f90271e,$7f90e0f2,$7f9199e2,$7f9251f0,
                                         $7f93091b,$7f93bf65,$7f9474ce,$7f952958,
                                         $7f95dd01,$7f968fcd,$7f9741ba,$7f97f2ca,
                                         $7f98a2fd,$7f995254,$7f9a00d0,$7f9aae71,
                                         $7f9b5b38,$7f9c0726,$7f9cb23b,$7f9d5c78,
                                         $7f9e05de,$7f9eae6e,$7f9f5627,$7f9ffd0b,
                                         $7fa0a31b,$7fa14856,$7fa1ecbf,$7fa29054,
                                         $7fa33318,$7fa3d50b,$7fa4762c,$7fa5167e,
                                         $7fa5b601,$7fa654b5,$7fa6f29b,$7fa78fb3,
                                         $7fa82bff,$7fa8c77f,$7fa96234,$7fa9fc1e,
                                         $7faa953e,$7fab2d94,$7fabc522,$7fac5be8,
                                         $7facf1e6,$7fad871d,$7fae1b8f,$7faeaf3b,
                                         $7faf4222,$7fafd445,$7fb065a4,$7fb0f641,
                                         $7fb1861b,$7fb21534,$7fb2a38c,$7fb33124,
                                         $7fb3bdfb,$7fb44a14,$7fb4d56f,$7fb5600c,
                                         $7fb5e9ec,$7fb6730f,$7fb6fb76,$7fb78323,
                                         $7fb80a15,$7fb8904d,$7fb915cc,$7fb99a92,
                                         $7fba1ea0,$7fbaa1f7,$7fbb2497,$7fbba681,
                                         $7fbc27b5,$7fbca835,$7fbd2801,$7fbda719,
                                         $7fbe257e,$7fbea331,$7fbf2032,$7fbf9c82,
                                         $7fc01821,$7fc09311,$7fc10d52,$7fc186e4,
                                         $7fc1ffc8,$7fc277ff,$7fc2ef89,$7fc36667,
                                         $7fc3dc9a,$7fc45221,$7fc4c6ff,$7fc53b33,
                                         $7fc5aebe,$7fc621a0,$7fc693db,$7fc7056f,
                                         $7fc7765c,$7fc7e6a3,$7fc85645,$7fc8c542,
                                         $7fc9339b,$7fc9a150,$7fca0e63,$7fca7ad3,
                                         $7fcae6a2,$7fcb51cf,$7fcbbc5c,$7fcc2649,
                                         $7fcc8f97,$7fccf846,$7fcd6058,$7fcdc7cb,
                                         $7fce2ea2,$7fce94dd,$7fcefa7b,$7fcf5f7f,
                                         $7fcfc3e8,$7fd027b7,$7fd08aed,$7fd0ed8b,
                                         $7fd14f90,$7fd1b0fd,$7fd211d4,$7fd27214,
                                         $7fd2d1bf,$7fd330d4,$7fd38f55,$7fd3ed41,
                                         $7fd44a9a,$7fd4a761,$7fd50395,$7fd55f37,
                                         $7fd5ba48,$7fd614c9,$7fd66eba,$7fd6c81b,
                                         $7fd720ed,$7fd77932,$7fd7d0e8,$7fd82812,
                                         $7fd87eae,$7fd8d4bf,$7fd92a45,$7fd97f40,
                                         $7fd9d3b0,$7fda2797,$7fda7af5,$7fdacdca,
                                         $7fdb2018,$7fdb71dd,$7fdbc31c,$7fdc13d5,
                                         $7fdc6408,$7fdcb3b6,$7fdd02df,$7fdd5184,
                                         $7fdd9fa5,$7fdded44,$7fde3a60,$7fde86fb,
                                         $7fded314,$7fdf1eac,$7fdf69c4,$7fdfb45d,
                                         $7fdffe76,$7fe04811,$7fe0912e,$7fe0d9ce,
                                         $7fe121f0,$7fe16996,$7fe1b0c1,$7fe1f770,
                                         $7fe23da4,$7fe2835f,$7fe2c89f,$7fe30d67,
                                         $7fe351b5,$7fe3958c,$7fe3d8ec,$7fe41bd4,
                                         $7fe45e46,$7fe4a042,$7fe4e1c8,$7fe522da,
                                         $7fe56378,$7fe5a3a1,$7fe5e358,$7fe6229b,
                                         $7fe6616d,$7fe69fcc,$7fe6ddbb,$7fe71b39,
                                         $7fe75847,$7fe794e5,$7fe7d114,$7fe80cd5,
                                         $7fe84827,$7fe8830c,$7fe8bd84,$7fe8f78f,
                                         $7fe9312f,$7fe96a62,$7fe9a32b,$7fe9db8a,
                                         $7fea137e,$7fea4b09,$7fea822b,$7feab8e5,
                                         $7feaef37,$7feb2521,$7feb5aa4,$7feb8fc1,
                                         $7febc478,$7febf8ca,$7fec2cb6,$7fec603e,
                                         $7fec9363,$7fecc623,$7fecf881,$7fed2a7c,
                                         $7fed5c16,$7fed8d4e,$7fedbe24,$7fedee9b,
                                         $7fee1eb1,$7fee4e68,$7fee7dc0,$7feeacb9,
                                         $7feedb54,$7fef0991,$7fef3771,$7fef64f5,
                                         $7fef921d,$7fefbee8,$7fefeb59,$7ff0176f,
                                         $7ff0432a,$7ff06e8c,$7ff09995,$7ff0c444,
                                         $7ff0ee9c,$7ff1189b,$7ff14243,$7ff16b94,
                                         $7ff1948e,$7ff1bd32,$7ff1e581,$7ff20d7b,
                                         $7ff2351f,$7ff25c70,$7ff2836d,$7ff2aa17,
                                         $7ff2d06d,$7ff2f672,$7ff31c24,$7ff34185,
                                         $7ff36695,$7ff38b55,$7ff3afc4,$7ff3d3e4,
                                         $7ff3f7b4,$7ff41b35,$7ff43e69,$7ff4614e,
                                         $7ff483e6,$7ff4a631,$7ff4c82f,$7ff4e9e1,
                                         $7ff50b47,$7ff52c62,$7ff54d33,$7ff56db9,
                                         $7ff58df5,$7ff5ade7,$7ff5cd90,$7ff5ecf1,
                                         $7ff60c09,$7ff62ada,$7ff64963,$7ff667a5,
                                         $7ff685a1,$7ff6a357,$7ff6c0c7,$7ff6ddf1,
                                         $7ff6fad7,$7ff71778,$7ff733d6,$7ff74fef,
                                         $7ff76bc6,$7ff78759,$7ff7a2ab,$7ff7bdba,
                                         $7ff7d888,$7ff7f315,$7ff80d61,$7ff8276c,
                                         $7ff84138,$7ff85ac4,$7ff87412,$7ff88d20,
                                         $7ff8a5f0,$7ff8be82,$7ff8d6d7,$7ff8eeef,
                                         $7ff906c9,$7ff91e68,$7ff935cb,$7ff94cf2,
                                         $7ff963dd,$7ff97a8f,$7ff99105,$7ff9a742,
                                         $7ff9bd45,$7ff9d30f,$7ff9e8a0,$7ff9fdf9,
                                         $7ffa131a,$7ffa2803,$7ffa3cb4,$7ffa512f,
                                         $7ffa6573,$7ffa7981,$7ffa8d59,$7ffaa0fc,
                                         $7ffab46a,$7ffac7a3,$7ffadaa8,$7ffaed78,
                                         $7ffb0015,$7ffb127f,$7ffb24b6,$7ffb36bb,
                                         $7ffb488d,$7ffb5a2e,$7ffb6b9d,$7ffb7cdb,
                                         $7ffb8de9,$7ffb9ec6,$7ffbaf73,$7ffbbff1,
                                         $7ffbd03f,$7ffbe05e,$7ffbf04f,$7ffc0012,
                                         $7ffc0fa6,$7ffc1f0d,$7ffc2e47,$7ffc3d54,
                                         $7ffc4c35,$7ffc5ae9,$7ffc6971,$7ffc77ce,
                                         $7ffc8600,$7ffc9407,$7ffca1e4,$7ffcaf96,
                                         $7ffcbd1f,$7ffcca7e,$7ffcd7b4,$7ffce4c1,
                                         $7ffcf1a5,$7ffcfe62,$7ffd0af6,$7ffd1763,
                                         $7ffd23a9,$7ffd2fc8,$7ffd3bc1,$7ffd4793,
                                         $7ffd533f,$7ffd5ec5,$7ffd6a27,$7ffd7563,
                                         $7ffd807a,$7ffd8b6e,$7ffd963d,$7ffda0e8,
                                         $7ffdab70,$7ffdb5d5,$7ffdc017,$7ffdca36,
                                         $7ffdd434,$7ffdde0f,$7ffde7c9,$7ffdf161,
                                         $7ffdfad8,$7ffe042f,$7ffe0d65,$7ffe167b,
                                         $7ffe1f71,$7ffe2848,$7ffe30ff,$7ffe3997,
                                         $7ffe4211,$7ffe4a6c,$7ffe52a9,$7ffe5ac8,
                                         $7ffe62c9,$7ffe6aae,$7ffe7275,$7ffe7a1f,
                                         $7ffe81ad,$7ffe891f,$7ffe9075,$7ffe97b0,
                                         $7ffe9ece,$7ffea5d2,$7ffeacbb,$7ffeb38a,
                                         $7ffeba3e,$7ffec0d8,$7ffec758,$7ffecdbf,
                                         $7ffed40d,$7ffeda41,$7ffee05d,$7ffee660,
                                         $7ffeec4b,$7ffef21f,$7ffef7da,$7ffefd7e,
                                         $7fff030b,$7fff0881,$7fff0de0,$7fff1328,
                                         $7fff185b,$7fff1d77,$7fff227e,$7fff276f,
                                         $7fff2c4b,$7fff3112,$7fff35c4,$7fff3a62,
                                         $7fff3eeb,$7fff4360,$7fff47c2,$7fff4c0f,
                                         $7fff504a,$7fff5471,$7fff5885,$7fff5c87,
                                         $7fff6076,$7fff6452,$7fff681d,$7fff6bd6,
                                         $7fff6f7d,$7fff7313,$7fff7698,$7fff7a0c,
                                         $7fff7d6f,$7fff80c2,$7fff8404,$7fff8736,
                                         $7fff8a58,$7fff8d6b,$7fff906e,$7fff9362,
                                         $7fff9646,$7fff991c,$7fff9be3,$7fff9e9c,
                                         $7fffa146,$7fffa3e2,$7fffa671,$7fffa8f1,
                                         $7fffab65,$7fffadca,$7fffb023,$7fffb26f,
                                         $7fffb4ae,$7fffb6e0,$7fffb906,$7fffbb20,
                                         $7fffbd2e,$7fffbf30,$7fffc126,$7fffc311,
                                         $7fffc4f1,$7fffc6c5,$7fffc88f,$7fffca4d,
                                         $7fffcc01,$7fffcdab,$7fffcf4a,$7fffd0e0,
                                         $7fffd26b,$7fffd3ec,$7fffd564,$7fffd6d2,
                                         $7fffd838,$7fffd993,$7fffdae6,$7fffdc31,
                                         $7fffdd72,$7fffdeab,$7fffdfdb,$7fffe104,
                                         $7fffe224,$7fffe33c,$7fffe44d,$7fffe556,
                                         $7fffe657,$7fffe751,$7fffe844,$7fffe930,
                                         $7fffea15,$7fffeaf3,$7fffebca,$7fffec9b,
                                         $7fffed66,$7fffee2a,$7fffeee8,$7fffefa0,
                                         $7ffff053,$7ffff0ff,$7ffff1a6,$7ffff247,
                                         $7ffff2e4,$7ffff37a,$7ffff40c,$7ffff499,
                                         $7ffff520,$7ffff5a3,$7ffff621,$7ffff69b,
                                         $7ffff710,$7ffff781,$7ffff7ee,$7ffff857,
                                         $7ffff8bb,$7ffff91c,$7ffff979,$7ffff9d2,
                                         $7ffffa27,$7ffffa79,$7ffffac8,$7ffffb13,
                                         $7ffffb5b,$7ffffba0,$7ffffbe2,$7ffffc21,
                                         $7ffffc5d,$7ffffc96,$7ffffccd,$7ffffd01,
                                         $7ffffd32,$7ffffd61,$7ffffd8e,$7ffffdb8,
                                         $7ffffde0,$7ffffe07,$7ffffe2b,$7ffffe4d,
                                         $7ffffe6d,$7ffffe8b,$7ffffea8,$7ffffec3,
                                         $7ffffedc,$7ffffef4,$7fffff0a,$7fffff1f,
                                         $7fffff33,$7fffff45,$7fffff56,$7fffff66,
                                         $7fffff75,$7fffff82,$7fffff8f,$7fffff9a,
                                         $7fffffa5,$7fffffaf,$7fffffb8,$7fffffc0,
                                         $7fffffc8,$7fffffce,$7fffffd5,$7fffffda,
                                         $7fffffdf,$7fffffe4,$7fffffe8,$7fffffeb,
                                         $7fffffef,$7ffffff1,$7ffffff4,$7ffffff6,
                                         $7ffffff8,$7ffffff9,$7ffffffb,$7ffffffc,
                                         $7ffffffd,$7ffffffd,$7ffffffe,$7fffffff,
                                         $7fffffff,$7fffffff,$7fffffff,$7fffffff,
                                         $7fffffff,$7fffffff,$7fffffff,$7fffffff,
                                         $7fffffff,$7fffffff,$7fffffff,$7fffffff);

     sincos_lookup0:array[0..1025] of longint=($00000000,$7fffffff,$003243f5,$7ffff621,
                                               $006487e3,$7fffd886,$0096cbc1,$7fffa72c,
                                               $00c90f88,$7fff6216,$00fb5330,$7fff0943,
                                               $012d96b1,$7ffe9cb2,$015fda03,$7ffe1c65,
                                               $01921d20,$7ffd885a,$01c45ffe,$7ffce093,
                                               $01f6a297,$7ffc250f,$0228e4e2,$7ffb55ce,
                                               $025b26d7,$7ffa72d1,$028d6870,$7ff97c18,
                                               $02bfa9a4,$7ff871a2,$02f1ea6c,$7ff75370,
                                               $03242abf,$7ff62182,$03566a96,$7ff4dbd9,
                                               $0388a9ea,$7ff38274,$03bae8b2,$7ff21553,
                                               $03ed26e6,$7ff09478,$041f6480,$7feeffe1,
                                               $0451a177,$7fed5791,$0483ddc3,$7feb9b85,
                                               $04b6195d,$7fe9cbc0,$04e8543e,$7fe7e841,
                                               $051a8e5c,$7fe5f108,$054cc7b1,$7fe3e616,
                                               $057f0035,$7fe1c76b,$05b137df,$7fdf9508,
                                               $05e36ea9,$7fdd4eec,$0615a48b,$7fdaf519,
                                               $0647d97c,$7fd8878e,$067a0d76,$7fd6064c,
                                               $06ac406f,$7fd37153,$06de7262,$7fd0c8a3,
                                               $0710a345,$7fce0c3e,$0742d311,$7fcb3c23,
                                               $077501be,$7fc85854,$07a72f45,$7fc560cf,
                                               $07d95b9e,$7fc25596,$080b86c2,$7fbf36aa,
                                               $083db0a7,$7fbc040a,$086fd947,$7fb8bdb8,
                                               $08a2009a,$7fb563b3,$08d42699,$7fb1f5fc,
                                               $09064b3a,$7fae7495,$09386e78,$7faadf7c,
                                               $096a9049,$7fa736b4,$099cb0a7,$7fa37a3c,
                                               $09cecf89,$7f9faa15,$0a00ece8,$7f9bc640,
                                               $0a3308bd,$7f97cebd,$0a6522fe,$7f93c38c,
                                               $0a973ba5,$7f8fa4b0,$0ac952aa,$7f8b7227,
                                               $0afb6805,$7f872bf3,$0b2d7baf,$7f82d214,
                                               $0b5f8d9f,$7f7e648c,$0b919dcf,$7f79e35a,
                                               $0bc3ac35,$7f754e80,$0bf5b8cb,$7f70a5fe,
                                               $0c27c389,$7f6be9d4,$0c59cc68,$7f671a05,
                                               $0c8bd35e,$7f62368f,$0cbdd865,$7f5d3f75,
                                               $0cefdb76,$7f5834b7,$0d21dc87,$7f531655,
                                               $0d53db92,$7f4de451,$0d85d88f,$7f489eaa,
                                               $0db7d376,$7f434563,$0de9cc40,$7f3dd87c,
                                               $0e1bc2e4,$7f3857f6,$0e4db75b,$7f32c3d1,
                                               $0e7fa99e,$7f2d1c0e,$0eb199a4,$7f2760af,
                                               $0ee38766,$7f2191b4,$0f1572dc,$7f1baf1e,
                                               $0f475bff,$7f15b8ee,$0f7942c7,$7f0faf25,
                                               $0fab272b,$7f0991c4,$0fdd0926,$7f0360cb,
                                               $100ee8ad,$7efd1c3c,$1040c5bb,$7ef6c418,
                                               $1072a048,$7ef05860,$10a4784b,$7ee9d914,
                                               $10d64dbd,$7ee34636,$11082096,$7edc9fc6,
                                               $1139f0cf,$7ed5e5c6,$116bbe60,$7ecf1837,
                                               $119d8941,$7ec8371a,$11cf516a,$7ec14270,
                                               $120116d5,$7eba3a39,$1232d979,$7eb31e78,
                                               $1264994e,$7eabef2c,$1296564d,$7ea4ac58,
                                               $12c8106f,$7e9d55fc,$12f9c7aa,$7e95ec1a,
                                               $132b7bf9,$7e8e6eb2,$135d2d53,$7e86ddc6,
                                               $138edbb1,$7e7f3957,$13c0870a,$7e778166,
                                               $13f22f58,$7e6fb5f4,$1423d492,$7e67d703,
                                               $145576b1,$7e5fe493,$148715ae,$7e57dea7,
                                               $14b8b17f,$7e4fc53e,$14ea4a1f,$7e47985b,
                                               $151bdf86,$7e3f57ff,$154d71aa,$7e37042a,
                                               $157f0086,$7e2e9cdf,$15b08c12,$7e26221f,
                                               $15e21445,$7e1d93ea,$16139918,$7e14f242,
                                               $16451a83,$7e0c3d29,$1676987f,$7e0374a0,
                                               $16a81305,$7dfa98a8,$16d98a0c,$7df1a942,
                                               $170afd8d,$7de8a670,$173c6d80,$7ddf9034,
                                               $176dd9de,$7dd6668f,$179f429f,$7dcd2981,
                                               $17d0a7bc,$7dc3d90d,$1802092c,$7dba7534,
                                               $183366e9,$7db0fdf8,$1864c0ea,$7da77359,
                                               $18961728,$7d9dd55a,$18c7699b,$7d9423fc,
                                               $18f8b83c,$7d8a5f40,$192a0304,$7d808728,
                                               $195b49ea,$7d769bb5,$198c8ce7,$7d6c9ce9,
                                               $19bdcbf3,$7d628ac6,$19ef0707,$7d58654d,
                                               $1a203e1b,$7d4e2c7f,$1a517128,$7d43e05e,
                                               $1a82a026,$7d3980ec,$1ab3cb0d,$7d2f0e2b,
                                               $1ae4f1d6,$7d24881b,$1b161479,$7d19eebf,
                                               $1b4732ef,$7d0f4218,$1b784d30,$7d048228,
                                               $1ba96335,$7cf9aef0,$1bda74f6,$7ceec873,
                                               $1c0b826a,$7ce3ceb2,$1c3c8b8c,$7cd8c1ae,
                                               $1c6d9053,$7ccda169,$1c9e90b8,$7cc26de5,
                                               $1ccf8cb3,$7cb72724,$1d00843d,$7cabcd28,
                                               $1d31774d,$7ca05ff1,$1d6265dd,$7c94df83,
                                               $1d934fe5,$7c894bde,$1dc4355e,$7c7da505,
                                               $1df5163f,$7c71eaf9,$1e25f282,$7c661dbc,
                                               $1e56ca1e,$7c5a3d50,$1e879d0d,$7c4e49b7,
                                               $1eb86b46,$7c4242f2,$1ee934c3,$7c362904,
                                               $1f19f97b,$7c29fbee,$1f4ab968,$7c1dbbb3,
                                               $1f7b7481,$7c116853,$1fac2abf,$7c0501d2,
                                               $1fdcdc1b,$7bf88830,$200d888d,$7bebfb70,
                                               $203e300d,$7bdf5b94,$206ed295,$7bd2a89e,
                                               $209f701c,$7bc5e290,$20d0089c,$7bb9096b,
                                               $21009c0c,$7bac1d31,$21312a65,$7b9f1de6,
                                               $2161b3a0,$7b920b89,$219237b5,$7b84e61f,
                                               $21c2b69c,$7b77ada8,$21f3304f,$7b6a6227,
                                               $2223a4c5,$7b5d039e,$225413f8,$7b4f920e,
                                               $22847de0,$7b420d7a,$22b4e274,$7b3475e5,
                                               $22e541af,$7b26cb4f,$23159b88,$7b190dbc,
                                               $2345eff8,$7b0b3d2c,$23763ef7,$7afd59a4,
                                               $23a6887f,$7aef6323,$23d6cc87,$7ae159ae,
                                               $24070b08,$7ad33d45,$243743fa,$7ac50dec,
                                               $24677758,$7ab6cba4,$2497a517,$7aa8766f,
                                               $24c7cd33,$7a9a0e50,$24f7efa2,$7a8b9348,
                                               $25280c5e,$7a7d055b,$2558235f,$7a6e648a,
                                               $2588349d,$7a5fb0d8,$25b84012,$7a50ea47,
                                               $25e845b6,$7a4210d8,$26184581,$7a332490,
                                               $26483f6c,$7a24256f,$26783370,$7a151378,
                                               $26a82186,$7a05eead,$26d809a5,$79f6b711,
                                               $2707ebc7,$79e76ca7,$2737c7e3,$79d80f6f,
                                               $27679df4,$79c89f6e,$27976df1,$79b91ca4,
                                               $27c737d3,$79a98715,$27f6fb92,$7999dec4,
                                               $2826b928,$798a23b1,$2856708d,$797a55e0,
                                               $288621b9,$796a7554,$28b5cca5,$795a820e,
                                               $28e5714b,$794a7c12,$29150fa1,$793a6361,
                                               $2944a7a2,$792a37fe,$29743946,$7919f9ec,
                                               $29a3c485,$7909a92d,$29d34958,$78f945c3,
                                               $2a02c7b8,$78e8cfb2,$2a323f9e,$78d846fb,
                                               $2a61b101,$78c7aba2,$2a911bdc,$78b6fda8,
                                               $2ac08026,$78a63d11,$2aefddd8,$789569df,
                                               $2b1f34eb,$78848414,$2b4e8558,$78738bb3,
                                               $2b7dcf17,$786280bf,$2bad1221,$7851633b,
                                               $2bdc4e6f,$78403329,$2c0b83fa,$782ef08b,
                                               $2c3ab2b9,$781d9b65,$2c69daa6,$780c33b8,
                                               $2c98fbba,$77fab989,$2cc815ee,$77e92cd9,
                                               $2cf72939,$77d78daa,$2d263596,$77c5dc01,
                                               $2d553afc,$77b417df,$2d843964,$77a24148,
                                               $2db330c7,$7790583e,$2de2211e,$777e5cc3,
                                               $2e110a62,$776c4edb,$2e3fec8b,$775a2e89,
                                               $2e6ec792,$7747fbce,$2e9d9b70,$7735b6af,
                                               $2ecc681e,$77235f2d,$2efb2d95,$7710f54c,
                                               $2f29ebcc,$76fe790e,$2f58a2be,$76ebea77,
                                               $2f875262,$76d94989,$2fb5fab2,$76c69647,
                                               $2fe49ba7,$76b3d0b4,$30133539,$76a0f8d2,
                                               $3041c761,$768e0ea6,$30705217,$767b1231,
                                               $309ed556,$76680376,$30cd5115,$7654e279,
                                               $30fbc54d,$7641af3d,$312a31f8,$762e69c4,
                                               $3158970e,$761b1211,$3186f487,$7607a828,
                                               $31b54a5e,$75f42c0b,$31e39889,$75e09dbd,
                                               $3211df04,$75ccfd42,$32401dc6,$75b94a9c,
                                               $326e54c7,$75a585cf,$329c8402,$7591aedd,
                                               $32caab6f,$757dc5ca,$32f8cb07,$7569ca99,
                                               $3326e2c3,$7555bd4c,$3354f29b,$75419de7,
                                               $3382fa88,$752d6c6c,$33b0fa84,$751928e0,
                                               $33def287,$7504d345,$340ce28b,$74f06b9e,
                                               $343aca87,$74dbf1ef,$3468aa76,$74c7663a,
                                               $34968250,$74b2c884,$34c4520d,$749e18cd,
                                               $34f219a8,$7489571c,$351fd918,$74748371,
                                               $354d9057,$745f9dd1,$357b3f5d,$744aa63f,
                                               $35a8e625,$74359cbd,$35d684a6,$74208150,
                                               $36041ad9,$740b53fb,$3631a8b8,$73f614c0,
                                               $365f2e3b,$73e0c3a3,$368cab5c,$73cb60a8,
                                               $36ba2014,$73b5ebd1,$36e78c5b,$73a06522,
                                               $3714f02a,$738acc9e,$37424b7b,$73752249,
                                               $376f9e46,$735f6626,$379ce885,$73499838,
                                               $37ca2a30,$7333b883,$37f76341,$731dc70a,
                                               $382493b0,$7307c3d0,$3851bb77,$72f1aed9,
                                               $387eda8e,$72db8828,$38abf0ef,$72c54fc1,
                                               $38d8fe93,$72af05a7,$39060373,$7298a9dd,
                                               $3932ff87,$72823c67,$395ff2c9,$726bbd48,
                                               $398cdd32,$72552c85,$39b9bebc,$723e8a20,
                                               $39e6975e,$7227d61c,$3a136712,$7211107e,
                                               $3a402dd2,$71fa3949,$3a6ceb96,$71e35080,
                                               $3a99a057,$71cc5626,$3ac64c0f,$71b54a41,
                                               $3af2eeb7,$719e2cd2,$3b1f8848,$7186fdde,
                                               $3b4c18ba,$716fbd68,$3b78a007,$71586b74,
                                               $3ba51e29,$71410805,$3bd19318,$7129931f,
                                               $3bfdfecd,$71120cc5,$3c2a6142,$70fa74fc,
                                               $3c56ba70,$70e2cbc6,$3c830a50,$70cb1128,
                                               $3caf50da,$70b34525,$3cdb8e09,$709b67c0,
                                               $3d07c1d6,$708378ff,$3d33ec39,$706b78e3,
                                               $3d600d2c,$70536771,$3d8c24a8,$703b44ad,
                                               $3db832a6,$7023109a,$3de4371f,$700acb3c,
                                               $3e10320d,$6ff27497,$3e3c2369,$6fda0cae,
                                               $3e680b2c,$6fc19385,$3e93e950,$6fa90921,
                                               $3ebfbdcd,$6f906d84,$3eeb889c,$6f77c0b3,
                                               $3f1749b8,$6f5f02b2,$3f430119,$6f463383,
                                               $3f6eaeb8,$6f2d532c,$3f9a5290,$6f1461b0,
                                               $3fc5ec98,$6efb5f12,$3ff17cca,$6ee24b57,
                                               $401d0321,$6ec92683,$40487f94,$6eaff099,
                                               $4073f21d,$6e96a99d,$409f5ab6,$6e7d5193,
                                               $40cab958,$6e63e87f,$40f60dfb,$6e4a6e66,
                                               $4121589b,$6e30e34a,$414c992f,$6e174730,
                                               $4177cfb1,$6dfd9a1c,$41a2fc1a,$6de3dc11,
                                               $41ce1e65,$6dca0d14,$41f93689,$6db02d29,
                                               $42244481,$6d963c54,$424f4845,$6d7c3a98,
                                               $427a41d0,$6d6227fa,$42a5311b,$6d48047e,
                                               $42d0161e,$6d2dd027,$42faf0d4,$6d138afb,
                                               $4325c135,$6cf934fc,$4350873c,$6cdece2f,
                                               $437b42e1,$6cc45698,$43a5f41e,$6ca9ce3b,
                                               $43d09aed,$6c8f351c,$43fb3746,$6c748b3f,
                                               $4425c923,$6c59d0a9,$4450507e,$6c3f055d,
                                               $447acd50,$6c242960,$44a53f93,$6c093cb6,
                                               $44cfa740,$6bee3f62,$44fa0450,$6bd3316a,
                                               $452456bd,$6bb812d1,$454e9e80,$6b9ce39b,
                                               $4578db93,$6b81a3cd,$45a30df0,$6b66536b,
                                               $45cd358f,$6b4af279,$45f7526b,$6b2f80fb,
                                               $4621647d,$6b13fef5,$464b6bbe,$6af86c6c,
                                               $46756828,$6adcc964,$469f59b4,$6ac115e2,
                                               $46c9405c,$6aa551e9,$46f31c1a,$6a897d7d,
                                               $471cece7,$6a6d98a4,$4746b2bc,$6a51a361,
                                               $47706d93,$6a359db9,$479a1d67,$6a1987b0,
                                               $47c3c22f,$69fd614a,$47ed5be6,$69e12a8c,
                                               $4816ea86,$69c4e37a,$48406e08,$69a88c19,
                                               $4869e665,$698c246c,$48935397,$696fac78,
                                               $48bcb599,$69532442,$48e60c62,$69368bce,
                                               $490f57ee,$6919e320,$49389836,$68fd2a3d,
                                               $4961cd33,$68e06129,$498af6df,$68c387e9,
                                               $49b41533,$68a69e81,$49dd282a,$6889a4f6,
                                               $4a062fbd,$686c9b4b,$4a2f2be6,$684f8186,
                                               $4a581c9e,$683257ab,$4a8101de,$68151dbe,
                                               $4aa9dba2,$67f7d3c5,$4ad2a9e2,$67da79c3,
                                               $4afb6c98,$67bd0fbd,$4b2423be,$679f95b7,
                                               $4b4ccf4d,$67820bb7,$4b756f40,$676471c0,
                                               $4b9e0390,$6746c7d8,$4bc68c36,$67290e02,
                                               $4bef092d,$670b4444,$4c177a6e,$66ed6aa1,
                                               $4c3fdff4,$66cf8120,$4c6839b7,$66b187c3,
                                               $4c9087b1,$66937e91,$4cb8c9dd,$6675658c,
                                               $4ce10034,$66573cbb,$4d092ab0,$66390422,
                                               $4d31494b,$661abbc5,$4d595bfe,$65fc63a9,
                                               $4d8162c4,$65ddfbd3,$4da95d96,$65bf8447,
                                               $4dd14c6e,$65a0fd0b,$4df92f46,$65826622,
                                               $4e210617,$6563bf92,$4e48d0dd,$6545095f,
                                               $4e708f8f,$6526438f,$4e984229,$65076e25,
                                               $4ebfe8a5,$64e88926,$4ee782fb,$64c99498,
                                               $4f0f1126,$64aa907f,$4f369320,$648b7ce0,
                                               $4f5e08e3,$646c59bf,$4f857269,$644d2722,
                                               $4faccfab,$642de50d,$4fd420a4,$640e9386,
                                               $4ffb654d,$63ef3290,$50229da1,$63cfc231,
                                               $5049c999,$63b0426d,$5070e92f,$6390b34a,
                                               $5097fc5e,$637114cc,$50bf031f,$635166f9,
                                               $50e5fd6d,$6331a9d4,$510ceb40,$6311dd64,
                                               $5133cc94,$62f201ac,$515aa162,$62d216b3,
                                               $518169a5,$62b21c7b,$51a82555,$6292130c,
                                               $51ced46e,$6271fa69,$51f576ea,$6251d298,
                                               $521c0cc2,$62319b9d,$524295f0,$6211557e,
                                               $5269126e,$61f1003f,$528f8238,$61d09be5,
                                               $52b5e546,$61b02876,$52dc3b92,$618fa5f7,
                                               $53028518,$616f146c,$5328c1d0,$614e73da,
                                               $534ef1b5,$612dc447,$537514c2,$610d05b7,
                                               $539b2af0,$60ec3830,$53c13439,$60cb5bb7,
                                               $53e73097,$60aa7050,$540d2005,$60897601,
                                               $5433027d,$60686ccf,$5458d7f9,$604754bf,
                                               $547ea073,$60262dd6,$54a45be6,$6004f819,
                                               $54ca0a4b,$5fe3b38d,$54efab9c,$5fc26038,
                                               $55153fd4,$5fa0fe1f,$553ac6ee,$5f7f8d46,
                                               $556040e2,$5f5e0db3,$5585adad,$5f3c7f6b,
                                               $55ab0d46,$5f1ae274,$55d05faa,$5ef936d1,
                                               $55f5a4d2,$5ed77c8a,$561adcb9,$5eb5b3a2,
                                               $56400758,$5e93dc1f,$566524aa,$5e71f606,
                                               $568a34a9,$5e50015d,$56af3750,$5e2dfe29,
                                               $56d42c99,$5e0bec6e,$56f9147e,$5de9cc33,
                                               $571deefa,$5dc79d7c,$5742bc06,$5da5604f,
                                               $57677b9d,$5d8314b1,$578c2dba,$5d60baa7,
                                               $57b0d256,$5d3e5237,$57d5696d,$5d1bdb65,
                                               $57f9f2f8,$5cf95638,$581e6ef1,$5cd6c2b5,
                                               $5842dd54,$5cb420e0,$58673e1b,$5c9170bf,
                                               $588b9140,$5c6eb258,$58afd6bd,$5c4be5b0,
                                               $58d40e8c,$5c290acc,$58f838a9,$5c0621b2,
                                               $591c550e,$5be32a67,$594063b5,$5bc024f0,
                                               $59646498,$5b9d1154,$598857b2,$5b79ef96,
                                               $59ac3cfd,$5b56bfbd,$59d01475,$5b3381ce,
                                               $59f3de12,$5b1035cf,$5a1799d1,$5aecdbc5,
                                               $5a3b47ab,$5ac973b5,$5a5ee79a,$5aa5fda5,
                                               $5a82799a,$5a82799a);

     sincos_lookup1:array[0..1023] of longint=($001921fb,$7ffffd88,$004b65ee,$7fffe9cb,
                                               $007da9d4,$7fffc251,$00afeda8,$7fff8719,
                                               $00e23160,$7fff3824,$011474f6,$7ffed572,
                                               $0146b860,$7ffe5f03,$0178fb99,$7ffdd4d7,
                                               $01ab3e97,$7ffd36ee,$01dd8154,$7ffc8549,
                                               $020fc3c6,$7ffbbfe6,$024205e8,$7ffae6c7,
                                               $027447b0,$7ff9f9ec,$02a68917,$7ff8f954,
                                               $02d8ca16,$7ff7e500,$030b0aa4,$7ff6bcf0,
                                               $033d4abb,$7ff58125,$036f8a51,$7ff4319d,
                                               $03a1c960,$7ff2ce5b,$03d407df,$7ff1575d,
                                               $040645c7,$7fefcca4,$04388310,$7fee2e30,
                                               $046abfb3,$7fec7c02,$049cfba7,$7feab61a,
                                               $04cf36e5,$7fe8dc78,$05017165,$7fe6ef1c,
                                               $0533ab20,$7fe4ee06,$0565e40d,$7fe2d938,
                                               $05981c26,$7fe0b0b1,$05ca5361,$7fde7471,
                                               $05fc89b8,$7fdc247a,$062ebf22,$7fd9c0ca,
                                               $0660f398,$7fd74964,$06932713,$7fd4be46,
                                               $06c5598a,$7fd21f72,$06f78af6,$7fcf6ce8,
                                               $0729bb4e,$7fcca6a7,$075bea8c,$7fc9ccb2,
                                               $078e18a7,$7fc6df08,$07c04598,$7fc3dda9,
                                               $07f27157,$7fc0c896,$08249bdd,$7fbd9fd0,
                                               $0856c520,$7fba6357,$0888ed1b,$7fb7132b,
                                               $08bb13c5,$7fb3af4e,$08ed3916,$7fb037bf,
                                               $091f5d06,$7facac7f,$09517f8f,$7fa90d8e,
                                               $0983a0a7,$7fa55aee,$09b5c048,$7fa1949e,
                                               $09e7de6a,$7f9dbaa0,$0a19fb04,$7f99ccf4,
                                               $0a4c1610,$7f95cb9a,$0a7e2f85,$7f91b694,
                                               $0ab0475c,$7f8d8de1,$0ae25d8d,$7f895182,
                                               $0b147211,$7f850179,$0b4684df,$7f809dc5,
                                               $0b7895f0,$7f7c2668,$0baaa53b,$7f779b62,
                                               $0bdcb2bb,$7f72fcb4,$0c0ebe66,$7f6e4a5e,
                                               $0c40c835,$7f698461,$0c72d020,$7f64aabf,
                                               $0ca4d620,$7f5fbd77,$0cd6da2d,$7f5abc8a,
                                               $0d08dc3f,$7f55a7fa,$0d3adc4e,$7f507fc7,
                                               $0d6cda53,$7f4b43f2,$0d9ed646,$7f45f47b,
                                               $0dd0d01f,$7f409164,$0e02c7d7,$7f3b1aad,
                                               $0e34bd66,$7f359057,$0e66b0c3,$7f2ff263,
                                               $0e98a1e9,$7f2a40d2,$0eca90ce,$7f247ba5,
                                               $0efc7d6b,$7f1ea2dc,$0f2e67b8,$7f18b679,
                                               $0f604faf,$7f12b67c,$0f923546,$7f0ca2e7,
                                               $0fc41876,$7f067bba,$0ff5f938,$7f0040f6,
                                               $1027d784,$7ef9f29d,$1059b352,$7ef390ae,
                                               $108b8c9b,$7eed1b2c,$10bd6356,$7ee69217,
                                               $10ef377d,$7edff570,$11210907,$7ed94538,
                                               $1152d7ed,$7ed28171,$1184a427,$7ecbaa1a,
                                               $11b66dad,$7ec4bf36,$11e83478,$7ebdc0c6,
                                               $1219f880,$7eb6aeca,$124bb9be,$7eaf8943,
                                               $127d7829,$7ea85033,$12af33ba,$7ea1039b,
                                               $12e0ec6a,$7e99a37c,$1312a230,$7e922fd6,
                                               $13445505,$7e8aa8ac,$137604e2,$7e830dff,
                                               $13a7b1bf,$7e7b5fce,$13d95b93,$7e739e1d,
                                               $140b0258,$7e6bc8eb,$143ca605,$7e63e03b,
                                               $146e4694,$7e5be40c,$149fe3fc,$7e53d462,
                                               $14d17e36,$7e4bb13c,$1503153a,$7e437a9c,
                                               $1534a901,$7e3b3083,$15663982,$7e32d2f4,
                                               $1597c6b7,$7e2a61ed,$15c95097,$7e21dd73,
                                               $15fad71b,$7e194584,$162c5a3b,$7e109a24,
                                               $165dd9f0,$7e07db52,$168f5632,$7dff0911,
                                               $16c0cef9,$7df62362,$16f2443e,$7ded2a47,
                                               $1723b5f9,$7de41dc0,$17552422,$7ddafdce,
                                               $17868eb3,$7dd1ca75,$17b7f5a3,$7dc883b4,
                                               $17e958ea,$7dbf298d,$181ab881,$7db5bc02,
                                               $184c1461,$7dac3b15,$187d6c82,$7da2a6c6,
                                               $18aec0db,$7d98ff17,$18e01167,$7d8f4409,
                                               $19115e1c,$7d85759f,$1942a6f3,$7d7b93da,
                                               $1973ebe6,$7d719eba,$19a52ceb,$7d679642,
                                               $19d669fc,$7d5d7a74,$1a07a311,$7d534b50,
                                               $1a38d823,$7d4908d9,$1a6a0929,$7d3eb30f,
                                               $1a9b361d,$7d3449f5,$1acc5ef6,$7d29cd8c,
                                               $1afd83ad,$7d1f3dd6,$1b2ea43a,$7d149ad5,
                                               $1b5fc097,$7d09e489,$1b90d8bb,$7cff1af5,
                                               $1bc1ec9e,$7cf43e1a,$1bf2fc3a,$7ce94dfb,
                                               $1c240786,$7cde4a98,$1c550e7c,$7cd333f3,
                                               $1c861113,$7cc80a0f,$1cb70f43,$7cbcccec,
                                               $1ce80906,$7cb17c8d,$1d18fe54,$7ca618f3,
                                               $1d49ef26,$7c9aa221,$1d7adb73,$7c8f1817,
                                               $1dabc334,$7c837ad8,$1ddca662,$7c77ca65,
                                               $1e0d84f5,$7c6c06c0,$1e3e5ee5,$7c602fec,
                                               $1e6f342c,$7c5445e9,$1ea004c1,$7c4848ba,
                                               $1ed0d09d,$7c3c3860,$1f0197b8,$7c3014de,
                                               $1f325a0b,$7c23de35,$1f63178f,$7c179467,
                                               $1f93d03c,$7c0b3777,$1fc4840a,$7bfec765,
                                               $1ff532f2,$7bf24434,$2025dcec,$7be5ade6,
                                               $205681f1,$7bd9047c,$208721f9,$7bcc47fa,
                                               $20b7bcfe,$7bbf7860,$20e852f6,$7bb295b0,
                                               $2118e3dc,$7ba59fee,$21496fa7,$7b989719,
                                               $2179f64f,$7b8b7b36,$21aa77cf,$7b7e4c45,
                                               $21daf41d,$7b710a49,$220b6b32,$7b63b543,
                                               $223bdd08,$7b564d36,$226c4996,$7b48d225,
                                               $229cb0d5,$7b3b4410,$22cd12bd,$7b2da2fa,
                                               $22fd6f48,$7b1feee5,$232dc66d,$7b1227d3,
                                               $235e1826,$7b044dc7,$238e646a,$7af660c2,
                                               $23beab33,$7ae860c7,$23eeec78,$7ada4dd8,
                                               $241f2833,$7acc27f7,$244f5e5c,$7abdef25,
                                               $247f8eec,$7aafa367,$24afb9da,$7aa144bc,
                                               $24dfdf20,$7a92d329,$250ffeb7,$7a844eae,
                                               $25401896,$7a75b74f,$25702cb7,$7a670d0d,
                                               $25a03b11,$7a584feb,$25d0439f,$7a497feb,
                                               $26004657,$7a3a9d0f,$26304333,$7a2ba75a,
                                               $26603a2c,$7a1c9ece,$26902b39,$7a0d836d,
                                               $26c01655,$79fe5539,$26effb76,$79ef1436,
                                               $271fda96,$79dfc064,$274fb3ae,$79d059c8,
                                               $277f86b5,$79c0e062,$27af53a6,$79b15435,
                                               $27df1a77,$79a1b545,$280edb23,$79920392,
                                               $283e95a1,$79823f20,$286e49ea,$797267f2,
                                               $289df7f8,$79627e08,$28cd9fc1,$79528167,
                                               $28fd4140,$79427210,$292cdc6d,$79325006,
                                               $295c7140,$79221b4b,$298bffb2,$7911d3e2,
                                               $29bb87bc,$790179cd,$29eb0957,$78f10d0f,
                                               $2a1a847b,$78e08dab,$2a49f920,$78cffba3,
                                               $2a796740,$78bf56f9,$2aa8ced3,$78ae9fb0,
                                               $2ad82fd2,$789dd5cb,$2b078a36,$788cf94c,
                                               $2b36ddf7,$787c0a36,$2b662b0e,$786b088c,
                                               $2b957173,$7859f44f,$2bc4b120,$7848cd83,
                                               $2bf3ea0d,$7837942b,$2c231c33,$78264849,
                                               $2c52478a,$7814e9df,$2c816c0c,$780378f1,
                                               $2cb089b1,$77f1f581,$2cdfa071,$77e05f91,
                                               $2d0eb046,$77ceb725,$2d3db928,$77bcfc3f,
                                               $2d6cbb10,$77ab2ee2,$2d9bb5f6,$77994f11,
                                               $2dcaa9d5,$77875cce,$2df996a3,$7775581d,
                                               $2e287c5a,$776340ff,$2e575af3,$77511778,
                                               $2e863267,$773edb8b,$2eb502ae,$772c8d3a,
                                               $2ee3cbc1,$771a2c88,$2f128d99,$7707b979,
                                               $2f41482e,$76f5340e,$2f6ffb7a,$76e29c4b,
                                               $2f9ea775,$76cff232,$2fcd4c19,$76bd35c7,
                                               $2ffbe95d,$76aa670d,$302a7f3a,$76978605,
                                               $30590dab,$768492b4,$308794a6,$76718d1c,
                                               $30b61426,$765e7540,$30e48c22,$764b4b23,
                                               $3112fc95,$76380ec8,$31416576,$7624c031,
                                               $316fc6be,$76115f63,$319e2067,$75fdec60,
                                               $31cc7269,$75ea672a,$31fabcbd,$75d6cfc5,
                                               $3228ff5c,$75c32634,$32573a3f,$75af6a7b,
                                               $32856d5e,$759b9c9b,$32b398b3,$7587bc98,
                                               $32e1bc36,$7573ca75,$330fd7e1,$755fc635,
                                               $333debab,$754bafdc,$336bf78f,$7537876c,
                                               $3399fb85,$75234ce8,$33c7f785,$750f0054,
                                               $33f5eb89,$74faa1b3,$3423d78a,$74e63108,
                                               $3451bb81,$74d1ae55,$347f9766,$74bd199f,
                                               $34ad6b32,$74a872e8,$34db36df,$7493ba34,
                                               $3508fa66,$747eef85,$3536b5be,$746a12df,
                                               $356468e2,$74552446,$359213c9,$744023bc,
                                               $35bfb66e,$742b1144,$35ed50c9,$7415ece2,
                                               $361ae2d3,$7400b69a,$36486c86,$73eb6e6e,
                                               $3675edd9,$73d61461,$36a366c6,$73c0a878,
                                               $36d0d746,$73ab2ab4,$36fe3f52,$73959b1b,
                                               $372b9ee3,$737ff9ae,$3758f5f2,$736a4671,
                                               $37864477,$73548168,$37b38a6d,$733eaa96,
                                               $37e0c7cc,$7328c1ff,$380dfc8d,$7312c7a5,
                                               $383b28a9,$72fcbb8c,$38684c19,$72e69db7,
                                               $389566d6,$72d06e2b,$38c278d9,$72ba2cea,
                                               $38ef821c,$72a3d9f7,$391c8297,$728d7557,
                                               $39497a43,$7276ff0d,$39766919,$7260771b,
                                               $39a34f13,$7249dd86,$39d02c2a,$72333251,
                                               $39fd0056,$721c7580,$3a29cb91,$7205a716,
                                               $3a568dd4,$71eec716,$3a834717,$71d7d585,
                                               $3aaff755,$71c0d265,$3adc9e86,$71a9bdba,
                                               $3b093ca3,$71929789,$3b35d1a5,$717b5fd3,
                                               $3b625d86,$7164169d,$3b8ee03e,$714cbbeb,
                                               $3bbb59c7,$71354fc0,$3be7ca1a,$711dd220,
                                               $3c143130,$7106430e,$3c408f03,$70eea28e,
                                               $3c6ce38a,$70d6f0a4,$3c992ec0,$70bf2d53,
                                               $3cc5709e,$70a7589f,$3cf1a91c,$708f728b,
                                               $3d1dd835,$70777b1c,$3d49fde1,$705f7255,
                                               $3d761a19,$70475839,$3da22cd7,$702f2ccd,
                                               $3dce3614,$7016f014,$3dfa35c8,$6ffea212,
                                               $3e262bee,$6fe642ca,$3e52187f,$6fcdd241,
                                               $3e7dfb73,$6fb5507a,$3ea9d4c3,$6f9cbd79,
                                               $3ed5a46b,$6f841942,$3f016a61,$6f6b63d8,
                                               $3f2d26a0,$6f529d40,$3f58d921,$6f39c57d,
                                               $3f8481dd,$6f20dc92,$3fb020ce,$6f07e285,
                                               $3fdbb5ec,$6eeed758,$40074132,$6ed5bb10,
                                               $4032c297,$6ebc8db0,$405e3a16,$6ea34f3d,
                                               $4089a7a8,$6e89ffb9,$40b50b46,$6e709f2a,
                                               $40e064ea,$6e572d93,$410bb48c,$6e3daaf8,
                                               $4136fa27,$6e24175c,$416235b2,$6e0a72c5,
                                               $418d6729,$6df0bd35,$41b88e84,$6dd6f6b1,
                                               $41e3abbc,$6dbd1f3c,$420ebecb,$6da336dc,
                                               $4239c7aa,$6d893d93,$4264c653,$6d6f3365,
                                               $428fbabe,$6d551858,$42baa4e6,$6d3aec6e,
                                               $42e584c3,$6d20afac,$43105a50,$6d066215,
                                               $433b2585,$6cec03af,$4365e65b,$6cd1947c,
                                               $43909ccd,$6cb71482,$43bb48d4,$6c9c83c3,
                                               $43e5ea68,$6c81e245,$44108184,$6c67300b,
                                               $443b0e21,$6c4c6d1a,$44659039,$6c319975,
                                               $449007c4,$6c16b521,$44ba74bd,$6bfbc021,
                                               $44e4d71c,$6be0ba7b,$450f2edb,$6bc5a431,
                                               $45397bf4,$6baa7d49,$4563be60,$6b8f45c7,
                                               $458df619,$6b73fdae,$45b82318,$6b58a503,
                                               $45e24556,$6b3d3bcb,$460c5cce,$6b21c208,
                                               $46366978,$6b0637c1,$46606b4e,$6aea9cf8,
                                               $468a624a,$6acef1b2,$46b44e65,$6ab335f4,
                                               $46de2f99,$6a9769c1,$470805df,$6a7b8d1e,
                                               $4731d131,$6a5fa010,$475b9188,$6a43a29a,
                                               $478546de,$6a2794c1,$47aef12c,$6a0b7689,
                                               $47d8906d,$69ef47f6,$48022499,$69d3090e,
                                               $482badab,$69b6b9d3,$48552b9b,$699a5a4c,
                                               $487e9e64,$697dea7b,$48a805ff,$69616a65,
                                               $48d16265,$6944da10,$48fab391,$6928397e,
                                               $4923f97b,$690b88b5,$494d341e,$68eec7b9,
                                               $49766373,$68d1f68f,$499f8774,$68b5153a,
                                               $49c8a01b,$689823bf,$49f1ad61,$687b2224,
                                               $4a1aaf3f,$685e106c,$4a43a5b0,$6840ee9b,
                                               $4a6c90ad,$6823bcb7,$4a957030,$68067ac3,
                                               $4abe4433,$67e928c5,$4ae70caf,$67cbc6c0,
                                               $4b0fc99d,$67ae54ba,$4b387af9,$6790d2b6,
                                               $4b6120bb,$677340ba,$4b89badd,$67559eca,
                                               $4bb24958,$6737ecea,$4bdacc28,$671a2b20,
                                               $4c034345,$66fc596f,$4c2baea9,$66de77dc,
                                               $4c540e4e,$66c0866d,$4c7c622d,$66a28524,
                                               $4ca4aa41,$66847408,$4ccce684,$6666531d,
                                               $4cf516ee,$66482267,$4d1d3b7a,$6629e1ec,
                                               $4d455422,$660b91af,$4d6d60df,$65ed31b5,
                                               $4d9561ac,$65cec204,$4dbd5682,$65b0429f,
                                               $4de53f5a,$6591b38c,$4e0d1c30,$657314cf,
                                               $4e34ecfc,$6554666d,$4e5cb1b9,$6535a86b,
                                               $4e846a60,$6516dacd,$4eac16eb,$64f7fd98,
                                               $4ed3b755,$64d910d1,$4efb4b96,$64ba147d,
                                               $4f22d3aa,$649b08a0,$4f4a4f89,$647bed3f,
                                               $4f71bf2e,$645cc260,$4f992293,$643d8806,
                                               $4fc079b1,$641e3e38,$4fe7c483,$63fee4f8,
                                               $500f0302,$63df7c4d,$50363529,$63c0043b,
                                               $505d5af1,$63a07cc7,$50847454,$6380e5f6,
                                               $50ab814d,$63613fcd,$50d281d5,$63418a50,
                                               $50f975e6,$6321c585,$51205d7b,$6301f171,
                                               $5147388c,$62e20e17,$516e0715,$62c21b7e,
                                               $5194c910,$62a219aa,$51bb7e75,$628208a1,
                                               $51e22740,$6261e866,$5208c36a,$6241b8ff,
                                               $522f52ee,$62217a72,$5255d5c5,$62012cc2,
                                               $527c4bea,$61e0cff5,$52a2b556,$61c06410,
                                               $52c91204,$619fe918,$52ef61ee,$617f5f12,
                                               $5315a50e,$615ec603,$533bdb5d,$613e1df0,
                                               $536204d7,$611d66de,$53882175,$60fca0d2,
                                               $53ae3131,$60dbcbd1,$53d43406,$60bae7e1,
                                               $53fa29ed,$6099f505,$542012e1,$6078f344,
                                               $5445eedb,$6057e2a2,$546bbdd7,$6036c325,
                                               $54917fce,$601594d1,$54b734ba,$5ff457ad,
                                               $54dcdc96,$5fd30bbc,$5502775c,$5fb1b104,
                                               $55280505,$5f90478a,$554d858d,$5f6ecf53,
                                               $5572f8ed,$5f4d4865,$55985f20,$5f2bb2c5,
                                               $55bdb81f,$5f0a0e77,$55e303e6,$5ee85b82,
                                               $5608426e,$5ec699e9,$562d73b2,$5ea4c9b3,
                                               $565297ab,$5e82eae5,$5677ae54,$5e60fd84,
                                               $569cb7a8,$5e3f0194,$56c1b3a1,$5e1cf71c,
                                               $56e6a239,$5dfade20,$570b8369,$5dd8b6a7,
                                               $5730572e,$5db680b4,$57551d80,$5d943c4e,
                                               $5779d65b,$5d71e979,$579e81b8,$5d4f883b,
                                               $57c31f92,$5d2d189a,$57e7afe4,$5d0a9a9a,
                                               $580c32a7,$5ce80e41,$5830a7d6,$5cc57394,
                                               $58550f6c,$5ca2ca99,$58796962,$5c801354,
                                               $589db5b3,$5c5d4dcc,$58c1f45b,$5c3a7a05,
                                               $58e62552,$5c179806,$590a4893,$5bf4a7d2,
                                               $592e5e19,$5bd1a971,$595265df,$5bae9ce7,
                                               $59765fde,$5b8b8239,$599a4c12,$5b68596d,
                                               $59be2a74,$5b452288,$59e1faff,$5b21dd90,
                                               $5a05bdae,$5afe8a8b,$5a29727b,$5adb297d,
                                               $5a4d1960,$5ab7ba6c,$5a70b258,$5a943d5e);
      VQ_FEXP=10;
      VQ_FMAN=21;
      VQ_FEXP_BIAS=768;  

type LOOKUP_T=longint;

{$ifdef fpc}
 {$undef OldDelphi}
     BeRoAudioOGGPtrUInt=PtrUInt;
     BeRoAudioOGGPtrInt=PtrInt;
{$else}
 {$ifdef conditionalexpressions}
  {$if CompilerVersion>=15.0}
     qword=uint64;        
   {$define QWordAlreadyRemapped}
  {$ifend}
  {$if CompilerVersion>=23.0}
   {$undef OldDelphi}
   BeRoAudioOGGPtrUInt=NativeUInt;
   BeRoAudioOGGPtrInt=NativeInt;
  {$else}
   {$define OldDelphi}
  {$ifend}
 {$else}
  {$define OldDelphi}
 {$endif}
{$endif}
{$ifdef OldDelphi}
{$ifndef QWordAlreadyRemapped}
     qword=int64;
{$endif}
{$ifdef cpu64}
     BeRoAudioOGGPtrUInt=qword;
     BeRoAudioOGGPtrInt=int64;
{$else}
     BeRoAudioOGGPtrUInt=longword;
     BeRoAudioOGGPtrInt=longint;
{$endif}
{$endif}

     PTwoPointers=^TTwoPointers;
     TTwoPointers=array[0..1] of pointer;

     PInt64Casted=^TInt64Casted;
     TInt64Casted=packed record
      case boolean of
       false:({$ifdef little_endian}Lo,Hi{$else}Hi,Lo{$endif}:longint;);
       true:(Value:int64;);
     end;

     ogg_int8_t=shortint;
     ogg_uint8_t=byte;

     ogg_int16_t=smallint;
     ogg_uint16_t=word;

     ogg_int32_t=longint;
     ogg_uint32_t=longword;

     ogg_int64_t=int64;
     ogg_uint64_t={$ifdef fpc}qword{$else}int64{$endif};

     PPLongint=^PLongint;
     PLongint=^Longint;

     PPLongword=^PLongword;
     PLongword=^Longword;

     PPPLongints=^TPPLongints;
     PPLongints=^TPLongints;
     PLongints=^TLongints;
     TPPLongints=array[0..$ffff] of PPLongints;
     TPLongints=array[0..$ffff] of PLongints;
     TLongints=array[0..$ffff] of longint;

     PSmallInts=^TSmallInts;
     TSmallInts=array[0..$ffff] of smallint;

     PPPointers=^TPPointers;
     PPointers=^TPointers;
     TPPointers=array[0..$ffff] of PPointers;
     TPointers=array[0..$ffff] of Pointer;

     PPLongwords=^TPLongwords;
     PLongwords=^TLongwords;
     TPLongwords=array[0..$ffff] of PLongwords;
     TLongwords=array[0..$ffff] of longword;

     PInt64=^int64;

     PInt64s=^TInt64s;
     TInt64s=array[0..$ffff] of int64;

     PPPogg_int32_t=^PPogg_int32_t;
     PPogg_int32_t=^Pogg_int32_t;
     Pogg_int32_t=^ogg_int32_t;

     PPogg_uint32_t=^Pogg_uint32_t;
     Pogg_uint32_t=^ogg_uint32_t;

     Pogg_buffer=^ogg_buffer;
     Pogg_reference=^ogg_reference;
     PPogg_reference=^Pogg_reference;
     Pogg_buffer_state=^ogg_buffer_state;

     ogg_buffer_state=record
      unused_buffers:Pogg_buffer;
      unused_references:Pogg_reference;
      outstanding:longint;
      shutdown:longint;
     end;

     ogg_buffer=record
      data:PAnsiChar;
      Size:longint;
      RefCount:longint;
      ptr:packed record
       case boolean of
        false:(owner:Pogg_buffer_state);
        true:(next:Pogg_buffer);
      end;
     end;

     ogg_reference=record
      buffer:Pogg_buffer;
      begin_:longint;
      length:longint;
      next:Pogg_reference;
     end;

     Poggpack_buffer=^oggpack_buffer;
     oggpack_buffer=record
      headbit:longint;
      headptr:PAnsiChar;
      headend:longint;
      head:Pogg_reference;
      tail:Pogg_reference;
      count:longint;
     end;

     Poggbyte_buffer=^oggbyte_buffer;
     oggbyte_buffer=record
      baseref:Pogg_reference;
      ref:Pogg_reference;
      ptr:PAnsiChar;
      pos:longint;
      end_:longint;
     end;

     Pogg_sync_state=^ogg_sync_state;
     ogg_sync_state=record
      bufferpool:Pogg_buffer_state;
      fifo_head:Pogg_reference;
      fifo_tail:Pogg_reference;
      fifo_fill:longint;
      unsynced:longint;
      headerbytes:longint;
      bodybytes:longint;
     end;

     Pogg_stream_state=^ogg_stream_state;
     ogg_stream_state=record
      header_head:Pogg_reference;
      header_tail:Pogg_reference;
      body_head:Pogg_reference;
      body_tail:Pogg_reference;
      e_o_s:longint;
      b_o_s:longint;
      serialno:longint;
      pageno:longint;
      packetno:ogg_int64_t;
      granulepos:ogg_int64_t;
      lacing_fill:longint;
      body_fill:ogg_uint32_t;
      holeflag:longint;
      spanflag:longint;
      clearflag:longint;
      laceptr:longint;
      body_fill_next:ogg_uint32_t;
     end;

     Pogg_packet=^ogg_packet;
     ogg_packet=record
      packet:Pogg_reference;
      bytes:longint;
      b_o_s:longint;
      e_o_s:longint;
      granulepos:ogg_int64_t;
      packetno:ogg_int64_t;
     end;

     Pogg_page=^ogg_page;
     ogg_page=record
      header:Pogg_reference;
      header_len:longint;
      body:Pogg_reference;
      body_len:longint;
     end;

     Pvorbis_info=^vorbis_info;
     vorbis_info=record
      version:longint;
      channels:longint;
      rate:longint;
      bitrate_upper:longint;
      bitrate_nominal:longint;
      bitrate_lower:longint;
      bitrate_window:longint;
      codec_setup:pointer;
     end;

     Pvorbis_dsp_state=^vorbis_dsp_state;
     vorbis_dsp_state=record
      analysisp:longint;
      vi:Pvorbis_info;
      pcm:PPLongints;
      pcmret:PPLongints;
      pcm_storage:longint;
      pcm_current:longint;
      pcm_returned:longint;
      preextraiplate:longint;
      eofflag:longint;
      lW:longint;
      W:longint;
      nW:longint;
      centerW:longint;
      granulepos:ogg_int64_t;
      sequence:ogg_int64_t;
      backend_state:pointer;
     end;

     Palloc_chain=^alloc_chain;

     Pvorbis_block=^vorbis_block;
     vorbis_block=record
      pcm:PPLongints;
      opb:oggpack_buffer;
      lW:longint;
      W:longint;
      nW:longint;
      pcmend:longint;
      mode:longint;
      eofflag:longint;
      granulepos:ogg_int64_t;
      sequence:ogg_int64_t;
      vd:Pvorbis_dsp_state;
      localstore:pointer;
      localtop:longint;
      localalloc:longint;
      totaluse:longint;
      reap:Palloc_chain;
     end;

     alloc_chain=record
      ptr:pointer;
      next:Palloc_chain;
     end;

     PPAnsiChar=^PAnsiChar;

     Pvorbis_comment=^vorbis_comment;
     vorbis_comment=record
      user_comments:PPAnsiChar;
      comment_lengths:PLongints;
      comments:longint;
      vendor:PAnsiChar;
     end;

     Pstatic_codebook=^static_codebook;
     static_codebook=record
      dim:longint;
      entries:longint;
      lengthlist:PLongints;
      maptype:longint;
      q_min:longint;
      q_delta:longint;
      q_quant:longint;
      q_sequencep:longint;
      quantlist:PLongints;
     end;

     Pcodebook=^codebook;
     codebook=record
      dim:longint;
      entries:longint;
      used_entries:longint;
      binarypoint:longint;
      valuelist:PLongints;
      codelist:PLongwords;
      dec_index:PLongints;
      dec_codelengths:PAnsiChar;
      dec_firsttable:PLongwords;
      dec_firsttablen:longint;
      dec_maxlength:longint;
      q_min:longint;
      q_delta:longint;
     end;

     Pcodebooks=^codebooks;
     PPcodebooks=^TPcodebooks;
     PPPcodebooks=^TPPcodebooks;
     TPPcodebooks=array[0..$ffff] of ppcodebooks;
     TPcodebooks=array[0..$ffff] of pcodebooks;
     codebooks=array[0..$ffff] of codebook;

     PPvorbis_look_mapping=^Pvorbis_look_mapping;
     Pvorbis_look_mapping=^vorbis_look_mapping;
     vorbis_look_mapping=pointer;

     PPvorbis_look_floor=^Pvorbis_look_floor;
     Pvorbis_look_floor=^vorbis_look_floor;
     vorbis_look_floor=pointer;

     PPvorbis_look_residue=^Pvorbis_look_residue;
     Pvorbis_look_residue=^vorbis_look_residue;
     vorbis_look_residue=pointer;

     Pvorbis_look_transform=^vorbis_look_transform;
     vorbis_look_transform=pointer;

     Pvorbis_info_mode=^vorbis_info_mode;
     vorbis_info_mode=record
      blockflag:longint;
      windowtype:longint;
      transformtype:longint;
      mapping:longint;
     end;

     PPvorbis_info_mapping=^Pvorbis_info_mapping;
     Pvorbis_info_mapping=^vorbis_info_mapping;
     vorbis_info_mapping=pointer;

     Pvorbis_info_floor=^vorbis_info_floor;
     vorbis_info_floor=pointer;

     Pvorbis_info_residue=^vorbis_info_residue;
     vorbis_info_residue=pointer;

     Pvorbis_info_transform=^vorbis_info_transform;
     vorbis_info_transform=pointer;

     Pprivate_state=^private_state;
     private_state=record
      window:TTwoPointers;
      modebits:longint;
      mode:PPvorbis_look_mapping;
      sample_count:ogg_int64_t;
     end;

     Pcodec_setup_info=^codec_setup_info;
     codec_setup_info=record
      blocksizes:array[0..1] of longint;
      modes:longint;
      maps:longint;
      times:longint;
      floors:longint;
      residues:longint;
      books:longint;
      mode_param:array[0..63] of Pvorbis_info_mode;
      map_type:array[0..63] of longint;
      map_param:array[0..63] of Pvorbis_info_mapping;
      time_type:array[0..63] of longint;
      floor_type:array[0..63] of longint;
      floor_param:array[0..63] of Pvorbis_info_floor;
      residue_type:array[0..63] of longint;
      residue_param:array[0..63] of Pvorbis_info_residue;
      book_param:array[0..255] of Pstatic_codebook;
      fullbooks:Pcodebook;
      passlimit:array[0..31] of longint;
      coupling_passes:longint;
     end;

     PPvorbis_func_floor=^Pvorbis_func_floor;
     Pvorbis_func_floor=^vorbis_func_floor;
     vorbis_func_floor=record
      unpack:function(vi:Pvorbis_info;opb:Poggpack_buffer):Pvorbis_info_floor;
      look:function(vd:Pvorbis_dsp_state;mi:Pvorbis_info_mode;i:Pvorbis_info_floor):Pvorbis_look_floor;
      free_info:procedure(i:Pvorbis_info_floor);
      free_look:procedure(i:Pvorbis_look_floor);
      inverse1:function(vb:Pvorbis_block;i:Pvorbis_look_floor):pointer;
      inverse2:function(vb:Pvorbis_block;i:Pvorbis_look_floor;memo:pointer;out_:PLongints):longint;
     end;

     Pvorbis_info_floor0=^vorbis_info_floor0;
     vorbis_info_floor0=record
      order:longint;
      rate:longint;
      barkmap:longint;
      ampbits:longint;
      ampdB:longint;
      numbooks:longint;
      books:array[0..15] of longint;
     end;

     Pvorbis_info_floor1=^vorbis_info_floor1;
     vorbis_info_floor1=record
      partitions:longint;
      partitionclass:array[0..VIF_PARTS-1] of longint;
      class_dim:array[0..VIF_CLASS-1] of longint;
      class_subs:array[0..VIF_CLASS-1] of longint;
      class_book:array[0..VIF_CLASS-1] of longint;
      class_subbook:array[0..VIF_CLASS-1,0..7] of longint;
      mult:longint;
      postlist:array[0..VIF_POSIT+1] of longint;
     end;

     PPvorbis_func_residue=^Pvorbis_func_residue;
     Pvorbis_func_residue=^vorbis_func_residue;
     vorbis_func_residue=record
      unpack:function(a:Pvorbis_info;b:Poggpack_buffer):Pvorbis_info_residue;
      look:function(a:Pvorbis_dsp_state;b:Pvorbis_info_mode;c:Pvorbis_info_residue):Pvorbis_look_residue;
      free_info:procedure(i:Pvorbis_info_residue);
      free_look:procedure(i:Pvorbis_look_residue);
      inverse:function(a:Pvorbis_block;b:Pvorbis_look_residue;c:PPLongints;d:PLongints;e:longint):longint;
     end;

     Pvorbis_info_residue0=^vorbis_info_residue0;
     vorbis_info_residue0=record
      begin_:longint;
      end_:longint;
      grouping:longint;
      partitions:longint;
      groupbook:longint;
      secondstages:array[0..63] of longint;
      booklist:array[0..255] of longint;
     end;

     Pvorbis_func_mapping=^vorbis_func_mapping;
     vorbis_func_mapping=record
      unpack:function(a:Pvorbis_info;b:Poggpack_buffer):Pvorbis_info_mapping;
      look:function(a:Pvorbis_dsp_state;b:Pvorbis_info_mode;c:Pvorbis_info_mapping):Pvorbis_look_mapping;
      free_info:procedure(i:Pvorbis_info_mapping);
      free_look:procedure(i:Pvorbis_look_mapping);
      inverse:function(a:Pvorbis_block;b:Pvorbis_look_mapping):longint;
     end;

     Pvorbis_info_mapping0=^vorbis_info_mapping0;
     vorbis_info_mapping0=record
      submaps:longint;
      chmuxlist:array[0..255] of longint;
      floorsubmap:array[0..15] of longint;
      residuesubmap:array[0..15] of longint;
      psy:array[0..1] of longint;
      coupling_steps:longint;
      coupling_mag:array[0..255] of longint;
      coupling_ang:array[0..255] of longint;
     end;

     Pvorbis_look_floor0=^vorbis_look_floor0;
     vorbis_look_floor0=record
      n:longint;
      ln:longint;
      m:longint;
      linearmap:PLongints;
      vi:Pvorbis_info_floor0;
      lsp_look:PLongints;
     end;

     Pvorbis_look_floor1=^vorbis_look_floor1;
     vorbis_look_floor1=record
      forward_index:array[0..VIF_POSIT+1] of longint;
      hineighbor:array[0..VIF_POSIT-1] of longint;
      loneighbor:array[0..VIF_POSIT-1] of longint;
      posts:longint;
      n:longint;
      quant_q:longint;
      vi:Pvorbis_info_floor1;
     end;

     Pvorbis_look_mapping0=^vorbis_look_mapping0;
     vorbis_look_mapping0=record
      mode:Pvorbis_info_mode;
      map:Pvorbis_info_mapping0;
      floor_look:PPvorbis_look_floor;
      residue_look:PPvorbis_look_residue;
      floor_func:PPvorbis_func_floor;
      residue_func:PPvorbis_func_residue;
      ch:longint;
      lastframe:longint;
      pcmbundle:PPLongints;
      zerobundle:PLongints;
      nonzero:PLongints;
      floormemo:PPPointers;
      channels:longint;
     end;

     Pvorbis_look_residue0=^vorbis_look_residue0;
     vorbis_look_residue0=record
      info:Pvorbis_info_residue0;
      map:longint;
      parts:longint;
      stages:longint;
      fullbooks:Pcodebooks;
      phrasebook:Pcodebook;
      partbooks:PPPcodebooks;
      partvals:longint;
      decodemap:PPLongints;
      partword:pointer;
      partwords:longint;
     end;

     Pov_callbacks=^ov_callbacks;
     ov_callbacks=record
      read_func:function(ptr:pointer;size,nmemb:BeRoAudioOGGPtrUInt;datasource:pointer):BeRoAudioOGGPtrUInt;
      seek_func:function(datasource:pointer;offset:int64;whence:longint):longint;
      close_func:function(datasource:pointer):longint;
      tell_func:function(datasource:pointer):longint;
     end;

     Pvorbis_infos=^Tvorbis_infos;
     Tvorbis_infos=array[0..0] of vorbis_info;

     Pvorbis_comments=^Tvorbis_comments;
     Tvorbis_comments=array[0..0] of vorbis_comment;

     POggVorbis_File=^OggVorbis_File;
     OggVorbis_File=record
      datasource:pointer;
      seekable:longint;
      offset:int64;
      end_:int64;
      oy:Pogg_sync_state;
      links:longint;
      offsets:PInt64s;
      dataoffsets:PInt64s;
      serialnos:PLongwords;
      pcmlengths:PInt64s;
      vi:Pvorbis_infos;
      vc:Pvorbis_comments;
      pcm_offset:ogg_int64_t;
      ready_state:longint;
      current_serialno:ogg_uint32_t;
      current_link:longint;
      bittrack:ogg_int64_t;
      samptrack:ogg_int64_t;
      os:Pogg_stream_state;
      vd:vorbis_dsp_state;
      vb:vorbis_block;
      callbacks:ov_callbacks;
     end;

procedure oggpack_readinit(b:Poggpack_buffer;r:Pogg_reference);
function oggpack_look(b:Poggpack_buffer;bits:longint):longint;
procedure oggpack_adv(b:Poggpack_buffer;bits:longint);
function oggpack_eop(b:Poggpack_buffer):longint;
function oggpack_read(b:Poggpack_buffer;bits:longint):longint;
function oggpack_bytes(b:Poggpack_buffer):longint;
function oggpack_bits(b:Poggpack_buffer):longint;

function _vorbis_window(type_,left:longint):pointer;
procedure _vorbis_apply_window(d:PLongints;window_p:PTwoPointers;blocksizes:PLongints;lW,W,nw:longint);

function ilog(v:longword):longint; {$ifdef caninline}inline;{$endif}

function vorbis_block_init(v:Pvorbis_dsp_state;vb:Pvorbis_block):longint;
function vorbis_block_clear(vb:Pvorbis_block):longint;

function vorbis_synthesis_restart(v:Pvorbis_dsp_state):longint;
function vorbis_synthesis_init(v:Pvorbis_dsp_state;vi:Pvorbis_info):longint;
function vorbis_synthesis_blockin(v:Pvorbis_dsp_state;vb:Pvorbis_block):longint;
function vorbis_synthesis_pcmout(v:Pvorbis_dsp_state;pcm:PPPLongints):longint;
function vorbis_synthesis_read(v:Pvorbis_dsp_state;bytes:longint):longint;

function _book_maptype1_quantvals(b:Pstatic_codebook):longint;

function vorbis_staticbook_unpack(opb:Poggpack_buffer):Pstatic_codebook;

function vorbis_book_decode(book:Pcodebook;b:Poggpack_buffer):longint;

type TDecodeFunc=function(book:Pcodebook;a:PLongints;b:Poggpack_buffer;n,point:longint):longint;

function vorbis_book_decodevs_add(book:Pcodebook;a:PLongints;b:Poggpack_buffer;n,point:longint):longint;
function vorbis_book_decodev_add(book:Pcodebook;a:PLongints;b:Poggpack_buffer;n,point:longint):longint;
function vorbis_book_decodev_set(book:Pcodebook;a:PLongints;b:Poggpack_buffer;n,point:longint):longint;
function vorbis_book_decodevv_add(book:Pcodebook;a:PPLongints;offset,ch:longint;b:Poggpack_buffer;n,point:longint):longint;

function vorbis_invsqlook_i(a,e:longint):longint;
function vorbis_fromdBlook_i(a:longint):longint;
function vorbis_coslook_i(a:longint):longint;
function vorbis_coslook2_i(a:longint):longint;

function toBARK(n:longint):longint;

procedure vorbis_lsp_to_curve(curve:PLongints;map:PLongints;n,ln:longint;lsp:PLongints;m:longint;amp,ampoffset:longint;icos:PLongints);

function bitreverse(x:ogg_uint32_t):ogg_uint32_t;

procedure floor0_free_info(i:Pvorbis_info_floor);
procedure floor0_free_look(i:Pvorbis_look_floor);
function floor0_unpack(vi:Pvorbis_info;opb:Poggpack_buffer):Pvorbis_info_floor;
function floor0_look(vd:Pvorbis_dsp_state;mi:Pvorbis_info_mode;i:Pvorbis_info_floor):Pvorbis_look_floor;
function floor0_inverse1(vb:Pvorbis_block;i:Pvorbis_look_floor):pointer;
function floor0_inverse2(vb:Pvorbis_block;i:Pvorbis_look_floor;memo:pointer;out_:PLongints):longint;

procedure floor1_free_info(i:Pvorbis_info_floor);
procedure floor1_free_look(i:Pvorbis_look_floor);
function floor1_unpack(vi:Pvorbis_info;opb:Poggpack_buffer):Pvorbis_info_floor;
function floor1_look(vd:Pvorbis_dsp_state;mi:Pvorbis_info_mode;i_:Pvorbis_info_floor):Pvorbis_look_floor;
function floor1_inverse1(vb:Pvorbis_block;i_:Pvorbis_look_floor):pointer;
function floor1_inverse2(vb:Pvorbis_block;i_:Pvorbis_look_floor;memo:pointer;out_:PLongints):longint;

function ogg_buffer_create:Pogg_buffer_state;
procedure ogg_buffer_destroy(bs:Pogg_buffer_state);
function ogg_buffer_alloc(bs:Pogg_buffer_state;bytes:longint):Pogg_reference;
procedure ogg_buffer_realloc(r:Pogg_reference;bytes:longint);
procedure ogg_buffer_mark(r:Pogg_reference);
function ogg_buffer_sub(r:Pogg_reference;begin_,length:longint):Pogg_reference;
function ogg_buffer_dup(r:Pogg_reference):Pogg_reference;
function ogg_buffer_split(tail,head:PPogg_reference;pos:longint):Pogg_reference;
procedure ogg_buffer_release_one(r:Pogg_reference);
procedure ogg_buffer_release(r:Pogg_reference);
function ogg_buffer_pretruncate(r:Pogg_reference;pos:longint):Pogg_reference;
function ogg_buffer_walk(r:Pogg_reference):Pogg_reference;
function ogg_buffer_cat(tail,head:Pogg_reference):Pogg_reference;

function oggbyte_init(b:Poggbyte_buffer;r:Pogg_reference):longint;
procedure oggbyte_set4(b:Poggbyte_buffer;val:ogg_uint32_t;pos:longint);
function oggbyte_read1(b:Poggbyte_buffer;pos:longint):byte;
function oggbyte_read4(b:Poggbyte_buffer;pos:longint):ogg_uint32_t;
function oggbyte_read8(b:Poggbyte_buffer;pos:longint):ogg_int64_t;

function ogg_page_version(og:Pogg_page):longint;
function ogg_page_continued(og:Pogg_page):longint;
function ogg_page_bos(og:Pogg_page):longint;
function ogg_page_eos(og:Pogg_page):longint;
function ogg_page_granulepos(og:Pogg_page):ogg_int64_t;
function ogg_page_serialno(og:Pogg_page):ogg_uint32_t;
function ogg_page_pageno(og:Pogg_page):ogg_uint32_t;
function ogg_page_packets(og:Pogg_page):longint;

function ogg_sync_create:Pogg_sync_state;
function ogg_sync_destroy(oy:Pogg_sync_state):longint;
function ogg_sync_bufferin(oy:Pogg_sync_state;bytes:longint):pointer;
function ogg_sync_wrote(oy:Pogg_sync_state;bytes:longint):longint;
function ogg_sync_pageseek(oy:Pogg_sync_state;og:Pogg_page):longint;
function ogg_sync_pageout(oy:Pogg_sync_state;og:Pogg_page):longint;
function ogg_sync_reset(oy:Pogg_sync_state):longint;

function ogg_stream_create(serialno:longint):Pogg_stream_state;
function ogg_stream_destroy(os:Pogg_stream_state):longint;
function ogg_stream_pagein(os:Pogg_stream_state;og:Pogg_page):longint;
function ogg_stream_reset(os:Pogg_stream_state):longint;
function ogg_stream_reset_serialno(os:Pogg_stream_state;serialno:longint):longint;

function ogg_stream_packetout(os:Pogg_stream_state;op:Pogg_packet):longint;
function ogg_stream_packetpeek(os:Pogg_stream_state;op:Pogg_packet):longint;

function ogg_packet_release(op:Pogg_packet):longint;

function ogg_page_release(og:Pogg_page):longint;
procedure ogg_page_dup(dup,orig:Pogg_page);

procedure vorbis_comment_init(vc:Pvorbis_comment);
function vorbis_comment_query(vc:Pvorbis_comment;tag:PAnsiChar;count:longint):PAnsiChar;
function vorbis_comment_query_count(vc:Pvorbis_comment;tag:PAnsiChar):longint;
procedure vorbis_comment_clear(vc:Pvorbis_comment);
function vorbis_info_blocksize(vi:Pvorbis_info;zo:longint):longint;
procedure vorbis_info_init(vi:Pvorbis_info);
procedure vorbis_info_clear(vi:Pvorbis_info);

function vorbis_synthesis_idheader(op:Pogg_packet):longint;
function vorbis_synthesis_headerin(vi:Pvorbis_info;vc:Pvorbis_comment;op:Pogg_packet):longint;

procedure mapping0_free_info(i:Pvorbis_info_mapping);
procedure mapping0_free_look(l:Pvorbis_look_mapping);
function mapping0_look(vd:Pvorbis_dsp_state;vm:Pvorbis_info_mode;m:Pvorbis_info_mapping):Pvorbis_look_mapping;
function mapping0_unpack(vi:Pvorbis_info;opb:Poggpack_buffer):Pvorbis_info_mapping;
function mapping0_inverse(vb:Pvorbis_block;l:Pvorbis_look_mapping):longint;

procedure mdct_forward(n:longint;in_,out_:PLongints);
procedure mdct_backward(n:longint;in_,out_:PLongints);

procedure res0_free_info(i:Pvorbis_info_residue);
procedure res0_free_look(i:Pvorbis_look_residue);
function res0_unpack(vi:Pvorbis_info;opb:Poggpack_buffer):Pvorbis_info_residue;
function res0_look(vd:Pvorbis_dsp_state;vm:Pvorbis_info_mode;vr:Pvorbis_info_residue):Pvorbis_look_residue;
function res0_inverse(vb:Pvorbis_block;vi:Pvorbis_look_residue;in_:PPLongInts;nonzero:PLongints;ch:longint):longint;
function res1_inverse(vb:Pvorbis_block;vi:Pvorbis_look_residue;in_:PPLongInts;nonzero:PLongints;ch:longint):longint;
function res2_inverse(vb:Pvorbis_block;vi:Pvorbis_look_residue;in_:PPLongInts;nonzero:PLongints;ch:longint):longint;

procedure vorbis_dsp_clear(v:Pvorbis_dsp_state);

procedure vorbis_book_clear(b:Pcodebook);

procedure vorbis_staticbook_clear(b:Pstatic_codebook);
procedure vorbis_staticbook_destroy(b:Pstatic_codebook);
function vorbis_book_init_decode(dest:Pcodebook;source:Pstatic_codebook):longint;

function vorbis_synthesis(vb:Pvorbis_block;op:Pogg_packet;decodep:longint):longint;

function vorbis_packet_blocksize(vi:Pvorbis_info;op:Pogg_packet):longint;

function ov_clear(vf:POggVorbis_File):longint;
function ov_open_callbacks(f:pointer;vf:POggVorbis_File;initial:PAnsiChar;ibytes:longint;callbacks:ov_callbacks):longint;
function ov_open(f:pointer;vf:POggVorbis_File;initial:PAnsiChar;ibytes:longint):longint;
function ov_test_callbacks(f:pointer;vf:POggVorbis_File;initial:PAnsiChar;ibytes:longint;callbacks:ov_callbacks):longint;
function ov_test(f:pointer;vf:POggVorbis_File;initial:PAnsiChar;ibytes:longint):longint;
function ov_test_open(vf:POggVorbis_File):longint;
function ov_streams(vf:POggVorbis_File):longint;
function ov_seekable(vf:POggVorbis_File):longint;
function ov_bitrate(vf:POggVorbis_File;i:longint):longint;
function ov_bitrate_instant(vf:POggVorbis_File):longint;
function ov_serialnumber(vf:POggVorbis_File;i:longint):longint;
function ov_raw_total(vf:POggVorbis_File;i:longint):ogg_int64_t;
function ov_pcm_total(vf:POggVorbis_File;i:longint):ogg_int64_t;
function ov_time_total(vf:POggVorbis_File;i:longint):ogg_int64_t;
function ov_raw_seek(vf:POggVorbis_File;pos:ogg_int64_t):longint;
function ov_pcm_seek_page(vf:POggVorbis_File;pos:ogg_int64_t):longint;
function ov_pcm_seek(vf:POggVorbis_File;pos:ogg_int64_t):longint;
function ov_time_seek(vf:POggVorbis_File;milliseconds:ogg_int64_t):longint;
function ov_time_seek_page(vf:POggVorbis_File;milliseconds:ogg_int64_t):longint;
function ov_raw_tell(vf:POggVorbis_File):ogg_int64_t;
function ov_pcm_tell(vf:POggVorbis_File):ogg_int64_t;
function ov_time_tell(vf:POggVorbis_File):ogg_int64_t;
function ov_info(vf:POggVorbis_File;link:longint):Pvorbis_info;
function ov_comment(vf:POggVorbis_File;link:longint):Pvorbis_comment;
function ov_read(vf:POggVorbis_File;buffer:pointer;bytes_req:longint;bitstream:PLongint):longint;

const floor0_exportbundle:vorbis_func_floor=(
       unpack:floor0_unpack;
       look:floor0_look;
       free_info:floor0_free_info;
       free_look:floor0_free_look;
       inverse1:floor0_inverse1;
       inverse2:floor0_inverse2;
      );

      floor1_exportbundle:vorbis_func_floor=(
       unpack:floor1_unpack;
       look:floor1_look;
       free_info:floor1_free_info;
       free_look:floor1_free_look;
       inverse1:floor1_inverse1;
       inverse2:floor1_inverse2;
      );

      residue0_exportbundle:vorbis_func_residue=(
       unpack:res0_unpack;
       look:res0_look;
       free_info:res0_free_info;
       free_look:res0_free_look;
       inverse:res0_inverse;
      );

      residue1_exportbundle:vorbis_func_residue=(
       unpack:res0_unpack;
       look:res0_look;
       free_info:res0_free_info;
       free_look:res0_free_look;
       inverse:res1_inverse;
      );

      residue2_exportbundle:vorbis_func_residue=(
       unpack:res0_unpack;
       look:res0_look;
       free_info:res0_free_info;
       free_look:res0_free_look;
       inverse:res2_inverse;
      );

      mapping0_exportbundle:vorbis_func_mapping=(
       unpack:mapping0_unpack;
       look:mapping0_look;
       free_info:mapping0_free_info;
       free_look:mapping0_free_look;
       inverse:mapping0_inverse;
      );

      _floor_P:array[0..1] of Pvorbis_func_floor=(@floor0_exportbundle,@floor1_exportbundle);

      _residue_P:array[0..2] of Pvorbis_func_residue=(@residue0_exportbundle,@residue1_exportbundle,@residue2_exportbundle);

      _mapping_P:array[0..0] of Pvorbis_func_mapping=(@mapping0_exportbundle);

implementation

function _ilog(v:longword):longint; {$ifdef caninline}inline;{$endif}
begin
 result:=0;
 while v<>0 do begin
  inc(result);
  v:=v shr 1;
 end;
end;

{$ifndef HasSAR}
function SARLongint(Value,Shift:longint):longint;
{$ifdef cpu386} assembler; register; {$ifdef fpc}nostackframe;{$endif}
asm
 mov ecx,edx
 sar eax,cl
end;
{$else}
{$ifdef cpuarm} assembler; {$ifdef fpc}nostackframe;{$endif}
asm
 mov r0,r0,asr r1
{$if defined(cpuarmv3) or defined(cpuarmv4) or defined(cpuarmv5)}
 mov pc,lr
{$else}
 bx lr
{$ifend}
end;
{$else} {$ifdef caninline}inline;{$endif}
begin
{$ifdef HasSAR}
 result:=SARLongint(Value,Shift);
{$else}
 Shift:=Shift and 31;
 result:=(longword(Value) shr Shift) or (longword(longint(longword(0-longword(longword(Value) shr 31)) and longword(0-longword(ord(Shift<>0))))) shl (32-Shift));
{$endif}
end;
{$endif}
{$endif}
{$endif}

function MULT32(x,y:longint):longint;
{$ifdef cpu386} assembler; register; {$ifdef fpc}nostackframe;{$endif}
asm
 imul edx
 mov eax,edx
end;
{$else}
{$ifdef cpuarm} assembler; {$ifdef fpc}nostackframe;{$endif}
asm
 smull r1,r0,r0,r1
{$if defined(cpuarmv3) or defined(cpuarmv4) or defined(cpuarmv5)}
 mov pc,lr
{$else}
 bx lr
{$ifend}
end;
{$else} {$ifdef caninline}inline;{$endif}
var v:TInt64Casted;
begin
 v.Value:=int64(x)*y;
 result:=v.Hi;
end;
{$endif}
{$endif}

function MULT31(x,y:longint):longint;
{$ifdef cpu386} assembler; register; {$ifdef fpc}nostackframe;{$endif}
asm
 imul edx
 shl edx,1
 shr eax,31
 or eax,edx
end;
{$else}
{$ifdef cpuarm} assembler; {$ifdef fpc}nostackframe;{$endif}
asm
 smull r1,r0,r0,r1
 movs r1,r1,lsr #31
 adc r0,r1,r0,lsl #1
{$if defined(cpuarmv3) or defined(cpuarmv4) or defined(cpuarmv5)}
 mov pc,lr
{$else}
 bx lr
{$ifend}
end;
{$else} {$ifdef caninline}inline;{$endif}
var v:TInt64Casted;
begin
 v.Value:=int64(x)*y;
 result:=(v.Hi shl 1) or (v.Lo shr 31);
end;
{$endif}
{$endif}

function MULT31_SHIFT15(x,y:longint):longint;
{$ifdef cpu386} assembler; register; {$ifdef fpc}nostackframe;{$endif}
asm
 imul edx
 shl edx,17
 shr eax,15
 or eax,edx
end;
{$else}
{$ifdef cpuarm} assembler; {$ifdef fpc}nostackframe;{$endif}
asm
 smull r1,r0,r0,r1
 movs r1,r1,lsr #15
 adc r0,r1,r0,lsl #17
{$if defined(cpuarmv3) or defined(cpuarmv4) or defined(cpuarmv5)}
 mov pc,lr
{$else}
 bx lr
{$ifend}
end;
{$else} {$ifdef caninline}inline;{$endif}
var v:TInt64Casted;
begin
 v.Value:=int64(x)*y;
 result:=(v.Hi shl 17) or (v.Lo shr 15);
end;
{$endif}
{$endif}

procedure XPROD32(a,b,t,v:longint;x,y:PLongint); {$ifdef caninline}inline;{$endif}
begin
 x^:=Mult32(a,t)+Mult32(b,v);
 y^:=Mult32(b,t)-Mult32(a,v);
end;

procedure XPROD31(a,b,t,v:longint;x,y:PLongint); {$ifdef caninline}inline;{$endif}
begin
 x^:=Mult31(a,t)+Mult31(b,v);
 y^:=Mult31(b,t)-Mult31(a,v);
end;

procedure XNPROD31(a,b,t,v:longint;x,y:PLongint); {$ifdef caninline}inline;{$endif}
begin
 x^:=Mult31(a,t)-Mult31(b,v);
 y^:=Mult31(b,t)+Mult31(a,v);
end;

function CLIP_TO_15(x:longint):longint;
{$ifdef cpuarm} assembler; {$ifdef fpc}nostackframe;{$endif}
asm
 subs r1,r0,#32768
 movpl r0,#32512
 orrpl r0,r0,#255
 adds r1,r0,#32768
 movmi r0,#32768
{$if defined(cpuarmv3) or defined(cpuarmv4) or defined(cpuarmv5)}
 mov pc,lr
{$else}
 bx lr
{$ifend}
end;
{$else} {$ifdef caninline}inline;{$endif}
begin
{if x>32767 then begin
  result:=32767;
 end else if x<-32768 then begin
  result:=-32768;
 end else begin
  result:=x;
 end;}
 result:=(x-(((ord(x<=32767) and 1)-1) and (x-32767)))-(((ord(x>=(-32768)) and 1)-1) and (x+32768));
end;
{$endif}

function VFLOAT_MULT(a,ap,b,bp:longint;p:PLongint):longint; {$ifdef caninline}inline;{$endif}
begin
 if (a and b)<>0 then begin
  p^:=ap+bp+32;
  result:=MULT32(a,b);
 end else begin
  result:=0;
 end;
end;

function VFLOAT_MULTI(a,ap,i:longint;p:PLongint):longint; {$ifdef caninline}inline;{$endif}
var ip:longint;
begin
 ip:=_ilog(abs(i))-31;
 result:=VFLOAT_MULT(a,ap,i shl (-ip),ip,p);
end;

function VFLOAT_ADD(a,ap,b,bp:longint;p:PLongint):longint; {$ifdef caninline}inline;{$endif}
var shift:longint;
begin
 if a=0 then begin
  p^:=bp;
  result:=b;
 end else if b=0 then begin
  p^:=ap;
  result:=a;
 end else begin
  if ap>bp then begin
   shift:=(ap-bp)+1;
   p^:=ap+1;
   a:=SARLongint(a,1);
   if shift<32 then begin
    b:=SARLongint(b+(1 shl (shift-1)),shift);
   end else begin
    b:=0;
   end;
  end else begin
   shift:=(bp-ap)+1;
   p^:=bp+1;
   b:=SARLongint(b,1);
   if shift<32 then begin
    a:=SARLongint(a+(1 shl (shift-1)),shift);
   end else begin
    a:=0;
   end;
  end;
  result:=a+b;
  if ((longword(result) and $c0000000)=$c0000000) or ((longword(result) and $c0000000)=0) then begin
   inc(result,result);
   dec(p^);
  end;
 end;
end;

{procedure dumpit(filename:ansistring;var buffer;size:BeRoAudioOGGPtrInt);
var f:file;
begin
 assignfile(f,filename);
 rewrite(f,1);
 blockwrite(f,buffer,size);
 closefile(f);
end;

procedure appendit(filename:ansistring;var buffer;size:BeRoAudioOGGPtrInt);
var f:file;
begin
 if fileexists(filename) then begin
  assignfile(f,filename);
  reset(f,1);
  seek(f,filesize(f));
 end else begin
  assignfile(f,filename);
  rewrite(f,1);
 end;
 blockwrite(f,buffer,size);
 closefile(f);
end;}

function Allocate(Size:BeRoAudioOGGPtrInt):pointer;
begin
 GetMem(result,Size);
 FillChar(result^,Size,AnsiChar(#0));
end;

function Reallocate(Data:pointer;Size:BeRoAudioOGGPtrInt):pointer;
begin
 result:=Data;
 ReallocMem(result,Size);
end;

procedure Exchange(base:PAnsiChar;size,a,b:BeRoAudioOGGPtrUInt);
var x,y:PAnsiChar;
    z:AnsiChar;
begin
 x:=@base[a*size];
 y:=@base[b*size];
 while size>0 do begin
  dec(size);
  z:=x^;
  x^:=y^;
  y^:=z;
  inc(x);
  inc(y);
 end;
end;

type TQuickSortCompareFunction=function(const a,b:pointer):longint;

procedure QuickSort(base:PAnsiChar;size:BeRoAudioOGGPtrUInt;l,r:BeRoAudioOGGPtrInt;CompareFunction:TQuickSortCompareFunction);
var i,j,p,q,k:BeRoAudioOGGPtrInt;
    v:PAnsiChar;
begin
 if l<r then begin
  i:=l-1;
  j:=r;
  p:=l-1;
  q:=r;
  v:=@base[BeRoAudioOGGPtrUInt(r)*size];
  while true do begin
   repeat
    inc(i);
   until (i=r) or (CompareFunction(@base[BeRoAudioOGGPtrUInt(i)*size],v)>=0);
   repeat
    dec(j);
    if j=1 then begin
     break;
    end;
   until CompareFunction(v,@base[BeRoAudioOGGPtrUInt(j)*size])>=0;
   if i>=j then begin
    break;
   end;
   Exchange(base,size,i,j);
   if CompareFunction(@base[BeRoAudioOGGPtrUInt(i)*size],v)=0 then begin
    inc(p);
    Exchange(base,size,p,i);
   end;
   if CompareFunction(v,@base[BeRoAudioOGGPtrUInt(j)*size])=0 then begin
    dec(q);
    Exchange(base,size,j,q);
   end;
  end;
  Exchange(base,size,i,r);
  j:=i-1;
  inc(i);
  k:=l;
  while k<p do begin
   Exchange(base,size,k,j);
   inc(k);
   dec(j);
  end;
  k:=r-1;
  while k>q do begin
   Exchange(base,size,i,k);
   dec(k);
   inc(i);
  end;
  QuickSort(base,size,l,j,CompareFunction);
  QuickSort(base,size,i,r,CompareFunction);
 end;
end;

procedure QSort(base:pointer;count,size:BeRoAudioOGGPtrUInt;CompareFunction:TQuickSortCompareFunction);
begin
 if (count>1) and (count<((high(BeRoAudioOGGPtrUInt) shr 1)-1)) and (size<((high(BeRoAudioOGGPtrUInt) shr 1)-1)) then begin
  QuickSort(base,size,0,count-1,CompareFunction);
 end;
end;

function memchr(p:pansichar;c:ansichar;l:longint):pointer;
var i:longint;
begin
 result:=nil;
 for i:=0 to l-1 do begin
  if p[i]=c then begin
   result:=@p[i];
   break;
  end;
 end;
end;

const mask:array[0..32] of longword=($00000000,$00000001,$00000003,$00000007,$0000000f,
                                     $0000001f,$0000003f,$0000007f,$000000ff,$000001ff,
                                     $000003ff,$000007ff,$00000fff,$00001fff,$00003fff,
                                     $00007fff,$0000ffff,$0001ffff,$0003ffff,$0007ffff,
                                     $000fffff,$001fffff,$003fffff,$007fffff,$00ffffff,
                                     $01ffffff,$03ffffff,$07ffffff,$0fffffff,$1fffffff,
                                     $3fffffff,$7fffffff,$ffffffff);

procedure oggpack_adv_halt(b:Poggpack_buffer); {$ifdef caninline}inline;{$endif}
begin
 b^.headptr:=@b^.head^.buffer^.data[b^.head^.begin_+b^.head^.length];
 b^.headend:=-1;
 b^.headbit:=0;
end;

procedure oggpack_span(b:Poggpack_buffer); {$ifdef caninline}inline;{$endif}
begin
 while b^.headend<1 do begin
  if assigned(b^.head^.next) then begin
   inc(b^.count,b^.head^.length);
   b^.head:=b^.head^.next;
   b^.headptr:=@b^.head^.buffer^.data[b^.head^.begin_-b^.headend];
   inc(b^.headend,b^.head^.length);
  end else begin
   if (b^.headend<0) or (b^.headbit<>0) then begin
    oggpack_adv_halt(b);
   end;
   break;
  end;
 end;
end;

procedure oggpack_readinit(b:Poggpack_buffer;r:Pogg_reference);
begin
 FillChar(b^,sizeof(oggpack_buffer),AnsiChar(#0));
 b^.tail:=r;
 b^.head:=r;
 b^.headptr:=@b^.head^.buffer^.data[b^.head^.begin_];
 b^.headend:=b^.head^.length;
 oggpack_span(b);
end;

function oggpack_look(b:Poggpack_buffer;bits:longint):longint;
var m,ret:longword;
    end_:longint;
    ptr:PAnsiChar;
    head:Pogg_reference;
begin
 m:=mask[bits];
 ret:=$ffffffff;
 inc(bits,b^.headbit);
 if bits>=(b^.headend shl 3) then begin
  end_:=b^.headend;
  ptr:=b^.headptr;
  head:=b^.head;
  if end_<0 then begin
   result:=-1;
   exit;
  end;
  if bits<>0 then begin
   while end_=0 do begin
    head:=head^.next;
    if not assigned(head) then begin
     result:=-1;
     exit;
    end;
    ptr:=@head^.buffer^.data[head^.begin_];
    end_:=head^.length;
   end;
   ret:=byte(ptr^) shr b^.headbit;
   inc(ptr);
   if bits>8 then begin
    dec(end_);
    while end_=0 do begin
     head:=head^.next;
     if not assigned(head) then begin
      result:=-1;
      exit;
     end;
     ptr:=@head^.buffer^.data[head^.begin_];
     end_:=head^.length;
    end;
    ret:=ret or (byte(ptr^) shl (8-b^.headbit));
    inc(ptr);
    if bits>16 then begin
     dec(end_);
     while end_=0 do begin
      head:=head^.next;
      if not assigned(head) then begin
       result:=-1;
       exit;
      end;
      ptr:=@head^.buffer^.data[head^.begin_];
      end_:=head^.length;
     end;
     ret:=ret or (byte(ptr^) shl (16-b^.headbit));
     inc(ptr);
     if bits>24 then begin
      dec(end_);
      while end_=0 do begin
       head:=head^.next;
       if not assigned(head) then begin
        result:=-1;
        exit;
       end;
       ptr:=@head^.buffer^.data[head^.begin_];
       end_:=head^.length;
      end;
      ret:=ret or (byte(ptr^) shl (24-b^.headbit));
      inc(ptr);
      if (bits>32) and (b^.headbit<>0) then begin
       dec(end_);
       while end_=0 do begin
        head:=head^.next;
        if not assigned(head) then begin
         result:=-1;
         exit;
        end;
        ptr:=@head^.buffer^.data[head^.begin_];
        end_:=head^.length;
       end;
       ret:=ret or (byte(ptr^) shl (32-b^.headbit));
      end;
     end;
    end;
   end;
  end;
 end else begin
  ret:=byte(b^.headptr[0]) shr b^.headbit;
  if bits>8 then begin
   ret:=ret or (byte(b^.headptr[1]) shl (8-b^.headbit));
   if bits>16 then begin
    ret:=ret or (byte(b^.headptr[2]) shl (16-b^.headbit));
    if bits>24 then begin
     ret:=ret or (byte(b^.headptr[3]) shl (24-b^.headbit));
     if (bits>32) and (b^.headbit<>0) then begin
      ret:=ret or (byte(b^.headptr[4]) shl (32-b^.headbit));
     end;
    end;
   end;
  end;
 end;
 result:=longint(longword(ret and m));
end;

procedure oggpack_adv(b:Poggpack_buffer;bits:longint);
begin
 inc(bits,b^.headbit);
 b^.headbit:=bits and 7;
 inc(b^.headptr,bits div 8);
 dec(b^.headend,bits div 8);
 if b^.headend<1 then begin
  oggpack_span(b);
 end;
end;

procedure oggpack_span_one(b:Poggpack_buffer); {$ifdef caninline}inline;{$endif}
begin
 while b^.headend<1 do begin
  if assigned(b^.head^.next) then begin
   inc(b^.count,b^.head^.length);
   b^.head:=b^.head^.next;
   b^.headptr:=@b^.head^.buffer^.data[b^.head^.begin_];
   inc(b^.headend,b^.head^.length);
  end else begin
   break;
  end;
 end;
end;

function oggpack_halt_one(b:Poggpack_buffer):longint; {$ifdef caninline}inline;{$endif}
begin
 if b^.headend<1 then begin
  oggpack_adv_halt(b);
  result:=-1;
 end else begin
  result:=0;
 end;
end;

function oggpack_eop(b:Poggpack_buffer):longint;
begin
 if b^.headend<0 then begin
  result:=-1;
 end else begin
  result:=0;
 end;
end;

function oggpack_read(b:Poggpack_buffer;bits:longint):longint;
{begin
 result:=oggpack_look(b,bits);
 oggpack_adv(b,bits);
end;{}
var m,ret:longword;
begin
 m:=mask[bits];
 ret:=$ffffffff;
 inc(bits,b^.headbit);
 if bits>=(b^.headend shl 3) then begin
  if b^.headend<0 then begin
   result:=-1;
   exit;
  end;
  if bits<>0 then begin
   if oggpack_halt_one(b)<>0 then begin
    result:=-1;
    exit;
   end;
   ret:=byte(b^.headptr^) shr b^.headbit;
   if bits>=8 then begin
    inc(b^.headptr);
    dec(b^.headend);
    oggpack_span_one(b);
    if bits>8 then begin
     if oggpack_halt_one(b)<>0 then begin
      result:=-1;
      exit;
     end;
     ret:=ret or (byte(b^.headptr^) shl (8-b^.headbit));
     if bits>=16 then begin
      inc(b^.headptr);
      dec(b^.headend);
      oggpack_span_one(b);
      if bits>16 then begin
       if oggpack_halt_one(b)<>0 then begin
        result:=-1;
        exit;
       end;
       ret:=ret or (byte(b^.headptr^) shl (16-b^.headbit));
       if bits>=24 then begin
        inc(b^.headptr);
        dec(b^.headend);
        oggpack_span_one(b);
        if bits>24 then begin
         if oggpack_halt_one(b)<>0 then begin
          result:=-1;
          exit;
         end;
         ret:=ret or (byte(b^.headptr^) shl (24-b^.headbit));
         if bits>=32 then begin
          inc(b^.headptr);
          dec(b^.headend);
          oggpack_span_one(b);
          if bits>32 then begin
           if oggpack_halt_one(b)<>0 then begin
            result:=-1;
            exit;
           end;
           ret:=ret or (byte(b^.headptr^) shl (32-b^.headbit));
          end;
         end;
        end;
       end;
      end;
     end;
    end;
   end;
  end;
 end else begin
  ret:=byte(b^.headptr[0]) shr b^.headbit;
  if bits>8 then begin
   ret:=ret or (byte(b^.headptr[1]) shl (8-b^.headbit));
   if bits>16 then begin
    ret:=ret or (byte(b^.headptr[2]) shl (16-b^.headbit));
    if bits>24 then begin
     ret:=ret or (byte(b^.headptr[3]) shl (24-b^.headbit));
     if (bits>32) and (b^.headbit<>0) then begin
      ret:=ret or (byte(b^.headptr[4]) shl (32-b^.headbit));
     end;
    end;
   end;
  end;
  inc(b^.headptr,bits div 8);
  dec(b^.headend,bits div 8);
 end;
 b^.headbit:=bits and 7;
 result:=longint(longword(ret and m));
//writeln('r ',result);
end;{}

function oggpack_bytes(b:Poggpack_buffer):longint;
begin
 result:=(((b^.count+BeRoAudioOGGPtrInt(BeRoAudioOGGPtrUInt(b^.headptr)))-BeRoAudioOGGPtrInt(BeRoAudioOGGPtrUInt(b^.head^.buffer^.data)))-b^.head^.begin_)+((b^.headbit+7) div 8);
end;

function oggpack_bits(b:Poggpack_buffer):longint;
begin
 result:=((((b^.count+BeRoAudioOGGPtrInt(BeRoAudioOGGPtrUInt(b^.headptr)))-BeRoAudioOGGPtrInt(BeRoAudioOGGPtrUInt(b^.head^.buffer^.data)))-b^.head^.begin_)*8)+b^.headbit;
end;

function _vorbis_window(type_,left:longint):pointer;
begin
 case type_ of
  0:begin
   case left of
    32:begin
     result:=@vwin64;
    end;
    64:begin
     result:=@vwin128;
    end;
    128:begin
     result:=@vwin256;
    end;
    256:begin
     result:=@vwin512;
    end;
    512:begin
     result:=@vwin1024;
    end;
    1024:begin
     result:=@vwin2048;
    end;
    2048:begin
     result:=@vwin4096;
    end;
    4096:begin
     result:=@vwin8192;
    end;
    else begin
     result:=nil;
    end;
   end;
  end;
  else begin
   result:=nil;
  end;
 end;
end;

procedure _vorbis_apply_window(d:PLongints;window_p:PTwoPointers;blocksizes:PLongints;lW,W,nw:longint);
var window:array[0..1] of PLongints;
    n,ln,rn,leftbegin,leftend,rightbegin,rightend,i,p:longint;
begin
 window[0]:=window_p[0];
 window[1]:=window_p[1];
 n:=blocksizes^[W];
 ln:=blocksizes^[lW];
 rn:=blocksizes^[nW];
 leftbegin:=(n div 4)-(ln div 4);
 leftend:=leftbegin+(ln div 2);
 rightbegin:=((n div 2)+(n div 4))-(rn div 4);
 rightend:=rightbegin+(rn div 2);
 for i:=0 to leftbegin-1 do begin
  d^[i]:=0;
 end;
 p:=0;
 for i:=leftbegin to leftend-1 do begin
  d^[i]:=MULT31(d^[i],window[lW]^[p]);
  inc(p);
 end;
 p:=(rn div 2)-1;
 for i:=rightbegin to rightend-1 do begin
  d^[i]:=MULT31(d^[i],window[nW]^[p]);
  dec(p);
 end;
 for i:=rightend to n-1 do begin
  d^[i]:=0;
 end;
end;

function ilog(v:longword):longint; {$ifdef caninline}inline;{$endif}
begin
 result:=0;
 if v<>0 then begin
  dec(v);
 end;
 while v<>0 do begin
  inc(result);
  v:=v shr 1;
 end;
end;

function vorbis_block_init(v:Pvorbis_dsp_state;vb:Pvorbis_block):longint;
begin
 FillChar(vb^,SizeOf(vorbis_block),AnsiChar(#0));
 vb^.vd:=v;
 vb^.localalloc:=0;
 vb^.localstore:=nil;
 result:=0;
end;

function _vorbis_block_alloc(vb:Pvorbis_block;bytes:longint):pointer;
var link:Palloc_chain;
begin
 bytes:=(bytes+(WORD_ALIGN-1)) and not (WORD_ALIGN-1);
 if (bytes+vb^.localtop)>vb^.localalloc then begin
  if assigned(vb^.localstore) then begin
   GetMem(link,SizeOf(alloc_chain));
   inc(vb^.totaluse,vb^.localtop);
   link^.next:=vb^.reap;
   link^.ptr:=vb^.localstore;
   vb^.reap:=link;
  end;
  vb^.localalloc:=bytes;
  GetMem(vb^.localstore,vb^.localalloc);
  vb^.localtop:=0;
 end;
 result:=@PAnsiChar(vb^.localstore)[vb^.localtop];
 inc(vb^.localtop,bytes);
end;

procedure _vorbis_block_ripcord(vb:Pvorbis_block);
var reap,next:Palloc_chain;
begin
 reap:=vb^.reap;
 while assigned(reap) do begin
  next:=reap^.next;
  FreeMem(reap^.ptr);
  FillChar(reap^,SizeOf(alloc_chain),AnsiChar(#0));
  FreeMem(reap);
  reap:=next;
 end;
 if vb^.totaluse<>0 then begin
  ReallocMem(vb^.localstore,vb^.totaluse+vb^.localalloc);
  inc(vb^.localalloc,vb^.totaluse);
  vb^.totaluse:=0;
 end;
 vb^.localtop:=0;
 vb^.reap:=nil;
end;

function vorbis_block_clear(vb:Pvorbis_block):longint;
begin
 _vorbis_block_ripcord(vb);
 if assigned(vb^.localstore) then begin
  FreeMem(vb^.localstore);
 end;
 FillChar(vb^,SizeOf(vorbis_block),AnsiChar(#0));
 result:=0;
end;

function _vds_init(v:Pvorbis_dsp_state;vi:Pvorbis_info):longint;
label abort_books;
var i,mapnum,maptype:longint;
    ci:Pcodec_setup_info;
    b:Pprivate_state;
    cb:Pcodebook;
begin
 ci:=vi^.codec_setup;
 if not assigned(ci) then begin
  result:=1;
  exit;
 end;
 b:=nil;
 FillChar(v^,SizeOf(vorbis_dsp_state),AnsiChar(#0));
 b:=Allocate(SizeOf(private_state));
 v^.backend_state:=b;
 v^.vi:=vi;
 b^.modebits:=ilog(ci^.modes);
 b^.window[0]:=_vorbis_window(0,ci^.blocksizes[0] div 2);
 b^.window[1]:=_vorbis_window(0,ci^.blocksizes[1] div 2);
 if not assigned(ci^.fullbooks) then begin
  ci^.fullbooks:=Allocate(SizeOf(codebook)*ci^.books);
  cb:=ci^.fullbooks;
  for i:=0 to ci^.books-1 do begin
   if not assigned(ci^.book_param[i]) then begin
    goto abort_books;
   end;
   if vorbis_book_init_decode(cb,ci^.book_param[i])<>0 then begin
    goto abort_books;
   end;
   vorbis_staticbook_destroy(ci^.book_param[i]);
   ci^.book_param[i]:=nil;
   inc(cb);
  end;
 end;
 v^.pcm_storage:=ci^.blocksizes[1];
 v^.pcm:=Allocate(vi^.channels*SizeOf(PLongints));
 v^.pcmret:=Allocate(vi^.channels*SizeOf(PLongints));
 for i:=0 to vi^.channels-1 do begin
  v^.pcm^[i]:=Allocate(v^.pcm_storage*SizeOf(ogg_int32_t));
 end;
 v^.lW:=0;
 v^.W:=0;
 b^.mode:=Allocate(ci^.modes*SizeOf(Pvorbis_look_mapping));
 for i:=0 to ci^.modes-1 do begin
  mapnum:=ci^.mode_param[i]^.mapping;
  maptype:=ci^.map_type[i];
  PPointers(b^.mode)^[i]:=_mapping_P[maptype]^.look(v,ci^.mode_param[i],ci^.map_param[mapnum]);
 end;
 result:=0;
 exit;
abort_books:
 for i:=0 to ci^.books-1 do begin
  if assigned(ci^.book_param[i]) then begin
   vorbis_staticbook_destroy(ci^.book_param[i]);
   ci^.book_param[i]:=nil;
  end;
 end;
 vorbis_dsp_clear(v);
 result:=-1;
end;

function vorbis_synthesis_restart(v:Pvorbis_dsp_state):longint;
var vi:Pvorbis_info;
    ci:Pcodec_setup_info;
begin
 vi:=v^.vi;
 if (not assigned(v^.backend_state)) or not assigned(vi) then begin
  result:=-1;
  exit;
 end;
 ci:=vi^.codec_setup;
 if not assigned(ci) then begin
  result:=-1;
  exit;
 end;
 v^.centerW:=ci^.blocksizes[1] div 2;
 v^.pcm_current:=v^.centerW;
 v^.pcm_returned:=-1;
 v^.granulepos:=-1;
 v^.sequence:=-1;
 Pprivate_state(v^.backend_state)^.sample_count:=-1;
 result:=0;
end;

function vorbis_synthesis_init(v:Pvorbis_dsp_state;vi:Pvorbis_info):longint;
begin
 if _vds_init(v,vi)<>0 then begin
  result:=1;
  exit;
 end;
 vorbis_synthesis_restart(v);
 result:=0;
end;

procedure vorbis_dsp_clear(v:Pvorbis_dsp_state);
var i,mapnum,maptype:longint;
    vi:Pvorbis_info;
    ci:Pcodec_setup_info;
    b:Pprivate_state;
begin
 if assigned(v) then begin
  vi:=v^.vi;
  if assigned(vi) then begin
   ci:=vi^.codec_setup;
  end else begin
   ci:=nil;
  end;
  b:=v^.backend_state;

  if assigned(v^.pcm) then begin
   for i:=0 to vi^.channels-1 do begin
    if assigned(PPointers(v^.pcm)^[i]) then begin
     FreeMem(PPointers(v^.pcm)^[i]);
    end;
   end;
   FreeMem(v^.pcm);
   if assigned(v^.pcmret) then begin
    FreeMem(v^.pcmret);
   end;
  end;

  if assigned(ci) then begin
   for i:=0 to ci^.modes-1 do begin
    mapnum:=ci^.mode_param[i]^.mapping;
    maptype:=ci^.map_type[i];
    if assigned(b) and assigned(b^.mode) then begin
     _mapping_P[maptype]^.free_look(PPointers(b^.mode)^[i]);
    end;
    if mapnum<>0 then begin
    end;
   end;
  end;

  if assigned(b) then begin
   if assigned(b^.mode) then begin
    FreeMem(b^.mode);
   end;
   FreeMem(b);
  end;

  FillChar(v^,SizeOf(vorbis_dsp_state),AnsiChar(#0));
 end;
end;

function vorbis_synthesis_blockin(v:Pvorbis_dsp_state;vb:Pvorbis_block):longint;
var vi:Pvorbis_info;
    ci:Pcodec_setup_info;
    b:Pprivate_state;
    i,j,n,n0,n1,thisCenter,prevCenter:longint;
    pcm,p:PLongints;
    extra:int64;
begin
 vi:=v^.vi;
 ci:=vi^.codec_setup;
 b:=v^.backend_state;

 if (v^.pcm_current>v^.pcm_returned) and (v^.pcm_returned<>-1) then begin
  result:=OV_EINVAL;
  exit;
 end;

 v^.lW:=v^.W;
 v^.W:=vb^.W;
 v^.nW:=-1;

 if (v^.sequence=-1) or ((v^.sequence+1)<>vb^.sequence) then begin
  v^.granulepos:=-1;
  b^.sample_count:=-1;
 end;

 v^.sequence:=vb^.sequence;

 if assigned(vb^.pcm) then begin
  n:=ci^.blocksizes[v^.W] div 2;
  n0:=ci^.blocksizes[0] div 2;
  n1:=ci^.blocksizes[1] div 2;

  if v^.centerW<>0 then begin
   thisCenter:=n1;
   prevCenter:=0;
  end else begin
   thisCenter:=0;
   prevCenter:=n1;
  end;

  for j:=0 to vi^.channels-1 do begin
   if v^.lW<>0 then begin
    if v^.W<>0 then begin
     pcm:=@v^.pcm^[j]^[prevCenter];
     p:=vb^.pcm^[j];
     for i:=0 to n1-1 do begin
      inc(pcm^[i],p^[i]);
     end;
    end else begin
     pcm:=@v^.pcm^[j]^[(prevCenter+(n1 div 2))-(n0 div 2)];
     p:=vb^.pcm^[j];
     for i:=0 to n0-1 do begin
      inc(pcm^[i],p^[i]);
     end;
    end;
   end else begin
    if v^.W<>0 then begin
     pcm:=@v^.pcm^[j]^[prevCenter];
     p:=@vb^.pcm^[j]^[((n1 div 2)-(n0 div 2))];
     for i:=0 to n0-1 do begin
      inc(pcm^[i],p^[i]);
     end;
     for i:=n0 to ((n1 div 2)+(n0 div 2))-1 do begin
      pcm^[i]:=p^[i];
     end;
    end else begin
     pcm:=@v^.pcm^[j]^[prevCenter];
     p:=vb^.pcm^[j];
     for i:=0 to n0-1 do begin
      inc(pcm^[i],p^[i]);
     end;
    end;
   end;
   begin
    pcm:=@v^.pcm^[j]^[thisCenter];
    p:=@vb^.pcm^[j]^[n];
    for i:=0 to n-1 do begin
     pcm^[i]:=p^[i];
    end;
   end;
  end;
    
  if v^.centerW<>0 then begin
   v^.centerW:=0;
  end else begin
   v^.centerW:=n1;
  end;
    
  if v^.pcm_returned=-1 then begin
   v^.pcm_returned:=thisCenter;
   v^.pcm_current:=thisCenter;
  end else begin
   v^.pcm_returned:=prevCenter;
   v^.pcm_current:=prevCenter+(ci^.blocksizes[v^.lW] div 4)+(ci^.blocksizes[v^.W] div 4);
  end;

 end;
    
 if b^.sample_count=-1 then begin
  b^.sample_count:=0;
 end else begin
  inc(b^.sample_count,(ci^.blocksizes[v^.lW] div 4)+(ci^.blocksizes[v^.W] div 4));
 end;
    
 if v^.granulepos=-1 then begin
  if vb^.granulepos<>-1 then begin
   v^.granulepos:=vb^.granulepos;
   if b^.sample_count>v^.granulepos then begin
    extra:=b^.sample_count-vb^.granulepos;
    if extra<0 then begin
     extra:=0;
    end;
    if vb^.eofflag<>0 then begin
     if extra>(v^.pcm_current-v^.pcm_returned) then begin
      extra:=(v^.pcm_current-v^.pcm_returned);
     end;
     dec(v^.pcm_current,extra);
    end else begin
     inc(v^.pcm_returned,extra);
     if v^.pcm_returned>v^.pcm_current then begin
      v^.pcm_returned:=v^.pcm_current;
     end;
    end;
   end;
  end;
 end else begin
  inc(v^.granulepos,(ci^.blocksizes[v^.lW] div 4)+(ci^.blocksizes[v^.W] div 4));
  if (vb^.granulepos<>-1) and (v^.granulepos<>vb^.granulepos) then begin
   if v^.granulepos>vb^.granulepos then begin
    extra:=v^.granulepos-vb^.granulepos;
    if extra<>0 then begin
     if vb^.eofflag<>0 then begin
      if extra>(v^.pcm_current-v^.pcm_returned) then begin
       extra:=(v^.pcm_current-v^.pcm_returned);
      end;
      if extra<0 then begin
       extra:=0;
      end;
      dec(v^.pcm_current,extra);
     end;
    end;
   end;
   v^.granulepos:=vb^.granulepos;
  end;
 end;
 if vb^.eofflag<>0 then begin
  v^.eofflag:=1;
 end;
 result:=0;
end;

function vorbis_synthesis_pcmout(v:Pvorbis_dsp_state;pcm:PPPLongints):longint;
var vi:Pvorbis_info;
    i:longint;
begin
 result:=0;
 vi:=v^.vi;
 if (v^.pcm_returned>-1) and (v^.pcm_returned<v^.pcm_current) then begin
  if assigned(pcm) then begin
   for i:=0 to vi^.channels-1 do begin
    v^.pcmret^[i]:=pointer(@v^.pcm^[i]^[v^.pcm_returned]);
   end;
   pcm^[0]:=v^.pcmret;
  end;
  result:=v^.pcm_current-v^.pcm_returned;
 end;
end;

function vorbis_synthesis_read(v:Pvorbis_dsp_state;bytes:longint):longint;
begin
 if (bytes<>0) and ((v^.pcm_returned+bytes)>v^.pcm_current) then begin
  result:=OV_EINVAL;
  exit;
 end;
 inc(v^.pcm_returned,bytes);
 result:=0;
end;

function _book_maptype1_quantvals(b:Pstatic_codebook):longint;
var bits,vals,acc,acc1,i:longint;
begin
 bits:=_ilog(b^.entries);
 vals:=b^.entries shr (((bits-1)*(b^.dim-1)) div b^.dim);
 while true do begin
  acc:=1;
  acc1:=1;
  for i:=0 to b^.dim-1 do begin
   acc:=acc*vals;
   acc1:=acc1*(vals+1);
  end;
  if (acc<=b^.entries) and (acc1>b^.entries) then begin
   result:=vals;
   exit;
  end else begin
   if acc>b^.entries then begin
    dec(vals);
   end else begin
    inc(vals);
   end;
  end;
 end;
end;

function vorbis_staticbook_unpack(opb:Poggpack_buffer):Pstatic_codebook;
label _eofout,_errout;
var i,j,num,len,quantvals,unused:longint;
    s:Pstatic_codebook;
begin
 s:=Allocate(SizeOf(static_codebook));

 if oggpack_read(opb,24)<>$564342 then begin
  goto _eofout;
 end;

 if (_ilog(s^.dim)+ilog(s^.entries))>24 then begin
  goto _eofout;
 end;

 s^.dim:=oggpack_read(opb,16);
 s^.entries:=oggpack_read(opb,24);
 if s^.entries=-1 then begin
  goto _eofout;
 end;

 case oggpack_read(opb,1) of
  0:begin
   unused:=oggpack_read(opb,1);
{  if (unused<>0) and ((s^.entries shr 3)>(opb^.storage-oggpack_bytes(opb))) then begin
    goto _eofout;
   end;}
   s^.lengthlist:=Allocate(s^.entries*sizeof(ogg_int32_t));
   if unused<>0 then begin
    for i:=0 to s^.entries-1 do begin
     if oggpack_read(opb,1)<>0 then begin
      num:=oggpack_read(opb,5);
      if num=(-1) then begin
       goto _eofout;
      end;
      PLongints(s^.lengthlist)^[i]:=num+1;
     end else begin
      PLongints(s^.lengthlist)^[i]:=0;
     end;
    end;
   end else begin
    for i:=0 to s^.entries-1 do begin
     num:=oggpack_read(opb,5);
     if num=(-1) then begin
      goto _eofout;
     end;
     PLongints(s^.lengthlist)^[i]:=num+1;
    end;
   end;
  end;
  1:begin
   len:=oggpack_read(opb,5)+1;
   s^.lengthlist:=Allocate(s^.entries*sizeof(ogg_int32_t));
   i:=0;
   while i<s^.entries do begin
    num:=oggpack_read(opb,_ilog(s^.entries-i));
    if num=(-1) then begin
     goto _eofout;
    end;
    if (len>32) or (num>(s^.entries-i)) or ((num>0) and (((((num-1) shr (len shr 1)) shr (len+1)) shr 1)>0)) then begin
     goto _errout;
    end;
    j:=0; 
    while (j<num) and (i<s^.entries) do begin
     PLongints(s^.lengthlist)^[i]:=len;
     inc(i);
     inc(j);
    end;
    inc(len);
   end;
  end;
  else begin
   goto _eofout;
  end;
 end;

 s^.maptype:=oggpack_read(opb,4);
 case s^.maptype of
  0:begin
  end;
  1,2:begin
   s^.q_min:=oggpack_read(opb,32);
   s^.q_delta:=oggpack_read(opb,32);
   s^.q_quant:=oggpack_read(opb,4)+1;
   s^.q_sequencep:=oggpack_read(opb,1);
   if s^.q_sequencep=-1 then begin
    goto _eofout;
   end;
   case s^.maptype of
    1:begin
     if s^.dim=0 then begin
      quantvals:=0;
     end else begin
      quantvals:=_book_maptype1_quantvals(s);
     end;
    end;
    2:begin
     quantvals:=s^.entries*s^.dim;
    end;
    else begin
     quantvals:=0;
    end;
   end;
   s^.quantlist:=Allocate(SizeOf(ogg_int32_t)*quantvals);
   for i:=0 to quantvals-1 do begin
    PLongints(s^.quantlist)^[i]:=oggpack_read(opb,s^.q_quant);
   end;
   if (quantvals<>0) and (PLongints(s^.quantlist)^[quantvals-1]=-1) then begin
    goto _eofout;
   end;
  end;
  else begin
   goto _errout;
  end;
 end;

 result:=s;
 exit;

_errout:
_eofout:
 vorbis_staticbook_destroy(s);
 result:=nil;
end;

function bitreverse(x:ogg_uint32_t):ogg_uint32_t;
begin
 x:=((x shr 16) and $0000ffff) or ((x shl 16) and $ffff0000);
 x:=((x shr 8) and $00ff00ff) or ((x shl 8) and $ff00ff00);
 x:=((x shr 4) and $0f0f0f0f) or ((x shl 4) and $f0f0f0f0);
 x:=((x shr 2) and $33333333) or ((x shl 2) and $cccccccc);
 result:=((x shr 1) and $55555555) or ((x shl 1) and $aaaaaaaa);
end;

function decode_packed_entry_number(book:Pcodebook;b:Poggpack_buffer):longint;
var read,lo,hi,lok,entry,p,test:longint;
    testword:longword;
begin
 read:=book^.dec_maxlength;
 lok:=oggpack_look(b,book^.dec_firsttablen);

 if lok>=0 then begin
  entry:=PLongwords(book^.dec_firsttable)^[lok];
  if (entry and $80000000)<>0 then begin
   lo:=SARLongint(entry,15) and $7fff;
   hi:=book^.used_entries-(entry and $7fff);
  end else begin
   oggpack_adv(b,byte(book^.dec_codelengths[entry-1]));
   result:=entry-1;
   exit;
  end;
 end else begin
  lo:=0;
  hi:=book^.used_entries;
 end;

 lok:=oggpack_look(b,read);

 while (lok<0) and (read>1) do begin
  dec(read);
  lok:=oggpack_look(b,read);
 end;

 if lok<0 then begin
  oggpack_adv(b,1);
  result:=-1;
  exit;
 end;

 testword:=bitreverse(lok);

 while (hi-lo)>1 do begin
  p:=SARLongint(hi-lo,1);
  test:=ord(PLongwords(book^.codelist)^[lo+p]>testword) and 1;
  inc(lo,p and (test-1));
  dec(hi,p and (-test));
 end;

 if byte(book^.dec_codelengths[lo])<=read then begin
  oggpack_adv(b,byte(book^.dec_codelengths[lo]));
  result:=lo;
  exit;
 end;

 oggpack_adv(b,read+1);
 result:=-1;
end;

function vorbis_book_decode(book:Pcodebook;b:Poggpack_buffer):longint;
var packed_entry:longint;
begin
 result:=-1;
 if book^.used_entries>0 then begin
  packed_entry:=decode_packed_entry_number(book,b);
  if packed_entry>=0 then begin
   result:=book^.dec_index^[packed_entry];
  end;
 end;
end;

function vorbis_book_decodevs_add(book:Pcodebook;a:PLongints;b:Poggpack_buffer;n,point:longint):longint;
var step,i,j,o,shift:longint;
    entry:PLongints;
    t:PPLongints;
begin
 if book^.used_entries>0 then begin
  step:=n div book^.dim;
  GetMem(entry,step*sizeof(longint));
  GetMem(t,step*sizeof(PLongint));
  shift:=point-book^.binarypoint;
  if shift>=0 then begin
   for i:=0 to step-1 do begin
    entry^[i]:=decode_packed_entry_number(book,b);
    if entry[i]=-1 then begin
     result:=-1;
     FreeMem(entry);
     FreeMem(t);
     exit;
    end;
    t^[i]:=@book^.valuelist^[entry^[i]*book^.dim];
   end;
   i:=0;
   o:=0;
   while i<book^.dim do begin
    for j:=0 to step-1 do begin
     inc(PLongints(a)^[o+j],SARLongint(t^[j]^[i],shift));
    end;
    inc(i);
    inc(o,step);
   end;
  end else begin
   for i:=0 to step-1 do begin
    entry^[i]:=decode_packed_entry_number(book,b);
    if entry[i]=-1 then begin
     result:=-1;
     FreeMem(entry);
     FreeMem(t);
     exit;
    end;
    t^[i]:=@book^.valuelist^[entry^[i]*book^.dim];
   end;
   i:=0;
   o:=0;
   while i<book^.dim do begin
    for j:=0 to step-1 do begin
     inc(PLongints(a)^[o+j],t^[j]^[i] shl (-shift));
    end;
    inc(i);
    inc(o,step);
   end;
  end;
  FreeMem(entry);
  FreeMem(t);
 end;
 result:=0;
end;

function vorbis_book_decodev_add(book:Pcodebook;a:PLongints;b:Poggpack_buffer;n,point:longint):longint;
var i,j,entry,shift:longint;
    t:PLongints;
begin
 if book^.used_entries>0 then begin
  shift:=point-book^.binarypoint;
  if shift>=0 then begin
   i:=0;
   while i<n do begin
    entry:=decode_packed_entry_number(book,b);
    if entry=-1 then begin
     result:=-1;
     exit;
    end;
    t:=@book^.valuelist^[entry*book^.dim];
    for j:=0 to book^.dim-1 do begin
     inc(a^[i],SARLongint(t^[j],shift));
     inc(i);
    end;
   end;
  end else begin
   i:=0;
   while i<n do begin
    entry:=decode_packed_entry_number(book,b);
    if entry=-1 then begin
     result:=-1;
     exit;
    end;
    t:=@book^.valuelist^[entry*book^.dim];
    for j:=0 to book^.dim-1 do begin
     inc(a^[i],t^[j] shl (-shift));
     inc(i);
    end;
   end;
  end;
 end;
 result:=0;
end;

function vorbis_book_decodev_set(book:Pcodebook;a:PLongints;b:Poggpack_buffer;n,point:longint):longint;
var i,j,entry,shift:longint;
    t:PLongints;
begin
 if book^.used_entries>0 then begin
  shift:=point-book^.binarypoint;
  if shift>=0 then begin
   i:=0;
   while i<n do begin
    entry:=decode_packed_entry_number(book,b);
    if entry=-1 then begin
     result:=-1;
     exit;
    end;
    t:=@book^.valuelist^[entry*book^.dim];
    j:=0;
    while (i<n) and (j<book^.dim) do begin
     inc(a^[i],SARLongint(t^[j],shift));
     inc(i);
     inc(j);
    end;
   end;
  end else begin
   i:=0;
   while i<n do begin
    entry:=decode_packed_entry_number(book,b);
    if entry=-1 then begin
     result:=-1;
     exit;
    end;
    t:=@book^.valuelist^[entry*book^.dim];
    j:=0;
    while (i<n) and (j<book^.dim) do begin
     inc(a^[i],t^[j] shl (-shift));
     inc(i);
     inc(j);
    end;
   end;
  end;
 end else begin
  i:=0;
  while i<n do begin
   a^[i]:=0;
   inc(i);
  end;
 end;
 result:=0;
end;

function vorbis_book_decodevv_add(book:Pcodebook;a:PPLongints;offset,ch:longint;b:Poggpack_buffer;n,point:longint):longint;
var i,j,entry,chptr,shift:longint;
    t:PLongints;
begin
 if book^.used_entries>0 then begin
  chptr:=0;
  shift:=point-book^.binarypoint;
  if shift>=0 then begin
   i:=offset;
   while i<(offset+n) do begin
    entry:=decode_packed_entry_number(book,b);
    if entry=-1 then begin
     result:=-1;
     exit;
    end;
    t:=@book^.valuelist^[entry*book^.dim];
    for j:=0 to book^.dim-1 do begin
     inc(a^[chptr]^[i],SARLongint(t^[j],shift));
     inc(chptr);
     if chptr=ch then begin
      chptr:=0;
      inc(i);
     end;
    end;
   end;
  end else begin
   i:=offset;
   while i<(offset+n) do begin
    entry:=decode_packed_entry_number(book,b);
    if entry=-1 then begin
     result:=-1;
     exit;
    end;
    t:=@book^.valuelist^[entry*book^.dim];
    for j:=0 to book^.dim-1 do begin
     inc(a^[chptr]^[i],t^[j] shl (-shift));
     inc(chptr);
     if chptr=ch then begin
      chptr:=0;
      inc(i);
     end;
    end;
   end;
  end;
 end;
 result:=0;
end;

function vorbis_invsqlook_i(a,e:longint):longint;
var i,d,val:longint;
begin
 i:=(a and $7fff) shr (INVSQ_LOOKUP_I_SHIFT-1);
 d:=a and INVSQ_LOOKUP_I_MASK;
 val:=(INVSQ_LOOKUP_I[i]-SARLongint(INVSQ_LOOKUP_IDel[i]*d,INVSQ_LOOKUP_I_SHIFT))*ADJUST_SQRT2[e and 1];
 e:=SARLongint(e,1)+21;
 result:=SARLongint(val,e);
end;

function vorbis_fromdBlook_i(a:longint):longint;
var i:longint;
begin
 i:=SARLongint(-a,12-FROMdB2_SHIFT);
 if i<0 then begin
  result:=$7fffffff;
 end else if i>=(FROMdB_LOOKUP_SZ shl FROMdB_SHIFT) then begin
  result:=0;
 end else begin
  result:=FROMdB_LOOKUP[SARLongint(i,FROMdB_SHIFT)]*FROMdB2_LOOKUP[i and FROMdB2_MASK];
 end;
end;

function vorbis_coslook_i(a:longint):longint;
var i,d:longint;
begin
 i:=SARLongint(a,COS_LOOKUP_I_SHIFT);
 d:=a and COS_LOOKUP_I_MASK;
 result:=COS_LOOKUP_I[i]-SARLongint((d*(COS_LOOKUP_I[i]-COS_LOOKUP_I[i+1])),COS_LOOKUP_I_SHIFT);
end;

function vorbis_coslook2_i(a:longint):longint;
var i,d:longint;
begin
 a:=a and $1ffff;
 if a>$10000 then begin
  a:=$20000-a;
 end;
 i:=SARLongint(a,COS_LOOKUP_I_SHIFT);
 d:=a and COS_LOOKUP_I_MASK;
 result:=SARLongint((COS_LOOKUP_I[i] shl COS_LOOKUP_I_SHIFT)-(d*(COS_LOOKUP_I[i]-COS_LOOKUP_I[i+1])),(COS_LOOKUP_I_SHIFT-LSP_FRACBITS)+14);
end;

function toBARK(n:longint):longint;
var i:longint;
begin
 i:=0;
 while i<27 do begin
  if (n>=barklook[i]) and (n<barklook[i+1]) then begin
   break;
  end;
  inc(i);
 end;
 if i=27 then begin
  result:=27 shl 15;
 end else begin
  result:=(i shl 15)+(((n-barklook[i]) shl 15) div (barklook[i+1]-barklook[i]));
 end;
end;

procedure vorbis_lsp_to_curve(curve:PLongints;map:PLongints;n,ln:longint;lsp:PLongints;m:longint;amp,ampoffset:longint;icos:PLongints);
var i,j,k,ampoffseti,ampi,val,qexp,shift,wi:longint;
    ilsp:PLongints;
    pi,qi:longword;
begin
 ampoffseti:=ampoffset*4096;
 ampi:=amp;
 GetMem(ilsp,m*SizeOf(longint));
 for i:=0 to m-1 do begin
  val:=MULT32(lsp[i],$517cc2);
  if (val<0) or (SARLongint(val,COS_LOOKUP_I_SHIFT)>=COS_LOOKUP_I_SZ) then begin
   FillChar(curve^,SizeOf(Longint)*n,AnsiChar(#0));
   FreeMem(ilsp);
   exit;
  end;
  ilsp^[i]:=vorbis_coslook_i(val);
 end;

 i:=0;
 while i<n do begin
  k:=map^[i];
  pi:=46341;
  qi:=46341;
  qexp:=0;
  wi:=icos[k];

  j:=1;
  if m>1 then begin
   qi:=qi*longword(abs(ilsp^[0]-wi));
   pi:=pi*longword(abs(ilsp^[1]-wi));
   inc(j,2);
   while j<m do begin
    shift:=MLOOP_1[(pi or qi) shr 25];
    if shift=0 then begin
     shift:=MLOOP_2[(pi or qi) shr 19];
     if shift=0 then begin
      shift:=MLOOP_3[(pi or qi) shr 16];
     end;
    end;
    qi:=(qi shr shift)*longword(abs(ilsp[j-1]-wi));
    pi:=(pi shr shift)*longword(abs(ilsp[j]-wi));
    inc(qexp,shift);
    inc(j,2);
   end;
  end;

  shift:=MLOOP_1[(pi or qi) shr 25];
  if shift=0 then begin
   shift:=MLOOP_2[(pi or qi) shr 19];
   if shift=0 then begin
    shift:=MLOOP_3[(pi or qi) shr 16];
   end;
  end;

  if (m and 1)<>0 then begin
   qi:=(qi shr shift)*longword(abs(ilsp^[j-1]-wi));
   pi:=(pi shr shift) shl 14;
   inc(qexp,shift);

   shift:=MLOOP_1[(pi or qi) shr 25];
   if shift=0 then begin
    shift:=MLOOP_2[(pi or qi) shr 19];
    if shift=0 then begin
     shift:=MLOOP_3[(pi or qi) shr 16];
    end;
   end;

   pi:=pi shr shift;
   qi:=qi shr shift;
   inc(qexp,shift-(14*SARLongint(m+1,1)));

   pi:=(pi*pi) shr 16;
   qi:=(qi*qi) shr 16;
   qexp:=(qexp*2)+m;

   pi:=pi*longword((1 shl 14)-SARLongint(wi*wi,14));
   inc(qi,pi shr 14);
  end else begin
   pi:=pi shr shift;
   qi:=qi shr shift;
   inc(qexp,shift-(7*m));

   pi:=(pi*pi) shr 16;
   qi:=(qi*qi) shr 16;
   qexp:=(qexp*2)+m;

   pi:=pi*longword((1 shl 14)-wi);
   qi:=qi*longword((1 shl 14)-wi);
   qi:=(qi+pi) shr 14;
  end;

  if (qi and $ffff0000)<>0 then begin
   qi:=qi shr 1;
   inc(qexp);
  end else begin
   while (qi<>0) and ((qi and $8000)=0) do begin
    qi:=qi shl 1;
    dec(qexp);
   end;
  end;

  amp:=vorbis_fromdBlook_i((ampi*vorbis_invsqlook_i(qi,qexp))-ampoffseti);
  curve^[i]:=MULT31_SHIFT15(curve^[i],amp);
  while true do begin
   inc(i);
   if map^[i]=k then begin
    curve^[i]:=MULT31_SHIFT15(curve^[i],amp);
   end else begin
    break;
   end;
  end;
 end;

 FreeMem(ilsp);
end;

procedure floor0_free_info(i:Pvorbis_info_floor);
begin
 if assigned(i) then begin
  FillChar(Pvorbis_info_floor0(i)^,SizeOf(vorbis_info_floor0),AnsiChar(#0));
  FreeMem(Pvorbis_info_floor0(i));
 end;
end;

procedure floor0_free_look(i:Pvorbis_look_floor);
begin
 if assigned(i) then begin
  if assigned(Pvorbis_look_floor0(i)^.linearmap) then begin
   FreeMem(Pvorbis_look_floor0(i)^.linearmap);
  end;
  if assigned(Pvorbis_look_floor0(i)^.lsp_look) then begin
   FreeMem(Pvorbis_look_floor0(i)^.lsp_look);
  end;
  FillChar(Pvorbis_look_floor0(i)^,SizeOf(vorbis_look_floor0),AnsiChar(#0));
  FreeMem(Pvorbis_look_floor0(i));
 end;
end;

function floor0_unpack(vi:Pvorbis_info;opb:Poggpack_buffer):Pvorbis_info_floor;
var ci:Pcodec_setup_info;
    j:longint;
    info:Pvorbis_info_floor0;
begin
 ci:=vi^.codec_setup;
 info:=Allocate(SizeOf(vorbis_info_floor0));
 info^.order:=oggpack_read(opb,8);
 info^.rate:=oggpack_read(opb,16);
 info^.barkmap:=oggpack_read(opb,16);
 info^.ampbits:=oggpack_read(opb,6);
 info^.ampdB:=oggpack_read(opb,8);
 info^.numbooks:=oggpack_read(opb,4)+1;
 if (info^.order<1) or (info^.rate<1) or (info^.barkmap<1) or (info^.numbooks<1) then begin
  FreeMem(info);
  result:=nil;
 end else begin
  for j:=0 to info^.numbooks-1 do begin
   info^.books[j]:=oggpack_read(opb,8);
   if ((info^.books[j]<0) or (info^.books[j]>=ci^.books)) or ((ci^.book_param[info^.books[j]]^.maptype=0) or (ci^.book_param[info^.books[j]]^.dim<1)) then begin
    FreeMem(info);
    result:=nil;
    exit;
   end;
  end;
  result:=pointer(info);
 end;
end;

function floor0_look(vd:Pvorbis_dsp_state;mi:Pvorbis_info_mode;i:Pvorbis_info_floor):Pvorbis_look_floor;
var j,val:longint;
    vi:Pvorbis_info;
    ci:Pcodec_setup_info;
    info:Pvorbis_info_floor0;
    look:Pvorbis_look_floor0;
begin
 vi:=vd^.vi;
 ci:=vi^.codec_setup;
 info:=pointer(i);
 look:=Allocate(SizeOf(vorbis_look_floor0));
 look^.m:=info^.order;
 look^.n:=ci^.blocksizes[mi^.blockflag] div 2;
 look^.ln:=info^.barkmap;
 look^.vi:=info;
 look^.linearmap:=Allocate(SizeOf(longint)*(look^.n+1));
 for j:=0 to look^.n-1 do begin
  val:=SARLongint(look^.ln*((toBARK(((info^.rate div 2)*j) div look^.n) shl 11) div toBARK(info^.rate div 2)),11);
  if val>=look^.ln then begin
   val:=look^.ln-1;
  end;
  look^.linearmap^[j]:=val;
 end;
 look^.linearmap^[look^.n]:=-1;
 look^.lsp_look:=Allocate(SizeOf(longint)*look^.ln);
 for j:=0 to look^.ln do begin
  look^.lsp_look^[j]:=vorbis_coslook2_i(($10000*j) div look^.ln);
 end;
 result:=pointer(look);
end;

function floor0_inverse1(vb:Pvorbis_block;i:Pvorbis_look_floor):pointer;
var look:Pvorbis_look_floor0;
    info:Pvorbis_info_floor0;
    j,k,ampraw,maxval,t,amp,booknum,last:longint;
    ci:Pcodec_setup_info;
    b:Pcodebook;
    lsp:PLongints;
begin
 result:=nil;
 look:=pointer(i);
 info:=look^.vi;
 ampraw:=oggpack_read(@vb^.opb,info^.ampbits);
 if ampraw>0 then begin
  maxval:=(1 shl info^.ampbits)-1;
  t:=ampraw*info^.ampdB;
  amp:=(t shl 4) div maxval;
  booknum:=oggpack_read(@vb^.opb,_ilog(info^.numbooks));
  if (booknum<>-1) and (booknum<info^.numbooks) then begin
   ci:=vb^.vd^.vi^.codec_setup;
   b:=ci^.fullbooks;
   inc(b,info^.books[booknum]);
   last:=0;
   lsp:=_vorbis_block_alloc(vb,sizeof(longint)*(look^.m+1));
   if vorbis_book_decodev_set(b,pointer(lsp),@vb^.opb,look^.m,-24)=-1 then begin
    exit;
   end;
   j:=0;
   while j<look^.m do begin
    k:=0;
    while (j<look^.m) and (k<b^.dim) do begin
     inc(lsp^[j],last);
     inc(j);
     inc(k);
    end;
    last:=lsp^[j-1];
   end;
   lsp^[look^.m]:=amp;
   result:=lsp;
  end;
 end;
end;

function floor0_inverse2(vb:Pvorbis_block;i:Pvorbis_look_floor;memo:pointer;out_:PLongints):longint;
var look:Pvorbis_look_floor0;
    info:Pvorbis_info_floor0;
    amp:longint;
    lsp:PLongints;
begin
 result:=0;
 look:=pointer(i);
 info:=look^.vi;
 if assigned(memo) then begin
  lsp:=memo;
  amp:=lsp^[look^.m];
  vorbis_lsp_to_curve(out_,look^.linearmap,look^.n,look^.ln,lsp,look^.m,amp,info^.ampdB,look^.lsp_look);
  result:=1;
 end;
end;

procedure floor1_free_info(i:Pvorbis_info_floor);
begin
 if assigned(i) then begin
  FillChar(Pvorbis_info_floor1(i)^,SizeOf(vorbis_info_floor1),AnsiChar(#0));
  FreeMem(Pvorbis_info_floor1(i));
 end;
end;

procedure floor1_free_look(i:Pvorbis_look_floor);
begin
 if assigned(i) then begin
  FillChar(Pvorbis_look_floor1(i)^,SizeOf(vorbis_look_floor1),AnsiChar(#0));
  FreeMem(Pvorbis_look_floor1(i));
 end;
end;

function icomp(const a,b:pointer):longint;
begin
 result:=pplongint(a)^^-pplongint(b)^^;
end;

function floor1_unpack(vi:Pvorbis_info;opb:Poggpack_buffer):Pvorbis_info_floor;
label err_out;
var ci:Pcodec_setup_info;
    j,k,count,maxclass,rangebits,t:longint;
    info:Pvorbis_info_floor1;
    sortpointer:array[0..VIF_POSIT+1] of plongint;
begin                             
 ci:=vi^.codec_setup;
 info:=Allocate(SizeOf(vorbis_info_floor1));
 info^.partitions:=oggpack_read(opb,5);
 maxclass:=0;
 for j:=0 to info^.partitions-1 do begin
  info^.partitionclass[j]:=oggpack_read(opb,4);
  if info^.partitionclass[j]<0 then begin
   goto err_out;
  end;
  if maxclass<info^.partitionclass[j] then begin
   maxclass:=info^.partitionclass[j];
  end;
 end;
 for j:=0 to maxclass do begin
  info^.class_dim[j]:=oggpack_read(opb,3)+1;
  info^.class_subs[j]:=oggpack_read(opb,2);
  if info^.class_subs[j]<0 then begin
   goto err_out;
  end;
  if info^.class_subs[j]<>0 then begin
   info^.class_book[j]:=oggpack_read(opb,8);
  end;
  if (info^.class_book[j]<0) or (info^.class_book[j]>=ci^.books) then begin
   goto err_out;
  end;
  for k:=0 to (1 shl info^.class_subs[j])-1 do begin
   info^.class_subbook[j,k]:=oggpack_read(opb,8)-1;
   if (info^.class_subbook[j,k]<-1) or (info^.class_subbook[j][k]>=ci^.books) then begin
    goto err_out;
   end;
  end;
 end;
 info^.mult:=oggpack_read(opb,2)+1;
 rangebits:=oggpack_read(opb,4);
 if rangebits<0 then begin
  goto err_out;
 end;
 k:=0;
 count:=0;
 for j:=0 to info^.partitions-1 do begin
  inc(count,info^.class_dim[info^.partitionclass[j]]);
  if count>VIF_POSIT then begin
   goto err_out;
  end;
  while k<count do begin
   t:=oggpack_read(opb,rangebits);
   info^.postlist[k+2]:=t;
   if (t<0) or (t>=(1 shl rangebits)) then begin
    goto err_out;
   end;
   inc(k);
  end;
 end;
 info^.postlist[0]:=0;
 info^.postlist[1]:=1 shl rangebits;
 for j:=0 to count+1 do begin
  sortpointer[j]:=@info^.postlist[j];
 end;
 qsort(@sortpointer,count+2,sizeof(plongint),icomp);
 for j:=1 to count+1 do begin
  if sortpointer[j-1]^=sortpointer[j]^ then begin
   goto err_out;
  end;
 end;
 result:=pointer(info);
 exit;
err_out:
 floor1_free_info(pointer(info));
 result:=nil;
end;

function floor1_look(vd:Pvorbis_dsp_state;mi:Pvorbis_info_mode;i_:Pvorbis_info_floor):Pvorbis_look_floor;
var sortpointer:array[0..VIF_POSIT+1] of plongint;
    info:Pvorbis_info_floor1;
    look:Pvorbis_look_floor1;
    i,j,n,lo,hi,lx,hx,currentx,x:longint;
begin
 info:=pointer(i_);
 look:=Allocate(SizeOf(vorbis_look_floor1));
 n:=0;
 look^.vi:=info;
 look^.n:=info^.postlist[1];
 for i:=0 to info^.partitions-1 do begin
  inc(n,info^.class_dim[info^.partitionclass[i]]);
 end;
 inc(n,2);
 look^.posts:=n;
 for i:=0 to n-1 do begin
  sortpointer[i]:=@info^.postlist[i];
 end;
 qsort(@sortpointer[0],n,sizeof(plongint),icomp);
 for i:=0 to n-1 do begin
  look^.forward_index[i]:=(BeRoAudioOGGPtrUInt(sortpointer[i])-BeRoAudioOGGPtrUInt(pointer(@info^.postlist[0]))) div sizeof(longint);
 end;
 case info^.mult of
  1:begin
   look^.quant_q:=256;
  end;
  2:begin
   look^.quant_q:=128;
  end;
  3:begin
   look^.quant_q:=86;
  end;
  4:begin
   look^.quant_q:=64;
  end;
 end;
 for i:=0 to n-3 do begin
  lo:=0;
  hi:=1;
  lx:=0;
  hx:=look^.n;
  currentx:=info^.postlist[i+2];
  for j:=0 to i+1 do begin
   x:=info^.postlist[j];
   if (x>lx) and (x<currentx) then begin
    lo:=j;
    lx:=x;
   end;
   if (x<hx) and (x>currentx) then begin
    hi:=j;
    hx:=x;
   end;
  end;
  look^.loneighbor[i]:=lo;
  look^.hineighbor[i]:=hi;
 end;
 result:=pointer(look);
end;

function render_point(x0,x1,y0,y1,x:longint):longint;
var dy,adx,ady,err,off:longint;
begin
 y0:=y0 and $7fff;
 y1:=y1 and $7fff;
 dy:=y1-y0;
 adx:=x1-x0;
 ady:=abs(dy);
 err:=ady*(x-x0);
 off:=err div adx;
 if dy<0 then begin
  result:=y0-off;
 end else begin
  result:=y0+off;
 end;
end;

const FLOOR_fromdB_LOOKUP:array[0..255] of longint=($000000e5,$000000f4,$00000103,$00000114,
                                                    $00000126,$00000139,$0000014e,$00000163,
                                                    $0000017a,$00000193,$000001ad,$000001c9,
                                                    $000001e7,$00000206,$00000228,$0000024c,
                                                    $00000272,$0000029b,$000002c6,$000002f4,
                                                    $00000326,$0000035a,$00000392,$000003cd,
                                                    $0000040c,$00000450,$00000497,$000004e4,
                                                    $00000535,$0000058c,$000005e8,$0000064a,
                                                    $000006b3,$00000722,$00000799,$00000818,
                                                    $0000089e,$0000092e,$000009c6,$00000a69,
                                                    $00000b16,$00000bcf,$00000c93,$00000d64,
                                                    $00000e43,$00000f30,$0000102d,$0000113a,
                                                    $00001258,$0000138a,$000014cf,$00001629,
                                                    $0000179a,$00001922,$00001ac4,$00001c82,
                                                    $00001e5c,$00002055,$0000226f,$000024ac,
                                                    $0000270e,$00002997,$00002c4b,$00002f2c,
                                                    $0000323d,$00003581,$000038fb,$00003caf,
                                                    $000040a0,$000044d3,$0000494c,$00004e10,
                                                    $00005323,$0000588a,$00005e4b,$0000646b,
                                                    $00006af2,$000071e5,$0000794c,$0000812e,
                                                    $00008993,$00009283,$00009c09,$0000a62d,
                                                    $0000b0f9,$0000bc79,$0000c8b9,$0000d5c4,
                                                    $0000e3a9,$0000f274,$00010235,$000112fd,
                                                    $000124dc,$000137e4,$00014c29,$000161bf,
                                                    $000178bc,$00019137,$0001ab4a,$0001c70e,
                                                    $0001e4a1,$0002041f,$000225aa,$00024962,
                                                    $00026f6d,$000297f0,$0002c316,$0002f109,
                                                    $000321f9,$00035616,$00038d97,$0003c8b4,
                                                    $000407a7,$00044ab2,$00049218,$0004de23,
                                                    $00052f1e,$0005855c,$0005e135,$00064306,
                                                    $0006ab33,$00071a24,$0007904b,$00080e20,
                                                    $00089422,$000922da,$0009bad8,$000a5cb6,
                                                    $000b091a,$000bc0b1,$000c8436,$000d5471,
                                                    $000e3233,$000f1e5f,$001019e4,$001125c1,
                                                    $00124306,$001372d5,$0014b663,$00160ef7,
                                                    $00177df0,$001904c1,$001aa4f9,$001c603d,
                                                    $001e384f,$00202f0f,$0022467a,$002480b1,
                                                    $0026dff7,$002966b3,$002c1776,$002ef4fc,
                                                    $0032022d,$00354222,$0038b828,$003c67c2,
                                                    $004054ae,$004482e8,$0048f6af,$004db488,
                                                    $0052c142,$005821ff,$005ddc33,$0063f5b0,
                                                    $006a74a7,$00715faf,$0078bdce,$0080967f,
                                                    $0088f1ba,$0091d7f9,$009b5247,$00a56a41,
                                                    $00b02a27,$00bb9ce2,$00c7ce12,$00d4ca17,
                                                    $00e29e20,$00f15835,$0101074b,$0111bb4e,
                                                    $01238531,$01367704,$014aa402,$016020a7,
                                                    $017702c3,$018f6190,$01a955cb,$01c4f9cf,
                                                    $01e269a8,$0201c33b,$0223265a,$0246b4ea,
                                                    $026c9302,$0294e716,$02bfda13,$02ed9793,
                                                    $031e4e09,$03522ee4,$03896ed0,$03c445e2,
                                                    $0402efd6,$0445ac4b,$048cbefc,$04d87013,
                                                    $05290c67,$057ee5ca,$05da5364,$063bb204,
                                                    $06a36485,$0711d42b,$0787710e,$0804b299,
                                                    $088a17ef,$0918287e,$09af747c,$0a50957e,
                                                    $0afc2f19,$0bb2ef7f,$0c759034,$0d44d6ca,
                                                    $0e2195bc,$0f0cad0d,$10070b62,$1111aeea,
                                                    $122da66c,$135c120f,$149e24d9,$15f525b1,
                                                    $176270e3,$18e7794b,$1a85c9ae,$1c3f06d1,
                                                    $1e14f07d,$200963d7,$221e5ccd,$2455f870,
                                                    $26b2770b,$29363e2b,$2be3db5c,$2ebe06b6,
                                                    $31c7a55b,$3503ccd4,$3875c5aa,$3c210f44,
                                                    $4009632b,$4432b8cf,$48a149bc,$4d59959e,
                                                    $52606733,$57bad899,$5d6e593a,$6380b298,
                                                    $69f80e9a,$70dafda8,$78307d76,$7fffffff);

procedure render_line(n,x0,x1,y0,y1:longint;d:PLongints);
var dy,adx,ady,base,sy,x,y,err:longint;
begin
 dy:=y1-y0;
 adx:=x1-x0;
 ady:=abs(dy);
 base:=dy div adx;
 if dy<0 then begin
  sy:=base-1;
 end else begin
  sy:=base+1;
 end;
 x:=x0;
 y:=y0;
 err:=0;
 if n>x1 then begin
  n:=x1;
 end;
 dec(ady,abs(base*adx));
 if x<n then begin
  d^[x]:=MULT31_SHIFT15(d^[x],FLOOR_fromdB_LOOKUP[y]);
//  writeln(d^[x]);
 end;
 inc(x);
 while x<n do begin
  inc(err,ady);
  if err>=adx then begin
   dec(err,adx);
   inc(y,sy);
  end else begin
   inc(y,base);
  end;
  d^[x]:=MULT31_SHIFT15(d^[x],FLOOR_fromdB_LOOKUP[y]);
//  writeln(d^[x]);
  inc(x);
 end;
end;

function floor1_inverse1(vb:Pvorbis_block;i_:Pvorbis_look_floor):pointer;
label eop;
var look:Pvorbis_look_floor1;
    info:Pvorbis_info_floor1;
    ci:Pcodec_setup_info;
    i,j,k,classv,cdim,csubbits,csub,cval,book,predicted,hiroom,loroom,room,val:longint;
    books:Pcodebooks;
    fit_value:plongints;
begin
 look:=pointer(i_);
 info:=look^.vi;
 ci:=vb^.vd^.vi^.codec_setup;
 books:=pointer(ci^.fullbooks);

 if oggpack_read(@vb^.opb,1)=1 then begin
  fit_value:=_vorbis_block_alloc(vb,look^.posts*sizeof(longint));
  fit_value^[0]:=oggpack_read(@vb^.opb,_ilog(look^.quant_q-1));
  fit_value^[1]:=oggpack_read(@vb^.opb,_ilog(look^.quant_q-1));

  j:=2;
  for i:=0 to info^.partitions-1 do begin
   classv:=info^.partitionclass[i];
   cdim:=info^.class_dim[classv];
   csubbits:=info^.class_subs[classv];
   csub:=1 shl csubbits;
   cval:=0;

   if csubbits<>0 then begin
    cval:=vorbis_book_decode(@books[info^.class_book[classv]],@vb^.opb);
    if cval=-1 then begin
     goto eop;
    end;
   end;

   for k:=0 to cdim-1 do begin
    book:=info^.class_subbook[classv,cval and (csub-1)];
    cval:=SARLongint(cval,csubbits);
    if book>=0 then begin
     fit_value^[j+k]:=vorbis_book_decode(@books[book],@vb^.opb);
     if fit_value^[j+k]=-1 then begin
      goto eop;
     end;
    end else begin
     fit_value[j+k]:=0;
    end;
   end;

   inc(j,cdim);
  end;

  for i:=2 to look^.posts-1 do begin
   predicted:=render_point(info^.postlist[look^.loneighbor[i-2]],
                           info^.postlist[look^.hineighbor[i-2]],
                           fit_value^[look^.loneighbor[i-2]],
                           fit_value^[look^.hineighbor[i-2]],
                           info^.postlist[i]);
// writeln(predicted,' ',look^.loneighbor[i-2],' ',look^.hineighbor[i-2],' ',info^.postlist[look^.loneighbor[i-2]],' ',info^.postlist[look^.hineighbor[i-2]],' ',fit_value^[look^.loneighbor[i-2]],' ',fit_value^[look^.hineighbor[i-2]],' ',info^.postlist[i]);
   hiroom:=look^.quant_q-predicted;
   loroom:=predicted;
   if hiroom<loroom then begin
    room:=hiroom shl 1;
   end else begin
    room:=loroom shl 1;
   end;
   val:=fit_value^[i];
   if val<>0 then begin
    if val>=room then begin
     if hiroom>loroom then begin
      dec(val,loroom);
     end else begin
      val:=(-1)-(val-hiroom);
     end;
    end else begin
     if (val and 1)<>0 then begin
      val:=-SARLongint(val+1,1);
     end else begin
      val:=SARLongint(val,1);
     end;
    end;
    fit_value^[i]:=(val+predicted) and $7fff;
    fit_value^[look^.loneighbor[i-2]]:=fit_value^[look^.loneighbor[i-2]] and $7fff;
    fit_value^[look^.hineighbor[i-2]]:=fit_value^[look^.hineighbor[i-2]] and $7fff;
   end else begin
    fit_value[i]:=predicted or $8000;
   end;
  end;

  result:=pointer(fit_value);
  exit;
 end;
eop:
 result:=nil;
end;

function floor1_inverse2(vb:Pvorbis_block;i_:Pvorbis_look_floor;memo:pointer;out_:PLongints):longint;
var look:Pvorbis_look_floor1;
    info:Pvorbis_info_floor1;
    ci:Pcodec_setup_info;
    n,j,hx,lx,ly,current,hy:longint;
//  books:Pcodebooks;
    fit_value:plongints;
begin
 look:=pointer(i_);
 info:=look^.vi;
 ci:=vb^.vd^.vi^.codec_setup;
//books:=pointer(ci^.fullbooks);
 n:=ci^.blocksizes[vb^.W] div 2;
 if assigned(memo) then begin
  fit_value:=memo;
  hx:=0;
  lx:=0;
  ly:=fit_value^[0]*info^.mult;
  if ly<0 then begin
   ly:=0;
  end else if ly>255 then begin
   ly:=255;
  end;
  for j:=1 to look^.posts-1 do begin
   current:=look^.forward_index[j];
   hy:=fit_value^[current] and $7fff;
// writeln(hy);
   if hy=fit_value^[current] then begin
    hx:=info^.postlist[current];
    hy:=hy*info^.mult;
    if hy<0 then begin
     hy:=0;
    end else if hy>255 then begin
     hy:=255;
    end;
//  writeln(lx,' ',ly,' ',hx,' ',hy,' ');
    render_line(n,lx,hx,ly,hy,out_);
//    writeln(ly,' ',hy);
    lx:=hx;
    ly:=hy;
   end;
  end;
  for j:=hx to n-1 do begin
   out_^[j]:=MULT31_SHIFT15(out_^[j],FLOOR_fromdB_LOOKUP[ly]);
  end;
  result:=1;
  exit;
 end;
 FillChar(out_^,n*sizeof(longint),AnsiChar(#0));
 result:=0;
end;

function ogg_buffer_create:Pogg_buffer_state;
begin
 result:=Allocate(SizeOf(ogg_buffer_state));
end;

procedure _ogg_buffer_destroy(bs:Pogg_buffer_state);
var bt,b:Pogg_buffer;
    rt,r:Pogg_reference;
begin
 if bs^.shutdown<>0 then begin
  bt:=bs^.unused_buffers;
  rt:=bs^.unused_references;
  while assigned(bt) do begin
   b:=bt;
   bt:=b^.ptr.next;
   if assigned(b^.data) then begin
    FreeMem(b^.data);
   end;
   FreeMem(b);
  end;
  bs^.unused_buffers:=nil;
  while assigned(rt) do begin
   r:=rt;
   rt:=r^.next;
   FreeMem(r);
  end;
  bs^.unused_references:=nil;
  if bs^.outstanding=0 then begin
   FreeMem(bs);
  end;
 end;
end;

procedure ogg_buffer_destroy(bs:Pogg_buffer_state);
begin
 bs^.shutdown:=1;
 _ogg_buffer_destroy(bs);
end;

function _fetch_buffer(bs:Pogg_buffer_state;bytes:longint):Pogg_buffer;
var ob:Pogg_buffer;
begin
 inc(bs^.outstanding);
 if assigned(bs^.unused_buffers) then begin
  ob:=bs^.unused_buffers;
  bs^.unused_buffers:=ob^.ptr.next;
  if ob^.size<bytes then begin
   ReallocMem(ob^.data,bytes);
   ob^.size:=bytes;
  end;
 end else begin
  ob:=Allocate(SizeOf(ogg_buffer));
  if bytes<16 then begin
   ob^.data:=Allocate(16);
  end else begin
   ob^.data:=Allocate(Bytes);
  end;
  ob^.size:=bytes;
 end;
 ob^.refcount:=1;
 ob^.ptr.owner:=bs;
 result:=ob;
end;

function _fetch_ref(bs:Pogg_buffer_state):Pogg_reference;
begin
 inc(bs^.outstanding);
 if assigned(bs^.unused_references) then begin
  result:=bs^.unused_references;
  bs^.unused_references:=result^.next;
 end else begin
  result:=Allocate(SizeOf(ogg_reference));
 end;
 result^.begin_:=0;
 result^.length:=0;
 result^.next:=nil;
end;

function ogg_buffer_alloc(bs:Pogg_buffer_state;bytes:longint):Pogg_reference;
var b:Pogg_buffer;
begin
 b:=_fetch_buffer(bs,bytes);
 result:=_fetch_ref(bs);
 result^.buffer:=b;
end;

procedure ogg_buffer_realloc(r:Pogg_reference;bytes:longint);
var b:Pogg_buffer;
begin
 b:=r^.buffer;
 if b^.size<bytes then begin
  ReallocMem(b^.data,bytes);
  b^.size:=bytes;
 end;
end;

procedure _ogg_buffer_mark_one(r:Pogg_reference);
begin
 inc(r^.buffer^.refcount);
end;

procedure ogg_buffer_mark(r:Pogg_reference);
begin
 while assigned(r) do begin
  _ogg_buffer_mark_one(r);
  r:=r^.next;
 end;
end;

function ogg_buffer_sub(r:Pogg_reference;begin_,length:longint):Pogg_reference;
var head,temp:Pogg_reference;
begin
 result:=nil;
 head:=nil;
 while assigned(r) and (begin_>=r^.length) do begin
  dec(begin_,r^.length);
  r:=r^.next;
 end;
 while assigned(r) and (length<>0) do begin
  temp:=_fetch_ref(r^.buffer^.ptr.owner);
  if assigned(head) then begin
   head^.next:=temp;
  end else begin
   result:=temp;
  end;
  head:=temp;
  head^.buffer:=r^.buffer;
  head^.begin_:=r^.begin_+begin_;
  head^.length:=length;
  if head^.length>(r^.length-begin_) then begin
   head^.length:=r^.length-begin_;
  end;
  begin_:=0;
  dec(length,head^.length);
  r:=r^.next;
 end;
 ogg_buffer_mark(result);
end;

function ogg_buffer_dup(r:Pogg_reference):Pogg_reference;
var head,temp:Pogg_reference;
begin
 result:=nil;
 head:=nil;
 while assigned(r) do begin
  temp:=_fetch_ref(r^.buffer^.ptr.owner);
  if assigned(head) then begin
   head^.next:=temp;
  end else begin
   result:=temp;
  end;
  head:=temp;
  head^.buffer:=r^.buffer;
  head^.begin_:=r^.begin_;
  head^.length:=r^.length;
  r:=r^.next;
 end;
 ogg_buffer_mark(result);
end;

function ogg_buffer_split(tail,head:PPogg_reference;pos:longint):Pogg_reference;
var r:Pogg_reference;
    lengthA,beginB,lengthB:longint;
begin
 result:=tail^;
 r:=tail^;
 while assigned(r) and (pos>r^.length) do begin
  dec(pos,r^.length);
  r:=r^.next;
 end;
 if (not assigned(r)) or (pos=0) then begin
  result:=nil;
  exit;
 end else begin
  if pos>=r^.length then begin
   if assigned(r^.next) then begin
    tail^:=r^.next;
    r^.next:=nil;
   end else begin
    tail^:=nil;
    head^:=nil;
   end;
  end else begin
   lengthA:=pos;
   beginB:=r^.begin_+pos;
   lengthB:=r^.length-pos;
   tail^:=_fetch_ref(r^.buffer^.ptr.owner);
   tail^^.buffer:=r^.buffer;
   tail^^.begin_:=beginB;
   tail^^.length:=lengthB;
   tail^^.next:=r^.next;
   _ogg_buffer_mark_one(tail^);
   if assigned(head) and (r=head^) then begin
    head^:=tail^;
   end;
   r^.next:=nil;
   r^.length:=lengthA;
  end;
 end;
end;

procedure ogg_buffer_release_one(r:Pogg_reference);
var ob:Pogg_buffer;
    bs:Pogg_buffer_state;
begin
 ob:=r^.buffer;
 bs:=ob^.ptr.owner;
 dec(ob^.refcount);
 if ob^.refcount=0 then begin
  dec(bs^.outstanding);
  ob^.ptr.next:=bs^.unused_buffers;
  bs^.unused_buffers:=ob;
 end;
 dec(bs^.outstanding);
 r^.next:=bs^.unused_references;
 bs^.unused_references:=r;
 _ogg_buffer_destroy(bs);
end;

procedure ogg_buffer_release(r:Pogg_reference);
var next:Pogg_reference;
begin
 while assigned(r) do begin
  next:=r^.next;
  ogg_buffer_release_one(r);
  r:=next;
 end;
end;

function ogg_buffer_pretruncate(r:Pogg_reference;pos:longint):Pogg_reference;
var next:Pogg_reference;
begin
 while assigned(r) and (pos>=r^.length) do begin
  next:=r^.next;
  dec(pos,r^.length);
  ogg_buffer_release_one(r);
  r:=next;
 end;
 if assigned(r) then begin
  inc(r^.begin_,pos);
  dec(r^.length,pos);
 end;
 result:=r;
end;

function ogg_buffer_walk(r:Pogg_reference):Pogg_reference;
begin
 if not assigned(r) then begin
  result:=nil;
  exit;
 end;
 while assigned(r^.next) do begin
  r:=r^.next;
 end;
 result:=r;
end;

function ogg_buffer_cat(tail,head:Pogg_reference):Pogg_reference;
begin
 if not assigned(tail) then begin
  result:=head;
  exit;
 end;
 while assigned(tail^.next) do begin
  tail:=tail^.next;
 end;
 tail^.next:=head;
 result:=ogg_buffer_walk(head);
end;

procedure _positionB(b:Poggbyte_buffer;pos:longint);
begin
 if pos<b^.pos then begin
  b^.ref:=b^.baseref;
  b^.pos:=0;
  b^.end_:=b^.pos+b^.ref^.length;
  b^.ptr:=@b^.ref^.buffer^.data[b^.ref^.begin_];
 end;
end;

procedure _positionF(b:Poggbyte_buffer;pos:longint);
begin
 while pos>=b^.end_ do begin
  inc(b^.pos,b^.ref^.length);
  b^.ref:=b^.ref^.next;
  b^.end_:=b^.ref^.length+b^.pos;
  b^.ptr:=@b^.ref^.buffer^.data[b^.ref^.begin_];
 end;
end;

function oggbyte_init(b:Poggbyte_buffer;r:Pogg_reference):longint;
begin
 FillChar(b^,SizeOf(oggbyte_buffer),AnsiChar(#0));
 if assigned(r) then begin
  b^.ref:=r;
  b^.baseref:=r;
  b^.pos:=0;
  b^.end_:=b^.ref^.length;
  b^.ptr:=@b^.ref^.buffer^.data[b^.ref^.begin_];
  result:=0;
 end else begin
  result:=-1;
 end;
end;

procedure oggbyte_set4(b:Poggbyte_buffer;val:ogg_uint32_t;pos:longint);
begin
 _positionB(b,pos);
 _positionF(b,pos);
 b^.ptr[pos-b^.pos]:=ansichar(byte(val and $ff));
 _positionF(b,pos+1);
 b^.ptr[(pos+1)-b^.pos]:=ansichar(byte((val shr 8) and $ff));
 _positionF(b,pos+2);
 b^.ptr[(pos+2)-b^.pos]:=ansichar(byte((val shr 16) and $ff));
 _positionF(b,pos+3);
 b^.ptr[(pos+3)-b^.pos]:=ansichar(byte((val shr 24) and $ff));
end;

function oggbyte_read1(b:Poggbyte_buffer;pos:longint):byte;
begin
 _positionB(b,pos);
 _positionF(b,pos);
 result:=byte(b^.ptr[pos-b^.pos]);
end;

function oggbyte_read4(b:Poggbyte_buffer;pos:longint):ogg_uint32_t;
begin
 _positionB(b,pos);
 _positionF(b,pos);
 result:=byte(b^.ptr[pos-b^.pos]);
 _positionF(b,pos+1);
 result:=result or (byte(b^.ptr[(pos+1)-b^.pos]) shl 8);
 _positionF(b,pos+2);
 result:=result or (byte(b^.ptr[(pos+2)-b^.pos]) shl 16);
 _positionF(b,pos+3);
 result:=result or (byte(b^.ptr[(pos+3)-b^.pos]) shl 24);
end;

function oggbyte_read8(b:Poggbyte_buffer;pos:longint):ogg_int64_t;
var t:array[0..6] of byte;
    i:longint;
begin
 _positionB(b,pos);
 for i:=0 to 6 do begin
  _positionF(b,pos);
  t[i]:=byte(b^.ptr[pos-b^.pos]);
  inc(pos);
 end;
 _positionF(b,pos);
 result:=byte(b^.ptr[pos-b^.pos]);
 for i:=6 downto 0 do begin
  result:=(result shl 8) or t[i];
 end;
end;

function ogg_page_version(og:Pogg_page):longint;
var ob:oggbyte_buffer;
begin
 oggbyte_init(@ob,og^.header);
 result:=oggbyte_read1(@ob,4);
end;

function ogg_page_continued(og:Pogg_page):longint;
var ob:oggbyte_buffer;
begin
 oggbyte_init(@ob,og^.header);
 result:=oggbyte_read1(@ob,5) and 1;
end;

function ogg_page_bos(og:Pogg_page):longint;
var ob:oggbyte_buffer;
begin
 oggbyte_init(@ob,og^.header);
 result:=oggbyte_read1(@ob,5) and 2;
end;

function ogg_page_eos(og:Pogg_page):longint;
var ob:oggbyte_buffer;
begin
 oggbyte_init(@ob,og^.header);
 result:=oggbyte_read1(@ob,5) and 4;
end;

function ogg_page_granulepos(og:Pogg_page):ogg_int64_t;
var ob:oggbyte_buffer;
begin
 oggbyte_init(@ob,og^.header);
 result:=oggbyte_read8(@ob,6);
end;

function ogg_page_serialno(og:Pogg_page):ogg_uint32_t;
var ob:oggbyte_buffer;
begin
 oggbyte_init(@ob,og^.header);
 result:=oggbyte_read4(@ob,14);
end;

function ogg_page_pageno(og:Pogg_page):ogg_uint32_t;
var ob:oggbyte_buffer;
begin
 oggbyte_init(@ob,og^.header);
 result:=oggbyte_read4(@ob,18);
end;

function ogg_page_packets(og:Pogg_page):longint;
var i,n:longint;
    ob:oggbyte_buffer;
begin
 result:=0;
 oggbyte_init(@ob,og^.header);
 n:=oggbyte_read1(@ob,26);
 for i:=0 to n-1 do begin
  if oggbyte_read1(@ob,27+i)<255 then begin
   inc(result);
  end;
 end;
end;

const crc_lookup:array[0..255] of ogg_uint32_t=($00000000,$04c11db7,$09823b6e,$0d4326d9,
                                                $130476dc,$17c56b6b,$1a864db2,$1e475005,
                                                $2608edb8,$22c9f00f,$2f8ad6d6,$2b4bcb61,
                                                $350c9b64,$31cd86d3,$3c8ea00a,$384fbdbd,
                                                $4c11db70,$48d0c6c7,$4593e01e,$4152fda9,
                                                $5f15adac,$5bd4b01b,$569796c2,$52568b75,
                                                $6a1936c8,$6ed82b7f,$639b0da6,$675a1011,
                                                $791d4014,$7ddc5da3,$709f7b7a,$745e66cd,
                                                $9823b6e0,$9ce2ab57,$91a18d8e,$95609039,
                                                $8b27c03c,$8fe6dd8b,$82a5fb52,$8664e6e5,
                                                $be2b5b58,$baea46ef,$b7a96036,$b3687d81,
                                                $ad2f2d84,$a9ee3033,$a4ad16ea,$a06c0b5d,
                                                $d4326d90,$d0f37027,$ddb056fe,$d9714b49,
                                                $c7361b4c,$c3f706fb,$ceb42022,$ca753d95,
                                                $f23a8028,$f6fb9d9f,$fbb8bb46,$ff79a6f1,
                                                $e13ef6f4,$e5ffeb43,$e8bccd9a,$ec7dd02d,
                                                $34867077,$30476dc0,$3d044b19,$39c556ae,
                                                $278206ab,$23431b1c,$2e003dc5,$2ac12072,
                                                $128e9dcf,$164f8078,$1b0ca6a1,$1fcdbb16,
                                                $018aeb13,$054bf6a4,$0808d07d,$0cc9cdca,
                                                $7897ab07,$7c56b6b0,$71159069,$75d48dde,
                                                $6b93dddb,$6f52c06c,$6211e6b5,$66d0fb02,
                                                $5e9f46bf,$5a5e5b08,$571d7dd1,$53dc6066,
                                                $4d9b3063,$495a2dd4,$44190b0d,$40d816ba,
                                                $aca5c697,$a864db20,$a527fdf9,$a1e6e04e,
                                                $bfa1b04b,$bb60adfc,$b6238b25,$b2e29692,
                                                $8aad2b2f,$8e6c3698,$832f1041,$87ee0df6,
                                                $99a95df3,$9d684044,$902b669d,$94ea7b2a,
                                                $e0b41de7,$e4750050,$e9362689,$edf73b3e,
                                                $f3b06b3b,$f771768c,$fa325055,$fef34de2,
                                                $c6bcf05f,$c27dede8,$cf3ecb31,$cbffd686,
                                                $d5b88683,$d1799b34,$dc3abded,$d8fba05a,
                                                $690ce0ee,$6dcdfd59,$608edb80,$644fc637,
                                                $7a089632,$7ec98b85,$738aad5c,$774bb0eb,
                                                $4f040d56,$4bc510e1,$46863638,$42472b8f,
                                                $5c007b8a,$58c1663d,$558240e4,$51435d53,
                                                $251d3b9e,$21dc2629,$2c9f00f0,$285e1d47,
                                                $36194d42,$32d850f5,$3f9b762c,$3b5a6b9b,
                                                $0315d626,$07d4cb91,$0a97ed48,$0e56f0ff,
                                                $1011a0fa,$14d0bd4d,$19939b94,$1d528623,
                                                $f12f560e,$f5ee4bb9,$f8ad6d60,$fc6c70d7,
                                                $e22b20d2,$e6ea3d65,$eba91bbc,$ef68060b,
                                                $d727bbb6,$d3e6a601,$dea580d8,$da649d6f,
                                                $c423cd6a,$c0e2d0dd,$cda1f604,$c960ebb3,
                                                $bd3e8d7e,$b9ff90c9,$b4bcb610,$b07daba7,
                                                $ae3afba2,$aafbe615,$a7b8c0cc,$a379dd7b,
                                                $9b3660c6,$9ff77d71,$92b45ba8,$9675461f,
                                                $8832161a,$8cf30bad,$81b02d74,$857130c3,
                                                $5d8a9099,$594b8d2e,$5408abf7,$50c9b640,
                                                $4e8ee645,$4a4ffbf2,$470cdd2b,$43cdc09c,
                                                $7b827d21,$7f436096,$7200464f,$76c15bf8,
                                                $68860bfd,$6c47164a,$61043093,$65c52d24,
                                                $119b4be9,$155a565e,$18197087,$1cd86d30,
                                                $029f3d35,$065e2082,$0b1d065b,$0fdc1bec,
                                                $3793a651,$3352bbe6,$3e119d3f,$3ad08088,
                                                $2497d08d,$2056cd3a,$2d15ebe3,$29d4f654,
                                                $c5a92679,$c1683bce,$cc2b1d17,$c8ea00a0,
                                                $d6ad50a5,$d26c4d12,$df2f6bcb,$dbee767c,
                                                $e3a1cbc1,$e760d676,$ea23f0af,$eee2ed18,
                                                $f0a5bd1d,$f464a0aa,$f9278673,$fde69bc4,
                                                $89b8fd09,$8d79e0be,$803ac667,$84fbdbd0,
                                                $9abc8bd5,$9e7d9662,$933eb0bb,$97ffad0c,
                                                $afb010b1,$ab710d06,$a6322bdf,$a2f33668,
                                                $bcb4666d,$b8757bda,$b5365d03,$b1f740b4);

function ogg_sync_create:Pogg_sync_state;
begin
 result:=Allocate(SizeOf(ogg_sync_state));
 result^.bufferpool:=ogg_buffer_create();
end;

function ogg_sync_destroy(oy:Pogg_sync_state):longint;
begin
 if assigned(oy) then begin
  ogg_sync_reset(oy);
  ogg_buffer_destroy(oy^.bufferpool);
  FillChar(oy^,SizeOf(ogg_sync_state),#0);
  FreeMem(oy);
 end;
 result:=OGG_SUCCESS;
end;

function ogg_sync_bufferin(oy:Pogg_sync_state;bytes:longint):pointer;
var n:Pogg_reference;
begin
 if not assigned(oy^.fifo_head) then begin
  oy^.fifo_head:=ogg_buffer_alloc(oy^.bufferpool,bytes);
  oy^.fifo_tail:=oy^.fifo_head;
  result:=oy^.fifo_head^.buffer^.data;
  exit;
 end;

 if ((oy^.fifo_head^.buffer^.size-oy^.fifo_head^.length)-oy^.fifo_head^.begin_)>=bytes then begin
  result:=@oy^.fifo_head^.buffer^.data[oy^.fifo_head^.length+oy^.fifo_head^.begin_];
  exit;
 end;

 if oy^.fifo_head^.length=0 then begin
  ogg_buffer_realloc(oy^.fifo_head,bytes);
  result:=@oy^.fifo_head^.buffer^.data[oy^.fifo_head^.begin_];
  exit;
 end;

 n:=ogg_buffer_alloc(oy^.bufferpool,bytes);
 oy^.fifo_head^.next:=n;
 oy^.fifo_head:=n;

 result:=oy^.fifo_head^.buffer^.data;
end;

function ogg_sync_wrote(oy:Pogg_sync_state;bytes:longint):longint;
begin
 if not assigned(oy^.fifo_head) then begin
  result:=OGG_EINVAL;
  exit;
 end;
 if ((oy^.fifo_head^.buffer^.size-oy^.fifo_head^.length)-oy^.fifo_head^.begin_)<bytes then begin
  result:=OGG_EINVAL;
  exit;
 end;
 inc(oy^.fifo_head^.length,bytes);
 inc(oy^.fifo_fill,bytes);
 result:=OGG_SUCCESS;
end;

function _checksum(r:Pogg_reference;bytes:longint):ogg_uint32_t;
var j,post:longint;
    data:PAnsiChar;
begin
 result:=0;
 while assigned(r) do begin
  data:=@r^.buffer^.data[r^.begin_];
  if bytes<r^.length then begin
   post:=bytes;
  end else begin
   post:=r^.length;
  end;
  for j:=0 to post-1 do begin
   result:=(result shl 8) xor crc_lookup[((result shr 24) and $ff) xor byte(data[j])];
  end;
  dec(bytes,post);
  r:=r^.next;
 end;
end;

function ogg_sync_pageseek(oy:Pogg_sync_state;og:Pogg_page):longint;
label sync_out,sync_fail;
var page:oggbyte_buffer;
    bytes,i:longint;
    chksum:ogg_uint32_t;
    now,next:PAnsiChar;
begin
 result:=0;

 ogg_page_release(og);

 bytes:=oy^.fifo_fill;
 oggbyte_init(@page,oy^.fifo_tail);

 if oy^.headerbytes=0 then begin
  if bytes<27 then begin
   goto sync_out;
  end;
  if (oggbyte_read1(@page,0)<>ord('O')) or (oggbyte_read1(@page,1)<>ord('g')) or (oggbyte_read1(@page,2)<>ord('g')) or (oggbyte_read1(@page,3)<>ord('S')) then begin
   goto sync_fail;
  end;
  oy^.headerbytes:=oggbyte_read1(@page,26)+27;
 end;
 if bytes<oy^.headerbytes then begin
  goto sync_out;
 end;
 if oy^.bodybytes=0 then begin
  for i:=0 to oy^.headerbytes-28 do begin
   inc(oy^.bodybytes,oggbyte_read1(@page,27+i));
  end;
 end;
  
 if (oy^.bodybytes+oy^.headerbytes)>bytes then begin
  goto sync_out;
 end;

 chksum:=oggbyte_read4(@page,22);
 oggbyte_set4(@page,0,22);
 if chksum<>_checksum(oy^.fifo_tail,oy^.bodybytes+oy^.headerbytes) then begin
  oggbyte_set4(@page,chksum,22);
  goto sync_fail;
 end;
 oggbyte_set4(@page,chksum,22);

 if assigned(og) then begin
  og^.header:=ogg_buffer_split(@oy^.fifo_tail,@oy^.fifo_head,oy^.headerbytes);
  og^.header_len:=oy^.headerbytes;
  og^.body:=ogg_buffer_split(@oy^.fifo_tail,@oy^.fifo_head,oy^.bodybytes);
  og^.body_len:=oy^.bodybytes;
 end else begin
  oy^.fifo_tail:=ogg_buffer_pretruncate(oy^.fifo_tail,oy^.headerbytes+oy^.bodybytes);
  if not assigned(oy^.fifo_tail) then begin
   oy^.fifo_head:=nil;
  end;
 end;

 result:=oy^.headerbytes+oy^.bodybytes;
 oy^.unsynced:=0;
 oy^.headerbytes:=0;
 oy^.bodybytes:=0;
 dec(oy^.fifo_fill,result);

 exit;

sync_fail:

 oy^.headerbytes:=0;
 oy^.bodybytes:=0;
 oy^.fifo_tail:=ogg_buffer_pretruncate(oy^.fifo_tail,1);
 dec(result);
 while assigned(oy^.fifo_tail) do begin
  now:=@oy^.fifo_tail^.buffer^.data[oy^.fifo_tail^.begin_];
  next:=memchr(now,'O',oy^.fifo_tail^.length);
  if assigned(next) then begin
   bytes:=next-now;
   oy^.fifo_tail:=ogg_buffer_pretruncate(oy^.fifo_tail,bytes);
   dec(result,bytes);
   break;
  end else begin
   bytes:=oy^.fifo_tail^.length;
   dec(result,bytes);
   oy^.fifo_tail:=ogg_buffer_pretruncate(oy^.fifo_tail,bytes);
  end;
 end;
 if not assigned(oy^.fifo_tail) then begin
  oy^.fifo_head:=nil;
 end;
 inc(oy^.fifo_fill,result);
sync_out:
end;

function ogg_sync_pageout(oy:Pogg_sync_state;og:Pogg_page):longint;
var r:longint;
begin
 while true do begin
  r:=ogg_sync_pageseek(oy,og);
  if r>0 then begin
   result:=1;
   exit;
  end else if r=0 then begin
   result:=0;
   exit;
  end;
  if oy^.unsynced=0 then begin
   oy^.unsynced:=1;
   result:=OGG_HOLE;
   exit;
  end;
 end;
end;

function ogg_sync_reset(oy:Pogg_sync_state):longint;
begin
 ogg_buffer_release(oy^.fifo_tail);
 oy^.fifo_tail:=nil;
 oy^.fifo_head:=nil;
 oy^.fifo_fill:=0;
 oy^.unsynced:=0;
 oy^.headerbytes:=0;
 oy^.bodybytes:=0;
 result:=OGG_SUCCESS;
end;

function ogg_stream_create(serialno:longint):Pogg_stream_state;
begin
 result:=Allocate(SizeOf(ogg_stream_state));
 result^.serialno:=serialno;
 result^.pageno:=-1;
end;

function ogg_stream_destroy(os:Pogg_stream_state):longint;
begin
 if assigned(os) then begin
  ogg_buffer_release(os^.header_tail);
  ogg_buffer_release(os^.body_tail);
  FillChar(os^,SizeOf(ogg_stream_state),#0);
  FreeMem(os);
 end;
 result:=OGG_SUCCESS;
end;

const FINFLAG=longword($80000000);
      FINMASK=longword($7fffffff);

procedure _next_lace(ob:Poggbyte_buffer;Os:Pogg_stream_state);
var val:longint;
begin
 os^.body_fill_next:=0;
 while os^.laceptr<os^.lacing_fill do begin
  val:=oggbyte_read1(ob,27+os^.laceptr);
  inc(os^.laceptr);
  inc(os^.body_fill_next,val);
  if val<255 then begin
   os^.body_fill_next:=os^.body_fill_next or FINFLAG;
   os^.clearflag:=1;
   break;
  end;
 end;
end;

procedure _span_queued_page(os:Pogg_stream_state);
var pageno:longint;
    ob:oggbyte_buffer;
    og:ogg_page;
begin
 while (os^.body_fill and FINFLAG)=0 do begin
  if not assigned(os^.header_tail) then begin
   break;
  end;
  if os^.lacing_fill>=0 then begin
   os^.header_tail:=ogg_buffer_pretruncate(os^.header_tail,os^.lacing_fill+27);
  end;
  os^.lacing_fill:=0;
  os^.laceptr:=0;
  os^.clearflag:=0;
  if not assigned(os^.header_tail) then begin
   os^.header_head:=nil;
   break;
  end else begin
   FillChar(og,SizeOf(ogg_page),AnsiChar(#0));
   og.header:=os^.header_tail;
   pageno:=ogg_page_pageno(@og);
   oggbyte_init(@ob,os^.header_tail);
   os^.lacing_fill:=oggbyte_read1(@ob,26);
   if pageno<>os^.pageno then begin
    if os^.pageno=-1 then begin
     os^.holeflag:=1;
    end else begin
     os^.holeflag:=2;
    end;
    os^.body_tail:=ogg_buffer_pretruncate(os^.body_tail,os^.body_fill);
    if not assigned(os^.body_tail) then begin
     os^.body_head:=nil;
    end;
    os^.body_fill:=0;
   end;
   if ogg_page_continued(@og)<>0 then begin
    if os^.body_fill=0 then begin
     _next_lace(@ob,os);
     os^.body_tail:=ogg_buffer_pretruncate(os^.body_tail,os^.body_fill_next and FINMASK);
     if not assigned(os^.body_tail) then begin
      os^.body_head:=nil;
     end;
     if (os^.spanflag=0) and (os^.holeflag=0) then begin
      os^.spanflag:=2;
     end;
    end;
   end else begin
    if os^.body_fill>0 then begin
     os^.body_tail:=ogg_buffer_pretruncate(os^.body_tail,os^.body_fill);
     if not assigned(os^.body_tail) then begin
      os^.body_head:=nil;
     end;
     os^.body_fill:=0;
     if (os^.spanflag=0) and (os^.holeflag=0) then begin
      os^.spanflag:=2;
     end;
    end;
   end;
   if os^.laceptr<os^.lacing_fill then begin
    os^.granulepos:=ogg_page_granulepos(@og);
    _next_lace(@ob,os);
    inc(os^.body_fill,os^.body_fill_next);
    _next_lace(@ob,os);
   end;
   os^.pageno:=pageno+1;
   os^.e_o_s:=ogg_page_eos(@og);
   os^.b_o_s:=ogg_page_bos(@og);
  end;
 end;
end;

function ogg_stream_pagein(os:Pogg_stream_state;og:Pogg_page):longint;
var serialno,version:longint;
begin
 serialno:=ogg_page_serialno(og);
 version:=ogg_page_version(og);
 if serialno<>os^.serialno then begin
  ogg_page_release(og);
  result:=OGG_ESERIAL;
  exit;
 end;
 if version>0 then begin
  ogg_page_release(og);
  result:=OGG_EVERSION;
  exit;
 end;
 if not assigned(os^.body_tail) then begin
  os^.body_tail:=og^.body;
  os^.body_head:=ogg_buffer_walk(og^.body);
 end else begin
  os^.body_head:=ogg_buffer_cat(os^.body_head,og^.body);
 end;
 if not assigned(os^.header_tail) then begin
  os^.header_tail:=og^.header;
  os^.header_head:=ogg_buffer_walk(og^.header);
  os^.lacing_fill:=-27;
 end else begin
  os^.header_head:=ogg_buffer_cat(os^.header_head,og^.header);
 end;
 FillChar(og^,SizeOf(ogg_page),AnsiChar(#0));
 result:=OGG_SUCCESS;
end;

function ogg_stream_reset(os:Pogg_stream_state):longint;
begin
 ogg_buffer_release(os^.header_tail);
 ogg_buffer_release(os^.body_tail);
 os^.header_tail:=nil;
 os^.header_head:=nil;
 os^.body_tail:=nil;
 os^.body_head:=nil;
 os^.e_o_s:=0;
 os^.b_o_s:=0;
 os^.pageno:=-1;
 os^.packetno:=0;
 os^.granulepos:=0;
 os^.body_fill:=0;
 os^.lacing_fill:=0;
 os^.holeflag:=0;
 os^.spanflag:=0;
 os^.clearflag:=0;
 os^.laceptr:=0;
 os^.body_fill_next:=0;
 result:=OGG_SUCCESS;
end;

function ogg_stream_reset_serialno(os:Pogg_stream_state;serialno:longint):longint;
begin
 ogg_stream_reset(os);
 os^.serialno:=serialno;
 result:=OGG_SUCCESS;
end;

function _packetout(os:Pogg_stream_state;op:Pogg_packet;adv:longint):longint;
var temp:longint;
    ob:oggbyte_buffer;
begin
 ogg_packet_release(op);
 _span_queued_page(os);
 if os^.holeflag<>0 then begin
  temp:=os^.holeflag;
  if os^.clearflag<>0 then begin
   os^.holeflag:=0;
  end else begin
   os^.holeflag:=1;
  end;
  if temp=2 then begin
   inc(os^.packetno);
   result:=OGG_HOLE;
   exit;
  end;
 end; 
 if os^.spanflag<>0 then begin
  temp:=os^.spanflag;
  if os^.clearflag<>0 then begin
   os^.spanflag:=0;
  end else begin
   os^.spanflag:=1;
  end;
  if temp=2 then begin
   inc(os^.packetno);
   result:=OGG_SPAN;
   exit;
  end;
 end;
 if (os^.body_fill and FINFLAG)=0 then begin
  result:=0;
  exit;
 end;
 if (not assigned(op)) and (adv=0) then begin
  result:=1;
  exit;
 end;
 if assigned(op) then begin
  op^.b_o_s:=os^.b_o_s;
  if (os^.e_o_s<>0) and (os^.body_fill_next=0) then begin
   op^.e_o_s:=os^.e_o_s;
  end else begin
   op^.e_o_s:=0;
  end;
  if ((os^.body_fill and FINFLAG)<>0) and ((os^.body_fill_next and FINFLAG)=0) then begin
   op^.granulepos:=os^.granulepos;
  end else begin
   op^.granulepos:=-1;
  end;
  op^.packetno:=os^.packetno;
 end;

 if adv<>0 then begin
  oggbyte_init(@ob,os^.header_tail);
  if assigned(op) then begin
   op^.packet:=ogg_buffer_split(@os^.body_tail,@os^.body_head,os^.body_fill and FINMASK);
   op^.bytes:=os^.body_fill and FINMASK;
  end else begin
   os^.body_tail:=ogg_buffer_pretruncate(os^.body_tail,os^.body_fill and FINMASK);
   if not assigned(os^.body_tail) then begin
    os^.body_head:=nil;
   end;
  end;
  os^.body_fill:=os^.body_fill_next;
  _next_lace(@ob,os);
 end else begin
  if assigned(op) then begin
   op^.packet:=ogg_buffer_sub(os^.body_tail,0,os^.body_fill and FINMASK);
   op^.bytes:=os^.body_fill and FINMASK;
  end;
 end;

 if adv<>0 then begin
  inc(os^.packetno);
  os^.b_o_s:=0;
 end;
 result:=1;
end;

function ogg_stream_packetout(os:Pogg_stream_state;op:Pogg_packet):longint;
begin
 result:=_packetout(os,op,1);
end;

function ogg_stream_packetpeek(os:Pogg_stream_state;op:Pogg_packet):longint;
begin
 result:=_packetout(os,op,0);
end;

function ogg_packet_release(op:Pogg_packet):longint;
begin
 if assigned(op) then begin
  ogg_buffer_release(op^.packet);
  FillChar(op^,SizeOf(ogg_packet),AnsiChar(#0));
 end;
 result:=OGG_SUCCESS;
end;

function ogg_page_release(og:Pogg_page):longint;
begin
 if assigned(og) then begin
  ogg_buffer_release(og^.header);
  ogg_buffer_release(og^.body);
  FillChar(og^,SizeOf(ogg_page),AnsiChar(#0));
 end;
 result:=OGG_SUCCESS;
end;

procedure ogg_page_dup(dup,orig:Pogg_page);
begin
 dup^.header_len:=orig^.header_len;
 dup^.body_len:=orig^.body_len;
 dup^.header:=ogg_buffer_dup(orig^.header);
 dup^.body:=ogg_buffer_dup(orig^.body);
end;

procedure _v_readstring(o:Poggpack_buffer;buf:PAnsiChar;bytes:longint);
var i:longint;
begin
 for i:=0 to bytes-1 do begin
  buf[i]:=ansichar(byte(oggpack_read(o,8)));
 end;
end;

procedure vorbis_comment_init(vc:Pvorbis_comment);
begin
 FillChar(vc^,SizeOf(vorbis_comment),AnsiChar(#0));
end;

function tagcompare(s1,s2:PAnsiChar;n:longint):longint;
var c:longint;
begin
 result:=0;
 for c:=0 to n-1 do begin
  if upcase(s1[c])<>upcase(s2[c]) then begin
   result:=-1;
   break;
  end;
 end;
end;

function vorbis_comment_query(vc:Pvorbis_comment;tag:PAnsiChar;count:longint):PAnsiChar;
var i,found,taglen:longint;
    fulltag:ansistring;
begin
 result:=nil;
 found:=0;
 taglen:=system.length(tag)+1;
 fulltag:=tag+'=';
 for i:=0 to vc^.comments-1 do begin
  if tagcompare(PPointers(vc^.user_comments)^[i],PAnsiChar(fulltag),taglen)=0 then begin
   if count=found then begin
    result:=@PAnsiChar(PPointers(vc^.user_comments)^[i])[taglen];
    exit;
   end else begin
    inc(found);
   end;
  end;
 end;
end;

function vorbis_comment_query_count(vc:Pvorbis_comment;tag:PAnsiChar):longint;
var i,taglen:longint;
    fulltag:ansistring;
begin
 result:=0;
 taglen:=system.length(tag)+1;
 fulltag:=tag+'=';
 for i:=0 to vc^.comments-1 do begin
  if tagcompare(PPointers(vc^.user_comments)^[i],PAnsiChar(fulltag),taglen)=0 then begin
   inc(result);
  end;
 end;
end;

procedure vorbis_comment_clear(vc:Pvorbis_comment);
var i:longint;
begin
 if assigned(vc) then begin
  for i:=0 to vc^.comments-1 do begin
   if assigned(PPointers(vc^.user_comments)^[i]) then begin
    FreeMem(PPointers(vc^.user_comments)^[i]);
   end;
  end;
  if assigned(vc^.user_comments) then begin
   FreeMem(vc^.user_comments);
  end;
  if assigned(vc^.comment_lengths) then begin
   FreeMem(vc^.comment_lengths);
  end;
  if assigned(vc^.vendor) then begin
   FreeMem(vc^.vendor);
  end;
  FillChar(vc^,SizeOf(vorbis_comment),AnsiChar(#0));
 end;
end; 

function vorbis_info_blocksize(vi:Pvorbis_info;zo:longint):longint;
var ci:Pcodec_setup_info;
begin
 ci:=vi^.codec_setup;
 if assigned(ci) then begin
  result:=ci^.blocksizes[zo];
 end else begin
  result:=-1;
 end;
end;

procedure vorbis_info_init(vi:Pvorbis_info);
begin
 FillChar(vi^,SizeOf(vorbis_info),AnsiChar(#0));
 vi^.codec_setup:=Allocate(sizeof(codec_setup_info));
end;

procedure vorbis_info_clear(vi:Pvorbis_info);
var ci:Pcodec_setup_info;
    i:longint;
begin
 ci:=vi^.codec_setup;
 if assigned(ci) then begin
  for i:=0 to ci^.modes-1 do begin
   if assigned(ci^.mode_param[i]) then begin
    FreeMem(ci^.mode_param[i]);
   end;
  end;
  for i:=0 to ci^.maps-1 do begin
   if assigned(ci^.map_param[i]) then begin
    _mapping_P[ci^.map_type[i]]^.free_info(ci^.map_param[i]);
   end;
  end;
  for i:=0 to ci^.floors-1 do begin
   if assigned(ci^.floor_param[i]) then begin
    _floor_P[ci^.floor_type[i]]^.free_info(ci^.floor_param[i]);
   end;
  end;
  for i:=0 to ci^.residues-1 do begin
   if assigned(ci^.residue_param[i]) then begin
    _residue_P[ci^.residue_type[i]]^.free_info(ci^.residue_param[i]);
   end;
  end;
  for i:=0 to ci^.books-1 do begin
   if assigned(ci^.book_param[i]) then begin
    vorbis_staticbook_destroy(ci^.book_param[i]);
   end;
   if assigned(ci^.fullbooks) then begin
    vorbis_book_clear(@Pcodebooks(ci^.fullbooks)^[i]);
   end;
  end;
  if assigned(ci^.fullbooks) then begin
   FreeMem(ci^.fullbooks);
  end;
  FreeMem(ci);
 end;
 FillChar(vi^,SizeOf(vorbis_info),AnsiChar(#0));
end;

function _vorbis_unpack_info(vi:Pvorbis_info;opb:Poggpack_buffer):longint;
label err_out;
var ci:Pcodec_setup_info;
begin
 ci:=vi^.codec_setup;
 if not assigned(ci) then begin
  result:=OV_EFAULT;
  exit;
 end;

 vi^.version:=oggpack_read(opb,32);
 if vi^.version<>0 then begin
  result:=OV_EVERSION;
  exit;
 end;

 vi^.channels:=oggpack_read(opb,8);
 vi^.rate:=oggpack_read(opb,32);

 vi^.bitrate_upper:=oggpack_read(opb,32);
 vi^.bitrate_nominal:=oggpack_read(opb,32);
 vi^.bitrate_lower:=oggpack_read(opb,32);

 ci^.blocksizes[0]:=1 shl oggpack_read(opb,4);
 ci^.blocksizes[1]:=1 shl oggpack_read(opb,4);
  
 if vi^.rate<1 then begin
  goto err_out;
 end;
 if vi^.channels<1 then begin
  goto err_out;
 end;
 if ci^.blocksizes[0]<64 then begin
  goto err_out;
 end;
 if ci^.blocksizes[1]<ci^.blocksizes[0] then begin
  goto err_out;
 end;
 if ci^.blocksizes[1]>8192 then begin
  goto err_out;
 end;
  
 if oggpack_read(opb,1)<>1 then begin
  goto err_out;
 end;

 result:=0;
 exit;
err_out:
 vorbis_info_clear(vi);
 result:=OV_EBADHEADER;
end;

function _vorbis_unpack_comment(vc:Pvorbis_comment;opb:Poggpack_buffer):longint;
label err_out;
var i,vendorlen,len:longint;
begin
 vendorlen:=oggpack_read(opb,32);
 if vendorlen<0 then begin
  goto err_out;
 end;
 vc^.vendor:=Allocate(vendorlen+1);
 _v_readstring(opb,vc^.vendor,vendorlen);
 vc^.comments:=oggpack_read(opb,32);
 if vc^.comments<0 then begin
  goto err_out;
 end;                   
 vc^.user_comments:=Allocate((vc^.comments+1)*SizeOf(PAnsiChar));
 vc^.comment_lengths:=Allocate((vc^.comments+1)*SizeOf(longint));
 for i:=0 to vc^.comments-1 do begin
  len:=oggpack_read(opb,32);
  if len<0 then begin
   goto err_out;
  end;
  PLongints(vc^.comment_lengths)^[i]:=len;
  PPointers(vc^.user_comments)^[i]:=Allocate(len+1);
  _v_readstring(opb,PPointers(vc^.user_comments)^[i],len);
 end;
 if oggpack_read(opb,1)<>1 then begin
  goto err_out;
 end;
 result:=0;
 exit;
err_out:
 vorbis_comment_clear(vc);
 result:=OV_EBADHEADER;
end;

function _vorbis_unpack_books(vi:Pvorbis_info;opb:Poggpack_buffer):longint;
label err_out;
var ci:Pcodec_setup_info;
    i:longint;
begin
 ci:=vi^.codec_setup;
 if not assigned(ci) then begin
  result:=OV_EFAULT;
  exit;
 end;
 ci^.books:=oggpack_read(opb,8)+1;

 for i:=0 to ci^.books-1 do begin
  ci^.book_param[i]:=vorbis_staticbook_unpack(opb);
  if not assigned(ci^.book_param[i]) then begin
   goto err_out;
  end;
 end;

 ci^.times:=oggpack_read(opb,6)+1;
 for i:=0 to ci^.times-1 do begin
  ci^.time_type[i]:=oggpack_read(opb,16);
  if (ci^.time_type[i]<0) or (ci^.time_type[i]>=VI_TIMEB) then begin
   goto err_out;
  end;
 end;

 ci^.floors:=oggpack_read(opb,6)+1;
 for i:=0 to ci^.floors-1 do begin
  ci^.floor_type[i]:=oggpack_read(opb,16);
  if (ci^.floor_type[i]<0) or (ci^.floor_type[i]>=VI_FLOORB) then begin
   goto err_out;
  end;
  ci^.floor_param[i]:=_floor_P[ci^.floor_type[i]]^.unpack(vi,opb);
  if not assigned(ci^.floor_param[i]) then begin
   goto err_out;
  end;
 end;

 ci^.residues:=oggpack_read(opb,6)+1;
 for i:=0 to ci^.residues-1 do begin
  ci^.residue_type[i]:=oggpack_read(opb,16);
  if (ci^.residue_type[i]<0) or (ci^.residue_type[i]>=VI_RESB) then begin
   goto err_out;
  end;
  ci^.residue_param[i]:=_residue_P[ci^.residue_type[i]]^.unpack(vi,opb);
  if not assigned(ci^.residue_param[i]) then begin
   goto err_out;
  end;
 end;

 ci^.maps:=oggpack_read(opb,6)+1;
 for i:=0 to ci^.maps-1 do begin
  ci^.map_type[i]:=oggpack_read(opb,16);
  if (ci^.map_type[i]<0) or (ci^.map_type[i]>=VI_MAPB) then begin
   goto err_out;
  end;
  ci^.map_param[i]:=_mapping_P[ci^.map_type[i]]^.unpack(vi,opb);
  if not assigned(ci^.map_param[i]) then begin
   goto err_out;
  end;
 end;

 ci^.modes:=oggpack_read(opb,6)+1;
 for i:=0 to ci^.modes-1 do begin
  ci^.mode_param[i]:=Allocate(SizeOf(vorbis_info_mode));
  ci^.mode_param[i]^.blockflag:=oggpack_read(opb,1);
  ci^.mode_param[i]^.windowtype:=oggpack_read(opb,16);
  ci^.mode_param[i]^.transformtype:=oggpack_read(opb,16);
  ci^.mode_param[i]^.mapping:=oggpack_read(opb,8);
  if ci^.mode_param[i]^.windowtype>=VI_WINDOWB then begin
   goto err_out;
  end;
  if ci^.mode_param[i]^.transformtype>=VI_WINDOWB then begin
   goto err_out;
  end;
  if ci^.mode_param[i]^.mapping>=ci^.maps then begin
   goto err_out;
  end;
 end;

 if oggpack_read(opb,1)<>1 then begin
  goto err_out;
 end;

 result:=0;
 exit;
err_out:
 vorbis_info_clear(vi);
 result:=OV_EBADHEADER;
end;

function vorbis_synthesis_idheader(op:Pogg_packet):longint;
var opb:oggpack_buffer;
    buffer:array[0..5] of ansichar;
begin
 if assigned(op) then begin
  oggpack_readinit(@opb,op^.packet);
  if op^.b_o_s=0 then begin
   result:=0;
   exit;
  end;
  if oggpack_read(@opb,8)<>1 then begin
   result:=0;
   exit;
  end;
  FillChar(buffer,SizeOf(buffer),AnsiChar(#0));
  _v_readstring(@opb,buffer,6);
  if buffer<>'vorbis' then begin
   result:=0;
   exit;
  end;
  result:=1;
  exit;
 end;
 result:=0;
end;

function vorbis_synthesis_headerin(vi:Pvorbis_info;vc:Pvorbis_comment;op:Pogg_packet):longint;
var opb:oggpack_buffer;
    buffer:array[0..5] of ansichar;
    packtype:longint;
begin
 if assigned(op) then begin
  oggpack_readinit(@opb,op^.packet);
  packtype:=oggpack_read(@opb,8);
  FillChar(buffer,SizeOf(buffer),AnsiChar(#0));
  _v_readstring(@opb,buffer,6);
  if buffer<>'vorbis' then begin
   result:=OV_ENOTVORBIS;
   exit;
  end;
  case packtype of
   $01:begin
    if op^.b_o_s=0 then begin
     result:=OV_EBADHEADER;
     exit;
    end;
    if vi^.rate<>0 then begin
     result:=OV_EBADHEADER;
     exit;
    end;
    result:=_vorbis_unpack_info(vi,@opb);
    exit;
   end;
   $03:begin
    if vi^.rate=0 then begin
     result:=OV_EBADHEADER;
     exit;
    end;
    result:=_vorbis_unpack_comment(vc,@opb);
    exit;
   end;
   $05:begin
    if (vi^.rate=0) or not assigned(vc^.vendor) then begin
     result:=OV_EBADHEADER;
     exit;
    end;
    result:=_vorbis_unpack_books(vi,@opb);
    exit;
   end;
   else begin
    result:=OV_EBADHEADER;
    exit;
   end;
  end;
 end;
 result:=OV_EBADHEADER;
end;

procedure mapping0_free_info(i:Pvorbis_info_mapping);
begin
 if assigned(i) then begin
  FillChar(Pvorbis_info_mapping0(i)^,SizeOf(vorbis_info_mapping0),AnsiChar(#0));
  FreeMem(Pvorbis_info_mapping0(i));
 end;
end;

procedure mapping0_free_look(l:Pvorbis_look_mapping);
var look:Pvorbis_look_mapping0;
    i:longint;
begin
 look:=pointer(l);;
 if assigned(look) then begin
  for i:=0 to look^.map^.submaps-1 do begin
   Pvorbis_func_floor(PPointers(look^.floor_func)^[i])^.free_look(Pvorbis_look_floor(PPointers(look^.floor_look)^[i]));
   Pvorbis_func_residue(PPointers(look^.residue_func)^[i])^.free_look(Pvorbis_look_residue(PPointers(look^.residue_look)^[i]));
  end;
  FreeMem(look^.floor_func);
  FreeMem(look^.residue_func);
  FreeMem(look^.floor_look);
  FreeMem(look^.residue_look);
  if assigned(look^.pcmbundle) then begin
   FreeMem(look^.pcmbundle);
  end;
  if assigned(look^.zerobundle) then begin
   FreeMem(look^.zerobundle);
  end;
  if assigned(look^.nonzero) then begin
   FreeMem(look^.nonzero);
  end;
  if assigned(look^.floormemo) then begin
   FreeMem(look^.floormemo);
  end;
  FillChar(look^,SizeOf(vorbis_look_mapping0),AnsiChar(#0));
  FreeMem(look);
 end;
end;

function mapping0_look(vd:Pvorbis_dsp_state;vm:Pvorbis_info_mode;m:Pvorbis_info_mapping):Pvorbis_look_mapping;
var i,floornum,resnum:longint;
    vi:Pvorbis_info;
    ci:Pcodec_setup_info;
    look:Pvorbis_look_mapping0;
    info:Pvorbis_info_mapping0;
begin
 vi:=vd^.vi;
 ci:=vi^.codec_setup;
 look:=Allocate(SizeOf(vorbis_look_mapping0));
 info:=Pvorbis_info_mapping0(m);
 look^.map:=Pvorbis_info_mapping0(m);
 look^.mode:=vm;
 look^.floor_look:=Allocate(info^.submaps*SizeOf(Pvorbis_look_floor));
 look^.residue_look:=Allocate(info^.submaps*SizeOf(Pvorbis_look_residue));
 look^.floor_func:=Allocate(info^.submaps*SizeOf(Pvorbis_func_floor));
 look^.residue_func:=Allocate(info^.submaps*SizeOf(Pvorbis_func_residue));
 for i:=0 to info^.submaps-1 do begin
  floornum:=info^.floorsubmap[i];
  resnum:=info^.residuesubmap[i];
  PPointers(look^.floor_func)^[i]:=_floor_P[ci^.floor_type[floornum]];
  PPointers(look^.floor_look)^[i]:=Pvorbis_func_floor(PPointers(look^.floor_func)^[i])^.look(vd,vm,ci^.floor_param[floornum]);
  PPointers(look^.residue_func)^[i]:=_residue_P[ci^.residue_type[resnum]];
  PPointers(look^.residue_look)^[i]:=Pvorbis_func_residue(PPointers(look^.residue_func)^[i])^.look(vd,vm,ci^.residue_param[resnum]);
 end;
 look^.ch:=vi^.channels;
 result:=pointer(look);
end;

function mapping0_unpack(vi:Pvorbis_info;opb:Poggpack_buffer):Pvorbis_info_mapping;
label err_out;
var i,testM,testA,temp:longint;
    info:Pvorbis_info_mapping0;
    ci:Pcodec_setup_info;
begin
 info:=Allocate(SizeOf(vorbis_info_mapping0));
 ci:=vi^.codec_setup;

 if oggpack_read(opb,1)<>0 then begin
  info^.submaps:=oggpack_read(opb,4)+1;
 end else begin
  info^.submaps:=1;
 end;

 if oggpack_read(opb,1)<>0 then begin
  info^.coupling_steps:=oggpack_read(opb,8)+1;
  for i:=0 to info^.coupling_steps-1 do begin
   testM:=oggpack_read(opb,ilog(vi^.channels));
   info^.coupling_mag[i]:=testM;
   testA:=oggpack_read(opb,ilog(vi^.channels));
   info^.coupling_ang[i]:=testA;
   if (testM<0) or (testA<0) or (testM=testA) or (testM>=vi^.channels) or (testA>=vi^.channels) then begin
    goto err_out;
   end;
  end;
 end;

 if oggpack_read(opb,2)>0 then begin
  goto err_out;
 end;
 if info^.submaps>1 then begin
  for i:=0 to vi^.channels-1 do begin
   info^.chmuxlist[i]:=oggpack_read(opb,4);
   if info^.chmuxlist[i]>=info^.submaps then begin
    goto err_out;
   end;
  end;
 end;
 for i:=0 to info^.submaps-1 do begin
  temp:=oggpack_read(opb,8);
  if temp>=ci^.times then begin
   goto err_out;
  end;
  info^.floorsubmap[i]:=oggpack_read(opb,8);
  if info^.floorsubmap[i]>=ci^.floors then begin
   goto err_out;
  end;
  info^.residuesubmap[i]:=oggpack_read(opb,8);
  if info^.residuesubmap[i]>=ci^.residues then begin
   goto err_out;
  end;
 end;
 result:=pointer(info);
 exit;
err_out:
 mapping0_free_info(pointer(info));
 result:=nil;
end;

const seq:longint=0;

function mapping0_inverse(vb:Pvorbis_block;l:Pvorbis_look_mapping):longint;
var vd:Pvorbis_dsp_state;
    vi:Pvorbis_info;
    ci:Pcodec_setup_info;
    b:Pprivate_state;
    look:Pvorbis_look_mapping0;
    info:Pvorbis_info_mapping0;
    i,j,n,submap,ch_in_bundle,mag,ang:longint;
    pcmbundle:PPLongints;
    zerobundle:PLongints;
    nonzero:PLongints;
    floormemo:PPPointers;
    pcmM,pcmA,pcm:PLongints;
begin
 vd:=vb^.vd;
 vi:=vd^.vi;
 ci:=vi^.codec_setup;
 b:=vd^.backend_state;
 look:=pointer(l);
 info:=look^.map;
 n:=ci^.blocksizes[vb^.W];
 vb^.pcmend:=n;
 if look^.channels=0 then begin
  look^.pcmbundle:=Allocate(vi^.channels*SizeOf(PLongint));
  look^.zerobundle:=Allocate(vi^.channels*SizeOf(longint));
  look^.nonzero:=Allocate(vi^.channels*SizeOf(longint));
  look^.floormemo:=Allocate(vi^.channels*SizeOf(PPointers));
  look^.channels:=vi^.channels;
 end else if look^.channels<vi^.channels then begin
  look^.pcmbundle:=Reallocate(look^.pcmbundle,vi^.channels*SizeOf(PLongint));
  look^.zerobundle:=Reallocate(look^.zerobundle,vi^.channels*SizeOf(longint));
  look^.nonzero:=Reallocate(look^.nonzero,vi^.channels*SizeOf(longint));
  look^.floormemo:=Reallocate(look^.floormemo,vi^.channels*SizeOf(PPointers));
  look^.channels:=vi^.channels;
 end;
 pcmbundle:=look^.pcmbundle;
 zerobundle:=look^.zerobundle;
 nonzero:=look^.nonzero;
 floormemo:=look^.floormemo;
 for i:=0 to vi^.channels-1 do begin
  submap:=info^.chmuxlist[i];
  floormemo^[i]:=Pvorbis_func_floor(PPointers(look^.floor_func)^[submap])^.inverse1(vb,Pvorbis_look_floor(PPointers(look^.floor_look)^[submap]));
  if assigned(floormemo^[i]) then begin
   nonzero^[i]:=1;
  end else begin
   nonzero^[i]:=0;
  end;                           
  FillChar(vb^.pcm^[i]^,(sizeof(ogg_int32_t)*n) div 2,AnsiChar(#0));
 end;
 for i:=0 to info^.coupling_steps-1 do begin
  if (nonzero^[info^.coupling_mag[i]]<>0) or (nonzero^[info^.coupling_ang[i]]<>0) then begin
   nonzero^[info^.coupling_mag[i]]:=1;
   nonzero^[info^.coupling_ang[i]]:=1;
  end;
 end;
 for i:=0 to info^.submaps-1 do begin
  ch_in_bundle:=0;
  for j:=0 to vi^.channels-1 do begin
   if info^.chmuxlist[j]=i then begin
    if nonzero^[j]<>0 then begin
     zerobundle[ch_in_bundle]:=1;
    end else begin
     zerobundle[ch_in_bundle]:=0;
    end;
    pcmbundle[ch_in_bundle]:=vb^.pcm^[j];
    inc(ch_in_bundle);
   end;
  end;
  Pvorbis_func_residue(PPointers(look^.residue_func)^[i])^.inverse(vb,Pvorbis_look_residue(PPointers(look^.residue_look)^[i]),pointer(pcmbundle),pointer(zerobundle),ch_in_bundle);
 end;
 for i:=info^.coupling_steps-1 downto 0 do begin
  pcmM:=vb^.pcm^[info^.coupling_mag[i]];
  pcmA:=vb^.pcm^[info^.coupling_ang[i]];
  for j:=0 to (n div 2)-1 do begin
   mag:=pcmM[j];
   ang:=pcmA[j];
   if mag>0 then begin
    if ang>0 then begin
     pcmM[j]:=mag;
     pcmA[j]:=mag-ang;
    end else begin
     pcmA[j]:=mag;
     pcmM[j]:=mag+ang;
    end;
   end else begin
    if ang>0 then begin
     pcmM[j]:=mag;
     pcmA[j]:=mag+ang;
    end else begin
     pcmA[j]:=mag;
     pcmM[j]:=mag-ang;
    end;
   end;
  end;
 end;
 for i:=0 to vi^.channels-1 do begin
  pcm:=vb^.pcm^[i];
  submap:=info^.chmuxlist[i];
  Pvorbis_func_floor(PPointers(look^.floor_func)^[submap])^.inverse2(vb,Pvorbis_look_floor(PPointers(look^.floor_look)^[submap]),floormemo[i],pcm);
 end;
 for i:=0 to vi^.channels-1 do begin
  pcm:=vb^.pcm^[i];
  mdct_backward(n,pcm,pcm);
 end;
 for i:=0 to vi^.channels-1 do begin
  pcm:=vb^.pcm^[i];
  if nonzero^[i]<>0 then begin
   _vorbis_apply_window(pointer(pcm),@b^.window,@ci^.blocksizes[0],vb^.lW,vb^.W,vb^.nW);
  end else begin
   for j:=0 to n-1 do begin
    pcm^[j]:=0;
   end;
  end;
 end;
 inc(seq,vi^.channels);
 result:=0;
end;

procedure mdct_butterfly_8(x:PLongints); {$ifdef caninline}inline;{$endif}
var r0,r1,r2,r3,r4,r5,r6,r7:longint;
begin
 r0:=x^[4]+x^[0];
 r1:=x^[4]-x^[0];
 r2:=x^[5]+x^[1];
 r3:=x^[5]-x^[1];
 r4:=x^[6]+x^[2];
 r5:=x^[6]-x^[2];
 r6:=x^[7]+x^[3];
 r7:=x^[7]-x^[3];
 x^[0]:=r5+r3;
 x^[1]:=r7-r1;
 x^[2]:=r5-r3;
 x^[3]:=r7+r1;
 x^[4]:=r4-r0;
 x^[5]:=r6-r2;
 x^[6]:=r4+r0;
 x^[7]:=r6+r2;
end;

procedure mdct_butterfly_16(x:PLongints); {$ifdef caninline}inline;{$endif}
var r0,r1:longint;
begin
 r0:=x^[0]-x^[8];
 inc(x^[8],x^[0]);
 r1:=x^[1]-x^[9];
 inc(x^[9],x^[1]);
 x^[0]:=MULT31((r0+r1),cPI2_8);
 x^[1]:=MULT31((r1-r0),cPI2_8);
 r0:=x^[10]-x^[2];
 inc(x^[10],x^[2]);
 r1:=x^[3]-x^[11];
 inc(x^[11],x^[3]);
 x^[2]:=r1;
 x^[3]:=r0;
 r0:=x^[12]-x^[4];
 inc(x^[12],x^[4]);
 r1:=x^[13]-x^[5];
 inc(x^[13],x^[5]);
 x^[4]:=MULT31((r0-r1),cPI2_8);
 x^[5]:=MULT31((r0+r1),cPI2_8);
 r0:=x^[14]-x^[6];
 inc(x^[14],x^[6]);
 r1:=x^[15]-x^[7];
 inc(x^[15],x^[7]);
 x^[6]:=r0;
 x^[7]:=r1;
 mdct_butterfly_8(x);
 mdct_butterfly_8(pointer(@x^[8]));
end;

procedure mdct_butterfly_32(x:PLongints); {$ifdef caninline}inline;{$endif}
var r0,r1:longint;
begin
 r0:=x^[30]-x^[14];
 inc(x^[30],x^[14]);
 r1:=x^[31]-x^[15];
 inc(x^[31],x^[15]);
 x^[14]:=r0;
 x^[15]:=r1;
 r0:=x^[28]-x^[12];
 inc(x^[28],x^[12]);
 r1:=x^[29]-x^[13];
 inc(x^[29],x^[13]);
 XNPROD31(r0,r1,cPI1_8,cPI3_8,@x^[12],@x^[13]);
 r0:=x^[26]-x^[10];
 inc(x^[26],x^[10]);
 r1:=x^[27]-x^[11];
 inc(x^[27],x^[11]);
 x^[10]:=MULT31((r0-r1),cPI2_8);
 x^[11]:=MULT31((r0+r1),cPI2_8);
 r0:=x^[24]-x^[8];
 inc(x^[24],x^[8]);
 r1:=x^[25]-x^[9];
 inc(x^[25],x^[9]);
 XNPROD31(r0,r1,cPI3_8,cPI1_8,@x^[ 8],@x^[ 9]);
 r0:=x^[22]-x^[6];
 inc(x^[22],x^[6]);
 r1:=x^[7]-x^[23];
 inc(x^[23],x^[7]);
 x^[6]:=r1;
 x^[7]:=r0;
 r0:=x^[4]-x^[20];
 inc(x^[20],x^[4]);
 r1:=x^[5]-x^[21];
 inc(x^[21],x^[5]);
 XPROD31(r0,r1,cPI3_8,cPI1_8,@x^[4],@x^[5]);
 r0:=x^[2]-x^[18];
 inc(x^[18],x^[2]);
 r1:=x^[3]-x^[19];
 inc(x^[19],x^[3]);
 x^[2]:=MULT31((r1+r0),cPI2_8);
 x^[3]:=MULT31((r1-r0),cPI2_8);
 r0:=x^[0]-x^[16];
 inc(x^[16],x^[0]);
 r1:=x^[1]-x^[17];
 inc(x^[17],x^[1]);
 XPROD31(r0,r1,cPI1_8,cPI3_8,@x^[0],@x^[1]);
 mdct_butterfly_16(x);
 mdct_butterfly_16(@x^[16]);
end;

procedure mdct_butterfly_generic(x:PLongints;points,step:longint);
var T,x1,x2:PLongints;
    r0,r1:longint;
begin
 T:=@sincos_lookup0[0];
 x1:=@x^[points-8];
 x2:=@x^[SARLongint(points,1)-8];
 repeat
  r0:=x1^[6]-x2^[6];
  inc(x1^[6],x2^[6]);
  r1:=x2^[7]-x1^[7];
  inc(x1^[7],x2^[7]);
  XPROD31(r1,r0,T^[0],T^[1],@x2^[6],@x2^[7]);
  inc(plongint(T),step);
  r0:=x1^[4]-x2^[4];
  inc(x1^[4],x2^[4]);
  r1:=x2^[5]-x1^[5];
  inc(x1^[5],x2^[5]);
  XPROD31(r1,r0,T^[0],T^[1],@x2^[4],@x2^[5]);
  inc(plongint(T),step);
  r0:=x1^[2]-x2^[2];
  inc(x1^[2],x2^[2]);
  r1:=x2^[3]-x1^[3];
  inc(x1^[3],x2^[3]);
  XPROD31(r1,r0,T^[0],T^[1],@x2^[2],@x2^[3]);
  inc(plongint(T),step);
  r0:=x1^[0]-x2^[0];
  inc(x1^[0],x2^[0]);
  r1:=x2^[1]-x1^[1];
  inc(x1^[1],x2^[1]);
  XPROD31(r1,r0,T^[0],T^[1],@x2^[0],@x2^[1]);
  inc(plongint(T),step);
  dec(plongint(x1),8);
  dec(plongint(x2),8);
 until BeRoAudioOGGPtrUInt(T)>=BeRoAudioOGGPtrUInt(pointer(@sincos_lookup0[1024]));
 repeat
  r0:=x1^[6]-x2^[6];
  inc(x1^[6],x2^[6]);
  r1:=x1^[7]-x2^[7];
  inc(x1^[7],x2^[7]);
  XNPROD31(r0,r1,T^[0],T^[1],@x2^[6],@x2^[7]);
  dec(plongint(T),step);
  r0:=x1^[4]-x2^[4];
  inc(x1^[4],x2^[4]);
  r1:=x1^[5]-x2^[5];
  inc(x1^[5],x2^[5]);
  XNPROD31(r0,r1,T^[0],T^[1],@x2^[4],@x2^[5]);
  dec(plongint(T),step);
  r0:=x1^[2]-x2^[2];
  inc(x1^[2],x2^[2]);
  r1:=x1^[3]-x2^[3];
  inc(x1^[3],x2^[3]);
  XNPROD31(r0,r1,T^[0],T^[1],@x2^[2],@x2^[3]);
  dec(plongint(T),step);
  r0:=x1^[0]-x2^[0];
  inc(x1^[0],x2^[0]);
  r1:=x1^[1]-x2^[1];
  inc(x1^[1],x2^[1]);
  XNPROD31(r0,r1,T^[0],T^[1],@x2^[0],@x2^[1]);
  dec(plongint(T),step);
  dec(plongint(x1),8);
  dec(plongint(x2),8);
 until BeRoAudioOGGPtrUInt(T)<=BeRoAudioOGGPtrUInt(pointer(@sincos_lookup0[0]));
 repeat
  r0:=x2^[6]-x1^[6];
  inc(x1^[6],x2^[6]);
  r1:=x2^[7]-x1^[7];
  inc(x1^[7],x2^[7]);
  XPROD31(r0,r1,T^[0],T^[1],@x2^[6],@x2^[7]);
  inc(plongint(T),step);
  r0:=x2^[4]-x1^[4];
  inc(x1^[4],x2^[4]);
  r1:=x2^[5]-x1^[5];
  inc(x1^[5],x2^[5]);
  XPROD31(r0,r1,T^[0],T^[1],@x2^[4],@x2^[5]);
  inc(plongint(T),step);
  r0:=x2^[2]-x1^[2];
  inc(x1^[2],x2^[2]);
  r1:=x2^[3]-x1^[3];
  inc(x1^[3],x2^[3]);
  XPROD31(r0,r1,T^[0],T^[1],@x2^[2],@x2^[3]);
  inc(plongint(T),step);
  r0:=x2^[0]-x1^[0];
  inc(x1^[0],x2^[0]);
  r1:=x2^[1]-x1^[1];
  inc(x1^[1],x2^[1]);
  XPROD31(r0,r1,T^[0],T^[1],@x2^[0],@x2^[1]);
  inc(plongint(T),step);
  dec(plongint(x1),8);
  dec(plongint(x2),8);
 until BeRoAudioOGGPtrUInt(T)>=BeRoAudioOGGPtrUInt(pointer(@sincos_lookup0[1024]));
 repeat
  r0:=x1^[6]-x2^[6];
  inc(x1^[6],x2^[6]);
  r1:=x2^[7]-x1^[7];
  inc(x1^[7],x2^[7]);
  XNPROD31(r1,r0,T^[0],T^[1],@x2^[6],@x2^[7]);
  dec(plongint(T),step);
  r0:=x1^[4]-x2^[4];
  inc(x1^[4],x2^[4]);
  r1:=x2^[5]-x1^[5];
  inc(x1^[5],x2^[5]);
  XNPROD31(r1,r0,T^[0],T^[1],@x2^[4],@x2^[5]);
  dec(plongint(T),step);
  r0:=x1^[2]-x2^[2];
  inc(x1^[2],x2^[2]);
  r1:=x2^[3]-x1^[3];
  inc(x1^[3],x2^[3]);
  XNPROD31(r1,r0,T^[0],T^[1],@x2^[2],@x2^[3]);
  dec(plongint(T),step);
  r0:=x1^[0]-x2^[0];
  inc(x1^[0],x2^[0]);
  r1:=x2^[1]-x1^[1];
  inc(x1^[1],x2^[1]);
  XNPROD31(r1,r0,T^[0],T^[1],@x2^[0],@x2^[1]);
  dec(plongint(T),step);
  dec(plongint(x1),8);
  dec(plongint(x2),8);
 until BeRoAudioOGGPtrUInt(T)<=BeRoAudioOGGPtrUInt(pointer(@sincos_lookup0[0]));
end;

procedure mdct_butterflies(x:PLongints;points,shift:longint);
var stages,i,j:longint;
begin
 stages:=8-shift;
 i:=0;
 while true do begin
  dec(stages);
  if stages<=0 then begin
   break;
  end;
  for j:=0 to (1 shl i)-1 do begin
   mdct_butterfly_generic(pointer(@x^[SARLongint(points,i)*j]),SARLongint(points,i),4 shl (i+shift));
  end;
  inc(i);
 end;
 j:=0;
 while j<points do begin
  mdct_butterfly_32(pointer(@x^[j]));
  inc(j,32);
 end;
end;
    
function bitrev12(x:longint):longint;
const bitrev:array[0..15] of byte=(0,8,4,12,2,10,6,14,1,9,5,13,3,11,7,15);
begin
 result:=bitrev[(x shr 8) and $f] or (bitrev[(x shr 4) and $f] shl 4) or (bitrev[x and $f] shl 8);
end;

procedure mdct_bitreverse(x:PLongints;n,step,shift:longint);
var bit,r0,r1,r2,r3:longint;
    w0,w1,T,TTop,x0,x1:PLongints;
begin
 bit:=0;
 w0:=x;
 w1:=pointer(@w0^[SARLongint(n,1)]);
 x:=w1;
 if step>=4 then begin
  t:=pointer(@sincos_lookup0[SARLongint(step,1)]);
 end else begin
  t:=pointer(@sincos_lookup1[0]);
 end;
 Ttop:=pointer(@T^[1024]);
 repeat
  r3:=bitrev12(bit);
  inc(bit);
  x0:=pointer(@x^[SARLongint((r3 xor $fff),shift)-1]);
  x1:=pointer(@x^[SARLongint(r3,shift)]);
  r0:=x0^[0]+x1^[0];
  r1:=x1^[1]-x0^[1];
  XPROD32(r0,r1,T^[1],T^[0],@r2,@r3);
  inc(plongint(T),step);
  dec(plongint(w1),4);
  r0:=SARLongint(x0^[1]+x1^[1],1);
  r1:=SARLongint(x0^[0]-x1^[0],1);
  w0^[0]:=r0+r2;
  w0^[1]:=r1+r3;
  w1^[2]:=r0-r2;
  w1^[3]:=r3-r1;
  r3:=bitrev12(bit);
  inc(bit);
  x0:=pointer(@x^[SARLongint((r3 xor $fff),shift)-1]);
  x1:=pointer(@x^[SARLongint(r3,shift)]);
  r0:=x0^[0]+x1^[0];
  r1:=x1^[1]-x0^[1];
  XPROD32(r0,r1,T^[1],T^[0],@r2,@r3);
  inc(plongint(T),step);
  r0:=SARLongint(x0^[1]+x1^[1],1);
  r1:=SARLongint(x0^[0]-x1^[0],1);
  w0^[2]:=r0+r2;
  w0^[3]:=r1+r3;
  w1^[0]:=r0-r2;
  w1^[1]:=r3-r1;
  inc(plongint(w0),4);
 until BeRoAudioOGGPtrUInt(T)>=BeRoAudioOGGPtrUInt(Ttop);
 repeat
  r3:=bitrev12(bit);
  inc(bit);
  x0:=pointer(@x^[SARLongint((r3 xor $fff),shift)-1]);
  x1:=pointer(@x^[SARLongint(r3,shift)]);
  r0:=x0^[0]+x1^[0];
  r1:=x1^[1]-x0^[1];
  dec(plongint(T),step);
  XPROD32(r0,r1,T^[0],T^[1],@r2,@r3);
  dec(plongint(w1),4);
  r0:=SARLongint(x0^[1]+x1^[1],1);
  r1:=SARLOngint(x0^[0]-x1^[0],1);
  w0^[0]:=r0+r2;
  w0^[1]:=r1+r3;
  w1^[2]:=r0-r2;
  w1^[3]:=r3-r1;
  r3:=bitrev12(bit);
  inc(bit);
  x0:=pointer(@x^[SARLongint((r3 xor $fff),shift)-1]);
  x1:=pointer(@x^[SARLongint(r3,shift)]);
  r0:=x0^[0]+x1^[0];
  r1:=x1^[1]-x0^[1];
  dec(plongint(T),step);
  XPROD32(r0,r1,T^[0],T^[1],@r2,@r3);
  r0:=SARLongint(x0^[1]+x1^[1],1);
  r1:=SARLongint(x0^[0]-x1^[0],1);
  w0^[2]:=r0+r2;
  w0^[3]:=r1+r3;
  w1^[0]:=r0-r2;
  w1^[1]:=r3-r1;
  inc(plongint(w0),4);
 until BeRoAudioOGGPtrUInt(w0)>=BeRoAudioOGGPtrUInt(w1);
end;

procedure mdct_backward(n:longint;in_,out_:PLongints);
var n2,n4,shift,step,t0,t1,v0,v1,q0,q1:longint;
    iX,oX,T,V,oX1,oX2:PLongints;
begin
 n2:=SARLongint(n,1);
 n4:=SARLongint(n,2);
 shift:=6;
 while (n and (1 shl shift))=0 do begin
  inc(shift);
 end;
 shift:=13-shift;
 step:=2 shl shift;
 iX:=pointer(@in_^[n2-7]);
 oX:=pointer(@out_^[n2+n4]);
 T:=pointer(@sincos_lookup0[0]);
 repeat
  dec(plongint(oX),4);
  XPROD31(iX^[4],iX^[6],T^[0],T^[1],@oX^[2],@oX^[3]);
  inc(plongint(T),step);
  XPROD31(iX^[0],iX^[2],T^[0],T^[1],@oX^[0],@oX^[1]);
  inc(plongint(T),step);
  dec(plongint(iX),8);
 until BeRoAudioOGGPtrUInt(iX)<BeRoAudioOGGPtrUInt(pointer(@in_^[n4]));
 repeat
  dec(plongint(oX),4);
  XPROD31(iX^[4],iX^[6],T^[1],T^[0],@oX^[2],@oX^[3]);
  dec(plongint(T),step);
  XPROD31(iX^[0],iX^[2],T^[1],T^[0],@oX^[0],@oX^[1]);
  dec(plongint(T),step);
  dec(plongint(iX),8);
 until BeRoAudioOGGPtrUInt(iX)<BeRoAudioOGGPtrUInt(pointer(@in_^[0]));
 iX:=pointer(@in_^[n2-8]);
 oX:=pointer(@out_^[n2+n4]);
 T:=pointer(@sincos_lookup0[0]);
 repeat
  inc(plongint(T),step);
  XNPROD31(iX^[6],iX^[4],T^[0],T^[1],@oX^[0],@oX^[1]);
  inc(plongint(T),step);
  XNPROD31(iX^[2],iX^[0],T^[0],T^[1],@oX^[2],@oX^[3]);
  dec(plongint(iX),8);
  inc(plongint(oX),4);
 until BeRoAudioOGGPtrUInt(iX)<BeRoAudioOGGPtrUInt(pointer(@in_^[n4]));
 repeat
  dec(plongint(T),step);
  XNPROD31(iX^[6],iX^[4],T^[1],T^[0],@oX^[0],@oX^[1]);
  dec(plongint(T),step);
  XNPROD31(iX^[2],iX^[0],T^[1],T^[0],@oX^[2],@oX^[3]);
  dec(plongint(iX),8);
  inc(plongint(oX),4);
 until BeRoAudioOGGPtrUInt(iX)<BeRoAudioOGGPtrUInt(pointer(@in_^[0]));
 mdct_butterflies(pointer(@out_^[n2]),n2,shift);
 mdct_bitreverse(out_,n,step,shift);
 step:=SARLongint(Step,2);
 oX1:=pointer(@out_^[n2+n4]);
 oX2:=pointer(@out_^[n2+n4]);
 iX:=pointer(@out_^[0]);
 case step of
  0:begin
   T:=pointer(@sincos_lookup0[0]);
   V:=pointer(@sincos_lookup1[0]);
   t0:=T^[0];
   inc(plongint(T));
   t1:=T^[0];
   inc(plongint(T));
   repeat
    dec(plongint(oX1),4);

    v0:=V^[0];
    inc(plongint(V));
    v1:=V^[0];
    inc(plongint(V));

    q0:=SARLongint(v0-t0,2);
    inc(t0,q0);
    q1:=SARLongint(v1-t1,2);
    inc(t1,q1);
    XPROD31(iX^[0],-iX^[1],t0,t1,@oX1^[3],@oX2^[0]);
    t0:=v0-q0;
    t1:=v1-q1;
    XPROD31(iX^[2],-iX^[3],t0,t1,@oX1^[2],@oX2^[1]);

    t0:=T^[0];
    inc(plongint(T));
    t1:=T^[0];
    inc(plongint(T));
    q0:=SARLongint(t0-v0,2);
    inc(v0,q0);
    q1:=SARLongint(t1-v1,2);
    inc(v1,q1);
    XPROD31(iX^[4],-iX^[5],v0,v1,@oX1^[1],@oX2^[2]);
    v0:=t0-q0;
    v1:=t1-q1;
    XPROD31(iX^[6],-iX^[7],v0,v1,@oX1^[0],@oX2^[3]);

    inc(plongint(oX2),4);
    inc(plongint(iX),8);
   until BeRoAudioOGGPtrUInt(iX)>=BeRoAudioOGGPtrUInt(oX1);
  end;
  1:begin
   T:=pointer(@sincos_lookup0[0]);
   V:=pointer(@sincos_lookup1[0]);
   t0:=SARLongint(T^[0],1);
   inc(plongint(T));
   t1:=SARLongint(T^[0],1);
   inc(plongint(T));
   repeat
    dec(plongint(oX1),4);

    v0:=SARLongint(V^[0],1);
    inc(plongint(V));
    inc(t0,v0);

    v1:=SARLongint(V^[0],1);
    inc(plongint(V));
    inc(t1,v1);

    XPROD31(iX^[0],-iX^[1],t0,t1,@oX1^[3],@oX2^[0]);

    t0:=SARLongint(T^[0],1);
    inc(plongint(T));
    inc(v0,t0);

    t1:=SARLongint(T^[0],1);
    inc(plongint(T));
    inc(v1,t1);

    XPROD31(iX^[2],-iX^[3],v0,v1,@oX1^[2],@oX2^[1]);

    v0:=SARLongint(V^[0],1);
    inc(plongint(V));
    inc(t0,v0);

    v1:=SARLongint(V^[0],1);
    inc(plongint(V));
    inc(t1,v1);

    XPROD31(iX^[4],-iX^[5],t0,t1,@oX1^[1],@oX2^[2]);

    t0:=SARLongint(T^[0],1);
    inc(plongint(T));
    inc(v0,t0);

    t1:=SARLongint(T^[0],1);
    inc(plongint(T));
    inc(v1,t1);

    XPROD31(iX^[6],-iX^[7],v0,v1,@oX1^[0],@oX2^[3]);

    inc(plongint(oX2),4);
    inc(plongint(iX),8);
   until BeRoAudioOGGPtrUInt(iX)>=BeRoAudioOGGPtrUInt(oX1);
  end;
  else begin
   if step>=4 then begin
    T:=pointer(@sincos_lookup0[SARLongint(step,1)]);
   end else begin
    T:=pointer(@sincos_lookup1[0]);
   end;
   repeat
    dec(plongint(oX1),4);
    XPROD31(iX^[0],-iX^[1],T^[0],T^[1],@oX1^[3],@oX2^[0]);
    inc(plongint(T),step);
    XPROD31(iX^[2],-iX^[3],T^[0],T^[1],@oX1^[2],@oX2^[1]);
    inc(plongint(T),step);
    XPROD31(iX^[4],-iX^[5],T^[0],T^[1],@oX1^[1],@oX2^[2]);
    inc(plongint(T),step);
    XPROD31(iX^[6],-iX^[7],T^[0],T^[1],@oX1^[0],@oX2^[3]);
    inc(plongint(T),step);
    inc(plongint(oX2),4);
    inc(plongint(iX),8);
   until BeRoAudioOGGPtrUInt(iX)>=BeRoAudioOGGPtrUInt(oX1);
  end;
 end;
 iX:=pointer(@out_^[n2+n4]);
 oX1:=pointer(@out_^[n4]);
 oX2:=oX1;
 repeat
  dec(plongint(oX1),4);
  dec(plongint(iX),4);
  q0:=iX^[3];
  oX1^[3]:=q0;
  oX2^[0]:=-q0;
  q0:=iX^[2];
  oX1^[2]:=q0;
  oX2^[1]:=-q0;
  q0:=iX^[1];
  oX1^[1]:=q0;
  oX2^[2]:=-q0;
  q0:=iX^[0];
  oX1^[0]:=q0;
  oX2^[3]:=-q0;
  inc(plongint(oX2),4);
 until BeRoAudioOGGPtrUInt(oX2)>=BeRoAudioOGGPtrUInt(iX);
 iX:=pointer(@out_^[n2+n4]);
 oX1:=pointer(@out_^[n2+n4]);
 oX2:=pointer(@out_^[n2]);
 repeat
  dec(plongint(oX1),4);
  oX1^[0]:=iX^[3];
  oX1^[1]:=iX^[2];
  oX1^[2]:=iX^[1];
  oX1^[3]:=iX^[0];
  inc(plongint(iX),4);
 until BeRoAudioOGGPtrUInt(oX1)<=BeRoAudioOGGPtrUInt(oX2);
end;

procedure mdct_forward(n:longint;in_,out_:PLongints);
begin
end;

procedure res0_free_info(i:Pvorbis_info_residue);
begin
 if assigned(i) then begin
  FillChar(Pvorbis_info_residue0(i)^,SizeOf(vorbis_info_residue0),AnsiChar(#0));
  FreeMem(Pvorbis_info_residue0(i));
 end;
end;

procedure res0_free_look(i:Pvorbis_look_residue);
var j:longint;
    look:Pvorbis_look_residue0;
begin
 if assigned(i) then begin
  look:=pointer(i);
  for j:=0 to look^.parts-1 do begin
   if assigned(look^.partbooks[j]) then begin
    FreeMem(look^.partbooks[j]);
   end;
  end;
  FreeMem(look^.partbooks);
  for j:=0 to look^.partvals-1 do begin
   FreeMem(look^.decodemap[j]);
  end;
  FreeMem(look^.decodemap);
  if assigned(look.partword) then begin
   FreeMem(look.partword);
  end;
  FillChar(look^,SizeOf(vorbis_look_residue0),AnsiChar(#0));
  FreeMem(look);
 end;
end;

function icount(v:longword):longint; {$ifdef caninline}inline;{$endif}
begin
 result:=0;
 while v<>0 do begin
  inc(result,v and 1);
  v:=v shr 1;
 end;
end;

function res0_unpack(vi:Pvorbis_info;opb:Poggpack_buffer):Pvorbis_info_residue;
label errout;
var j,acc,cascade:longint;
    info:Pvorbis_info_residue0;
    ci:Pcodec_setup_info;
begin
 acc:=0;
 info:=Allocate(SizeOf(vorbis_info_residue0));
 ci:=vi^.codec_setup;
 info^.begin_:=oggpack_read(opb,24);
 info^.end_:=oggpack_read(opb,24);
 info^.grouping:=oggpack_read(opb,24)+1;
 info^.partitions:=oggpack_read(opb,6)+1;
 info^.groupbook:=oggpack_read(opb,8);
 for j:=0 to info^.partitions-1 do begin
  cascade:=oggpack_read(opb,3);
  if oggpack_read(opb,1)<>0 then begin
   cascade:=cascade or (oggpack_read(opb,5) shl 3);
  end;
  info^.secondstages[j]:=cascade;
  inc(acc,icount(cascade));
 end;
 for j:=0 to acc-1 do begin
  info^.booklist[j]:=oggpack_read(opb,8);
 end;
 if info^.groupbook>=ci^.books then begin
  goto errout;
 end;
 for j:=0 to acc-1 do begin
  if info^.booklist[j]>=ci^.books then begin
   goto errout;
  end;
 end;
 result:=pointer(info);
 exit;
errout:
 res0_free_info(pointer(info));
 result:=nil;
end;

function res0_look(vd:Pvorbis_dsp_state;vm:Pvorbis_info_mode;vr:Pvorbis_info_residue):Pvorbis_look_residue;
var info:Pvorbis_info_residue0;
    look:Pvorbis_look_residue0;
    ci:Pcodec_setup_info;
    j,k,acc,dim,maxstage,stages,val,mult,deco:longint;
begin
 info:=pointer(vr);
 look:=Allocate(SizeOf(vorbis_look_residue0));
 ci:=vd^.vi^.codec_setup;
 acc:=0;
 maxstage:=0;
 look^.info:=info;
 look^.map:=vm^.mapping;
 look^.parts:=info^.partitions;
 look^.fullbooks:=pointer(ci^.fullbooks);
 look^.phrasebook:=@Pcodebooks(ci^.fullbooks)^[info^.groupbook];
 dim:=look^.phrasebook^.dim;
 look^.partbooks:=Allocate(look^.parts*SizeOf(PPcodebooks));
 for j:=0 to look^.parts-1 do begin
  stages:=_ilog(info^.secondstages[j]);
  if stages<>0 then begin
   if stages>maxstage then begin
    maxstage:=stages;
   end;
   look^.partbooks[j]:=Allocate(stages*SizeOf(Pcodebooks));
   for k:=0 to stages-1 do begin
    if (info^.secondstages[j] and (1 shl k))<>0 then begin
     look^.partbooks^[j]^[k]:=@Pcodebooks(ci^.fullbooks)^[info^.booklist[acc]];
     inc(acc);
    end;
   end;
  end;
 end;

 look^.partvals:=look^.parts;
 for j:=1 to dim-1 do begin
  look^.partvals:=look^.partvals*look^.parts;
 end;
 look^.stages:=maxstage;
 look^.decodemap:=Allocate(look^.partvals*SizeOf(PLongints));
 for j:=0 to look^.partvals-1 do begin
  val:=j;
  mult:=look^.partvals div look^.parts;
  look^.decodemap[j]:=Allocate(dim*SizeOf(longint));
  for k:=0 to dim-1 do begin
   deco:=val div mult;
   dec(val,deco*mult);
   mult:=mult div look^.parts;
   look^.decodemap^[j]^[k]:=deco;
  end;
 end;

 result:=pointer(look);
end;

function _01inverse(vb:Pvorbis_block;v1:Pvorbis_look_residue;in_:PPLongints;ch:longint;decodepart:TDecodeFunc):longint;
label eopbreak,errout;
var i,j,k,l,s,samples_per_partition,partitions_per_word,max,end_,n,partvals,partwords,temp,offset:longint;
    info:Pvorbis_info_residue0;
    look:Pvorbis_look_residue0;
    partword:PPPLongints;
    stagebook:Pcodebook;
begin
 look:=pointer(v1);
 info:=look^.info;
 samples_per_partition:=info^.grouping;
 partitions_per_word:=look^.phrasebook^.dim;
 max:=SARLongint(vb^.pcmend,1);
 if info^.end_<max then begin
  end_:=info^.end_;
 end else begin
  end_:=max;
 end;
 n:=end_-info^.begin_;
 if n>0 then begin
  partvals:=n div samples_per_partition;
  partwords:=(partvals+partitions_per_word-1) div partitions_per_word;
  if look.partwords=0 then begin
   look.partword:=Allocate(ch*sizeof(PPLongints));
   look.partwords:=ch;
  end else if look.partwords<ch then begin
   look.partword:=Reallocate(look.partword,ch*sizeof(PPLongints));
   look.partwords:=ch;
  end;
  partword:=look.partword;
  for j:=0 to ch-1 do begin
   partword[j]:=_vorbis_block_alloc(vb,partwords*sizeof(PLongints));
  end;
  for s:=0 to look^.stages-1 do begin
   i:=0;
   l:=0;
   while i<partvals do begin
    if s=0 then begin
     for j:=0 to ch-1 do begin
      temp:=vorbis_book_decode(look^.phrasebook,@vb^.opb);
      if temp=-1 then begin
       goto eopbreak;
      end;
      partword^[j]^[l]:=look^.decodemap[temp];
      if not assigned(partword^[j]^[l]) then begin
       goto errout;
      end;
     end;
    end;
    k:=0;
    while (k<partitions_per_word) and (i<partvals) do begin
     for j:=0 to ch-1 do begin
      offset:=info^.begin_+(i*samples_per_partition);
      if (info^.secondstages[partword^[j]^[l]^[k]] and (1 shl s))<>0 then begin
       stagebook:=@look^.partbooks[partword^[j]^[l]^[k]]^[s]^[0];
       if assigned(stagebook) then begin
        if decodepart(stagebook,@in_^[j]^[offset],@vb^.opb,samples_per_partition,-8)=-1 then begin
         goto eopbreak;
        end;
       end;
      end;
     end;
     inc(k);
     inc(i);
    end;
    inc(l);
   end;
  end;
 end;
errout:
eopbreak:
 result:=0;
end;

function res0_inverse(vb:Pvorbis_block;vi:Pvorbis_look_residue;in_:PPLongInts;nonzero:PLongints;ch:longint):longint;
var i,used:longint;
begin
 used:=0;
 for i:=0 to ch-1 do begin
  if nonzero^[i]<>0 then begin
   in_^[used]:=in_^[i];
   inc(used);
  end;
 end;
 if used<>0 then begin
  result:=_01inverse(vb,vi,in_,used,vorbis_book_decodevs_add);
 end else begin
  result:=0;
 end;
end;

function res1_inverse(vb:Pvorbis_block;vi:Pvorbis_look_residue;in_:PPLongInts;nonzero:PLongints;ch:longint):longint;
var i,used:longint;
begin
 used:=0;
 for i:=0 to ch-1 do begin
  if nonzero^[i]<>0 then begin
   in_^[used]:=in_^[i];
   inc(used);
  end;
 end;
 if used<>0 then begin
  result:=_01inverse(vb,vi,in_,used,vorbis_book_decodev_add);
 end else begin
  result:=0;
 end;
end;

function res2_inverse(vb:Pvorbis_block;vi:Pvorbis_look_residue;in_:PPLongInts;nonzero:PLongints;ch:longint):longint;
label eopbreak,errout;
var i,k,l,s,samples_per_partition,partitions_per_word,max,end_,n,partvals,partwords,temp,beginoff:longint;
    info:Pvorbis_info_residue0;
    look:Pvorbis_look_residue0;
    partword:PPLongints;
    stagebook:Pcodebook;
begin
 look:=pointer(vi);
 info:=look^.info;
 samples_per_partition:=info^.grouping;
 partitions_per_word:=look^.phrasebook^.dim;
 max:=SARLongint(vb^.pcmend*ch,1);
 if info^.end_<max then begin
  end_:=info^.end_;
 end else begin
  end_:=max;
 end;
 n:=end_-info^.begin_;
 if n>0 then begin
  partvals:=n div samples_per_partition;
  partwords:=(partvals+(partitions_per_word-1)) div partitions_per_word;
  if look.partwords=0 then begin
   look.partword:=Allocate(partwords*sizeof(PLongints));
   look.partwords:=partwords;
  end else if look.partwords<partwords then begin
   look.partword:=Reallocate(look.partword,partwords*sizeof(PLongints));
   look.partwords:=partwords;
  end;
  partword:=look.partword;
  beginoff:=info^.begin_ div ch;
  i:=0;
  while i<ch do begin
   if nonzero^[i]<>0 then begin
    break;
   end;
   inc(i);
  end;
  if i=ch then begin
   result:=0;
   exit;
  end;
  samples_per_partition:=samples_per_partition div ch;
  for s:=0 to look^.stages-1 do begin
   i:=0;
   l:=0;
   while i<partvals do begin
    if s=0 then begin
     temp:=vorbis_book_decode(look^.phrasebook,@vb^.opb);
     if temp=-1 then begin
      goto eopbreak;
     end;
     partword^[l]:=look^.decodemap[temp];
     if not assigned(partword^[l]) then begin
      goto errout;
     end;
    end;
    k:=0;                    
    while (k<partitions_per_word) and (i<partvals) do begin
     if (info^.secondstages[partword^[l]^[k]] and (1 shl s))<>0 then begin
      stagebook:=@look^.partbooks[partword^[l]^[k]]^[s]^[0];
      if assigned(stagebook) then begin
       if vorbis_book_decodevv_add(stagebook,in_,(i*samples_per_partition)+beginoff,ch,@vb^.opb,samples_per_partition,-8)=-1 then begin
        goto eopbreak;
       end;
      end;
     end;
     inc(k);
     inc(i);
    end;
    inc(l);
   end;
  end;
 end;
errout:
eopbreak:
 result:=0;
end;

function _float32_unpack(val:longint;point:PLongint):Longint;
var mant,sign,exp:longint;
begin
 mant:=val and $1fffff;
 sign:=val and $80000000;
 exp:=SARLongint((val and $7fe00000),VQ_FMAN)-((VQ_FMAN-1)+VQ_FEXP_BIAS);
 if mant<>0 then begin
  while (mant and $40000000)=0 do begin
   mant:=mant shl 1;
   dec(exp);
  end;
  if sign<>0 then begin
   mant:=-mant;
  end;
 end else begin
//sign:=0;
  exp:=-9999;
 end;
 point^:=exp;
 result:=mant;
end;

function _make_words(l:PLongints;n,sparsecount:longint):PLongwords;
var i,j,count,length:longint;
   marker:array[0..32] of longword;
   entry,temp:longword;
begin
 count:=0;
 if sparsecount<>0 then begin
  result:=Allocate(sparsecount*SizeOf(longword));
 end else begin
  result:=Allocate(n*SizeOf(longword));
 end;
 FillChar(marker,SizeOf(marker),AnsiChar(#0));
 for i:=0 to n-1 do begin
  length:=l^[i];
  if length>0 then begin
   entry:=marker[length];
   if (length<32) and ((entry shr length)<>0) then begin
    FreeMem(result);
    result:=nil;
    exit;
   end;
   result^[count]:=entry;
   inc(count);
   for j:=length downto 1 do begin
    if (marker[j] and 1)<>0 then begin
     if j=1 then begin
      inc(marker[1]);
     end else begin
      marker[j]:=marker[j-1] shl 1;
     end;
     break;
    end;
    inc(marker[j]);
   end;
   for j:=length+1 to 32 do begin
    if (marker[j] shr 1)=entry then begin
     entry:=marker[j];
     marker[j]:=marker[j-1] shl 1;
    end else begin
     break;
    end;
   end;
  end else begin
   if sparsecount=0 then begin
    inc(count);
   end;
  end;
 end;
 i:=0;
 count:=0;
 while i<n do begin
  temp:=0;
  for j:=0 to l^[i]-1 do begin
   temp:=(temp shl 1) or ((result[count] shr j) and 1);
  end;
  if sparsecount<>0 then begin
   if l^[i]<>0 then begin
    result^[count]:=temp;
    inc(count);
   end;
  end else begin
   result^[count]:=temp;
   inc(count);
  end;
  inc(i);
 end;
end;

function _book_unquantize(b:Pstatic_codebook;n:longint;sparsemap:PLongints;maxpoint:PLongint):PLongints;
var j,k,count,quantvals,minpoint,delpoint,mindel,delta,last,lastpoint,indexdiv,index,point,val:longint;
    rp:PLongints;
begin
 result:=nil;
 if b^.maptype in [1,2] then begin
  count:=0;
  mindel:=_float32_unpack(b^.q_min,@minpoint);
  delta:=_float32_unpack(b^.q_delta,@delpoint);
  result:=Allocate((n*b^.dim)*sizeof(longint));
  rp:=Allocate((n*b^.dim)*sizeof(longint));
  maxpoint^:=minpoint;
  case b^.maptype of
   1:begin
    quantvals:=_book_maptype1_quantvals(b);
    for j:=0 to b^.entries-1 do begin
     if (assigned(sparsemap) and (b^.lengthlist^[j]<>0)) or not assigned(sparsemap) then begin
      last:=0;
      lastpoint:=0;
      indexdiv:=1;
      for k:=0 to b^.dim-1 do begin
       index:=(j div indexdiv) mod quantvals;
       point:=0;
       val:=VFLOAT_MULTI(delta,delpoint,abs(b^.quantlist^[index]),@point);
       val:=VFLOAT_ADD(mindel,minpoint,val,point,@point);
       val:=VFLOAT_ADD(last,lastpoint,val,point,@point);
       if b^.q_sequencep<>0 then begin
        last:=val;
        lastpoint:=point;
       end;
       if assigned(sparsemap) then begin
        result^[(sparsemap[count]*b^.dim)+k]:=val;
        rp^[(sparsemap[count]*b^.dim)+k]:=point;
       end else begin
        result^[(count*b^.dim)+k]:=val;
        rp^[(count*b^.dim)+k]:=point;
       end;
       if maxpoint^<point then begin
        maxpoint^:=point;
       end;
       indexdiv:=indexdiv*quantvals;
      end;
      inc(count);
     end;
    end;
   end;
   2:begin
    for j:=0 to b^.entries-1 do begin
     if (assigned(sparsemap) and (b^.lengthlist^[j]<>0)) or not assigned(sparsemap) then begin
      last:=0;
      lastpoint:=0;
      for k:=0 to b^.dim-1 do begin
       point:=0;
       val:=VFLOAT_MULTI(delta,delpoint,abs(b^.quantlist[(j*b^.dim)+k]),@point);
       val:=VFLOAT_ADD(mindel,minpoint,val,point,@point);
       val:=VFLOAT_ADD(last,lastpoint,val,point,@point);
       if b^.q_sequencep<>0 then begin
        last:=val;
        lastpoint:=point;
       end;
       if assigned(sparsemap) then begin
        result^[(sparsemap[count]*b^.dim)+k]:=val;
        rp^[(sparsemap[count]*b^.dim)+k]:=point;
       end else begin
        result^[(count*b^.dim)+k]:=val;
        rp^[(count*b^.dim)+k]:=point;
       end;
       if maxpoint^<point then begin
        maxpoint^:=point;
       end;
      end;
      inc(count);
     end;
    end;
   end;
  end;
  for j:=0 to (n*b^.dim)-1 do begin
   if rp^[j]<maxpoint^ then begin
    result^[j]:=SARLongint(result^[j],maxpoint^-rp^[j]);
   end;
  end;
  FreeMem(rp);
 end;
end;

procedure vorbis_staticbook_clear(b:Pstatic_codebook);
begin
 if assigned(b^.quantlist) then begin
  FreeMem(b^.quantlist);
 end;
 if assigned(b^.lengthlist) then begin
  FreeMem(b^.lengthlist);
 end;
 FillChar(b^,sizeof(static_codebook),AnsiChar(#0));
end;

procedure vorbis_staticbook_destroy(b:Pstatic_codebook);
begin
 vorbis_staticbook_clear(b);
 FreeMem(b);
end;

procedure vorbis_book_clear(b:Pcodebook);
begin
 if assigned(b^.valuelist) then begin
  FreeMem(b^.valuelist);
 end;
 if assigned(b^.codelist) then begin
  FreeMem(b^.codelist);
 end;
 if assigned(b^.dec_index) then begin
  FreeMem(b^.dec_index);
 end;
 if assigned(b^.dec_codelengths) then begin
  FreeMem(b^.dec_codelengths);
 end;
 if assigned(b^.dec_firsttable) then begin
  FreeMem(b^.dec_firsttable);
 end;
 FillChar(b^,sizeof(static_codebook),AnsiChar(#0));
end;

function sort32a(const a,b:pointer):longint;
begin
 result:=ord(pplongword(a)^^>pplongword(b)^^)-ord(pplongword(a)^^<pplongword(b)^^);
end;

function vorbis_book_init_decode(dest:Pcodebook;source:Pstatic_codebook):longint;
label err_out;
var i,j,n,tabn,position,lo,hi:longint;
    sortindex:PLongints;
    codes:PLongwords;
    codep:PPLongwords;
    orig,mask,w,loval,hival:longword;
begin
 codep:=nil;
 sortindex:=nil;

 n:=0;
 FillChar(dest^,SizeOf(codebook),#0);

 for i:=0 to source^.entries-1 do begin
  if source^.lengthlist^[i]>0 then begin
   inc(n);
  end;
 end;

 dest^.entries:=source^.entries;
 dest^.used_entries:=n;
 dest^.dim:=source^.dim;

 if n>0 then begin
  codes:=_make_words(source^.lengthlist,source^.entries,dest^.used_entries);
  codep:=Allocate(n*SizeOf(PLongwords));

  if not assigned(codes) then begin
   goto err_out;
  end;

  for i:=0 to n-1 do begin
   codes^[i]:=bitreverse(codes^[i]);
   codep^[i]:=@codes^[i];
  end;
  qsort(codep,n,sizeof(PLongwords),sort32a);

  sortindex:=Allocate(n*SizeOf(longint));
  dest^.codelist:=Allocate(n*sizeof(longword));

  for i:=0 to n-1 do begin
   position:=(BeRoAudioOGGPtrUInt(codep^[i])-BeRoAudioOGGPtrUInt(codes)) div sizeof(longword);
   sortindex^[position]:=i;
  end;

  for i:=0 to n-1 do begin
   dest^.codelist^[sortindex^[i]]:=codes^[i];
  end;

  FreeMem(codes);
  codes:=nil;

  dest^.valuelist:=_book_unquantize(source,n,sortindex,@dest^.binarypoint);
  dest^.dec_index:=Allocate(n*sizeof(longint));

  n:=0;
  for i:=0 to source^.entries-1 do begin
   if source^.lengthlist^[i]>0 then begin
    dest^.dec_index^[sortindex^[n]]:=i;
    inc(n);
   end;
  end;

  dest^.dec_codelengths:=Allocate(n*sizeof(ansichar));
  n:=0;
  for i:=0 to source^.entries-1 do begin
   if source^.lengthlist^[i]>0 then begin
    dest^.dec_codelengths[sortindex^[n]]:=ansichar(byte(source^.lengthlist^[i]));
    inc(n);
   end;
  end;

  dest^.dec_firsttablen:=_ilog(dest^.used_entries)-4;
  if dest^.dec_firsttablen<5 then begin
   dest^.dec_firsttablen:=5;
  end else if dest^.dec_firsttablen>8 then begin
   dest^.dec_firsttablen:=8;
  end;

  tabn:=1 shl dest^.dec_firsttablen;
  dest^.dec_firsttable:=Allocate(tabn*sizeof(longword));
  dest^.dec_maxlength:=0;

  for i:=0 to n-1 do begin
   if dest^.dec_maxlength<byte(dest^.dec_codelengths[i]) then begin
    dest^.dec_maxlength:=byte(dest^.dec_codelengths[i]);
   end;
   if byte(dest^.dec_codelengths[i])<=dest^.dec_firsttablen then begin
    orig:=bitreverse(dest^.codelist^[i]);
    for j:=0 to (1 shl (dest^.dec_firsttablen-byte(dest^.dec_codelengths[i])))-1 do begin
     dest^.dec_firsttable^[orig or longword(j shl byte(dest^.dec_codelengths[i]))]:=i+1;
    end;
   end;
  end;

  mask:=$fffffffe shl (31-dest^.dec_firsttablen);
  lo:=0;
  hi:=0;
  for i:=0 to tabn-1 do begin
   w:=i shl (32-dest^.dec_firsttablen);
   if dest^.dec_firsttable[bitreverse(w)]=0 then begin
    while ((lo+1)<n) and (dest^.codelist[lo+1]<=w) do begin
     inc(lo);
    end;
    while (hi<n) and (w>=(dest^.codelist[hi] and mask)) do begin
     inc(hi);
    end;
    loval:=lo;
    hival:=n-hi;
    if loval>$7fff then begin
     loval:=$7fff;
    end;
    if hival>$7fff then begin
     hival:=$7fff;
    end;
    dest^.dec_firsttable[bitreverse(w)]:=$80000000 or (loval shl 15) or hival;
   end;
  end;
 end;
 if assigned(codep) then begin
  FreeMem(codep);
 end;
 if assigned(sortindex) then begin
  FreeMem(sortindex);
 end;
 result:=0;
 exit;
err_out:
 if assigned(codep) then begin
  FreeMem(codep);
 end;
 if assigned(sortindex) then begin
  FreeMem(sortindex);
 end;
 vorbis_book_clear(dest);
 result:=-1;
end;

function vorbis_synthesis(vb:Pvorbis_block;op:Pogg_packet;decodep:longint):longint;
var vd:Pvorbis_dsp_state;
    b:Pprivate_state;
    vi:Pvorbis_info;
    ci:Pcodec_setup_info;
    opb:Poggpack_buffer;
    type_,mode,i:longint;
begin
 vd:=vb^.vd;
 b:=vd^.backend_state;
 vi:=vd^.vi;
 ci:=vi^.codec_setup;
 opb:=@vb^.opb;
 _vorbis_block_ripcord(vb);
 oggpack_readinit(opb,op^.packet);
 if oggpack_read(opb,1)<>0 then begin
  result:=OV_ENOTAUDIO;
  exit;
 end;
 mode:=oggpack_read(opb,b^.modebits);
 if mode=-1 then begin
  result:=OV_EBADPACKET;
  exit;
 end;
 vb^.mode:=mode;
 vb^.W:=ci^.mode_param[mode]^.blockflag;
 if vb^.W<>0 then begin
  vb^.lW:=oggpack_read(opb,1);
  vb^.nW:=oggpack_read(opb,1);
  if vb^.nW=-1 then begin
   result:=OV_EBADPACKET;
   exit;
  end;
 end else begin
  vb^.lW:=0;
  vb^.nW:=0;
 end;

 vb^.granulepos:=op^.granulepos;
 vb^.sequence:=op^.packetno-3;
 vb^.eofflag:=op^.e_o_s;

 if decodep<>0 then begin
  vb^.pcmend:=ci^.blocksizes[vb^.W];
  vb^.pcm:=_vorbis_block_alloc(vb,sizeof(PLongints)*vi^.channels);
  for i:=0 to vi^.channels-1 do begin
   vb^.pcm^[i]:=_vorbis_block_alloc(vb,vb^.pcmend*sizeof(longint));
  end;
  type_:=ci^.map_type[ci^.mode_param[mode]^.mapping];
  result:=_mapping_P[type_]^.inverse(vb,PPointers(b^.mode)^[mode]);
 end else begin
  vb^.pcmend:=0;
  vb^.pcm:=nil;
  result:=0;
 end;
end;

function vorbis_packet_blocksize(vi:Pvorbis_info;op:Pogg_packet):longint;
var ci:Pcodec_setup_info;
    opb:oggpack_buffer;
    mode,modebits,v:longint;
begin
 ci:=vi^.codec_setup;
 oggpack_readinit(@opb,op^.packet);
 if oggpack_read(@opb,1)<>0 then begin
  result:=OV_ENOTAUDIO;
  exit;
 end;
 modebits:=0;
 v:=ci^.modes;
 while v>1 do begin
  inc(modebits);
  v:=SARLongint(v,1);
 end;
 mode:=oggpack_read(@opb,modebits);
 if mode=-1 then begin
  result:=OV_EBADPACKET;
 end else begin
  result:=ci^.blocksizes[ci^.mode_param[mode]^.blockflag];
 end;
end;

function _get_data(vf:POggVorbis_File):longint;
var buffer:PAnsiChar;
    bytes:longint;
begin
 errno:=0;
 if assigned(vf^.datasource) then begin
  buffer:=ogg_sync_bufferin(vf^.oy,CHUNKSIZE);
  bytes:=vf^.callbacks.read_func(buffer,1,CHUNKSIZE,vf^.datasource);
  if bytes>0 then begin
   ogg_sync_wrote(vf^.oy,bytes);
  end;
  if (bytes=0) and (errno<>0) then begin
   result:=-1;
  end else begin
   result:=bytes;
  end;
 end else begin
  result:=0;
 end;
end;

function _seek_helper(vf:POggVorbis_File;offset:ogg_int64_t):longint;
begin
 if assigned(vf^.datasource) then begin
  if (not assigned(vf^.callbacks.seek_func)) or (vf^.callbacks.seek_func(vf^.datasource,offset,SEEK_SET)=-1) then begin
   result:=OV_EREAD;
   exit;
  end;
  vf^.offset:=offset;
  ogg_sync_reset(vf^.oy);
  result:=0;
 end else begin
  result:=OV_EFAULT;
 end;
end;

function _get_next_page(vf:POggVorbis_File;og:Pogg_page;boundary:ogg_int64_t):ogg_int64_t;
var more:longint;
    r:int64;
begin
 if boundary>0 then begin
  inc(boundary,vf^.offset);
 end;
 while true do begin
  if (boundary>0) and (vf^.offset>=boundary) then begin
   result:=OV_FALSE;
   exit;
  end;
  more:=ogg_sync_pageseek(vf^.oy,og);
  if more<0 then begin
   dec(vf^.offset,more);
  end else begin
   if more=0 then begin
    if boundary=0 then begin
     result:=OV_FALSE;
     exit;
    end;
    r:=_get_data(vf);
    if r=0 then begin
     result:=OV_EOF;
     exit;
    end else if r<0 then begin
     result:=OV_EREAD;
     exit;
    end;
   end else begin
    result:=vf^.offset;
    inc(vf^.offset,more);
    exit;
   end;
  end;
 end;
end;

function _get_prev_page(vf:POggVorbis_File;og:Pogg_page):ogg_int64_t;
var begin_,end_,offset:longint;
begin
 begin_:=vf^.offset;
 end_:=begin_;
 offset:=-1;
 while offset=-1 do begin
  dec(begin_,CHUNKSIZE);
  if begin_<0 then begin
   begin_:=0;
  end;
  result:=_seek_helper(vf,begin_);
  if result<>0 then begin
   exit;
  end;
  while vf^.offset<end_ do begin
   result:=_get_next_page(vf,og,end_-vf^.offset);
   if result=OV_EREAD then begin
    exit;
   end;
   if result<0 then begin
    break;
   end else begin
    offset:=result;
   end;
  end;
 end;
 if og^.header_len=0 then begin
  ogg_page_release(og);
  result:=_seek_helper(vf,offset);
  if result<>0 then begin
   exit;
  end;
  result:=_get_next_page(vf,og,CHUNKSIZE);
  if result<0 then begin
   result:=OV_EFAULT;
   exit;
  end;
 end;
 result:=offset;
end;

procedure _add_serialno(og:Pogg_page;serialno_list:PPLongwords;n:PLongint);
var s:longint;
begin
 s:=ogg_page_serialno(og);
 inc(n^);
 if assigned(serialno_list^[0]) then begin
  ReallocMem(serialno_list^[0],n^*sizeof(longword));
 end else begin
  GetMem(serialno_list^[0],n^*sizeof(longword));
 end;
 serialno_list^[0]^[n^-1]:=s;
end;

function _lookup_serialno(s:longint;serialno_list:PLongwords;n:longint):longint;
begin
 result:=0;
 if assigned(serialno_list) then begin
  while n>0 do begin
   dec(n);
   if serialno_list^[0]=longword(s) then begin
    result:=1;
    exit;
   end;
   inc(plongword(serialno_list));
  end;
 end;
end;

function _lookup_page_serialno(og:Pogg_page;serialno_list:pointer;n:longint):longint;
begin
 result:=_lookup_serialno(ogg_page_serialno(og),serialno_list,n);
enD;

function _get_prev_page_serial(vf:POggVorbis_File;serial_list:PLongwords;serial_n:longint;serialno:PLongint;granpos:PInt64):ogg_int64_t;
var og:ogg_page;
    begin_,end_,ret,prefoffset,offset,ret_gran:int64;
    ret_serialno:longword;
begin
 FillChar(og,SizeOf(ogg_page),#0);

 begin_:=vf^.offset;
 end_:=begin_;

 prefoffset:=-1;
 offset:=-1;
 ret_serialno:=$ffffffff;
 ret_gran:=-1;

 while offset=-1 do begin
  dec(begin_,CHUNKSIZE);
  if begin_<0 then begin
   begin_:=0;
  end;
  ret:=_seek_helper(vf,begin_);
  if ret<>0 then begin
   result:=ret;
   exit;
  end;
  while vf^.offset<end_ do begin
   ret:=_get_next_page(vf,@og,end_-vf^.offset);
   if ret=OV_EREAD then begin
    result:=OV_EREAD;
    exit;
   end;
   if ret<0 then begin
    ogg_page_release(@og);
    break;
   end else begin
    ret_serialno:=ogg_page_serialno(@og);
    ret_gran:=ogg_page_granulepos(@og);
    offset:=ret;
    ogg_page_release(@og);
    if ret_serialno=longword(serialno^) then begin
     prefoffset:=ret;
     granpos^:=ret_gran;
    end;
    if _lookup_serialno(ret_serialno,serial_list,serial_n)=0 then begin
     prefoffset:=-1;
    end;
   end;
  end;
 end;
 if prefoffset>=0 then begin
  result:=prefoffset;
  exit;
 end;
 serialno^:=ret_serialno;
 granpos^:=ret_gran;
 result:=offset;
end;

function _fetch_headers(vf:POggVorbis_File;vi:Pvorbis_info;vc:Pvorbis_comment;serialno_list:PPLongwords;serialno_n:PLongint;og_ptr:Pogg_page):longint;
label bail_header;
var og:ogg_page;
    op:ogg_packet;
    i,ret,allbos:longint;
    llret:int64;
begin
 FillChar(og,SizeOf(ogg_page),AnsiChar(#0));
 FillChar(op,SizeOf(ogg_packet),AnsiChar(#0));
 allbos:=0;

 if not assigned(og_ptr) then begin
  llret:=_get_next_page(vf,@og,CHUNKSIZE);
  if llret=OV_EREAD then begin
   result:=OV_EREAD;
   exit;
  end;
  if llret<0 then begin
   result:=OV_ENOTVORBIS;
   exit;
  end;
  og_ptr:=@og;
 end;

 vorbis_info_init(vi);
 vorbis_comment_init(vc);
 vf^.ready_state:=OPENED;

 while ogg_page_bos(og_ptr)<>0 do begin
  if assigned(serialno_list) then begin
   if _lookup_page_serialno(og_ptr,serialno_list^[0],serialno_n^)<>0 then begin
    if assigned(serialno_list^[0]) then begin
     FreeMem(serialno_list^[0]);
    end;
    serialno_list^[0]:=nil;
    serialno_n^:=0;
    ret:=OV_EBADHEADER;
    goto bail_header;
   end;
   _add_serialno(og_ptr,serialno_list,serialno_n);
  end;
  if vf^.ready_state<STREAMSET then begin
   ogg_stream_reset_serialno(vf^.os,ogg_page_serialno(og_ptr));
   ogg_stream_pagein(vf^.os,og_ptr);
   if (ogg_stream_packetout(vf^.os,@op)>0) and (vorbis_synthesis_idheader(@op)<>0) then begin
    vf^.ready_state:=STREAMSET;
    ret:=vorbis_synthesis_headerin(vi,vc,@op);
    if ret<>0 then begin
     ret:=OV_EBADHEADER;
     goto bail_header;
    end;
   end;
  end;
  begin
   llret:=_get_next_page(vf,og_ptr,CHUNKSIZE);
   if llret=OV_EREAD then begin
    ret:=OV_EREAD;
    goto bail_header;
   end;
   if llret<0 then begin
    ret:=OV_ENOTVORBIS;
    goto bail_header;
   end;
   if (vf^.ready_state=STREAMSET) and (vf^.os^.serialno=longint(ogg_page_serialno(og_ptr))) then begin
    ogg_stream_pagein(vf^.os,og_ptr);
    break;
   end;
  end
 end;

 if vf^.ready_state<>STREAMSET then begin
  ret:=OV_ENOTVORBIS;
  goto bail_header;
 end;

 while true do begin
  i:=0;
  while i<2 do begin
   while i<2 do begin
    result:=ogg_stream_packetout(vf^.os,@op);
    if result=0 then begin
     break;
    end;
    if result=-1 then begin
     ret:=OV_EBADHEADER;
     goto bail_header;
    end;
    ret:=vorbis_synthesis_headerin(vi,vc,@op);
    if ret<>0 then begin
     goto bail_header;
    end;
    inc(i);
   end;
   while i<2 do begin
    if _get_next_page(vf,og_ptr,CHUNKSIZE)<0 then begin
     ret:=OV_EBADHEADER;
     goto bail_header;
    end;
    if vf^.os^.serialno=longint(ogg_page_serialno(og_ptr)) then begin
     ogg_stream_pagein(vf^.os,og_ptr);
     break;
    end;
    if ogg_page_bos(og_ptr)<>0 then begin
     if allbos<>0 then begin
      ret:=OV_EBADHEADER;
      goto bail_header;
     end else begin
      allbos:=1;
     end;
    end;
   end;
  end;

  ogg_packet_release(@op);
  ogg_page_release(@og);

  result:=0;
  exit;
 end;

bail_header:
 ogg_packet_release(@op);
 ogg_page_release(@og);
 vorbis_info_clear(vi);
 vorbis_comment_clear(vc);
 vf^.ready_state:=OPENED;
 result:=ret;
end;

function _initial_pcmoffset(vf:POggVorbis_File;vi:Pvorbis_info):ogg_int64_t;
var og:ogg_page;
    accumulated,pos:int64;
    lastblock,ret,serialno,thisblock:longint;
    op:ogg_packet;
begin
 FillChar(og,SizeOf(ogg_page),AnsiChar(#0));
 accumulated:=0;
 lastblock:=-1;
 serialno:=vf^.os^.serialno;

 while true do begin
  FillChar(op,SizeOf(ogg_packet),AnsiChar(#0));
  if _get_next_page(vf,@og,-1)<0 then begin
   break;
  end;
  if ogg_page_bos(@og)<>0 then begin
   break;
  end;
  if ogg_page_serialno(@og)<>longword(serialno) then begin
   continue;
  end;
  pos:=ogg_page_granulepos(@og);
  ogg_stream_pagein(vf^.os,@og);
  while true do begin
   ret:=ogg_stream_packetout(vf^.os,@op);
   if ret=0 then begin
    break;
   end;
   if ret>0 then begin
    thisblock:=vorbis_packet_blocksize(vi,@op);
    if lastblock<>-1 then begin
     inc(accumulated,SARLongint(lastblock+thisblock,2));
    end;
    lastblock:=thisblock;
   end;
  end;
  ogg_packet_release(@op);
  if pos<>-1 then begin
   accumulated:=pos-accumulated;
   break;
  end;
 end;

 if accumulated<0 then begin
  accumulated:=0;
 end;

 ogg_page_release(@og);
 result:=accumulated;
end;

function _bisect_forward_serialno(vf:POggVorbis_File;begin_,searched,end_,endgran:int64;endserial:longint;currentno_list:PLongwords;currentnos,m:longint):longint;
var pcmoffset,dataoffset,endsearched,next,searchgran,ret,last,bisect:int64;
    serialno,next_serialnos,testserial:longint;
    next_serialno_list:PLongwords;
    vi:vorbis_info;
    vc:vorbis_comment;
    og:ogg_page;
begin
//dataoffset:=searched;
 endsearched:=end_;
 next:=end_;
 searchgran:=-1;
 serialno:=vf^.os^.serialno;
 if _lookup_serialno(endserial,currentno_list,currentnos)<>0 then begin
  while endserial<>serialno do begin
   endserial:=serialno;
   vf^.offset:=_get_prev_page_serial(vf,currentno_list,currentnos,@endserial,@endgran);
  end;
  vf^.links:=m+1;
  if assigned(vf^.offsets) then begin
   FreeMem(vf^.offsets);
  end;
  if assigned(vf^.serialnos) then begin
   FreeMem(vf^.serialnos);
  end;
  if assigned(vf^.dataoffsets) then begin
   FreeMem(vf^.dataoffsets);
  end;
  vf^.offsets:=Allocate((vf^.links+1)*sizeof(int64));
  vf^.vi:=Reallocate(vf^.vi,vf^.links*sizeof(vorbis_info));
  vf^.vc:=Reallocate(vf^.vc,vf^.links*sizeof(vorbis_comment));
  vf^.serialnos:=Allocate(vf^.links*sizeof(longword));
  vf^.dataoffsets:=Allocate(vf^.links*sizeof(int64));
  vf^.pcmlengths:=Allocate(vf^.links*2*sizeof(int64));
  vf^.offsets^[m+1]:=end_;
  vf^.offsets^[m]:=begin_;
  vf^.pcmlengths^[(m*2)+1]:=endgran;
 end else begin
  next_serialno_list:=nil;
  while searched<endsearched do begin
   FillChar(og,SizeOf(ogg_page),AnsiChar(#0));
   if (endsearched-searched)<CHUNKSIZE then begin
    bisect:=searched;
   end else begin
    bisect:=(searched+endsearched) div 2;
   end;
   ret:=_seek_helper(vf,bisect);
   if ret<>0 then begin
    result:=ret;
    exit;
   end;
   last:=_get_next_page(vf,@og,-1);
   if last=OV_EREAD then begin
    result:=OV_EREAD;
    exit;
   end;
   if (last<0) or (_lookup_page_serialno(@og,currentno_list,currentnos)=0) then begin
    endsearched:=bisect;
    if last>=0 then begin
     next:=last;
    end;
   end else begin
    searched:=last+og.header_len+og.body_len;
   end;
   ogg_page_release(@og);
  end; 
  begin
   testserial:=serialno+1;
   vf^.offset:=next;
   while testserial<>serialno do begin
    testserial:=serialno;
    vf^.offset:=_get_prev_page_serial(vf,currentno_list,currentnos,@testserial,@searchgran);
   end;
  end;
  if vf^.offset<>next then begin
   ret:=_seek_helper(vf,next);
   if ret<>0 then begin
    result:=ret;
    exit;
   end;
  end;
  ret:=_fetch_headers(vf,@vi,@vc,@next_serialno_list,@next_serialnos,nil);
  if ret<>0 then begin
   result:=ret;
   exit;
  end;
  serialno:=vf^.os^.serialno;
  dataoffset:=vf^.offset;
  pcmoffset:=_initial_pcmoffset(vf,@vi);
  ret:=_bisect_forward_serialno(vf,next,vf^.offset,end_,endgran,endserial,next_serialno_list,next_serialnos,m+1);
  if ret<>0 then begin
   result:=ret;
   exit;
  end;
  if assigned(next_serialno_list) then begin
   FreeMem(next_serialno_list);
  end;
  vf^.offsets[m+1]:=next;
  vf^.serialnos[m+1]:=serialno;
  vf^.dataoffsets[m+1]:=dataoffset;
  vf^.vi^[m+1]:=vi;
  vf^.vc^[m+1]:=vc;
  vf^.pcmlengths[(m*2)+1]:=searchgran;
  vf^.pcmlengths[(m*2)+2]:=pcmoffset;
  dec(vf^.pcmlengths[(m*2)+3],pcmoffset);
 end;
 result:=0;
end;

function _make_decode_ready(vf:POggVorbis_File):longint;
begin
 if vf^.ready_state>STREAMSET then begin
  result:=0;
  exit;
 end;
 if vf^.ready_state<STREAMSET then begin
  result:=OV_EFAULT;
  exit;
 end;
 if vf^.seekable<>0 then begin
  if vorbis_synthesis_init(@vf^.vd,@vf^.vi^[vf^.current_link])<>0 then begin
   result:=OV_EBADLINK;
   exit;
  end;
 end else begin
  if vorbis_synthesis_init(@vf^.vd,@vf^.vi^[0])<>0 then begin
   result:=OV_EBADLINK;
   exit;
  end;
 end;
 vorbis_block_init(@vf^.vd,@vf^.vb);
 vf^.ready_state:=INITSET;
 vf^.bittrack:=0;
 vf^.samptrack:=0;
 result:=0;
end;

function _open_seekable2(vf:POggVorbis_File):longint;
var dataoffset,end_,endgran,pcmoffset:int64;
    endserial,serialno:longint;
begin
 dataoffset:=vf^.dataoffsets[0];
 endgran:=-1;
 endserial:=vf^.os^.serialno;
 serialno:=vf^.os^.serialno;
 pcmoffset:=_initial_pcmoffset(vf,@vf^.vi[0]);
 if assigned(vf^.callbacks.seek_func) and assigned(vf^.callbacks.tell_func) then begin
  vf^.callbacks.seek_func(vf^.datasource,0,SEEK_END);
  vf^.offset:=vf^.callbacks.tell_func(vf^.datasource);
  vf^.end_:=vf^.offset;
 end else begin
  vf^.offset:=-1;
  vf^.end_:=-1;
 end;
 if vf^.end_=-1 then begin
  result:=OV_EINVAL;
  exit;
 end;
 end_:=_get_prev_page_serial(vf,@vf^.serialnos[2],vf^.serialnos[1],@endserial,@endgran);
 if end_<0 then begin
  result:=end_;
  exit;
 end;
 if _bisect_forward_serialno(vf,0,dataoffset,vf^.offset,endgran,endserial,@vf^.serialnos[2],vf^.serialnos[1],0)<0 then begin
  result:=OV_EREAD;
  exit;
 end;
 vf^.offsets[0]:=0;
 vf^.serialnos[0]:=serialno;
 vf^.dataoffsets[0]:=dataoffset;
 vf^.pcmlengths[0]:=pcmoffset;
 dec(vf^.pcmlengths[1],pcmoffset);
 result:=ov_raw_seek(vf,dataoffset);
end;

procedure _decode_clear(vf:POggVorbis_File);
begin
 vorbis_dsp_clear(@vf^.vd);
 vorbis_block_clear(@vf^.vb);
 vf^.ready_state:=OPENED;
end;

function _fetch_and_process_packet(vf:POggVorbis_File;readp,spanp:longint):longint;
label cleanup;
var og:ogg_page;
    op:ogg_packet;
    ret,oldsamples,link,i,samples,serialno:longint;
    granulepos,lret:int64;
begin
 FillChar(og,SizeOf(ogg_page),AnsiChar(#0));
 FillChar(op,SizeOf(ogg_packet),AnsiChar(#0));
 while true do begin
  if vf^.ready_state=STREAMSET then begin
   ret:=_make_decode_ready(vf);
   if ret<0 then begin
    goto cleanup;
   end;
  end;
  if vf^.ready_state=INITSET then begin
   while true do begin
    result:=ogg_stream_packetout(vf^.os,@op);
    if result=-1 then begin
     ret:=OV_HOLE;
     goto cleanup;
    end;
    if result>0 then begin
     granulepos:=op.granulepos;
     if vorbis_synthesis(@vf^.vb,@op,1)=0 then begin
      begin
       oldsamples:=vorbis_synthesis_pcmout(@vf^.vd,nil);
       if oldsamples<>0 then begin
        ret:=OV_EFAULT;
        goto cleanup;
       end;
       vorbis_synthesis_blockin(@vf^.vd,@vf^.vb);
       inc(vf^.samptrack,vorbis_synthesis_pcmout(@vf^.vd,nil)-oldsamples);
       inc(vf^.bittrack,op.bytes*8);
      end;
      if (granulepos<>-1) and (op.e_o_s=0) then begin
       if vf^.seekable<>0 then begin
        link:=vf^.current_link;
       end else begin
        link:=0;
       end;
       if (vf^.seekable<>0) and (link>0) then begin
        dec(granulepos,vf^.pcmlengths[link*2]);
       end;
       if granulepos<0 then begin
        granulepos:=0;
       end;
       samples:=vorbis_synthesis_pcmout(@vf^.vd,nil);
       dec(granulepos,samples);
       for i:=0 to link-1 do begin
        inc(granulepos,vf^.pcmlengths[i*2+1]);
       end;
       vf^.pcm_offset:=granulepos;
      end;
      ret:=1;
      goto cleanup;
     end;
    end else begin
     break;
    end;
   end;
  end;

  if vf^.ready_state>=OPENED then begin
   while true do begin
    if readp=0 then begin
     ret:=0;
     goto cleanup;
    end;
    lret:=_get_next_page(vf,@og,-1);
    if lret<0 then begin
     ret:=OV_EOF;
     goto cleanup;
    end;
    inc(vf^.bittrack,og.header_len*8);
    if vf^.ready_state=INITSET then begin
     if longword(vf^.current_serialno)<>ogg_page_serialno(@og) then begin
      if ogg_page_bos(@og)<>0 then begin
       if spanp=0 then begin
        ret:=OV_EOF;
        goto cleanup;
       end;
       _decode_clear(vf);
       if vf^.seekable=0 then begin
        vorbis_info_clear(@vf^.vi[0]);
        vorbis_comment_clear(@vf^.vc[0]);
       end;
       break;
      end else begin
       continue;
      end;
     end;
    end;
    break;
   end;
  end;

  if vf^.ready_state<>INITSET then begin
   if vf^.ready_state<STREAMSET then begin
    if vf^.seekable<>0 then begin
     serialno:=ogg_page_serialno(@og);
     link:=0;
     while link<vf^.links do begin
      if vf^.serialnos^[link]=longword(serialno) then begin
       break;
      end;
      inc(link);
     end;
     if link=vf^.links then begin
      continue;
     end;
     vf^.current_serialno:=serialno;
     vf^.current_link:=link;
     ogg_stream_reset_serialno(vf^.os,vf^.current_serialno);
     vf^.ready_state:=STREAMSET;
    end else begin
     ret:=_fetch_headers(vf,@vf^.vi[0],@vf^.vc[0],nil,nil,@og);
     if ret<>0 then begin
      goto cleanup;
     end;
     vf^.current_serialno:=vf^.os^.serialno;
     inc(vf^.current_link);
     link:=0;
     if link<>0 then begin
     end;
    end;
   end;
  end;

  ogg_stream_pagein(vf^.os,@og);
 end;
cleanup:
 ogg_packet_release(@op);
 ogg_page_release(@og);
 result:=ret;
end;
                       
function _ov_open1(f:pointer;vf:POggVorbis_File;initial:PAnsiChar;ibytes:longint;callbacks:ov_callbacks):longint;
var offsettest,serialno_list_size,ret:longint;
    serialno_list:PLongwords;
    buffer:PAnsiChar;
begin
 if assigned(f) then begin
  offsettest:=callbacks.seek_func(f,0,SEEK_CUR);
 end else begin
  offsettest:=-1;
 end;
 serialno_list:=nil;
 serialno_list_size:=0;
 FillChar(vf^,SizeOf(OggVorbis_File),AnsiChar(#0));
 vf^.datasource:=f;
 vf^.callbacks:=callbacks;
 vf^.oy:=ogg_sync_create();
 if assigned(initial) then begin
  buffer:=ogg_sync_bufferin(vf^.oy,ibytes);
  Move(initial^,buffer^,ibytes);
  ogg_sync_wrote(vf^.oy,ibytes);
 end;
 if offsettest<>-1 then begin
  vf^.seekable:=1;
 end;
 vf^.links:=1;
 vf^.vi:=Allocate(vf^.links*sizeof(vorbis_info));
 vf^.vc:=Allocate(vf^.links*sizeof(vorbis_comment));
 vf^.os:=ogg_stream_create(-1);
 ret:=_fetch_headers(vf,@vf^.vi[0],@vf^.vc[0],@serialno_list,@serialno_list_size,nil);
 if ret<0 then begin
  vf^.datasource:=nil;
  ov_clear(vf);
 end else begin
  vf^.serialnos:=Allocate((serialno_list_size+2)*sizeof(longword));
  vf^.serialnos^[0]:=vf^.current_serialno;
  vf^.serialnos^[1]:=serialno_list_size;
  Move(serialno_list^[0],vf^.serialnos^[2],serialno_list_size*sizeof(longword));
  vf^.offsets:=Allocate(1*sizeof(int64));
  vf^.dataoffsets:=Allocate(1*sizeof(int64));
  vf^.offsets^[0]:=0;
  vf^.dataoffsets^[0]:=vf^.offset;
  vf^.current_serialno:=vf^.os^.serialno;
  vf^.ready_state:=PARTOPEN;
 end;
 if assigned(serialno_list) then begin
  FreeMem(serialno_list);
 end;
 result:=ret;
end;

function _ov_open2(vf:POggVorbis_File):longint;
begin
 result:=0;
 if vf^.ready_state<OPENED then begin
  vf^.ready_state:=OPENED;
 end;
 if vf^.seekable<>0 then begin
  result:=_open_seekable2(vf);
  if result<>0 then begin
   vf^.datasource:=nil;
   ov_clear(vf);
  end;
 end;
end;

function ov_clear(vf:POggVorbis_File):longint;
var i:longint;
begin
 if assigned(vf) then begin
  vorbis_block_clear(@vf^.vb);
  vorbis_dsp_clear(@vf^.vd);
  ogg_stream_destroy(vf^.os);
  if assigned(vf^.vi) and (vf^.links>0) then begin
   for i:=0 to vf^.links-1 do begin
    vorbis_info_clear(@vf^.vi^[i]);
    vorbis_comment_clear(@vf^.vc^[i]);
   end;
   FreeMem(vf^.vi);
   FreeMem(vf^.vc);
  end;
  if assigned(vf^.dataoffsets) then begin
   FreeMem(vf^.dataoffsets);
  end;
  if assigned(vf^.pcmlengths) then begin
   FreeMem(vf^.pcmlengths);
  end;
  if assigned(vf^.serialnos) then begin
   FreeMem(vf^.serialnos);
  end;
  if assigned(vf^.offsets) then begin
   FreeMem(vf^.offsets);
  end;
  ogg_sync_destroy(vf^.oy);
  if assigned(vf^.datasource) and assigned(vf^.callbacks.close_func) then begin
   vf^.callbacks.close_func(vf^.datasource);
  end;
  FillChar(vf^,SizeOf(OggVorbis_File),AnsiChar(#0));
 end;
 result:=0;
end;

function ov_open_callbacks(f:pointer;vf:POggVorbis_File;initial:PAnsiChar;ibytes:longint;callbacks:ov_callbacks):longint;
begin
 result:=_ov_open1(f,vf,initial,ibytes,callbacks);
 if result=0 then begin
  result:=_ov_open2(vf);
 end;
end;

function fread(ptr:pointer;size,nmemb:BeRoAudioOGGPtrUInt;datasource:pointer):BeRoAudioOGGPtrUInt;
var res:integer;
begin
 System.BlockRead(FILE(datasource^),ptr^,nmemb*size,res);
 result:=res;
end;

function fseek(datasource:pointer;offset:int64;whence:longint):longint;
begin
 case whence of
  SEEK_SET:begin
   System.Seek(FILE(datasource^),offset);
  end;
  SEEK_CUR:begin
   System.Seek(FILE(datasource^),System.filepos(FILE(datasource^))+offset);
  end;
  SEEK_END:begin
   System.Seek(FILE(datasource^),System.filesize(FILE(datasource^))+offset);
  end;
 end;
 result:=System.filepos(FILE(datasource^));
end;

function fclose(datasource:pointer):longint;
begin
 System.Close{File}(FILE(datasource^));
 result:=0;
end;

function ftell(datasource:pointer):longint;
begin
 result:=System.filepos(FILE(datasource^));
end;

const _ov_open_callbacks:ov_callbacks=(read_func:fread;seek_func:fseek;close_func:fclose;tell_func:ftell);

function ov_open(f:pointer;vf:POggVorbis_File;initial:PAnsiChar;ibytes:longint):longint;
begin
 result:=ov_open_callbacks(f,vf,initial,ibytes,_ov_open_callbacks);
end;

function ov_test_callbacks(f:pointer;vf:POggVorbis_File;initial:PAnsiChar;ibytes:longint;callbacks:ov_callbacks):longint;
begin
 result:=_ov_open1(f,vf,initial,ibytes,callbacks);
end;

function ov_test(f:pointer;vf:POggVorbis_File;initial:PAnsiChar;ibytes:longint):longint;
begin
 result:=ov_test_callbacks(f,vf,initial,ibytes,_ov_open_callbacks);
end;

function ov_test_open(vf:POggVorbis_File):longint;
begin
 if vf^.ready_state<>PARTOPEN then begin
  result:=OV_EINVAL;
  exit;
 end;
 result:=_ov_open2(vf);
end;

function ov_streams(vf:POggVorbis_File):longint;
begin
 result:=vf^.links;
end;

function ov_seekable(vf:POggVorbis_File):longint;
begin
 result:=vf^.seekable;
end;

function ov_bitrate(vf:POggVorbis_File;i:longint):longint;
var bits:longint;
begin
 if vf^.ready_state<OPENED then begin
  result:=OV_EINVAL;
  exit;
 end;
 if i>=vf^.links then begin
  result:=OV_EINVAL;
  exit;
 end;
 if (vf^.seekable=0) and (i<>0) then begin
  result:=ov_bitrate(vf,0);
  exit;
 end;
 if i<0 then begin
  bits:=0;
  for i:=0 to vf^.links-1 do begin
   inc(bits,(vf^.offsets[i+1]-vf^.dataoffsets[i])*8);
  end;
  result:=(bits*1000) div ov_time_total(vf,-1);
  exit;
 end else begin
  if vf^.seekable<>0 then begin
   result:=((vf^.offsets[i+1]-vf^.dataoffsets[i])*8000) div ov_time_total(vf,i);
   exit;
  end else begin
   if vf^.vi[i].bitrate_nominal>0 then begin
    result:=vf^.vi[i].bitrate_nominal;
   end else begin
    if vf^.vi[i].bitrate_upper>0 then begin
     if vf^.vi[i].bitrate_lower>0 then begin
      result:=(vf^.vi[i].bitrate_upper+vf^.vi[i].bitrate_lower) div 2;
      exit;
     end else begin
      result:=vf^.vi[i].bitrate_upper;
      exit;
     end;
    end;
    result:=OV_FALSE;
    exit;
   end;
  end;
 end;
end;

function ov_bitrate_instant(vf:POggVorbis_File):longint;
var link:longint;
begin
 if vf^.seekable<>0 then begin
  link:=vf^.current_link;
 end else begin
  link:=0;
 end;
 if vf^.ready_state<OPENED then begin
  result:=OV_EINVAL;
  exit;
 end;
 if vf^.samptrack=0 then begin
  result:=OV_FALSE;
  exit;
 end;
 result:=(vf^.bittrack div vf^.samptrack)*vf^.vi[link].rate;
 vf^.bittrack:=0;
 vf^.samptrack:=0;
end;

function ov_serialnumber(vf:POggVorbis_File;i:longint):longint;
begin
 if i>=vf^.links then begin
  result:=ov_serialnumber(vf,vf^.links-1);
  exit;
 end;
 if (vf^.seekable=0) and (i>=0) then begin
  result:=ov_serialnumber(vf,-1);
  exit;
 end;
 if i<0 then begin
  result:=vf^.current_serialno;
 end else begin
  result:=vf^.serialnos^[i];
 end;
end;

function ov_raw_total(vf:POggVorbis_File;i:longint):ogg_int64_t;
begin
 if vf^.ready_state<OPENED then begin
  result:=OV_EINVAL;
  exit;
 end;
 if (vf^.seekable=0) or (i>=vf^.links) then begin
  result:=OV_EINVAL;
  exit;
 end;
 if i<0 then begin
  result:=0;
  for i:=0 to vf^.links-1 do begin
   inc(result,ov_raw_total(vf,i));
  end;
 end else begin
  result:=vf^.offsets^[i+1]-vf^.offsets^[i];
 end;
end;

function ov_pcm_total(vf:POggVorbis_File;i:longint):ogg_int64_t;
begin
 if vf^.ready_state<OPENED then begin
  result:=OV_EINVAL;
  exit;
 end;
 if (vf^.seekable=0) or (i>=vf^.links) then begin
  result:=OV_EINVAL;
  exit;
 end;
 if i<0 then begin
  result:=0;
  for i:=0 to vf^.links-1 do begin
   inc(result,ov_pcm_total(vf,i));
  end;
 end else begin
  result:=vf^.pcmlengths^[(i*2)+1];
 end;
end;

function ov_time_total(vf:POggVorbis_File;i:longint):ogg_int64_t;
begin
 if vf^.ready_state<OPENED then begin
  result:=OV_EINVAL;
  exit;
 end;
 if (vf^.seekable=0) or (i>=vf^.links) then begin
  result:=OV_EINVAL;
  exit;
 end;
 if i<0 then begin
  result:=0;
  for i:=0 to vf^.links-1 do begin
   inc(result,ov_time_total(vf,i));
  end;
 end else begin
  result:=(vf^.pcmlengths^[(i*2)+1]*1000) div vf^.vi^[i].rate;
 end;
end;

function ov_raw_seek(vf:POggVorbis_File;pos:ogg_int64_t):longint;
label seek_error;
var work_os:Pogg_stream_state;
    og,dup:ogg_page;
    op:ogg_packet;
    ret,lastblock,accblock,thisblock,lastflag,firstflag,i,link,granulepos,serialno:longint;
    pagepos:int64;
begin
 work_os:=nil;
 FillChar(og,SizeOf(ogg_page),AnsiChar(#0));
 FillChar(op,SizeOf(ogg_packet),AnsiChar(#0));
 if vf^.ready_state<OPENED then begin
  result:=OV_EINVAL;
  exit;
 end;
 if vf^.seekable=0 then begin
  result:=OV_ENOSEEK;
  exit;
 end;
 if (pos<0) or (pos>vf^.end_) then begin
  result:=OV_EINVAL;
  exit;
 end;
 vf^.pcm_offset:=-1;
 ogg_stream_reset_serialno(vf^.os,vf^.current_serialno);
 vorbis_synthesis_restart(@vf^.vd);
 ret:=_seek_helper(vf,pos);
 if ret<>0 then begin
  goto seek_error;
 end;
 begin
  lastblock:=0;
  accblock:=0;
  lastflag:=0;
  firstflag:=0;
  pagepos:=-1;
  work_os:=ogg_stream_create(vf^.current_serialno);
  while true do begin
   if vf^.ready_state>=STREAMSET then begin
    result:=ogg_stream_packetout(work_os,@op);
    if result>0 then begin
     if assigned(vf^.vi[vf^.current_link].codec_setup) then begin
      thisblock:=vorbis_packet_blocksize(@vf^.vi^[vf^.current_link],@op);
      if thisblock<0 then begin
       ogg_stream_packetout(vf^.os,nil);
       thisblock:=0;
      end else begin
       if (lastflag<>0) and (firstflag=0) then begin
        ogg_stream_packetout(vf^.os,nil);
       end else begin
        if lastblock<>0 then begin
         inc(accblock,SARLongint(lastblock+thisblock,2));
        end;
       end;
      end;
      if op.granulepos<>-1 then begin
       link:=vf^.current_link;
       granulepos:=op.granulepos-vf^.pcmlengths[link*2];
       if granulepos<0 then begin
        granulepos:=0;
       end;
       for i:=0 to link-1 do begin
        inc(granulepos,vf^.pcmlengths[(i*2)+1]);
       end;
       vf^.pcm_offset:=granulepos-accblock;
       if vf^.pcm_offset<0 then begin
        vf^.pcm_offset:=0;
       end;
       break;
      end;
      lastblock:=thisblock;
      continue;
     end else begin
      ogg_stream_packetout(vf^.os,Nil);
     end;
    end;
   end;
   if lastblock=0 then begin
    pagepos:=_get_next_page(vf,@og,-1);
    if pagepos<0 then begin
     vf^.pcm_offset:=ov_pcm_total(vf,-1);
     break;
    end;
   end else begin
    vf^.pcm_offset:=-1;
    break;
   end;
   if vf^.ready_state>=STREAMSET then begin
    if vf^.current_serialno<>ogg_page_serialno(@og) then begin
     if ogg_page_bos(@og)<>0 then begin
      _decode_clear(vf);
      ogg_stream_destroy(work_os);
     end;
    end;
   end;
   if vf^.ready_state<STREAMSET then begin
    serialno:=ogg_page_serialno(@og);
    link:=0;
    while link<vf^.links do begin
     if vf^.serialnos^[link]=longword(vf^.current_serialno) then begin
      break;
     end;
     inc(link);
    end;
    if link=vf^.links then begin
     continue;
    end;
    vf^.current_link:=link;
    vf^.current_serialno:=serialno;
    ogg_stream_reset_serialno(vf^.os,vf^.current_serialno);
    ogg_stream_reset_serialno(work_os,vf^.current_serialno);
    vf^.ready_state:=STREAMSET;
    firstflag:=ord(pagepos<=vf^.dataoffsets[link]) and 1;
   end;
   ogg_page_dup(@dup,@og);
   lastflag:=ogg_page_eos(@og);
   ogg_stream_pagein(vf^.os,@og);
   ogg_stream_pagein(work_os,@dup);
  end;
 end;
 ogg_packet_release(@op);
 ogg_page_release(@og);
 ogg_stream_destroy(work_os);
 vf^.bittrack:=0;
 vf^.samptrack:=0;
 result:=0;
 exit;
seek_error:
 ogg_packet_release(@op);
 ogg_page_release(@og);
 vf^.pcm_offset:=-1;
 ogg_stream_destroy(work_os);
 _decode_clear(vf);
 result:=OV_EBADLINK;
end;

function ov_pcm_seek_page(vf:POggVorbis_File;pos:ogg_int64_t):longint;
label seek_error;
var link:longint;
    total,end_,begin_,begintime,endtime,target,best,bisect,granulepos:int64;
    og:ogg_page;
    op:ogg_packet;
begin
//link:=-1;
//result:=0;
 total:=ov_pcm_total(vf,-1);
 FillChar(og,SizeOf(ogg_page),AnsiChar(#0));
 FillChar(op,SizeOf(ogg_packet),AnsiChar(#0));
 if vf^.ready_state<OPENED then begin
  result:=OV_EINVAL;
  exit;
 end;
 if vf^.seekable=0 then begin
  result:=OV_ENOSEEK;
  exit;
 end;
 if (pos<0) or (pos>total) then begin
  result:=OV_EINVAL;
  exit;
 end;
 link:=vf^.links-1;
 while link>=0 do begin
  dec(total,vf^.pcmlengths[(link*2)+1]);
  if pos>=total then begin
   break;
  end;
  dec(link);
 end;
 begin
  end_:=vf^.offsets[link+1];
  begin_:=vf^.offsets[link];
  begintime:=vf^.pcmlengths[link*2];
  endtime:=vf^.pcmlengths[(link*2)+1]+begintime;
  target:=(pos-total)+begintime;
  best:=begin_;
  while begin_<end_ do begin
   if (end_-begin_)<CHUNKSIZE then begin
    bisect:=begin_;
   end else begin
    bisect:=(begin_+(((target-begintime)*(end_-begin_)) div (endtime-begintime)))-CHUNKSIZE;
    if bisect<=begin_ then begin
     bisect:=begin_+1;
    end;
   end;
   _seek_helper(vf,bisect);
   while begin_<end_ do begin
    result:=_get_next_page(vf,@og,end_-vf^.offset);
    if result=OV_EREAD then begin
     goto seek_error;
    end;
    if result<0 then begin
     if bisect<=begin_+1 then begin
      end_:=begin_;
     end else begin
      if bisect=0 then begin
       goto seek_error;
      end;
      dec(bisect,CHUNKSIZE);
      if bisect<=begin_ then begin
       bisect:=begin_+1;
      end;
      _seek_helper(vf,bisect);
     end;
    end else begin
     granulepos:=ogg_page_granulepos(@og);
     if granulepos=-1 then begin
      continue;
     end;
     if granulepos<target then begin
      best:=result;
      begin_:=vf^.offset;
      begintime:=granulepos;
      if (target-begintime)>44100 then begin
       break;
      end;
      bisect:=begin_;
     end else begin
      if bisect<=(begin_+1) then begin
       end_:=begin_;
      end else begin
       if end_=vf^.offset then begin
        end_:=result;
        dec(bisect,CHUNKSIZE);
        if bisect<=begin_ then begin
         bisect:=begin_+1;
        end;
        _seek_helper(vf,bisect);
       end else begin
        end_:=result;
        endtime:=granulepos;
        break;
       end;
      end;
     end;
    end;
   end;
  end;
  begin
   result:=_seek_helper(vf,best);
   vf^.pcm_offset:=-1;
   if result<>0 then begin
    goto seek_error;
   end;
   result:=_get_next_page(vf,@og,-1);
   if result<0 then begin
    goto seek_error;
   end;
   if link<>vf^.current_link then begin
    _decode_clear(vf);
	  vf^.current_link:=link;
    vf^.current_serialno:=ogg_page_serialno(@og);
    vf^.ready_state:=STREAMSET;
	 end else begin
    vorbis_synthesis_restart(@vf^.vd);
   end;
   ogg_stream_reset_serialno(vf^.os,vf^.current_serialno);
   ogg_stream_pagein(vf^.os,@og);
   while true do begin
    result:=ogg_stream_packetpeek(vf^.os,@op);
    if result=0 then begin
     result:=_seek_helper(vf,best);
     if result<0 then begin
      goto seek_error;
     end;
     while true do begin
      result:=_get_prev_page(vf,@og);
      if result<0 then begin
       goto seek_error;
      end;
      if (ogg_page_serialno(@og)=longword(vf^.current_serialno)) and ((ogg_page_granulepos(@og)>-1) or (ogg_page_continued(@og)=0)) then begin
       result:=ov_raw_seek(vf,result);
       exit;
      end;
      vf^.offset:=result;
     end;
    end;
    if result<0 then begin
     result:=OV_EBADPACKET;
     goto seek_error;
    end;
    if op.granulepos<>-1 then begin
     vf^.pcm_offset:=op.granulepos-vf^.pcmlengths[vf^.current_link*2];
     if vf^.pcm_offset<0 then begin
      vf^.pcm_offset:=0;
     end;
     inc(vf^.pcm_offset,total);
     break;
    end else begin
     result:=ogg_stream_packetout(vf^.os,nil);
     exit;
    end;
   end;
  end;
 end;
 if (vf^.pcm_offset>pos) or (pos>ov_pcm_total(vf,-1)) then begin
  result:=OV_EFAULT;
  goto seek_error;
 end;
 vf^.bittrack:=0;
 vf^.samptrack:=0;
 ogg_page_release(@og);
 ogg_packet_release(@op);
 result:=0;
 exit;
seek_error:
 ogg_page_release(@og);
 ogg_packet_release(@op);
 vf^.pcm_offset:=-1;
 _decode_clear(vf);
end;

function ov_pcm_seek(vf:POggVorbis_File;pos:ogg_int64_t):longint;
var og:ogg_page;
    op:ogg_packet;
    thisblock,lastblock,ret,i,serialno,link,samples:longint;
    target:int64;
begin
 FillChar(og,SizeOf(ogg_page),AnsiChar(#0));
 FillChar(op,SizeOf(ogg_packet),AnsiChar(#0));
 lastblock:=0;
 ret:=ov_pcm_seek_page(vf,pos);
 if ret<0 then begin
  result:=ret;
  exit;
 end;
 _make_decode_ready(vf);
 while true do begin
  ret:=ogg_stream_packetpeek(vf^.os,@op);
  if ret>0 then begin
   thisblock:=vorbis_packet_blocksize(@vf^.vi^[vf^.current_link],@op);
   if thisblock<0 then begin
    ogg_stream_packetout(vf^.os,nil);
    continue;
   end;
   if lastblock<>0 then begin
    inc(vf^.pcm_offset,SARLongint(lastblock+thisblock,2));
   end;
   if (vf^.pcm_offset+SARLongint((thisblock+vorbis_info_blocksize(@vf^.vi^[0],1)),2))>=pos then begin
    break;
   end;
   ogg_stream_packetout(vf^.os,nil);
   vorbis_synthesis(@vf^.vb,@op,0);
   vorbis_synthesis_blockin(@vf^.vd,@vf^.vb);
   if op.granulepos>-1 then begin
    vf^.pcm_offset:=op.granulepos-vf^.pcmlengths[vf^.current_link*2];
    if vf^.pcm_offset<0 then begin
     vf^.pcm_offset:=0;
    end;
    for i:=0 to vf^.current_link-1 do begin
     inc(vf^.pcm_offset,vf^.pcmlengths[(i*2)+1]);
    end;
   end;
   lastblock:=thisblock;
  end else begin
   if(ret<0) and (ret<>OV_HOLE) then begin
    break;
   end;
   if _get_next_page(vf,@og,-1)<0 then begin
    break;
   end;
   if ogg_page_bos(@og)<>0 then begin
    _decode_clear(vf);
   end;
   if vf^.ready_state<STREAMSET then begin
    serialno:=ogg_page_serialno(@og);
    link:=0;
    while link<vf^.links do begin
     if vf^.serialnos^[link]=longword(serialno) then begin
      break;
     end;
     inc(link);
    end;
    if link=vf^.links then begin
     continue;
    end;
    vf^.current_link:=link;
    vf^.ready_state:=STREAMSET;
    vf^.current_serialno:=ogg_page_serialno(@og);
    ogg_stream_reset_serialno(vf^.os,serialno);
    ret:=_make_decode_ready(vf);
    if ret<>0 then begin
     ogg_page_release(@og);
     ogg_packet_release(@op);
     result:=ret;
     exit;
    end;
    lastblock:=0;
   end;
   ogg_stream_pagein(vf^.os,@og);
  end;
 end;
 vf^.bittrack:=0;
 vf^.samptrack:=0;
 while vf^.pcm_offset<pos do begin
  target:=pos-vf^.pcm_offset;
  samples:=vorbis_synthesis_pcmout(@vf^.vd,nil);
  if samples>target then begin
   samples:=target;
  end;
  vorbis_synthesis_read(@vf^.vd,samples);
  inc(vf^.pcm_offset,samples);
  if samples<target then begin
   if _fetch_and_process_packet(vf,1,1)<=0 then begin
    vf^.pcm_offset:=ov_pcm_total(vf,-1);
   end;
  end;
 end;
 ogg_page_release(@og);
 ogg_packet_release(@op);
 result:=0;
end;

function ov_time_seek(vf:POggVorbis_File;milliseconds:ogg_int64_t):longint;
var link:longint;
    pcm_total,time_total,addsec,target:int64;
begin
 pcm_total:=0;
 time_total:=0;
 if vf^.ready_state<OPENED then begin
  result:=OV_EINVAL;
  exit;
 end;
 if vf^.seekable=0 then begin
  result:=OV_ENOSEEK;
  exit;
 end;
 if milliseconds<0 then begin
  result:=OV_EINVAL;
  exit;
 end;
 link:=0;
 while link<vf^.links do begin
  addsec:=ov_time_total(vf,link);
  if milliseconds<(time_total+addsec) then begin
   break;
  end;
  inc(time_total,addsec);
  inc(pcm_total,vf^.pcmlengths^[(link*2)+1]);
  inc(link);
 end;
 if link=vf^.links then begin
  result:=OV_EINVAL;
  exit;
 end;
 target:=pcm_total+(((milliseconds-time_total)*vf^.vi[link].rate) div 1000);
 result:=ov_pcm_seek(vf,target);
end;

function ov_time_seek_page(vf:POggVorbis_File;milliseconds:ogg_int64_t):longint;
var link:longint;
    pcm_total,time_total,addsec,target:int64;
begin
 pcm_total:=0;
 time_total:=0;
 if vf^.ready_state<OPENED then begin
  result:=OV_EINVAL;
  exit;
 end;
 if vf^.seekable=0 then begin
  result:=OV_ENOSEEK;
  exit;
 end;
 if milliseconds<0 then begin
  result:=OV_EINVAL;
  exit;
 end;
 link:=0;
 while link<vf^.links do begin
  addsec:=ov_time_total(vf,link);
  if milliseconds<(time_total+addsec) then begin
   break;
  end;
  inc(time_total,addsec);
  inc(pcm_total,vf^.pcmlengths^[(link*2)+1]);
  inc(link);
 end;
 if link=vf^.links then begin
  result:=OV_EINVAL;
  exit;
 end;
 target:=pcm_total+(((milliseconds-time_total)*vf^.vi[link].rate) div 1000);
 result:=ov_pcm_seek_page(vf,target);
end;

function ov_raw_tell(vf:POggVorbis_File):ogg_int64_t;
begin
 if vf^.ready_state<OPENED then begin
  result:=OV_EINVAL;
  exit;
 end;
 result:=vf^.offset;
end;

function ov_pcm_tell(vf:POggVorbis_File):ogg_int64_t;
begin
 if vf^.ready_state<OPENED then begin
  result:=OV_EINVAL;
  exit;
 end;
 result:=vf^.pcm_offset;
end;

function ov_time_tell(vf:POggVorbis_File):ogg_int64_t;
var link:longinT;
    pcm_total,time_total:int64;
begin
 link:=0;
 pcm_total:=0;
 time_total:=0;
 if vf^.ready_state<OPENED then begin
  result:=OV_EINVAL;
  exit;
 end;
 if vf^.seekable<>0 then begin
  pcm_total:=ov_pcm_total(vf,-1);
  time_total:=ov_time_total(vf,-1);
  link:=vf^.links-1;
  while link>=0 do begin
   dec(pcm_total,vf^.pcmlengths[(link*2)+1]);
   dec(time_total,ov_time_total(vf,link));
   if vf^.pcm_offset>=pcm_total then begin
    break;
   end;
   dec(link);
  end;
 end;
 result:=time_total+(((1000*vf^.pcm_offset)-pcm_total) div vf^.vi[link].rate);
end;

function ov_info(vf:POggVorbis_File;link:longint):Pvorbis_info;
begin
 if vf^.seekable<>0 then begin
  if link<0 then begin
   if vf^.ready_state>=STREAMSET then begin
    result:=@vf^.vi^[vf^.current_link];
   end else begin
    result:=@vf^.vi[0];
   end;
  end else begin
   if link>=vf^.links then begin
    result:=nil;
   end else begin
    result:=@vf^.vi[link];
   end;
  end;
 end else begin
  result:=@vf^.vi[0];
 end;
end;

function ov_comment(vf:POggVorbis_File;link:longint):Pvorbis_comment;
begin
 if vf^.seekable<>0 then begin
  if link<0 then begin
   if vf^.ready_state>=STREAMSET then begin
    result:=@vf^.vc^[vf^.current_link];
   end else begin
    result:=@vf^.vc[0];
   end;
  end else begin
   if link>=vf^.links then begin
    result:=nil;
   end else begin
    result:=@vf^.vc[link];
   end;
  end;
 end else begin
  result:=@vf^.vc[0];
 end;
end;

function ov_read(vf:POggVorbis_File;buffer:pointer;bytes_req:longint;bitstream:PLongint):longint;
var i,j,ret,samples,channels:longint;
    pcm:PPLongints;
    src:PLongints;
    dest:PSmallInts;
begin
 if vf^.ready_state<OPENED then begin
  result:=OV_EINVAL;
  exit;
 end;
 samples:=0;
 while true do begin
  if vf^.ready_state=INITSET then begin
   samples:=vorbis_synthesis_pcmout(@vf^.vd,@pcm);
   if samples<>0 then begin
    break;
   end;
  end;
  ret:=_fetch_and_process_packet(vf,1,1);
  if ret=OV_EOF then begin
   result:=0;
   exit;
  end else if ret<=0 then begin
   result:=0;
   exit;
  end;
 end;
 if samples>0 then begin
  channels:=ov_info(vf,-1)^.channels;
  if samples>(bytes_req div (2*channels)) then begin
   samples:=bytes_req div (2*channels);
  end;
  for i:=0 to channels-1 do begin
   src:=pcm[i];
   dest:=@PSmallints(buffer)^[i];
   for j:=0 to samples-1 do begin
    dest^[0]:=CLIP_TO_15(SARLongint(src^[j],9));
    dest:=@dest^[channels];
   end;
  end;
  vorbis_synthesis_read(@vf^.vd,samples);
  inc(vf^.pcm_offset,samples);
  if assigned(bitstream) then begin
   bitstream^:=vf^.current_link;
  end;
  result:=samples*sizeof(smallint)*channels;
 end else begin
  result:=samples;
 end;
end;

end.