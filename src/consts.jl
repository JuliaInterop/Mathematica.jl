# Constants - from mathlink.h

module Pkt
  const ILLEGAL    =   0

  const CALL       =   7
  const EVALUATE   =  13
  const RETURN     =   3

  const INPUTNAME  =   8
  const ENTERTEXT  =  14
  const ENTEREXPR  =  15
  const OUTPUTNAME =   9
  const RETURNTEXT =   4
  const RETURNEXPR =  16

  const DISPLAY    =  11
  const DISPLAYEND =  12

  const MESSAGE    =   5
  const TEXT       =   2

  const INPUT      =   1
  const INPUTSTR   =  21
  const MENU       =   6
  const SYNTAX     =  10

  const SUSPEND    =  17
  const RESUME     =  18

  const BEGINDLG   =  19
  const ENDDLG     =  20

  const FIRSTUSER  = 128
  const LASTUSER   = 255
end

module TK
  const OLDINT  =    'I'    # /* 73 Ox49 01001001 */ # /* integer leaf node */
  const OLDREAL =    'R'    # /* 82 Ox52 01010010 */ # /* real leaf node */

  const FUNC    = 'F'   # /* 70 Ox46 01000110 */ # /* non-leaf node */

  const ERROR   = char(0)   # /* bad token */
  const ERR     = char(0)   # /* bad token */

  const STR     = '"'         # /* 34 0x22 00100010 */
  const SYM     = '\043'      # /* 35 0x23 # 00100011 */ # /* octal here as hash requires a trigraph */

  const REAL    = '*'         # /* 42 0x2A 00101010 */
  const INT     = '+'         # /* 43 0x2B 00101011 */

  # /* The following defines are for internal use only */
  const PCTEND  = ']'     # /* at end of top level expression */
  const APCTEND = '\n'    # /* at end of top level expression */
  const END     = '\n'
  const AEND    = '\r'
  const SEND    = ','

  const CONT    = '\\'
  const ELEN    = ' '

  const NULL    = '.'
  const OLDSYM  = 'Y'     # /* 89 0x59 01011001 */
  const OLDSTR  = 'S'     # /* 83 0x53 01010011 */

  const PACKED  = 'P'     # /* 80 0x50 01010000 */
  const ARRAY   = 'A'     # /* 65 0x41 01000001 */
  const DIM     = 'D'     # /* 68 0x44 01000100 */
end
