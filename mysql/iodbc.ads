---------------------------------------------------------------------------
-- Interface for unix odbc using The iODBC driver manager.
--
-- Copyright (C) 2000 Sune Falck, Tullinge, SWEDEN
--
-- Sune.Falck@swipnet.se
---------------------------------------------------------------------------
-- This library is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Library General Public
-- License as published by the Free Software Foundation; either
-- version 2 of the License, or (at your option) any later version.
--
-- This library is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- Library General Public License for more details.
--
-- You should have received a copy of the GNU Library General Public
-- License along with this library; if not, write to the Free
-- Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
--
-- As a special exception, if other files instantiate generics from this
-- unit, or you link  this unit with other files  to produce an executable,
-- this unit does not by itself cause the resulting executable to be
-- covered  by the  GNU  General  Public  License. This exception does not
-- however invalidate any other reasons why the executable file might be
-- covered by the GNU Public License.
---------------------------------------------------------------------------
--
--  Derived from isql.h isqltypes.h and isqlext.h in libiodbc-2.50
--
--  See http://www.openlink.co.uk/iodbc/
--
--  Some small changes to the generated bindings
--
--  1) Handles are defined as System.Address instead of pointer to void
--
--  2) Pointer to unsigned char is defined as Interfaces.C.char_array,
--
--  3) ODBC integer types are defined as Interfaces.Integer_XX etc
--
--  4) The generated A_SDWORD_T types etc are substituted by access SDWORD ...
--
--  5) Changed parameter names henv, hdbc, hstmt, hwnd to env, dbc, stmt wnd
--     to avoid conflict with the same type names.
--
--  1999-04-21 Sune Falck
--
---------------------------------------------------------------------------
-- HISTORY
--   1999-05-19 Sune Falck
--      The new libiodbc-2.50.2 distribution used new type names
--      prefixed with SQL (SQLSMALLINT etc). Generated a new binding
--      and adjusted it according to the above points.
--      The old type names are kept as subtypes of the new names
--      to avoid having to change any existing code.
--
--   1999-07-05 Sune Falck
--     Reworked the binding from the libiodbc-2.50.3 distribution
--
--   1999-11-14 Sune Falck
--     Changed SQLRETURN and BOOKMARK to use type from Interfaces
--     instead of Interfaces.C

with Interfaces.C;
with System;

package Iodbc is

    ODBCVER             : constant := 16#0250#;               -- sql.h:33
    SQL_SPEC_MAJOR      : constant := 2;                      -- sql.h:47
    SQL_SPEC_MINOR      : constant := 50;                     -- sql.h:48
    SQL_SPEC_STRING     : constant string :=
                          "02.50"&ascii.nul;                  -- sql.h:49
    SQL_SQLSTATE_SIZE     : constant := 5;                    -- sql.h:51
    SQL_MAX_MESSAGE_LENGTH: constant := 16#0200#;             -- sql.h:52
    SQL_MAX_DSN_LENGTH    : constant := 16#0020#;             -- sql.h:53
    SQL_MAX_OPTION_STRING_LENGTH: constant := 16#0100#;       -- sql.h:54
    SQL_HANDLE_ENV              : constant := 1;              -- sql.h:59
    SQL_HANDLE_DBC              : constant := 2;              -- sql.h:60
    SQL_HANDLE_STMT             : constant := 3;              -- sql.h:61
    SQL_INVALID_HANDLE          : constant := -2;             -- sql.h:69
    SQL_ERROR                   : constant := -1;             -- sql.h:70
    SQL_SUCCESS                 : constant := 8#0000#;        -- sql.h:71
    SQL_SUCCESS_WITH_INFO       : constant := 1;              -- sql.h:72
    SQL_NO_DATA_FOUND           : constant := 100;            -- sql.h:73
    SQL_UNKNOWN_TYPE            : constant := 8#0000#;        -- sql.h:79
    SQL_CHAR                    : constant := 1;              -- sql.h:80
    SQL_NUMERIC                 : constant := 2;              -- sql.h:81
    SQL_DECIMAL                 : constant := 3;              -- sql.h:82
    SQL_INTEGER                 : constant := 4;              -- sql.h:83
    SQL_SMALLINT                : constant := 5;              -- sql.h:84
    SQL_FLOAT                   : constant := 6;              -- sql.h:85
    SQL_REAL                    : constant := 7;              -- sql.h:86
    SQL_DOUBLE                  : constant := 8;              -- sql.h:87
    SQL_VARCHAR                 : constant := 12;             -- sql.h:88
    SQL_TYPE_NULL               : constant := 8#0000#;        -- sql.h:90
