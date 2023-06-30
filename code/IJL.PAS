unit IJL;

{$Z4,A+,OA+}

//Caution! It must be 8-byte alignment structures.

interface

uses
  Windows;

type
  IJL_UINT64 = TULargeInteger;
  TIJLERR = Integer;

const
  JBUFSIZE  = 4096;    // Size of file I/O buffer (4K).

type
  PIJLibVersion = ^TIJLibVersion;
  TIJLibVersion = record
    Major           : Integer;
    Minor           : Integer;
    Build           : Integer;
    Name            : PChar;
    Version         : PChar;
    InternalVersion : PChar;
    BuildDate       : PChar;
    CallConv        : PChar;
  end;

  PIJL_RECT = ^TIJL_RECT;
  TIJL_RECT = record
    Left   : Longint;
    Top    : Longint;
    Right  : Longint;
    Bottom : Longint;
  end;

  TIJL_HANDLE = Pointer;

const
  IJL_SETUP = -1;
type
  TIJLIOType = (
    // Read JPEG parameters (i.e., height, width, channels, sampling, etc.)
    // from a JPEG bit stream.
    IJL_JFILE_READPARAMS,      //    =  0
    IJL_JBUFF_READPARAMS,      //    =  1

    // Read a JPEG Interchange Format image.
    IJL_JFILE_READWHOLEIMAGE,  //    =  2
    IJL_JBUFF_READWHOLEIMAGE,  //    =  3

    // Read JPEG tables from a JPEG Abbreviated Format bit stream.
    IJL_JFILE_READHEADER,      //    =  4,
    IJL_JBUFF_READHEADER,      //    =  5,

    // Read image info from a JPEG Abbreviated Format bit stream.
    IJL_JFILE_READENTROPY,     //    =  6
    IJL_JBUFF_READENTROPY,     //    =  7

    // Write an entire JFIF bit stream.
    IJL_JFILE_WRITEWHOLEIMAGE, //    =  8
    IJL_JBUFF_WRITEWHOLEIMAGE, //    =  9

    // Write a JPEG Abbreviated Format bit stream.
    IJL_JFILE_WRITEHEADER,     //    = 10
    IJL_JBUFF_WRITEHEADER,     //    = 11

    // Write image info to a JPEG Abbreviated Format bit stream.
    IJL_JFILE_WRITEENTROPY,    //    = 12
    IJL_JBUFF_WRITEENTROPY,    //    = 13


    // Scaled Decoding Options:

    // Reads a JPEG image scaled to 1/2 size.
    IJL_JFILE_READONEHALF,     //    = 14
    IJL_JBUFF_READONEHALF,     //    = 15

    // Reads a JPEG image scaled to 1/4 size.
    IJL_JFILE_READONEQUARTER,  //    = 16
    IJL_JBUFF_READONEQUARTER,  //    = 17

    // Reads a JPEG image scaled to 1/8 size.
    IJL_JFILE_READONEEIGHTH,   //    = 18
    IJL_JBUFF_READONEEIGHTH,   //    = 19

    // Reads an embedded thumbnail from a JFIF bit stream.
    IJL_JFILE_READTHUMBNAIL,   //    = 20
    IJL_JBUFF_READTHUMBNAIL    //    = 21
    );

  TIJL_COLOR = (
    IJL_PAD1,      // = 0   // Stub for Delphi, enum type start with 0
    IJL_RGB,       // = 1   // Red-Green-Blue color space.
    IJL_BGR,       // = 2   // Reversed channel ordering from IJL_RGB.
    IJL_YCBCR,     // = 3   // Luminance-Chrominance color space as defined
                            // by CCIR Recommendation 601.
    IJL_G,         // = 4   // Grayscale color space.
    IJL_RGBA_FPX,  // = 5   // FlashPix RGB 4 channel color space that
                            // has pre-multiplied opacity.
    IJL_YCBCRA_FPX // = 6   // FlashPix YCbCr 4 channel color space that
                            // has pre-multiplied opacity.
    //IJL_OTHER  = 255      // Some other color space not defined by the IJL.
                            // (This means no color space conversion will
                            //  be done by the IJL.)
    );

  TIJL_JPGSUBSAMPLING = (
    IJL_PAD2,      // = 0     // Stub for Delphi, enum type start with 0
    IJL_411,       // = 1,    // Valid on a JPEG w/ 3 channels.
    IJL_422,       // = 2,    // Valid on a JPEG w/ 3 channels.
    IJL_4114,      // = 3,    // Valid on a JPEG w/ 4 channels.
    IJL_4224       // = 4     // Valid on a JPEG w/ 4 channels.
    );

  TIJL_DIBSUBSAMPLING = TIJL_JPGSUBSAMPLING;

  PHUFFMAN_TABLE = ^THUFFMAN_TABLE;
  THUFFMAN_TABLE = record
    huff_class : Integer;
    ident      : Integer;
    huffelem   : array [0..255] of UINT;
    huffval    : array [0..255] of SHORT;
    mincode    : array [0..16]  of SHORT;
    maxcode    : array [0..17]  of SHORT;
    valptr     : array [0..16]  of SHORT;
  end;

  PJPEGHuffTable = ^TJPEGHuffTable;
  TJPEGHuffTable = record
    bits   : PUCHAR;
    vals   : PUCHAR;
    hclass : UCHAR;
    ident  : UCHAR;
  end;

  PQUANT_TABLE = ^TQUANT_TABLE;
  TQUANT_TABLE = record
    precision : Integer;
    ident     : Integer;
    elements  : PSHORT;
    elarray   : array [0..83] of Short;
  end;

  PJPEGQuantTable = ^TJPEGQuantTable;
  TJPEGQuantTable = record
    quantizer : PUCHAR;
    ident     : UCHAR;
  end;

  PFRAME_COMPONENT = ^TFRAME_COMPONENT;
  TFRAME_COMPONENT = record
    ident     : Integer;
    hsampling : Integer;
    vsampling : Integer;
    quant_sel : Integer;
  end;

  PFRAME = ^TFRAME;
  TFRAME = record
    precision      : Integer;
    width          : Integer;
    height         : Integer;
    MCUheight      : Integer;
    MCUwidth       : Integer;
    max_hsampling  : Integer;
    max_vsampling  : Integer;
    ncomps         : Integer;
    horMCU         : Integer;
    totalMCU       : Longint;
    comps          : PFRAME_COMPONENT;
    restart_interv : Integer;
    SeenAllDCScans : Integer;
    SeenAllACScans : Integer;
  end;

  PSCAN_COMPONENT = ^TSCAN_COMPONENT;
  TSCAN_COMPONENT = record
    comp        : Integer;
    hsampling   : Integer;
    vsampling   : Integer;
    dc_table    : PHUFFMAN_TABLE;
    ac_table    : PHUFFMAN_TABLE;
    quant_table : PQUANT_TABLE;
  end;

  PSCAN = ^TSCAN;
  TSCAN = record
    ncomps         : Integer;
    gray_scale     : Integer;
    start_spec     : Integer;
    end_spec       : Integer;
    approx_high    : Integer;
    approx_low     : Integer;
    restart_interv : UINT;
    curxMCU        : DWORD;
    curyMCU        : DWORD;
    dc_diff        : array [0..3] of Integer;
    comps          : PSCAN_COMPONENT;
  end;

  TDCTTYPE = (
    IJL_AAN,   // = 0
    IJL_IPP    // = 1
  );

  TUPSAMPLING_TYPE = (
    IJL_BOX_FILTER,     // = 0
    IJL_TRIANGLE_FILTER // = 1
  );

  PSAMPLING_STATE = ^TSAMPLING_STATE;
  TSAMPLING_STATE = record
    top_row        : PShort;
    cur_row        : PShort;
    bottom_row     : PShort;
    last_row       : PShort;
    cur_row_number : Integer;
  end;

  TPROCESSOR_TYPE = (
    IJL_OTHER_PROC,            // = 0,
    IJL_PENTIUM_PROC,          // = 1,
    IJL_PENTIUM_PRO_PROC,      // = 2,
    IJL_PENTIUM_PROC_MMX_TECH, // = 3,
    IJL_PENTIUM_II_PROC,       // = 4
    IJL_PENTIUM_III_PROC       // = 5
  );

  PENTROPYSTRUCT = ^TENTROPYSTRUCT;
  TENTROPYSTRUCT = record
    offset            : DWORD;
    dcval1            : Integer;
    dcval2            : Integer;
    dcval3            : Integer;
    dcval4            : Integer;
    bit_buffer_64     : IJL_UINT64;
    bitbuf_bits_valid : Integer;
    unread_marker     : Byte;
  end;

//  PSTATE = ^TSTATE;
  TSTATE = record
    // Bit buffer.
    bit_buffer_64     : IJL_UINT64;
    bit_buffer_32     : DWORD;
    bitbuf_bits_valid : Integer;

    // Entropy.
    cur_entropy_ptr         : PByte;
    start_entropy_ptr       : PByte;
    end_entropy_ptr         : PByte;
    entropy_bytes_processed : Longint;
    entropy_buf_maxsize     : Longint;
    entropy_bytes_left      : Integer;
    Prog_EndOfBlock_Run     : Integer;

    // Input or output DIB.
    DIB_ptr        : PByte;

    unread_marker  : Byte;
    processor_type : TPROCESSOR_TYPE;
    cur_scan_comp  : Integer;
    hFile          : TIJL_HANDLE; //THandle;
    JPGBuffer      : array [0..JBUFSIZE-1] of Byte;
  end;

  TFAST_MCU_PROCESSING_TYPE = (
    IJL_NO_CC_OR_US,                   //  = 0,

    IJL_111_YCBCR_111_RGB,             //  = 1,
    IJL_111_YCBCR_111_BGR,             //  = 2,

    IJL_411_YCBCR_111_RGB,             //  = 3,
    IJL_411_YCBCR_111_BGR,             //  = 4,

    IJL_422_YCBCR_111_RGB,             //  = 5,
    IJL_422_YCBCR_111_BGR,             //  = 6,

    IJL_111_YCBCR_1111_RGBA_FPX,       //  = 7,
    IJL_411_YCBCR_1111_RGBA_FPX,       //  = 8,
    IJL_422_YCBCR_1111_RGBA_FPX,       //  = 9,

    IJL_1111_YCBCRA_FPX_1111_RGBA_FPX, //  = 10,
    IJL_4114_YCBCRA_FPX_1111_RGBA_FPX, //  = 11,
    IJL_4224_YCBCRA_FPX_1111_RGBA_FPX, //  = 12,

    IJL_111_RGB_1111_RGBA_FPX,         //  = 13,

    IJL_1111_RGBA_FPX_1111_RGBA_FPX    //  = 14
  );

  PJPEG_PROPERTIES = ^TJPEG_PROPERTIES;
  TJPEG_PROPERTIES = record
    // Compression/Decompression control.
    iotype          : TIJLIOTYPE;                // default = IJL_SETUP
    roi             : TIJL_RECT;                 // default = 0
    dcttype         : TDCTTYPE;                  // default = IJL_AAN
    fast_processing : TFAST_MCU_PROCESSING_TYPE; // default = IJL_NO_CC_OR_US
    intr            : DWORD;                     // default = FALSE

    // DIB specific I/O data specifiers.
    DIBBytes       : PByte;               // default = NULL
    DIBWidth       : DWORD;               // default = 0
    DIBHeight      : Integer;             // default = 0
    DIBPadBytes    : DWORD;               // default = 0
    DIBChannels    : DWORD;               // default = 3
    DIBColor       : TIJL_COLOR;          // default = IJL_BGR
    DIBSubsampling : TIJL_DIBSUBSAMPLING; // default = IJL_NONE
    DIBLineBytes   : Integer;             // default = 0

    // JPEG specific I/O data specifiers.
    JPGFile        : PChar;               // default = NULL
    JPGBytes       : PByte;               // default = NULL
    JPGSizeBytes   : DWORD;               // default = 0
    JPGWidth       : DWORD;               // default = 0
    JPGHeight      : DWORD;               // default = 0
    JPGChannels    : DWORD;               // default = 3
    JPGColor       : TIJL_COLOR;          // default = IJL_YCBCR
    JPGSubsampling : TIJL_JPGSUBSAMPLING; // default = IJL_411
    JPGThumbWidth  : DWORD;               // default = 0
    JPGThumbHeight : DWORD;               // default = 0

    // JPEG conversion properties.
    cconversion_reqd : DWORD;             // default = TRUE
    upsampling_reqd  : DWORD;             // default = TRUE
    jquality         : DWORD;             // default = 75
    jinterleaveType  : DWORD;             // default = 0
    numxMCUs         : DWORD;             // default = 0
    numyMCUs         : DWORD;             // default = 0

    // Tables.
    nqtables      : DWORD;
    maxquantindex : DWORD;
    nhuffActables : DWORD;
    nhuffDctables : DWORD;
    maxhuffindex  : DWORD;

    jFmtQuant     : array [0..3] of TQUANT_TABLE;
    jFmtAcHuffman : array [0..3] of THUFFMAN_TABLE;
    jFmtDcHuffman : array [0..3] of THUFFMAN_TABLE;

    jEncFmtQuant     : array [0..3] of PSHORT;
    jEncFmtAcHuffman : array [0..3] of PHUFFMAN_TABLE;
    jEncFmtDcHuffman : array [0..3] of PHUFFMAN_TABLE;

    // Allow user-defined tables.
    use_default_qtables : DWORD;
    use_default_htables : DWORD;

    rawquanttables   : array [0..3] of TJPEGQuantTable;
    rawhufftables    : array [0..7] of TJPEGHuffTable;
    HuffIdentifierAC : array [0..3] of Byte;
    HuffIdentifierDC : array [0..3] of Byte;

    // Frame specific members.
    jframe    : TFRAME;
    needframe : Integer;

    // SCAN persistent members.
    jscan : PSCAN;

    Pad   : DWORD;  // 8-byte alignment!!!

    // State members.
    state          : TSTATE;
    SawAdobeMarker : DWORD;
    AdobeXform     : DWORD;

    // ROI decoder members.
    rowoffsets : PENTROPYSTRUCT;

    // Intermediate buffers.
    MCUBuf  : PByte;
    tMCUBuf : array [0..720*2-1] of Byte; // ???

    // Processor detected.
    processor_type : TPROCESSOR_TYPE;

    // Test specific members.
    ignoreDCTs : DWORD;

    // Progressive mode members.
    progressive_found : Integer;
    coef_buffer       : PShort;

    // Upsampling mode members.
    upsampling_type    : TUPSAMPLING_TYPE;
    sampling_state_ptr : PSAMPLING_STATE;

    // Adobe APP14 segment variables
    AdobeVersion : Short;         // default = 100
    AdobeFlags0  : Short;         // default = 0
    AdobeFlags1  : Short;         // default = 0

    // JFIF APP0 segment variables
    jfif_app0_detected : Integer;
    jfif_app0_version  : Short;    // default = 0x0101
    jfif_app0_units    : UCHAR;    // default = 0 - pixel
    jfif_app0_Xdensity : Short;    // default = 1
    jfif_app0_Ydensity : Short;    // default = 1

    // comments related fields
    jpeg_comment      : PChar;     // default = NULL
    jpeg_comment_size : Short;     // default = 0

  end;