--  SQL_TYPE_MIN                : constant := 1;              -- sql.h:91
    SQL_TYPE_MAX                : constant := 12;             -- sql.h:92
    SQL_C_CHAR                  : constant := 1;              -- sql.h:98
    SQL_C_LONG                  : constant := 4;              -- sql.h:99
    SQL_C_SHORT                 : constant := 5;              -- sql.h:100
    SQL_C_FLOAT                 : constant := 7;              -- sql.h:101
    SQL_C_DOUBLE                : constant := 8;              -- sql.h:102
    SQL_C_DEFAULT               : constant := 99;             -- sql.h:103
    SQL_NO_NULLS                : constant := 8#0000#;        -- sql.h:109
    SQL_NULLABLE                : constant := 1;              -- sql.h:110
    SQL_NULLABLE_UNKNOWN        : constant := 2;              -- sql.h:111
    SQL_NULL_DATA               : constant := -1;             -- sql.h:117
    SQL_DATA_AT_EXEC            : constant := -2;             -- sql.h:118
    SQL_NTS                     : constant := -3;             -- sql.h:119
    SQL_CLOSE                   : constant := 8#0000#;        -- sql.h:125
    SQL_DROP                    : constant := 1;              -- sql.h:126
    SQL_UNBIND                  : constant := 2;              -- sql.h:127
    SQL_RESET_PARAMS            : constant := 3;              -- sql.h:128
    SQL_COMMIT                  : constant := 8#0000#;        -- sql.h:134
    SQL_ROLLBACK                : constant := 1;              -- sql.h:135
    SQL_COLUMN_COUNT            : constant := 8#0000#;        -- sql.h:141
    SQL_COLUMN_NAME             : constant := 1;              -- sql.h:142
    SQL_COLUMN_TYPE             : constant := 2;              -- sql.h:143
    SQL_COLUMN_LENGTH           : constant := 3;              -- sql.h:144
    SQL_COLUMN_PRECISION        : constant := 4;              -- sql.h:145
    SQL_COLUMN_SCALE            : constant := 5;              -- sql.h:146
    SQL_COLUMN_DISPLAY_SIZE     : constant := 6;              -- sql.h:147
    SQL_COLUMN_NULLABLE         : constant := 7;              -- sql.h:148
    SQL_COLUMN_UNSIGNED         : constant := 8;              -- sql.h:149
    SQL_COLUMN_MONEY            : constant := 9;              -- sql.h:150
    SQL_COLUMN_UPDATABLE        : constant := 10;             -- sql.h:151
    SQL_COLUMN_AUTO_INCREMENT   : constant := 11;             -- sql.h:152
    SQL_COLUMN_CASE_SENSITIVE   : constant := 12;             -- sql.h:153
    SQL_COLUMN_SEARCHABLE       : constant := 13;             -- sql.h:154
    SQL_COLUMN_TYPE_NAME        : constant := 14;             -- sql.h:155
    SQL_COLUMN_TABLE_NAME       : constant := 15;             -- sql.h:156
    SQL_COLUMN_OWNER_NAME       : constant := 16#0010#;       -- sql.h:157
    SQL_COLUMN_QUALIFIER_NAME   : constant := 17;             -- sql.h:158
    SQL_COLUMN_LABEL            : constant := 18;             -- sql.h:159
    SQL_COLATT_OPT_MAX          : constant := 18;             -- sql.h:161
    SQL_COLATT_OPT_MIN          : constant := 8#0000#;        -- sql.h:162
    SQL_COLUMN_DRIVER_START     : constant := 1000;           -- sql.h:163
    SQL_ATTR_READONLY           : constant := 8#0000#;        -- sql.h:169
    SQL_ATTR_WRITE              : constant := 1;              -- sql.h:170
    SQL_ATTR_READWRITE_UNKNOWN  : constant := 2;              -- sql.h:171
    SQL_UNSEARCHABLE            : constant := 8#0000#;        -- sql.h:177
    SQL_LIKE_ONLY               : constant := 1;              -- sql.h:178
    SQL_ALL_EXCEPT_LIKE         : constant := 2;              -- sql.h:179
    SQL_SEARCHABLE              : constant := 3;              -- sql.h:180
    SQL_NULL_HENV               : constant := 8#0000#;        -- sql.h:186
    SQL_NULL_HDBC               : constant := 8#0000#;        -- sql.h:187
    SQL_NULL_HSTMT              : constant := 8#0000#;        -- sql.h:188
    SQL_STILL_EXECUTING         : constant := 2;              -- sqlext.h:40
    SQL_NEED_DATA               : constant := 99;             -- sqlext.h:41
    SQL_DATE                    : constant := 9;              -- sqlext.h:47
    SQL_TIME                    : constant := 10;             -- sqlext.h:48
    SQL_TIMESTAMP               : constant := 11;             -- sqlext.h:49
    SQL_LONGVARCHAR             : constant := -1;             -- sqlext.h:50
    SQL_BINARY                  : constant := -2;             -- sqlext.h:51
    SQL_VARBINARY               : constant := -3;             -- sqlext.h:52
    SQL_LONGVARBINARY           : constant := -4;             -- sqlext.h:53
    SQL_BIGINT                  : constant := -5;             -- sqlext.h:54
    SQL_TINYINT                 : constant := -6;             -- sqlext.h:55
    SQL_BIT                     : constant := -7;             -- sqlext.h:56
    SQL_INTERVAL_YEAR           : constant := -80;            -- sqlext.h:58
    SQL_INTERVAL_MONTH          : constant := -81;            -- sqlext.h:59
    SQL_INTERVAL_YEAR_TO_MONTH  : constant := -82;            -- sqlext.h:60
    SQL_INTERVAL_DAY            : constant := -83;            -- sqlext.h:61
    SQL_INTERVAL_HOUR           : constant := -84;            -- sqlext.h:62
    SQL_INTERVAL_MINUTE         : constant := -85;            -- sqlext.h:63
    SQL_INTERVAL_SECOND         : constant := -86;            -- sqlext.h:64
    SQL_INTERVAL_DAY_TO_HOUR    : constant := -87;            -- sqlext.h:65
    SQL_INTERVAL_DAY_TO_MINUTE  : constant := -88;            -- sqlext.h:66
    SQL_INTERVAL_DAY_TO_SECOND  : constant := -89;            -- sqlext.h:67
    SQL_INTERVAL_HOUR_TO_MINUTE : constant := -90;            -- sqlext.h:68
    SQL_INTERVAL_HOUR_TO_SECOND : constant := -91;            -- sqlext.h:69
    SQL_INTERVAL_MINUTE_TO_SECOND: constant := -92;           -- sqlext.h:70
    SQL_UNICODE                  : constant := -95;           -- sqlext.h:71
    SQL_UNICODE_VARCHAR          : constant := -96;           -- sqlext.h:72
    SQL_UNICODE_LONGVARCHAR      : constant := -97;           -- sqlext.h:73
    SQL_UNICODE_CHAR             : constant := -95;           -- sqlext.h:74
    SQL_TYPE_DRIVER_START        : constant := -80;           -- sqlext.h:76
    SQL_TYPE_DRIVER_END          : constant := -97;           -- sqlext.h:77
    SQL_SIGNED_OFFSET            : constant := -20;           -- sqlext.h:79
    SQL_UNSIGNED_OFFSET          : constant := -22;           -- sqlext.h:80
    SQL_C_DATE                   : constant := 9;             -- sqlext.h:86
    SQL_C_TIME                   : constant := 10;            -- sqlext.h:87
    SQL_C_TIMESTAMP              : constant := 11;            -- sqlext.h:88
    SQL_C_BINARY                 : constant := -2;            -- sqlext.h:89
    SQL_C_BIT                    : constant := -7;            -- sqlext.h:90
    SQL_C_TINYINT                : constant := -6;            -- sqlext.h:91
    SQL_C_SLONG                  : constant := -16;           -- sqlext.h:92
    SQL_C_SSHORT                 : constant := -15;           -- sqlext.h:93
    SQL_C_STINYINT               : constant := -26;           -- sqlext.h:94
    SQL_C_ULONG                  : constant := -18;           -- sqlext.h:95
    SQL_C_USHORT                 : constant := -17;           -- sqlext.h:96
    SQL_C_UTINYINT               : constant := -28;           -- sqlext.h:97
    SQL_C_BOOKMARK               : constant := -18;           -- sqlext.h:98
    SQL_TYPE_MIN                 : constant := -7;            -- sqlext.h:105
    SQL_ALL_TYPES                : constant := 8#0000#;       -- sqlext.h:106
    SQL_DRIVER_NOPROMPT          : constant := 8#0000#;       -- sqlext.h:118
    SQL_DRIVER_COMPLETE          : constant := 1;             -- sqlext.h:119
    SQL_DRIVER_PROMPT            : constant := 2;             -- sqlext.h:120
    SQL_DRIVER_COMPLETE_REQUIRED : constant := 3;             -- sqlext.h:121
    SQL_NO_TOTAL                 : constant := -4;            -- sqlext.h:127
    SQL_DEFAULT_PARAM            : constant := -5;            -- sqlext.h:133
    SQL_IGNORE                   : constant := -6;            -- sqlext.h:134
    SQL_LEN_DATA_AT_EXEC_OFFSET  : constant := -100;          -- sqlext.h:135
    SQL_API_SQLALLOCCONNECT      : constant := 1;             -- sqlext.h:142
    SQL_API_SQLALLOCENV          : constant := 2;             -- sqlext.h:143
    SQL_API_SQLALLOCSTMT         : constant := 3;             -- sqlext.h:144
    SQL_API_SQLBINDCOL           : constant := 4;             -- sqlext.h:145
    SQL_API_SQLCANCEL            : constant := 5;             -- sqlext.h:146
    SQL_API_SQLCOLATTRIBUTES     : constant := 6;             -- sqlext.h:147
    SQL_API_SQLCONNECT           : constant := 7;             -- sqlext.h:148
    SQL_API_SQLDESCRIBECOL       : constant := 8;             -- sqlext.h:149
    SQL_API_SQLDISCONNECT        : constant := 9;             -- sqlext.h:150
    SQL_API_SQLERROR             : constant := 10;            -- sqlext.h:151
    SQL_API_SQLEXECDIRECT        : constant := 11;            -- sqlext.h:152
    SQL_API_SQLEXECUTE           : constant := 12;            -- sqlext.h:153
    SQL_API_SQLFETCH             : constant := 13;            -- sqlext.h:154
    SQL_API_SQLFREECONNECT       : constant := 14;            -- sqlext.h:155
    SQL_API_SQLFREEENV           : constant := 15;            -- sqlext.h:156
    SQL_API_SQLFREESTMT          : constant := 16#0010#;      -- sqlext.h:157
    SQL_API_SQLGETCURSORNAME     : constant := 17;            -- sqlext.h:158
    SQL_API_SQLNUMRESULTCOLS     : constant := 18;            -- sqlext.h:159
    SQL_API_SQLPREPARE           : constant := 19;            -- sqlext.h:160
    SQL_API_SQLROWCOUNT          : constant := 20;            -- sqlext.h:161
    SQL_API_SQLSETCURSORNAME     : constant := 21;            -- sqlext.h:162
    SQL_API_SQLSETPARAM          : constant := 22;            -- sqlext.h:163
    SQL_API_SQLTRANSACT          : constant := 23;            -- sqlext.h:164
    SQL_NUM_FUNCTIONS            : constant := 23;            -- sqlext.h:166
    SQL_EXT_API_START            : constant := 40;            -- sqlext.h:168
    SQL_API_SQLCOLUMNS           : constant := 40;            -- sqlext.h:170
    SQL_API_SQLDRIVERCONNECT     : constant := 41;            -- sqlext.h:171
    SQL_API_SQLGETCONNECTOPTION  : constant := 42;            -- sqlext.h:172
    SQL_API_SQLGETDATA           : constant := 43;            -- sqlext.h:173
    SQL_API_SQLGETFUNCTIONS      : constant := 44;            -- sqlext.h:174
    SQL_API_SQLGETINFO           : constant := 45;            -- sqlext.h:175
    SQL_API_SQLGETSTMTOPTION     : constant := 46;            -- sqlext.h:176
    SQL_API_SQLGETTYPEINFO       : constant := 47;            -- sqlext.h:177
    SQL_API_SQLPARAMDATA         : constant := 48;            -- sqlext.h:178
    SQL_API_SQLPUTDATA           : constant := 49;            -- sqlext.h:179
    SQL_API_SQLSETCONNECTOPTION  : constant := 50;            -- sqlext.h:180
    SQL_API_SQLSETSTMTOPTION     : constant := 51;            -- sqlext.h:181
    SQL_API_SQLSPECIALCOLUMNS    : constant := 52;            -- sqlext.h:182
    SQL_API_SQLSTATISTICS        : constant := 53;            -- sqlext.h:183
    SQL_API_SQLTABLES            : constant := 54;            -- sqlext.h:184
    SQL_API_SQLBROWSECONNECT     : constant := 55;            -- sqlext.h:186
    SQL_API_SQLCOLUMNPRIVILEGES  : constant := 56;            -- sqlext.h:187
    SQL_API_SQLDATASOURCES       : constant := 57;            -- sqlext.h:188
    SQL_API_SQLDESCRIBEPARAM     : constant := 58;            -- sqlext.h:189
    SQL_API_SQLEXTENDEDFETCH     : constant := 59;            -- sqlext.h:190
    SQL_API_SQLFOREIGNKEYS       : constant := 60;            -- sqlext.h:191
    SQL_API_SQLMORERESULTS       : constant := 61;            -- sqlext.h:192
    SQL_API_SQLNATIVESQL         : constant := 62;            -- sqlext.h:193
    SQL_API_SQLNUMPARAMS         : constant := 63;            -- sqlext.h:194
    SQL_API_SQLPARAMOPTIONS      : constant := 16#0040#;      -- sqlext.h:195
    SQL_API_SQLPRIMARYKEYS       : constant := 65;            -- sqlext.h:196
    SQL_API_SQLPROCEDURECOLUMNS  : constant := 66;            -- sqlext.h:197
    SQL_API_SQLPROCEDURES        : constant := 67;            -- sqlext.h:198
    SQL_API_SQLSETPOS            : constant := 68;            -- sqlext.h:199
    SQL_API_SQLSETSCROLLOPTIONS  : constant := 69;            -- sqlext.h:200
    SQL_API_SQLTABLEPRIVILEGES   : constant := 70;            -- sqlext.h:201
    SQL_API_SQLDRIVERS           : constant := 71;            -- sqlext.h:203
    SQL_API_SQLBINDPARAMETER     : constant := 72;            -- sqlext.h:204
    SQL_EXT_API_LAST             : constant := 72;            -- sqlext.h:205
    SQL_API_ALL_FUNCTIONS        : constant := 8#0000#;       -- sqlext.h:207
    SQL_NUM_EXTENSIONS           : constant := 33;            -- sqlext.h:209
    SQL_API_LOADBYORDINAL        : constant := 199;           -- sqlext.h:211
    SQL_INFO_FIRST               : constant := 8#0000#;       -- sqlext.h:217
    SQL_ACTIVE_CONNECTIONS       : constant := 8#0000#;       -- sqlext.h:218
    SQL_ACTIVE_STATEMENTS        : constant := 1;             -- sqlext.h:219
    SQL_DATA_SOURCE_NAME         : constant := 2;             -- sqlext.h:220
    SQL_DRIVER_HDBC              : constant := 3;             -- sqlext.h:221
    SQL_DRIVER_HENV              : constant := 4;             -- sqlext.h:222
    SQL_DRIVER_HSTMT             : constant := 5;             -- sqlext.h:223
    SQL_DRIVER_NAME              : constant := 6;             -- sqlext.h:224
    SQL_DRIVER_VER               : constant := 7;             -- sqlext.h:225
    SQL_FETCH_DIRECTION          : constant := 8;             -- sqlext.h:226
    SQL_ODBC_API_CONFORMANCE     : constant := 9;             -- sqlext.h:227
    SQL_ODBC_VER                 : constant := 10;            -- sqlext.h:228
    SQL_ROW_UPDATES              : constant := 11;            -- sqlext.h:229
    SQL_ODBC_SAG_CLI_CONFORMANCE : constant := 12;            -- sqlext.h:230
    SQL_SERVER_NAME              : constant := 13;            -- sqlext.h:231
    SQL_SEARCH_PATTERN_ESCAPE    : constant := 14;            -- sqlext.h:232
    SQL_ODBC_SQL_CONFORMANCE     : constant := 15;            -- sqlext.h:233
    SQL_DBMS_NAME                : constant := 17;            -- sqlext.h:234
    SQL_DBMS_VER                 : constant := 18;            -- sqlext.h:235
    SQL_ACCESSIBLE_TABLES        : constant := 19;            -- sqlext.h:236
    SQL_ACCESSIBLE_PROCEDURES    : constant := 20;            -- sqlext.h:237
    SQL_PROCEDURES               : constant := 21;            -- sqlext.h:238
    SQL_CONCAT_NULL_BEHAVIOR     : constant := 22;            -- sqlext.h:239
    SQL_CURSOR_COMMIT_BEHAVIOR   : constant := 23;            -- sqlext.h:240
    SQL_CURSOR_ROLLBACK_BEHAVIOR : constant := 24;            -- sqlext.h:241
    SQL_DATA_SOURCE_READ_ONLY    : constant := 25;            -- sqlext.h:242
    SQL_DEFAULT_TXN_ISOLATION    : constant := 26;            -- sqlext.h:243
    SQL_EXPRESSIONS_IN_ORDERBY   : constant := 27;            -- sqlext.h:244
    SQL_IDENTIFIER_CASE          : constant := 28;            -- sqlext.h:245
    SQL_IDENTIFIER_QUOTE_CHAR    : constant := 29;            -- sqlext.h:246
    SQL_MAX_COLUMN_NAME_LEN      : constant := 30;            -- sqlext.h:247
    SQL_MAX_CURSOR_NAME_LEN      : constant := 31;            -- sqlext.h:248
    SQL_MAX_OWNER_NAME_LEN       : constant := 16#0020#;      -- sqlext.h:249
    SQL_MAX_PROCEDURE_NAME_LEN   : constant := 33;            -- sqlext.h:250
    SQL_MAX_QUALIFIER_NAME_LEN   : constant := 34;            -- sqlext.h:251
    SQL_MAX_TABLE_NAME_LEN       : constant := 35;            -- sqlext.h:252
    SQL_MULT_RESULT_SETS         : constant := 36;            -- sqlext.h:253
    SQL_MULTIPLE_ACTIVE_TXN      : constant := 37;            -- sqlext.h:254
    SQL_OUTER_JOINS              : constant := 38;            -- sqlext.h:255
    SQL_OWNER_TERM               : constant := 39;            -- sqlext.h:256
    SQL_PROCEDURE_TERM           : constant := 40;            -- sqlext.h:257
    SQL_QUALIFIER_NAME_SEPARATOR : constant := 41;            -- sqlext.h:258
    SQL_QUALIFIER_TERM           : constant := 42;            -- sqlext.h:259
    SQL_SCROLL_CONCURRENCY       : constant := 43;            -- sqlext.h:260
    SQL_SCROLL_OPTIONS           : constant := 44;            -- sqlext.h:261
    SQL_TABLE_TERM               : constant := 45;            -- sqlext.h:262
    SQL_TXN_CAPABLE              : constant := 46;            -- sqlext.h:263
    SQL_USER_NAME                : constant := 47;            -- sqlext.h:264
    SQL_CONVERT_FUNCTIONS        : constant := 48;            -- sqlext.h:265
    SQL_NUMERIC_FUNCTIONS        : constant := 49;            -- sqlext.h:266
    SQL_STRING_FUNCTIONS         : constant := 50;            -- sqlext.h:267
    SQL_SYSTEM_FUNCTIONS         : constant := 51;            -- sqlext.h:268
    SQL_TIMEDATE_FUNCTIONS       : constant := 52;            -- sqlext.h:269
    SQL_CONVERT_BIGINT           : constant := 53;            -- sqlext.h:270
    SQL_CONVERT_BINARY           : constant := 54;            -- sqlext.h:271
    SQL_CONVERT_BIT              : constant := 55;            -- sqlext.h:272
    SQL_CONVERT_CHAR             : constant := 56;            -- sqlext.h:273
    SQL_CONVERT_DATE             : constant := 57;            -- sqlext.h:274
    SQL_CONVERT_DECIMAL          : constant := 58;            -- sqlext.h:275
    SQL_CONVERT_DOUBLE           : constant := 59;            -- sqlext.h:276
    SQL_CONVERT_FLOAT            : constant := 60;            -- sqlext.h:277
    SQL_CONVERT_INTEGER          : constant := 61;            -- sqlext.h:278
    SQL_CONVERT_LONGVARCHAR      : constant := 62;            -- sqlext.h:279
    SQL_CONVERT_NUMERIC          : constant := 63;            -- sqlext.h:280
    SQL_CONVERT_REAL             : constant := 16#0040#;      -- sqlext.h:281
    SQL_CONVERT_SMALLINT         : constant := 65;            -- sqlext.h:282
    SQL_CONVERT_TIME             : constant := 66;            -- sqlext.h:283
    SQL_CONVERT_TIMESTAMP        : constant := 67;            -- sqlext.h:284
    SQL_CONVERT_TINYINT          : constant := 68;            -- sqlext.h:285
    SQL_CONVERT_VARBINARY        : constant := 69;            -- sqlext.h:286
    SQL_CONVERT_VARCHAR          : constant := 70;            -- sqlext.h:287
    SQL_CONVERT_LONGVARBINARY    : constant := 71;            -- sqlext.h:288
    SQL_TXN_ISOLATION_OPTION     : constant := 72;            -- sqlext.h:289
    SQL_ODBC_SQL_OPT_IEF         : constant := 73;            -- sqlext.h:290
    SQL_CORRELATION_NAME         : constant := 74;            -- sqlext.h:295
    SQL_NON_NULLABLE_COLUMNS     : constant := 75;            -- sqlext.h:296
    SQL_DRIVER_HLIB              : constant := 76;            -- sqlext.h:301
    SQL_DRIVER_ODBC_VER          : constant := 77;            -- sqlext.h:302
    SQL_LOCK_TYPES               : constant := 78;            -- sqlext.h:303
    SQL_POS_OPERATIONS           : constant := 79;            -- sqlext.h:304
    SQL_POSITIONED_STATEMENTS    : constant := 80;            -- sqlext.h:305
    SQL_GETDATA_EXTENSIONS       : constant := 81;            -- sqlext.h:306
    SQL_BOOKMARK_PERSISTENCE     : constant := 82;            -- sqlext.h:307
    SQL_STATIC_SENSITIVITY       : constant := 83;            -- sqlext.h:308
    SQL_FILE_USAGE               : constant := 84;            -- sqlext.h:309
    SQL_NULL_COLLATION           : constant := 85;            -- sqlext.h:310
    SQL_ALTER_TABLE              : constant := 86;            -- sqlext.h:311
    SQL_COLUMN_ALIAS             : constant := 87;            -- sqlext.h:312
    SQL_GROUP_BY                 : constant := 88;            -- sqlext.h:313
    SQL_KEYWORDS                 : constant := 89;            -- sqlext.h:314
    SQL_ORDER_BY_COLUMNS_IN_SELECT: constant := 90;           -- sqlext.h:315
    SQL_OWNER_USAGE               : constant := 91;           -- sqlext.h:316
    SQL_QUALIFIER_USAGE           : constant := 92;           -- sqlext.h:317
    SQL_QUOTED_IDENTIFIER_CASE    : constant := 93;           -- sqlext.h:318
    SQL_SPECIAL_CHARACTERS        : constant := 94;           -- sqlext.h:319
    SQL_SUBQUERIES                : constant := 95;           -- sqlext.h:320
    SQL_UNION                     : constant := 96;           -- sqlext.h:321
    SQL_MAX_COLUMNS_IN_GROUP_BY   : constant := 97;           -- sqlext.h:322
    SQL_MAX_COLUMNS_IN_INDEX      : constant := 98;           -- sqlext.h:323
    SQL_MAX_COLUMNS_IN_ORDER_BY   : constant := 99;           -- sqlext.h:324
    SQL_MAX_COLUMNS_IN_SELECT     : constant := 100;          -- sqlext.h:325
    SQL_MAX_COLUMNS_IN_TABLE      : constant := 101;          -- sqlext.h:326
    SQL_MAX_INDEX_SIZE            : constant := 102;          -- sqlext.h:327
    SQL_MAX_ROW_SIZE_INCLUDES_LONG: constant := 103;          -- sqlext.h:328
    SQL_MAX_ROW_SIZE              : constant := 104;          -- sqlext.h:329
    SQL_MAX_STATEMENT_LEN         : constant := 105;          -- sqlext.h:330
    SQL_MAX_TABLES_IN_SELECT      : constant := 106;          -- sqlext.h:331
    SQL_MAX_USER_NAME_LEN         : constant := 107;          -- sqlext.h:332
    SQL_MAX_CHAR_LITERAL_LEN      : constant := 108;          -- sqlext.h:333
    SQL_TIMEDATE_ADD_INTERVALS    : constant := 109;          -- sqlext.h:334
    SQL_TIMEDATE_DIFF_INTERVALS   : constant := 110;          -- sqlext.h:335
    SQL_NEED_LONG_DATA_LEN        : constant := 111;          -- sqlext.h:336
    SQL_MAX_BINARY_LITERAL_LEN    : constant := 112;          -- sqlext.h:337
    SQL_LIKE_ESCAPE_CLAUSE        : constant := 113;          -- sqlext.h:338
    SQL_QUALIFIER_LOCATION        : constant := 114;          -- sqlext.h:339
    SQL_OJ_CAPABILITIES           : constant := 65003;        -- sqlext.h:344
    SQL_INFO_LAST                 : constant := 114;          -- sqlext.h:346
    SQL_INFO_DRIVER_START         : constant := 1000;         -- sqlext.h:347
    SQL_CVT_CHAR                  : constant := 16#0001#;     -- sqlext.h:353
    SQL_CVT_NUMERIC               : constant := 16#0002#;     -- sqlext.h:354
    SQL_CVT_DECIMAL               : constant := 16#0004#;     -- sqlext.h:355
    SQL_CVT_INTEGER               : constant := 16#0008#;     -- sqlext.h:356
    SQL_CVT_SMALLINT              : constant := 16#0010#;     -- sqlext.h:357
    SQL_CVT_FLOAT                 : constant := 16#0020#;     -- sqlext.h:358
    SQL_CVT_REAL                  : constant := 16#0040#;     -- sqlext.h:359
    SQL_CVT_DOUBLE                : constant := 16#0080#;     -- sqlext.h:360
    SQL_CVT_VARCHAR               : constant := 16#0100#;     -- sqlext.h:361
    SQL_CVT_LONGVARCHAR           : constant := 16#0200#;     -- sqlext.h:362
    SQL_CVT_BINARY                : constant := 16#0400#;     -- sqlext.h:363
    SQL_CVT_VARBINARY             : constant := 16#0800#;     -- sqlext.h:364
    SQL_CVT_BIT                   : constant := 16#1000#;     -- sqlext.h:365
    SQL_CVT_TINYINT               : constant := 16#2000#;     -- sqlext.h:366
    SQL_CVT_BIGINT                : constant := 16#4000#;     -- sqlext.h:367
    SQL_CVT_DATE                  : constant := 16#8000#;     -- sqlext.h:368
    SQL_CVT_TIME                  : constant := 16#0001_0000#;-- sqlext.h:369
    SQL_CVT_TIMESTAMP             : constant := 16#0002_0000#;-- sqlext.h:370
    SQL_CVT_LONGVARBINARY         : constant := 16#0004_0000#;-- sqlext.h:371
    SQL_FN_CVT_CONVERT            : constant := 16#0001#;     -- sqlext.h:377
    SQL_FN_STR_CONCAT             : constant := 16#0001#;     -- sqlext.h:383
    SQL_FN_STR_INSERT             : constant := 16#0002#;     -- sqlext.h:384
    SQL_FN_STR_LEFT               : constant := 16#0004#;     -- sqlext.h:385
    SQL_FN_STR_LTRIM              : constant := 16#0008#;     -- sqlext.h:386
    SQL_FN_STR_LENGTH             : constant := 16#0010#;     -- sqlext.h:387
    SQL_FN_STR_LOCATE             : constant := 16#0020#;     -- sqlext.h:388
    SQL_FN_STR_LCASE              : constant := 16#0040#;     -- sqlext.h:389
    SQL_FN_STR_REPEAT             : constant := 16#0080#;     -- sqlext.h:390
    SQL_FN_STR_REPLACE            : constant := 16#0100#;     -- sqlext.h:391
    SQL_FN_STR_RIGHT              : constant := 16#0200#;     -- sqlext.h:392
    SQL_FN_STR_RTRIM              : constant := 16#0400#;     -- sqlext.h:393
    SQL_FN_STR_SUBSTRING          : constant := 16#0800#;     -- sqlext.h:394
    SQL_FN_STR_UCASE              : constant := 16#1000#;     -- sqlext.h:395
    SQL_FN_STR_ASCII              : constant := 16#2000#;     -- sqlext.h:396
    SQL_FN_STR_CHAR               : constant := 16#4000#;     -- sqlext.h:397
    SQL_FN_STR_DIFFERENCE         : constant := 16#8000#;     -- sqlext.h:398
    SQL_FN_STR_LOCATE_2           : constant := 16#0001_0000#;-- sqlext.h:399
    SQL_FN_STR_SOUNDEX            : constant := 16#0002_0000#;-- sqlext.h:400
    SQL_FN_STR_SPACE              : constant := 16#0004_0000#;-- sqlext.h:401
    SQL_FN_NUM_ABS                : constant := 16#0001#;     -- sqlext.h:407
    SQL_FN_NUM_ACOS               : constant := 16#0002#;     -- sqlext.h:408
    SQL_FN_NUM_ASIN               : constant := 16#0004#;     -- sqlext.h:409
    SQL_FN_NUM_ATAN               : constant := 16#0008#;     -- sqlext.h:410
    SQL_FN_NUM_ATAN2              : constant := 16#0010#;     -- sqlext.h:411
    SQL_FN_NUM_CEILING            : constant := 16#0020#;     -- sqlext.h:412
    SQL_FN_NUM_COS                : constant := 16#0040#;     -- sqlext.h:413
    SQL_FN_NUM_COT                : constant := 16#0080#;     -- sqlext.h:414
    SQL_FN_NUM_EXP                : constant := 16#0100#;     -- sqlext.h:415
    SQL_FN_NUM_FLOOR              : constant := 16#0200#;     -- sqlext.h:416
    SQL_FN_NUM_LOG                : constant := 16#0400#;     -- sqlext.h:417
    SQL_FN_NUM_MOD                : constant := 16#0800#;     -- sqlext.h:418
    SQL_FN_NUM_SIGN               : constant := 16#1000#;     -- sqlext.h:419
    SQL_FN_NUM_SIN                : constant := 16#2000#;     -- sqlext.h:420
    SQL_FN_NUM_SQRT               : constant := 16#4000#;     -- sqlext.h:421
    SQL_FN_NUM_TAN                : constant := 16#8000#;     -- sqlext.h:422
    SQL_FN_NUM_PI                 : constant := 16#0001_0000#;-- sqlext.h:423
    SQL_FN_NUM_RAND               : constant := 16#0002_0000#;-- sqlext.h:424
    SQL_FN_NUM_DEGREES            : constant := 16#0004_0000#;-- sqlext.h:425
    SQL_FN_NUM_LOG10              : constant := 16#0008_0000#;-- sqlext.h:426
    SQL_FN_NUM_POWER              : constant := 16#0010_0000#;-- sqlext.h:427
    SQL_FN_NUM_RADIANS            : constant := 16#0020_0000#;-- sqlext.h:428
    SQL_FN_NUM_ROUND              : constant := 16#0040_0000#;-- sqlext.h:429
    SQL_FN_NUM_TRUNCATE           : constant := 16#0080_0000#;-- sqlext.h:430
    SQL_FN_TD_NOW                 : constant := 16#0001#;     -- sqlext.h:436
    SQL_FN_TD_CURDATE             : constant := 16#0002#;     -- sqlext.h:437
    SQL_FN_TD_DAYOFMONTH          : constant := 16#0004#;     -- sqlext.h:438
    SQL_FN_TD_DAYOFWEEK           : constant := 16#0008#;     -- sqlext.h:439
    SQL_FN_TD_DAYOFYEAR           : constant := 16#0010#;     -- sqlext.h:440
    SQL_FN_TD_MONTH               : constant := 16#0020#;     -- sqlext.h:441
    SQL_FN_TD_QUARTER             : constant := 16#0040#;     -- sqlext.h:442
    SQL_FN_TD_WEEK                : constant := 16#0080#;     -- sqlext.h:443
    SQL_FN_TD_YEAR                : constant := 16#0100#;     -- sqlext.h:444
    SQL_FN_TD_CURTIME             : constant := 16#0200#;     -- sqlext.h:445
    SQL_FN_TD_HOUR                : constant := 16#0400#;     -- sqlext.h:446
    SQL_FN_TD_MINUTE              : constant := 16#0800#;     -- sqlext.h:447
    SQL_FN_TD_SECOND              : constant := 16#1000#;     -- sqlext.h:448
    SQL_FN_TD_TIMESTAMPADD        : constant := 16#2000#;     -- sqlext.h:449
    SQL_FN_TD_TIMESTAMPDIFF       : constant := 16#4000#;     -- sqlext.h:450
    SQL_FN_TD_DAYNAME             : constant := 16#8000#;     -- sqlext.h:451
    SQL_FN_TD_MONTHNAME           : constant := 16#0001_0000#;-- sqlext.h:452
    SQL_FN_SYS_USERNAME           : constant := 16#0001#;     -- sqlext.h:458
    SQL_FN_SYS_DBNAME             : constant := 16#0002#;     -- sqlext.h:459
    SQL_FN_SYS_IFNULL             : constant := 16#0004#;     -- sqlext.h:460
    SQL_FN_TSI_FRAC_SECOND        : constant := 16#0001#;     -- sqlext.h:467
    SQL_FN_TSI_SECOND             : constant := 16#0002#;     -- sqlext.h:468
    SQL_FN_TSI_MINUTE             : constant := 16#0004#;     -- sqlext.h:469
    SQL_FN_TSI_HOUR               : constant := 16#0008#;     -- sqlext.h:470
    SQL_FN_TSI_DAY                : constant := 16#0010#;     -- sqlext.h:471
    SQL_FN_TSI_WEEK               : constant := 16#0020#;     -- sqlext.h:472
    SQL_FN_TSI_MONTH              : constant := 16#0040#;     -- sqlext.h:473
    SQL_FN_TSI_QUARTER            : constant := 16#0080#;     -- sqlext.h:474
    SQL_FN_TSI_YEAR               : constant := 16#0100#;     -- sqlext.h:475
    SQL_OAC_NONE                  : constant := 16#0000#;     -- sqlext.h:481
    SQL_OAC_LEVEL1                : constant := 16#0001#;     -- sqlext.h:482
    SQL_OAC_LEVEL2                : constant := 16#0002#;     -- sqlext.h:483
    SQL_OSCC_NOT_COMPLIANT        : constant := 16#0000#;     -- sqlext.h:489
    SQL_OSCC_COMPLIANT            : constant := 16#0001#;     -- sqlext.h:490
    SQL_OSC_MINIMUM               : constant := 16#0000#;     -- sqlext.h:496
    SQL_OSC_CORE                  : constant := 16#0001#;     -- sqlext.h:497
    SQL_OSC_EXTENDED              : constant := 16#0002#;     -- sqlext.h:498
    SQL_CB_NULL                   : constant := 16#0000#;     -- sqlext.h:504
    SQL_CB_NON_NULL               : constant := 16#0001#;     -- sqlext.h:505
    SQL_CB_DELETE                 : constant := 16#0000#;     -- sqlext.h:512
    SQL_CB_CLOSE                  : constant := 16#0001#;     -- sqlext.h:513
    SQL_CB_PRESERVE               : constant := 16#0002#;     -- sqlext.h:514
    SQL_IC_UPPER                  : constant := 16#0001#;     -- sqlext.h:520
    SQL_IC_LOWER                  : constant := 16#0002#;     -- sqlext.h:521
    SQL_IC_SENSITIVE              : constant := 16#0003#;     -- sqlext.h:522
    SQL_IC_MIXED                  : constant := 16#0004#;     -- sqlext.h:523
    SQL_TC_NONE                   : constant := 16#0000#;     -- sqlext.h:529
    SQL_TC_DML                    : constant := 16#0001#;     -- sqlext.h:530
    SQL_TC_ALL                    : constant := 16#0002#;     -- sqlext.h:531
    SQL_TC_DDL_COMMIT             : constant := 16#0003#;     -- sqlext.h:532
    SQL_TC_DDL_IGNORE             : constant := 16#0004#;     -- sqlext.h:533
    SQL_SO_FORWARD_ONLY           : constant := 16#0001#;     -- sqlext.h:539
    SQL_SO_KEYSET_DRIVEN          : constant := 16#0002#;     -- sqlext.h:540
    SQL_SO_DYNAMIC                : constant := 16#0004#;     -- sqlext.h:541
    SQL_SO_MIXED                  : constant := 16#0008#;     -- sqlext.h:542
    SQL_SO_STATIC                 : constant := 16#0010#;     -- sqlext.h:543
    SQL_SCCO_READ_ONLY            : constant := 16#0001#;     -- sqlext.h:549
    SQL_SCCO_LOCK                 : constant := 16#0002#;     -- sqlext.h:550
    SQL_SCCO_OPT_ROWVER           : constant := 16#0004#;     -- sqlext.h:551
    SQL_SCCO_OPT_VALUES           : constant := 16#0008#;     -- sqlext.h:552
    SQL_FD_FETCH_NEXT             : constant := 16#0001#;     -- sqlext.h:558
    SQL_FD_FETCH_FIRST            : constant := 16#0002#;     -- sqlext.h:559
    SQL_FD_FETCH_LAST             : constant := 16#0004#;     -- sqlext.h:560
    SQL_FD_FETCH_PRIOR            : constant := 16#0008#;     -- sqlext.h:561
    SQL_FD_FETCH_ABSOLUTE         : constant := 16#0010#;     -- sqlext.h:562
    SQL_FD_FETCH_RELATIVE         : constant := 16#0020#;     -- sqlext.h:563
    SQL_FD_FETCH_RESUME           : constant := 16#0040#;     -- sqlext.h:564
    SQL_FD_FETCH_BOOKMARK         : constant := 16#0080#;     -- sqlext.h:565
    SQL_TXN_READ_UNCOMMITTED      : constant := 16#0001#;     -- sqlext.h:571
    SQL_TXN_READ_COMMITTED        : constant := 16#0002#;     -- sqlext.h:572
    SQL_TXN_REPEATABLE_READ       : constant := 16#0004#;     -- sqlext.h:573
    SQL_TXN_SERIALIZABLE          : constant := 16#0008#;     -- sqlext.h:574
    SQL_TXN_VERSIONING            : constant := 16#0010#;     -- sqlext.h:575
    SQL_CN_NONE                   : constant := 16#0000#;     -- sqlext.h:581
    SQL_CN_DIFFERENT              : constant := 16#0001#;     -- sqlext.h:582
    SQL_CN_ANY                    : constant := 16#0002#;     -- sqlext.h:583
    SQL_NNC_NULL                  : constant := 16#0000#;     -- sqlext.h:589
    SQL_NNC_NON_NULL              : constant := 16#0001#;     -- sqlext.h:590
    SQL_NC_HIGH                   : constant := 16#0000#;     -- sqlext.h:596
    SQL_NC_LOW                    : constant := 16#0001#;     -- sqlext.h:597
    SQL_NC_START                  : constant := 16#0002#;     -- sqlext.h:598
    SQL_NC_END                    : constant := 16#0004#;     -- sqlext.h:599
    SQL_FILE_NOT_SUPPORTED        : constant := 16#0000#;     -- sqlext.h:605
    SQL_FILE_TABLE                : constant := 16#0001#;     -- sqlext.h:606
    SQL_FILE_QUALIFIER            : constant := 16#0002#;     -- sqlext.h:607
    SQL_GD_ANY_COLUMN             : constant := 16#0001#;     -- sqlext.h:613
    SQL_GD_ANY_ORDER              : constant := 16#0002#;     -- sqlext.h:614
    SQL_GD_BLOCK                  : constant := 16#0004#;     -- sqlext.h:615
    SQL_GD_BOUND                  : constant := 16#0008#;     -- sqlext.h:616
    SQL_AT_ADD_COLUMN             : constant := 16#0001#;     -- sqlext.h:622
    SQL_AT_DROP_COLUMN            : constant := 16#0002#;     -- sqlext.h:623
    SQL_PS_POSITIONED_DELETE      : constant := 16#0001#;     -- sqlext.h:629
    SQL_PS_POSITIONED_UPDATE      : constant := 16#0002#;     -- sqlext.h:630
    SQL_PS_SELECT_FOR_UPDATE      : constant := 16#0004#;     -- sqlext.h:631
    SQL_GB_NOT_SUPPORTED          : constant := 16#0000#;     -- sqlext.h:637
    SQL_GB_GROUP_BY_EQUALS_SELECT : constant := 16#0001#;     -- sqlext.h:638
    SQL_GB_GROUP_BY_CONTAINS_SELECT: constant := 16#0002#;    -- sqlext.h:639
    SQL_GB_NO_RELATION             : constant := 16#0003#;    -- sqlext.h:640
    SQL_OU_DML_STATEMENTS          : constant := 16#0001#;    -- sqlext.h:646
    SQL_OU_PROCEDURE_INVOCATION    : constant := 16#0002#;    -- sqlext.h:647
    SQL_OU_TABLE_DEFINITION        : constant := 16#0004#;    -- sqlext.h:648
    SQL_OU_INDEX_DEFINITION        : constant := 16#0008#;    -- sqlext.h:649
    SQL_OU_PRIVILEGE_DEFINITION    : constant := 16#0010#;    -- sqlext.h:650
    SQL_QU_DML_STATEMENTS          : constant := 16#0001#;    -- sqlext.h:656
    SQL_QU_PROCEDURE_INVOCATION    : constant := 16#0002#;    -- sqlext.h:657
    SQL_QU_TABLE_DEFINITION        : constant := 16#0004#;    -- sqlext.h:658
    SQL_QU_INDEX_DEFINITION        : constant := 16#0008#;    -- sqlext.h:659
    SQL_QU_PRIVILEGE_DEFINITION    : constant := 16#0010#;    -- sqlext.h:660
    SQL_SQ_COMPARISON              : constant := 16#0001#;    -- sqlext.h:666
    SQL_SQ_EXISTS                  : constant := 16#0002#;    -- sqlext.h:667
    SQL_SQ_IN                      : constant := 16#0004#;    -- sqlext.h:668
    SQL_SQ_QUANTIFIED              : constant := 16#0008#;    -- sqlext.h:669
    SQL_SQ_CORRELATED_SUBQUERIES   : constant := 16#0010#;    -- sqlext.h:670
    SQL_U_UNION                    : constant := 16#0001#;    -- sqlext.h:676
    SQL_U_UNION_ALL                : constant := 16#0002#;    -- sqlext.h:677
    SQL_BP_CLOSE                   : constant := 16#0001#;    -- sqlext.h:683
    SQL_BP_DELETE                  : constant := 16#0002#;    -- sqlext.h:684
    SQL_BP_DROP                    : constant := 16#0004#;    -- sqlext.h:685
    SQL_BP_TRANSACTION             : constant := 16#0008#;    -- sqlext.h:686
    SQL_BP_UPDATE                  : constant := 16#0010#;    -- sqlext.h:687
    SQL_BP_OTHER_HSTMT             : constant := 16#0020#;    -- sqlext.h:688
    SQL_BP_SCROLL                  : constant := 16#0040#;    -- sqlext.h:689
    SQL_SS_ADDITIONS               : constant := 16#0001#;    -- sqlext.h:695
    SQL_SS_DELETIONS               : constant := 16#0002#;    -- sqlext.h:696
    SQL_SS_UPDATES                 : constant := 16#0004#;    -- sqlext.h:697
    SQL_LCK_NO_CHANGE              : constant := 16#0001#;    -- sqlext.h:703
    SQL_LCK_EXCLUSIVE              : constant := 16#0002#;    -- sqlext.h:704
    SQL_LCK_UNLOCK                 : constant := 16#0004#;    -- sqlext.h:705
    SQL_POS_POSITION               : constant := 16#0001#;    -- sqlext.h:711
    SQL_POS_REFRESH                : constant := 16#0002#;    -- sqlext.h:712
    SQL_POS_UPDATE                 : constant := 16#0004#;    -- sqlext.h:713
    SQL_POS_DELETE                 : constant := 16#0008#;    -- sqlext.h:714
    SQL_POS_ADD                    : constant := 16#0010#;    -- sqlext.h:715
    SQL_QL_START                   : constant := 16#0001#;    -- sqlext.h:721
    SQL_QL_END                     : constant := 16#0002#;    -- sqlext.h:722
    SQL_OJ_LEFT                    : constant := 16#0001#;    -- sqlext.h:728
    SQL_OJ_RIGHT                   : constant := 16#0002#;    -- sqlext.h:729
    SQL_OJ_FULL                    : constant := 16#0004#;    -- sqlext.h:730
    SQL_OJ_NESTED                  : constant := 16#0008#;    -- sqlext.h:731
    SQL_OJ_NOT_ORDERED             : constant := 16#0010#;    -- sqlext.h:732
    SQL_OJ_INNER                   : constant := 16#0020#;    -- sqlext.h:733
    SQL_OJ_ALL_COMPARISON_OPS      : constant := 16#0040#;    -- sqlext.h:734
    SQL_QUERY_TIMEOUT              : constant := 8#0000#;     -- sqlext.h:740
    SQL_MAX_ROWS                   : constant := 1;           -- sqlext.h:741
    SQL_NOSCAN                     : constant := 2;           -- sqlext.h:742
    SQL_MAX_LENGTH                 : constant := 3;           -- sqlext.h:743
    SQL_ASYNC_ENABLE               : constant := 4;           -- sqlext.h:744
    SQL_BIND_TYPE                  : constant := 5;           -- sqlext.h:745
    SQL_CURSOR_TYPE                : constant := 6;           -- sqlext.h:746
    SQL_CONCURRENCY                : constant := 7;           -- sqlext.h:747
    SQL_KEYSET_SIZE                : constant := 8;           -- sqlext.h:748
    SQL_ROWSET_SIZE                : constant := 9;           -- sqlext.h:749
    SQL_SIMULATE_CURSOR            : constant := 10;          -- sqlext.h:750
    SQL_RETRIEVE_DATA              : constant := 11;          -- sqlext.h:751
    SQL_USE_BOOKMARKS              : constant := 12;          -- sqlext.h:752
    SQL_GET_BOOKMARK               : constant := 13;          -- sqlext.h:753
    SQL_ROW_NUMBER                 : constant := 14;          -- sqlext.h:754
    SQL_STMT_OPT_MIN               : constant := 8#0000#;     -- sqlext.h:756
    SQL_STMT_OPT_MAX               : constant := 14;          -- sqlext.h:757
    SQL_QUERY_TIMEOUT_DEFAULT      : constant := 8#0000#;     -- sqlext.h:763
    SQL_MAX_ROWS_DEFAULT           : constant := 8#0000#;     -- sqlext.h:769
    SQL_NOSCAN_OFF                 : constant := 8#0000#;     -- sqlext.h:775
    SQL_NOSCAN_ON                  : constant := 1;           -- sqlext.h:776
    SQL_NOSCAN_DEFAULT             : constant := 8#0000#;     -- sqlext.h:777
    SQL_MAX_LENGTH_DEFAULT         : constant := 8#0000#;     -- sqlext.h:783
    SQL_ASYNC_ENABLE_OFF           : constant := 8#0000#;     -- sqlext.h:789
    SQL_ASYNC_ENABLE_ON            : constant := 1;           -- sqlext.h:790
    SQL_ASYNC_ENABLE_DEFAULT       : constant := 8#0000#;     -- sqlext.h:791
    SQL_BIND_BY_COLUMN             : constant := 8#0000#;     -- sqlext.h:797
    SQL_BIND_TYPE_DEFAULT          : constant := 8#0000#;     -- sqlext.h:798
    SQL_CONCUR_READ_ONLY           : constant := 1;           -- sqlext.h:804
    SQL_CONCUR_LOCK                : constant := 2;           -- sqlext.h:805
    SQL_CONCUR_ROWVER              : constant := 3;           -- sqlext.h:806
    SQL_CONCUR_VALUES              : constant := 4;           -- sqlext.h:807
    SQL_CONCUR_DEFAULT             : constant := 1;           -- sqlext.h:808
    SQL_CURSOR_FORWARD_ONLY        : constant := 8#0000#;     -- sqlext.h:814
    SQL_CURSOR_KEYSET_DRIVEN       : constant := 1;           -- sqlext.h:815
    SQL_CURSOR_DYNAMIC             : constant := 2;           -- sqlext.h:816
    SQL_CURSOR_STATIC              : constant := 3;           -- sqlext.h:817
    SQL_CURSOR_TYPE_DEFAULT        : constant := 8#0000#;     -- sqlext.h:818
    SQL_ROWSET_SIZE_DEFAULT        : constant := 1;           -- sqlext.h:824
    SQL_KEYSET_SIZE_DEFAULT        : constant := 8#0000#;     -- sqlext.h:830
    SQL_SC_NON_UNIQUE              : constant := 8#0000#;     -- sqlext.h:836
    SQL_SC_TRY_UNIQUE              : constant := 1;           -- sqlext.h:837
    SQL_SC_UNIQUE                  : constant := 2;           -- sqlext.h:838
    SQL_RD_OFF                     : constant := 8#0000#;     -- sqlext.h:844
    SQL_RD_ON                      : constant := 1;           -- sqlext.h:845
    SQL_RD_DEFAULT                 : constant := 1;           -- sqlext.h:846
    SQL_UB_OFF                     : constant := 8#0000#;     -- sqlext.h:852
    SQL_UB_ON                      : constant := 1;           -- sqlext.h:853
    SQL_UB_DEFAULT                 : constant := 8#0000#;     -- sqlext.h:854
    SQL_ACCESS_MODE                : constant := 101;         -- sqlext.h:860
    SQL_AUTOCOMMIT                 : constant := 102;         -- sqlext.h:861
    SQL_LOGIN_TIMEOUT              : constant := 103;         -- sqlext.h:862
    SQL_OPT_TRACE                  : constant := 104;         -- sqlext.h:863
    SQL_OPT_TRACEFILE              : constant := 105;         -- sqlext.h:864
    SQL_TRANSLATE_DLL              : constant := 106;         -- sqlext.h:865
    SQL_TRANSLATE_OPTION           : constant := 107;         -- sqlext.h:866
    SQL_TXN_ISOLATION              : constant := 108;         -- sqlext.h:867
    SQL_CURRENT_QUALIFIER          : constant := 109;         -- sqlext.h:868
    SQL_ODBC_CURSORS               : constant := 110;         -- sqlext.h:869
    SQL_QUIET_MODE                 : constant := 111;         -- sqlext.h:870
    SQL_PACKET_SIZE                : constant := 112;         -- sqlext.h:871
    SQL_CONN_OPT_MIN               : constant := 101;         -- sqlext.h:873
    SQL_CONN_OPT_MAX               : constant := 112;         -- sqlext.h:874
    SQL_CONNECT_OPT_DRVR_START     : constant := 1000;        -- sqlext.h:875
    SQL_MODE_READ_WRITE            : constant := 8#0000#;     -- sqlext.h:881
    SQL_MODE_READ_ONLY             : constant := 1;           -- sqlext.h:882
    SQL_MODE_DEFAULT               : constant := 8#0000#;     -- sqlext.h:883
    SQL_AUTOCOMMIT_OFF             : constant := 8#0000#;     -- sqlext.h:889
    SQL_AUTOCOMMIT_ON              : constant := 1;           -- sqlext.h:890
    SQL_AUTOCOMMIT_DEFAULT         : constant := 1;           -- sqlext.h:891
    SQL_LOGIN_TIMEOUT_DEFAULT      : constant := 15;          -- sqlext.h:897
    SQL_OPT_TRACE_OFF              : constant := 8#0000#;     -- sqlext.h:903
    SQL_OPT_TRACE_ON               : constant := 1;           -- sqlext.h:904
    SQL_OPT_TRACE_DEFAULT          : constant := 8#0000#;     -- sqlext.h:905
    SQL_OPT_TRACE_FILE_DEFAULT     : constant string :=
                                     "odbc.log"&ascii.nul;    -- sqlext.h:906
    SQL_CUR_USE_IF_NEEDED          : constant := 8#0000#;     -- sqlext.h:912
    SQL_CUR_USE_ODBC               : constant := 1;           -- sqlext.h:913
    SQL_CUR_USE_DRIVER             : constant := 2;           -- sqlext.h:914
    SQL_CUR_DEFAULT                : constant := 2;           -- sqlext.h:915
    SQL_BEST_ROWID                 : constant := 1;           -- sqlext.h:921
    SQL_ROWVER                     : constant := 2;           -- sqlext.h:922
    SQL_SCOPE_CURROW               : constant := 8#0000#;     -- sqlext.h:924
    SQL_SCOPE_TRANSACTION          : constant := 1;           -- sqlext.h:925
    SQL_SCOPE_SESSION              : constant := 2;           -- sqlext.h:926
    SQL_ENTIRE_ROWSET              : constant := 8#0000#;     -- sqlext.h:932
    SQL_POSITION                   : constant := 8#0000#;     -- sqlext.h:938
    SQL_REFRESH                    : constant := 1;           -- sqlext.h:939
    SQL_UPDATE                     : constant := 2;           -- sqlext.h:940
    SQL_DELETE                     : constant := 3;           -- sqlext.h:941
    SQL_ADD                        : constant := 4;           -- sqlext.h:942
    SQL_LOCK_NO_CHANGE             : constant := 8#0000#;     -- sqlext.h:948
    SQL_LOCK_EXCLUSIVE             : constant := 1;           -- sqlext.h:949
    SQL_LOCK_UNLOCK                : constant := 2;           -- sqlext.h:950
    SQL_FETCH_NEXT                 : constant := 1;           -- sqlext.h:1015
    SQL_FETCH_FIRST                : constant := 2;           -- sqlext.h:1016
    SQL_FETCH_LAST                 : constant := 3;           -- sqlext.h:1017
    SQL_FETCH_PRIOR                : constant := 4;           -- sqlext.h:1018
    SQL_FETCH_ABSOLUTE             : constant := 5;           -- sqlext.h:1019
    SQL_FETCH_RELATIVE             : constant := 6;           -- sqlext.h:1020
    SQL_FETCH_BOOKMARK             : constant := 8;           -- sqlext.h:1021
    SQL_ROW_SUCCESS                : constant := 8#0000#;     -- sqlext.h:1027
    SQL_ROW_DELETED                : constant := 1;           -- sqlext.h:1028
    SQL_ROW_UPDATED                : constant := 2;           -- sqlext.h:1029
    SQL_ROW_NOROW                  : constant := 3;           -- sqlext.h:1030
    SQL_ROW_ADDED                  : constant := 4;           -- sqlext.h:1031
    SQL_ROW_ERROR                  : constant := 5;           -- sqlext.h:1032
    SQL_CASCADE                    : constant := 8#0000#;     -- sqlext.h:1038
    SQL_RESTRICT                   : constant := 1;           -- sqlext.h:1039
    SQL_SET_NULL                   : constant := 2;           -- sqlext.h:1040
    SQL_NO_ACTION                  : constant := 3;           -- sqlext.h:1041
    SQL_SET_DEFAULT                : constant := 4;           -- sqlext.h:1042
    SQL_PARAM_TYPE_UNKNOWN         : constant := 8#0000#;     -- sqlext.h:1049
    SQL_PARAM_INPUT                : constant := 1;           -- sqlext.h:1050
    SQL_PARAM_INPUT_OUTPUT         : constant := 2;           -- sqlext.h:1051
    SQL_RESULT_COL                 : constant := 3;           -- sqlext.h:1052
    SQL_PARAM_OUTPUT               : constant := 4;           -- sqlext.h:1053
    SQL_RETURN_VALUE               : constant := 5;           -- sqlext.h:1054
    SQL_PARAM_TYPE_DEFAULT         : constant := 2;           -- sqlext.h:1060
    SQL_SETPARAM_VALUE_MAX         : constant := -1;          -- sqlext.h:1061
    SQL_INDEX_UNIQUE               : constant := 8#0000#;     -- sqlext.h:1067
    SQL_INDEX_ALL                  : constant := 1;           -- sqlext.h:1068
    SQL_QUICK                      : constant := 8#0000#;     -- sqlext.h:1074
    SQL_ENSURE                     : constant := 1;           -- sqlext.h:1075
    SQL_TABLE_STAT                 : constant := 8#0000#;     -- sqlext.h:1081
    SQL_INDEX_CLUSTERED            : constant := 1;           -- sqlext.h:1082
    SQL_INDEX_HASHED               : constant := 2;           -- sqlext.h:1083
    SQL_INDEX_OTHER                : constant := 3;           -- sqlext.h:1084
    SQL_PT_UNKNOWN                 : constant := 8#0000#;     -- sqlext.h:1090
    SQL_PT_PROCEDURE               : constant := 1;           -- sqlext.h:1091
    SQL_PT_FUNCTION                : constant := 2;           -- sqlext.h:1092
    SQL_PC_UNKNOWN                 : constant := 8#0000#;     -- sqlext.h:1098
    SQL_PC_NOT_PSEUDO              : constant := 1;           -- sqlext.h:1099
    SQL_PC_PSEUDO                  : constant := 2;           -- sqlext.h:1100
    SQL_DATABASE_NAME              : constant := 16#0010#;    -- sqlext.h:1106
    SQL_FD_FETCH_PREV              : constant := 16#0008#;    -- sqlext.h:1107
    SQL_FETCH_PREV                 : constant := 4;           -- sqlext.h:1108
    SQL_CONCUR_TIMESTAMP           : constant := 3;           -- sqlext.h:1109
    SQL_SCCO_OPT_TIMESTAMP         : constant := 16#0004#;    -- sqlext.h:1110
    SQL_CC_DELETE                  : constant := 16#0000#;    -- sqlext.h:1111
    SQL_CR_DELETE                  : constant := 16#0000#;    -- sqlext.h:1112
    SQL_CC_CLOSE                   : constant := 16#0001#;    -- sqlext.h:1113
    SQL_CR_CLOSE                   : constant := 16#0001#;    -- sqlext.h:1114
    SQL_CC_PRESERVE                : constant := 16#0002#;    -- sqlext.h:1115
    SQL_CR_PRESERVE                : constant := 16#0002#;    -- sqlext.h:1116
    SQL_FETCH_RESUME               : constant := 7;           -- sqlext.h:1117
    SQL_SCROLL_FORWARD_ONLY        : constant := 8#0000#;     -- sqlext.h:1118
    SQL_SCROLL_KEYSET_DRIVEN       : constant := -1;          -- sqlext.h:1119
    SQL_SCROLL_DYNAMIC             : constant := -2;          -- sqlext.h:1120
    SQL_SCROLL_STATIC              : constant := -3;          -- sqlext.h:1121
    SQL_PC_NON_PSEUDO              : constant := 1;           -- sqlext.h:1122

    -------------------------------
    -- Type definitions for Odbc --
    -------------------------------

    subtype SQLSMALLINT  is Interfaces.Integer_16;            -- sqltypes.h:85
    subtype SQLUSMALLINT is Interfaces.Unsigned_16;           -- sqltypes.h:86
    subtype SQLINTEGER   is Interfaces.Integer_32;            -- sqltypes.h:87
    subtype SQLUINTEGER  is Interfaces.Unsigned_32;           -- sqltypes.h:88

    type SQLHANDLE is new System.Address;                     -- sqltypes.h:99
    type SQLHDBC   is new System.Address;                     -- sqltypes.h:112
    type SQLHENV   is new System.Address;                     -- sqltypes.h:111
    type SQLHSTMT  is new System.Address;                     -- sqltypes.h:113

    type SQLRETURN is new Interfaces.Integer_16;              -- sqltypes.h:131
    type BOOKMARK  is new Interfaces.Unsigned_32;             -- sqltypes.h:137
    type SQLHWND   is new System.Address;                     -- sqltypes.h:123

    subtype SQLPOINTER is System.Address;                     -- sqltypes.h:95

    --------------------------------------------
    -- Definitions compatible with iodbc-2.50 --
    --------------------------------------------

    subtype UDWORD is SQLUINTEGER;                            -- sqltypes.h:69
    subtype SDWORD is SQLINTEGER;                             -- sqltypes.h:70
    subtype UWORD  is SQLUSMALLINT;                           -- sqltypes.h:71
    subtype SWORD  is SQLSMALLINT;                            -- sqltypes.h:72

    subtype HDBC  is SQLHDBC;                                 -- sqltypes.h:108
    subtype HENV  is SQLHENV;                                 -- sqltypes.h:107
    subtype HSTMT is SQLHSTMT;                                -- sqltypes.h:109
    subtype HWND  is SQLHWND;                                 -- sqltypes.h:122
    subtype PTR   is SQLPOINTER;                              -- sqltypes.h:94

    subtype RETCODE is SQLRETURN;                             -- sqltypes.h:130

    -- -----------------------------------------------------------

    type struct_tagDATE_STRUCT;                               -- sqltypes.h:140
    type struct_tagTIME_STRUCT;                               -- sqltypes.h:149
    type struct_tagTIMESTAMP_STRUCT;                          -- sqltypes.h:158

    type struct_tagDATE_STRUCT is                             -- sqltypes.h:140
        record
            year : SQLSMALLINT;                               -- sqltypes.h:142
            month: SQLUSMALLINT;                              -- sqltypes.h:143
            day  : SQLUSMALLINT;                              -- sqltypes.h:144
        end record;

    pragma Convention(C,  struct_tagDATE_STRUCT);             -- sqltypes.h:140

    subtype DATE_STRUCT is struct_tagDATE_STRUCT;             -- sqltypes.h:146

    type struct_tagTIME_STRUCT is                             -- sqltypes.h:149
        record
            hour  : SQLUSMALLINT;                             -- sqltypes.h:151
            minute: SQLUSMALLINT;                             -- sqltypes.h:152
            second: SQLUSMALLINT;                             -- sqltypes.h:153
        end record;

    pragma Convention(C,  struct_tagTIME_STRUCT);             -- sqltypes.h:149

    subtype TIME_STRUCT is struct_tagTIME_STRUCT;             -- sqltypes.h:155

    type struct_tagTIMESTAMP_STRUCT is                        -- sqltypes.h:158
        record
            year    : SQLSMALLINT;                            -- sqltypes.h:160
            month   : SQLUSMALLINT;                           -- sqltypes.h:161
            day     : SQLUSMALLINT;                           -- sqltypes.h:162
            hour    : SQLUSMALLINT;                           -- sqltypes.h:163
            minute  : SQLUSMALLINT;                           -- sqltypes.h:164
            second  : SQLUSMALLINT;                           -- sqltypes.h:165
            fraction: SQLUINTEGER;                            -- sqltypes.h:166
        end record;

    pragma Convention(C,  struct_tagTIMESTAMP_STRUCT);       -- sqltypes.h:158

    subtype TIMESTAMP_STRUCT is struct_tagTIMESTAMP_STRUCT;  -- sqltypes.h:168

    function SQLALLOCCONNECT(henv : SQLHENV;
                             phdbc: access SQLHDBC)
                                    return SQLRETURN;        -- sql.h:195

    function SQLALLOCENV(phenv: access SQLHENV) return SQLRETURN;
                                                             -- sql.h:199

    function SQLALLOCSTMT(hdbc  : SQLHDBC;
                          phstmt: access SQLHSTMT)
                                  return SQLRETURN;          -- sql.h:202

    function SQLBINDCOL(hstmt     : SQLHSTMT;
                        icol      : SQLUSMALLINT;
                        fCType    : SQLSMALLINT;
                        rgbValue  : SQLPOINTER;
                        cbValueMax: SQLINTEGER;
                        pcbValue  : access SQLINTEGER)
                                    return SQLRETURN;        -- sql.h:206

    function SQLCANCEL(hstmt: SQLHSTMT) return SQLRETURN;    -- sql.h:214

    function SQLCOLATTRIBUTES(hstmt    : SQLHSTMT;
                              icol     : SQLUSMALLINT;
                              fDescType: SQLUSMALLINT;
                              rgbDesc  : SQLPOINTER;
                              cbDescMax: SQLSMALLINT;
                              pcbDesc  : access SQLSMALLINT;
                              pfDesc   : access SQLINTEGER)
                                         return SQLRETURN;   -- sql.h:217

    function SQLCONNECT(hdbc     : SQLHDBC;
                        szDSN    : Interfaces.C.char_array;
                        cbDSN    : SQLSMALLINT;
                        szUID    : Interfaces.C.char_array;
                        cbUID    : SQLSMALLINT;
                        szAuthStr: Interfaces.C.char_array;
                        cbAuthStr: SQLSMALLINT)
                                   return SQLRETURN;         -- sql.h:226

    function SQLDESCRIBECOL(hstmt       : SQLHSTMT;
                            icol        : SQLUSMALLINT;
                            szColName   : Interfaces.C.char_array;
                            cbColNameMax: SQLSMALLINT;
                            pcbColName  : access SQLSMALLINT;
                            pfSqlType   : access SQLSMALLINT;
                            pcbColDef   : access SQLUINTEGER;
                            pibScale    : access SQLSMALLINT;
                            pfNullable  : access SQLSMALLINT)
                                          return SQLRETURN;  -- sql.h:235

    function SQLDISCONNECT(hdbc: SQLHDBC) return SQLRETURN;  -- sql.h:246

    function SQLERROR(henv         : SQLHENV;
                      hdbc         : SQLHDBC;
                      hstmt        : SQLHSTMT;
                      szSqlState   : Interfaces.C.char_array;
                      pfNativeError: access SQLINTEGER;
                      szErrorMsg   : Interfaces.C.char_array;
                      cbErrorMsgMax: SQLSMALLINT;
                      pcbErrorMsg  : access SQLSMALLINT)
                                     return SQLRETURN;       -- sql.h:249

    function SQLEXECDIRECT(hstmt   : SQLHSTMT;
                           szSqlStr: Interfaces.C.char_array;
                           cbSqlStr: SQLINTEGER)
                                     return SQLRETURN;       -- sql.h:259

    function SQLEXECUTE(hstmt: SQLHSTMT) return SQLRETURN;   -- sql.h:264

    function SQLFETCH(hstmt: SQLHSTMT) return SQLRETURN;     -- sql.h:267

    function SQLFETCHSCROLL(Hstmt            : SQLHSTMT;
                            FetchDirection   : in SQLINTEGER := SQL_FETCH_NEXT;
                            FetchOffset      : in SQLINTEGER := 0)
                           return SQLRETURN;

    function SQLFREECONNECT(hdbc: SQLHDBC) return SQLRETURN; -- sql.h:270

    function SQLFREEENV(henv: SQLHENV) return SQLRETURN;     -- sql.h:273

    function SQLFREESTMT(hstmt  : SQLHSTMT;
                         fOption: SQLUSMALLINT)
                                  return SQLRETURN;          -- sql.h:276

    function SQLGETCURSORNAME(hstmt      : SQLHSTMT;
                              szCursor   : Interfaces.C.char_array;
                              cbCursorMax: SQLSMALLINT;
                              pcbCursor  : access SQLSMALLINT)
                                           return SQLRETURN; -- sql.h:280

    function SQLNUMRESULTCOLS(hstmt: SQLHSTMT;
                              pccol: access SQLSMALLINT)
                                     return SQLRETURN;       -- sql.h:286

    function SQLPREPARE (hstmt    : SQLHSTMT;
                         szSqlStr : Interfaces.C.char_array;
                         cbSqlStr : SQLINTEGER)
                                  return SQLRETURN;          -- sql.h:290

    function SQLROWCOUNT(hstmt: SQLHSTMT;
                         pcrow: access SQLINTEGER)
                                return SQLRETURN;            -- sql.h:295

    function SQLSETCURSORNAME (hstmt    : SQLHSTMT;
                               szCursor : Interfaces.C.char_array;
                               cbCursor : SQLSMALLINT)
                                        return SQLRETURN;    -- sql.h:299

    function SQLTRANSACT(henv : SQLHENV;
                         hdbc : SQLHDBC;
                         fType: SQLUSMALLINT)
                                return SQLRETURN;            -- sql.h:304

    function SQLSETPARAM(hstmt     : SQLHSTMT;
                         ipar      : SQLUSMALLINT;
                         fCType    : SQLSMALLINT;
                         fSqlType  : SQLSMALLINT;
                         cbParamDef: SQLUINTEGER;
                         ibScale   : SQLSMALLINT;
                         rgbValue  : SQLPOINTER;
                         pcbValue  : access SQLINTEGER)
                                     return SQLRETURN;       -- sql.h:312

    function SQLCOLUMNS(hstmt        : SQLHSTMT;
                        szCatalogName: Interfaces.C.char_array;
                        cbCatalogName: SQLSMALLINT;
                        szSchemaName : Interfaces.C.char_array;
                        cbSchemaName : SQLSMALLINT;
                        szTableName  : Interfaces.C.char_array;
                        cbTableName  : SQLSMALLINT;
                        szColumnName : Interfaces.C.char_array;
                        cbColumnName : SQLSMALLINT)
                                       return SQLRETURN;     -- sqlext.h:1129

    function SQLGETCONNECTOPTION(hdbc   : SQLHDBC;
                                 fOption: SQLUSMALLINT;
                                 pvParam: SQLPOINTER)
                                          return SQLRETURN;  -- sqlext.h:1140

    function SQLGETDATA(hstmt     : SQLHSTMT;
                        icol      : SQLUSMALLINT;
                        fCType    : SQLSMALLINT;
                        rgbValue  : SQLPOINTER;
                        cbValueMax: SQLINTEGER;
                        pcbValue  : access SQLINTEGER)
                                    return SQLRETURN;        -- sqlext.h:1145

    function SQLGETFUNCTIONS(hdbc     : SQLHDBC;
                             fFunction: SQLUSMALLINT;
                             pfExists : access SQLUSMALLINT)
                                        return SQLRETURN;    -- sqlext.h:1153

    function SQLGETINFO(hdbc          : SQLHDBC;
                        fInfoType     : SQLUSMALLINT;
                        rgbInfoValue  : SQLPOINTER;
                        cbInfoValueMax: SQLSMALLINT;
                        pcbInfoValue  : access SQLSMALLINT)
                                        return SQLRETURN;    -- sqlext.h:1158

    function SQLGETSTMTOPTION(hstmt  : SQLHSTMT;
                              fOption: SQLUSMALLINT;
                              pvParam: SQLPOINTER)
                                       return SQLRETURN;     -- sqlext.h:1165

    function SQLGETTYPEINFO(hstmt   : SQLHSTMT;
                            fSqlType: SQLSMALLINT)
                                      return SQLRETURN;      -- sqlext.h:1170

    function SQLPARAMDATA(hstmt    : SQLHSTMT;
                          prgbValue: access SQLPOINTER)
                                     return SQLRETURN;       -- sqlext.h:1174

    function SQLPUTDATA(hstmt   : SQLHSTMT;
                        rgbValue: SQLPOINTER;
                        cbValue : SQLINTEGER)
                                  return SQLRETURN;          -- sqlext.h:1178

    function SQLSETCONNECTOPTION(hdbc   : SQLHDBC;
                                 fOption: SQLUSMALLINT;
                                 vParam : SQLUINTEGER)
                                          return SQLRETURN;  -- sqlext.h:1183

    function SQLSETSTMTOPTION(hstmt  : SQLHSTMT;
                              fOption: SQLUSMALLINT;
                              vParam : SQLUINTEGER)
                                       return SQLRETURN;     -- sqlext.h:1188

    function SQLSETSTMTATTR(Hstmt        : SQLHSTMT;
                            Attribute    : SQLINTEGER;
                            ValuePtr     : SQLPOINTER;
                            StringLength : SQLINTEGER) return SQLRETURN;

    function SQLSPECIALCOLUMNS(hstmt        : SQLHSTMT;
                               fColType     : SQLUSMALLINT;
                               szCatalogName: Interfaces.C.char_array;
                               cbCatalogName: SQLSMALLINT;
                               szSchemaName : Interfaces.C.char_array;
                               cbSchemaName : SQLSMALLINT;
                               szTableName  : Interfaces.C.char_array;
                               cbTableName  : SQLSMALLINT;
                               fScope       : SQLUSMALLINT;
                               fNullable    : SQLUSMALLINT)
                                              return SQLRETURN;
                                                             -- sqlext.h:1193

    function SQLSTATISTICS(hstmt        : SQLHSTMT;
                           szCatalogName: Interfaces.C.char_array;
                           cbCatalogName: SQLSMALLINT;
                           szSchemaName : Interfaces.C.char_array;
                           cbSchemaName : SQLSMALLINT;
                           szTableName  : Interfaces.C.char_array;
                           cbTableName  : SQLSMALLINT;
                           fUnique      : SQLUSMALLINT;
                           fAccuracy    : SQLUSMALLINT)
                                          return SQLRETURN;  -- sqlext.h:1205

    function SQLTABLES(hstmt        : SQLHSTMT;
                       szCatalogName: Interfaces.C.char_array;
                       cbCatalogName: SQLSMALLINT;
                       szSchemaName : Interfaces.C.char_array;
                       cbSchemaName : SQLSMALLINT;
                       szTableName  : Interfaces.C.char_array;
                       cbTableName  : SQLSMALLINT;
                       szTableType  : Interfaces.C.char_array;
                       cbTableType  : SQLSMALLINT)
                                      return SQLRETURN;      -- sqlext.h:1216

    function SQLDRIVERCONNECT(hdbc             : SQLHDBC;
                              hwnd             : SQLHWND;
                              szConnStrIn      : Interfaces.C.char_array;
                              cbConnStrIn      : SQLSMALLINT;
                              szConnStrOut     : Interfaces.C.char_array;
                              cbConnStrOutMax  : SQLSMALLINT;
                              pcbConnStrOut    : access SQLSMALLINT;
                              fDriverCompletion: SQLUSMALLINT)
                                                 return SQLRETURN;
                                                             -- sqlext.h:1228

    function SQLBROWSECONNECT(hdbc           : SQLHDBC;
                              szConnStrIn    : Interfaces.C.char_array;
                              cbConnStrIn    : SQLSMALLINT;
                              szConnStrOut   : Interfaces.C.char_array;
                              cbConnStrOutMax: SQLSMALLINT;
                              pcbConnStrOut  : access SQLSMALLINT)
                                               return SQLRETURN;
                                                             -- sqlext.h:1241

    function SQLCOLUMNPRIVILEGES(hstmt        : SQLHSTMT;
                                 szCatalogName: Interfaces.C.char_array;
                                 cbCatalogName: SQLSMALLINT;
                                 szSchemaName : Interfaces.C.char_array;
                                 cbSchemaName : SQLSMALLINT;
                                 szTableName  : Interfaces.C.char_array;
                                 cbTableName  : SQLSMALLINT;
                                 szColumnName : Interfaces.C.char_array;
                                 cbColumnName : SQLSMALLINT)
                                                return SQLRETURN;
                                                             -- sqlext.h:1249

    function SQLDATASOURCES(henv            : SQLHENV;
                            fDirection      : SQLUSMALLINT;
                            szDSN           : Interfaces.C.char_array;
                            cbDSNMax        : SQLSMALLINT;
                            pcbDSN          : access SQLSMALLINT;
                            szDescription   : Interfaces.C.char_array;
                            cbDescriptionMax: SQLSMALLINT;
                            pcbDescription  : access SQLSMALLINT)
                                              return SQLRETURN;
                                                             -- sqlext.h:1260

    function SQLDESCRIBEPARAM(hstmt      : SQLHSTMT;
                              ipar       : SQLUSMALLINT;
                              pfSqlType  : access SQLSMALLINT;
                              pcbParamDef: access SQLUINTEGER;
                              pibScale   : access SQLSMALLINT;
                              pfNullable : access SQLSMALLINT)
                                           return SQLRETURN; -- sqlext.h:1270

    function SQLEXTENDEDFETCH(hstmt       : SQLHSTMT;
                              fFetchType  : SQLUSMALLINT;
                              irow        : SQLINTEGER;
                              pcrow       : access SQLUINTEGER;
                              rgfRowStatus: access SQLUSMALLINT)
                                            return SQLRETURN;-- sqlext.h:1278

    function SQLFOREIGNKEYS(hstmt          : SQLHSTMT;
                            szPkCatalogName: Interfaces.C.char_array;
                            cbPkCatalogName: SQLSMALLINT;
                            szPkSchemaName : Interfaces.C.char_array;
                            cbPkSchemaName : SQLSMALLINT;
                            szPkTableName  : Interfaces.C.char_array;
                            cbPkTableName  : SQLSMALLINT;
                            szFkCatalogName: Interfaces.C.char_array;
                            cbFkCatalogName: SQLSMALLINT;
                            szFkSchemaName : Interfaces.C.char_array;
                            cbFkSchemaName : SQLSMALLINT;
                            szFkTableName  : Interfaces.C.char_array;
                            cbFkTableName  : SQLSMALLINT)
                                             return SQLRETURN;
                                                             -- sqlext.h:1285

    function SQLMORERESULTS(hstmt: SQLHSTMT) return SQLRETURN;
                                                             -- sqlext.h:1300

    function SQLNATIVESQL(hdbc       : SQLHDBC;
                          szSqlStrIn : Interfaces.C.char_array;
                          cbSqlStrIn : SQLINTEGER;
                          szSqlStr   : Interfaces.C.char_array;
                          cbSqlStrMax: SQLINTEGER;
                          pcbSqlStr  : access SQLINTEGER)
                                       return SQLRETURN;     -- sqlext.h:1303

    function SQLNUMPARAMS(hstmt: SQLHSTMT;
                          pcpar: access SQLSMALLINT)
                                 return SQLRETURN;           -- sqlext.h:1311

    function SQLPARAMOPTIONS(hstmt: SQLHSTMT;
                             crow : SQLUINTEGER;
                             pirow: access SQLUINTEGER)
                                    return SQLRETURN;        -- sqlext.h:1315

    function SQLPRIMARYKEYS(hstmt        : SQLHSTMT;
                            szCatalogName: Interfaces.C.char_array;
                            cbCatalogName: SQLSMALLINT;
                            szSchemaName : Interfaces.C.char_array;
                            cbSchemaName : SQLSMALLINT;
                            szTableName  : Interfaces.C.char_array;
                            cbTableName  : SQLSMALLINT)
                                           return SQLRETURN;
                                                             -- sqlext.h:1320

    function SQLPROCEDURECOLUMNS(hstmt        : SQLHSTMT;
                                 szCatalogName: Interfaces.C.char_array;
                                 cbCatalogName: SQLSMALLINT;
                                 szSchemaName : Interfaces.C.char_array;
                                 cbSchemaName : SQLSMALLINT;
                                 szProcName   : Interfaces.C.char_array;
                                 cbProcName   : SQLSMALLINT;
                                 szColumnName : Interfaces.C.char_array;
                                 cbColumnName : SQLSMALLINT)
                                                return SQLRETURN;
                                                             -- sqlext.h:1329

    function SQLPROCEDURES(hstmt        : SQLHSTMT;
                           szCatalogName: Interfaces.C.char_array;
                           cbCatalogName: SQLSMALLINT;
                           szSchemaName : Interfaces.C.char_array;
                           cbSchemaName : SQLSMALLINT;
                           szProcName   : Interfaces.C.char_array;
                           cbProcName   : SQLSMALLINT)
                                          return SQLRETURN;  -- sqlext.h:1340

    function SQLSETPOS(hstmt  : SQLHSTMT;
                       irow   : SQLUSMALLINT;
                       fOption: SQLUSMALLINT;
                       fLock  : SQLUSMALLINT)
                                return SQLRETURN;            -- sqlext.h:1349

    function SQLTABLEPRIVILEGES(hstmt        : SQLHSTMT;
                                szCatalogName: Interfaces.C.char_array;
                                cbCatalogName: SQLSMALLINT;
                                szSchemaName : Interfaces.C.char_array;
                                cbSchemaName : SQLSMALLINT;
                                szTableName  : Interfaces.C.char_array;
                                cbTableName  : SQLSMALLINT)
                                               return SQLRETURN;
                                                             -- sqlext.h:1355

    function SQLDRIVERS(henv              : SQLHENV;
                        fDirection        : SQLUSMALLINT;
                        szDriverDesc      : Interfaces.C.char_array;
                        cbDriverDescMax   : SQLSMALLINT;
                        pcbDriverDesc     : access SQLSMALLINT;
                        szDriverAttributes: Interfaces.C.Char_Array;
                        cbDrvrAttrMax     : SQLSMALLINT;
                        pcbDrvrAttr       : access SQLSMALLINT)
                                            return SQLRETURN;-- sqlext.h:1368

    function SQLBINDPARAMETER(hstmt     : SQLHSTMT;
                              ipar      : SQLUSMALLINT;
                              fParamType: SQLSMALLINT;
                              fCType    : SQLSMALLINT;
                              fSqlType  : SQLSMALLINT;
                              cbColDef  : SQLUINTEGER;
                              ibScale   : SQLSMALLINT;
                              rgbValue  : SQLPOINTER;
                              cbValueMax: SQLINTEGER;
                              pcbValue  : access SQLINTEGER)
                                          return SQLRETURN;  -- sqlext.h:1378

    function SQLSETSCROLLOPTIONS(hstmt       : SQLHSTMT;
                                 fConcurrency: SQLUSMALLINT;
                                 crowKeyset  : SQLINTEGER;
                                 crowRowset  : SQLUSMALLINT)
                                               return SQLRETURN;
                                                             -- sqlext.h:1394