type
  PJPEG_CORE_PROPERTIES = ^TJPEG_CORE_PROPERTIES;
  TJPEG_CORE_PROPERTIES = record
    UseJPEGPROPERTIES : DWORD;               // default = 0

    // DIB specific I/O data specifiers.
    DIBBytes          : PByte;               // default = NULL
    DIBWidth          : DWORD;               // default = 0
    DIBHeight         : Integer;             // default = 0
    DIBPadBytes       : DWORD;               // default = 0
    DIBChannels       : DWORD;               // default = 3
    DIBColor          : TIJL_COLOR;          // default = IJL_BGR
    DIBSubsampling    : TIJL_DIBSUBSAMPLING; // default = IJL_NONE

    // JPEG specific I/O data specifiers.
    JPGFile           : PChar;               // default = NULL
    JPGBytes          : PByte;               // default = NULL
    JPGSizeBytes      : DWORD;               // default = 0
    JPGWidth          : DWORD;               // default = 0
    JPGHeight         : DWORD;               // default = 0
    JPGChannels       : DWORD;               // default = 3
    JPGColor          : TIJL_COLOR;          // default = IJL_YCBCR
    JPGSubsampling    : TIJL_JPGSUBSAMPLING; // default = IJL_411
    JPGThumbWidth     : DWORD;               // default = 0
    JPGThumbHeight    : DWORD;               // default = 0

    // JPEG conversion properties.
    cconversion_reqd  : DWORD;               // default = TRUE
    upsampling_reqd   : DWORD;               // default = TRUE
    jquality          : DWORD;               // default = 75

    Pad               : DWORD;               // 8-byte alignment!!!
    // Low-level properties.
    jprops            : TJPEG_PROPERTIES;
  end;

const
  // The following "error" values indicate an "OK" condition.
  IJL_OK                              =   0;

var
  ijlInit : function(jcprops : PJPEG_CORE_PROPERTIES) : Integer; stdcall;
  ijlFree : function(jcprops : PJPEG_CORE_PROPERTIES) : Integer; stdcall;
  ijlRead : function(jcprops : PJPEG_CORE_PROPERTIES; IoType : TIJLIOTYPE) : Integer; stdcall;
  ijlWrite : function(jcprops : PJPEG_CORE_PROPERTIES; IoType : TIJLIOTYPE) : Integer; stdcall;
  jpgLib : HINST;

function InitJPG: Boolean;

implementation

function InitJPG: Boolean;
begin
  Result := True;
  jpgLib := LoadLibrary('ijl15.dll');
  if (jpgLib <> 0) then begin
    ijlInit  := GetProcAddress(jpgLib, 'ijlInit');
    ijlFree  := GetProcAddress(jpgLib, 'ijlFree');
    ijlRead  := GetProcAddress(jpgLib, 'ijlRead');
    ijlWrite := GetProcAddress(jpgLib, 'ijlWrite');
  end else
    Result := False;
end;

begin
  InitJPG;
end

postlude
begin
  FreeLibrary(jpgLib);
end.