private

    pragma Import (Stdcall, SQLALLOCCONNECT, "SQLAllocConnect");   -- sql.h:195

    pragma Import (Stdcall, SQLALLOCENV, "SQLAllocEnv");           -- sql.h:199

    pragma Import (Stdcall, SQLALLOCSTMT, "SQLAllocStmt");         -- sql.h:202

    pragma Import (Stdcall, SQLBINDCOL, "SQLBindCol");             -- sql.h:206

    pragma Import (Stdcall, SQLCANCEL, "SQLCancel");               -- sql.h:214

    pragma Import (Stdcall, SQLCOLATTRIBUTES, "SQLColAttributes"); -- sql.h:217

    pragma Import (Stdcall, SQLCONNECT, "SQLConnect");             -- sql.h:226

    pragma Import (Stdcall, SQLDESCRIBECOL, "SQLDescribeCol");     -- sql.h:235

    pragma Import (Stdcall, SQLDISCONNECT, "SQLDisconnect");       -- sql.h:246

    pragma Import (Stdcall, SQLERROR, "SQLError");                 -- sql.h:249

    pragma Import (Stdcall, SQLEXECDIRECT, "SQLExecDirect");       -- sql.h:259

    pragma Import (Stdcall, SQLEXECUTE, "SQLExecute");             -- sql.h:264

    pragma Import (Stdcall, SQLFETCH, "SQLFetch");                 -- sql.h:267

    pragma Import (Stdcall, SQLFETCHSCROLL, "SQLFetchScroll");

    pragma Import (Stdcall, SQLFREECONNECT, "SQLFreeConnect");     -- sql.h:270

    pragma Import (Stdcall, SQLFREEENV, "SQLFreeEnv");             -- sql.h:273

    pragma Import (Stdcall, SQLFREESTMT, "SQLFreeStmt");           -- sql.h:276

    pragma Import (Stdcall, SQLGETCURSORNAME, "SQLGetCursorName"); -- sql.h:280

    pragma Import (Stdcall, SQLNUMRESULTCOLS, "SQLNumResultCols"); -- sql.h:286

    pragma Import (Stdcall, SQLPREPARE, "SQLPrepare");             -- sql.h:290

    pragma Import (Stdcall, SQLROWCOUNT, "SQLRowCount");           -- sql.h:295

    pragma Import (Stdcall, SQLSETCURSORNAME, "SQLSetCursorName"); -- sql.h:299

    pragma Import (Stdcall, SQLTRANSACT, "SQLTransact");           -- sql.h:304

    pragma Import (Stdcall, SQLSETPARAM, "SQLSetParam");           -- sql.h:312

    pragma Import (Stdcall, SQLCOLUMNS, "SQLColumns");             -- sqlext.h:1129

    pragma Import (Stdcall, SQLGETCONNECTOPTION, "SQLGetConnectOption");
                                                             -- sqlext.h:1140

    pragma Import (Stdcall, SQLGETDATA, "SQLGetData");             -- sqlext.h:1145

    pragma Import (Stdcall, SQLGETFUNCTIONS, "SQLGetFunctions");   -- sqlext.h:1153

    pragma Import (Stdcall, SQLGETINFO, "SQLGetInfo");             -- sqlext.h:1158

    pragma Import (Stdcall, SQLGETSTMTOPTION, "SQLGetStmtOption"); -- sqlext.h:1165

    pragma Import (Stdcall, SQLGETTYPEINFO, "SQLGetTypeInfo");     -- sqlext.h:1170

    pragma Import (Stdcall, SQLPARAMDATA, "SQLParamData");         -- sqlext.h:1174

    pragma Import (Stdcall, SQLPUTDATA, "SQLPutData");             -- sqlext.h:1178

    pragma Import (Stdcall, SQLSETCONNECTOPTION, "SQLSetConnectOption");
                                                             -- sqlext.h:1183

    pragma Import (Stdcall, SQLSETSTMTOPTION, "SQLSetStmtOption"); -- sqlext.h:1188

    pragma Import (Stdcall, SQLSETSTMTATTR, "SQLSetStmtAttr");

    pragma Import (Stdcall, SQLSPECIALCOLUMNS, "SQLSpecialColumns");
                                                             -- sqlext.h:1193

    pragma Import (Stdcall, SQLSTATISTICS, "SQLStatistics");       -- sqlext.h:1205

    pragma Import (Stdcall, SQLTABLES, "SQLTables");               -- sqlext.h:1216

    pragma Import (Stdcall, SQLDRIVERCONNECT, "SQLDriverConnect"); -- sqlext.h:1228

    pragma Import (Stdcall, SQLBROWSECONNECT, "SQLBrowseConnect"); -- sqlext.h:1241

    pragma Import (Stdcall, SQLCOLUMNPRIVILEGES, "SQLColumnPrivileges");
                                                             -- sqlext.h:1249

    pragma Import (Stdcall, SQLDATASOURCES, "SQLDataSources");     -- sqlext.h:1260

    pragma Import (Stdcall, SQLDESCRIBEPARAM, "SQLDescribeParam"); -- sqlext.h:1270

    pragma Import (Stdcall, SQLEXTENDEDFETCH, "SQLExtendedFetch"); -- sqlext.h:1278

    pragma Import (Stdcall, SQLFOREIGNKEYS, "SQLForeignKeys");     -- sqlext.h:1285

    pragma Import (Stdcall, SQLMORERESULTS, "SQLMoreResults");     -- sqlext.h:1300

    pragma Import (Stdcall, SQLNATIVESQL, "SQLNativeSql");         -- sqlext.h:1303

    pragma Import (Stdcall, SQLNUMPARAMS, "SQLNumParams");         -- sqlext.h:1311

    pragma Import (Stdcall, SQLPARAMOPTIONS, "SQLParamOptions");   -- sqlext.h:1315

    pragma Import (Stdcall, SQLPRIMARYKEYS, "SQLPrimaryKeys");     -- sqlext.h:1320

    pragma Import (Stdcall, SQLPROCEDURECOLUMNS, "SQLProcedureColumns");
                                                             -- sqlext.h:1329

    pragma Import (Stdcall, SQLPROCEDURES, "SQLProcedures");       -- sqlext.h:1340

    pragma Import (Stdcall, SQLSETPOS, "SQLSetPos");               -- sqlext.h:1349

    pragma Import (Stdcall, SQLTABLEPRIVILEGES, "SQLTablePrivileges");
                                                             -- sqlext.h:1355

    pragma Import (Stdcall, SQLDRIVERS, "SQLDrivers");             -- sqlext.h:1368

    pragma Import (Stdcall, SQLBINDPARAMETER, "SQLBindParameter"); -- sqlext.h:1378

    pragma Import (Stdcall, SQLSETSCROLLOPTIONS, "SQLSetScrollOptions");
                                                             -- sqlext.h:1394

end Iodbc;
