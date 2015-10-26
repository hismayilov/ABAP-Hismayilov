*----------------------------------------------------------------------
*      N Overton : Created ( T/Code ZTUD)
*
*      Dynamic table export / import facility.
*
*      Restrictions - Table definition MUST exist on target
*                     system for import.
*                   - Entire table is exported / imported
*                   - Must be WIN95/98 WIN-NT long filenames
*----------------------------------------------------------------------
* TEXTS
*
* List Header...: For SAP Table: &1............................
*
* Column Heading: | Function    Status(48 spaces)# Records  |
*
* Selection Texts: PATH         Folder  Path for file
*                  P_CLEAR      Delete Existing Records
*                  P_EXP        Export to PC File
*                  P_IMP        Import from PC File
*                  TABNAME      SAP table name
*
* Text Symbols:    B00  Dynamic Import/Export of SAP data
*                  B01  SAP Table Name
*                  B02  Program Function
*                  B03  Folder For Data File
*                  B04  Existing Records Deletion Selection
*                  ER2  File not found. Please check.
*                  PGE  Page
*----------------------------------------------------------------------
* This program once created will allow you to download or upload table
* data from any SAP table. It has the functionality to allow you to
* select whether data should be appended or original data cleaed before
* inserting new data.
* This is very useful when attempting to transfer data from one client
* to another
*----------------------------------------------------------------------

REPORT zsptud01 LINE-SIZE 80
                LINE-COUNT 65
                NO STANDARD PAGE HEADING.

TABLES: dd02l, dd03l.

* selection screen
SELECTION-SCREEN BEGIN OF BLOCK b00 WITH FRAME TITLE text-b00.
*
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE text-b01.
PARAMETERS: tabname     LIKE dd02l-tabname OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b01.
*
SELECTION-SCREEN BEGIN OF BLOCK b03 WITH FRAME TITLE text-b03.
PARAMETERS: path(30)    TYPE c DEFAULT 'C:\SAPWorkdir'.
SELECTION-SCREEN END OF BLOCK b03.
*
SELECTION-SCREEN BEGIN OF BLOCK b04 WITH FRAME TITLE text-b04.
PARAMETERS: p_exp RADIOBUTTON GROUP radi,
            p_imp RADIOBUTTON GROUP radi,
            p_clear     AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK b04.

SELECTION-SCREEN END OF BLOCK b00.

* data
DATA: q_return     LIKE syst-subrc,
      err_flag(1)  TYPE c,
      answer(1)    TYPE c,
      w_text1(62)  TYPE c,
      w_text2(40)  TYPE c,
      winfile(128) TYPE c,
      w_system(40) TYPE c,
      winsys(7)    TYPE c,
      zname(8)     TYPE c,
      w_line(80)   TYPE c.

* internal tables
DATA : BEGIN OF textpool_tab OCCURS 0.
        INCLUDE STRUCTURE textpool.
DATA : END OF textpool_tab.

* table for subroutine pool
DATA : itab(80) OCCURS 0.

* events
INITIALIZATION.
  PERFORM check_system.
*
AT SELECTION-SCREEN ON tabname.
  PERFORM check_table_exists.
*
START-OF-SELECTION.
  PERFORM init_report_texts.
  PERFORM request_confirmation.
*
END-OF-SELECTION.
  IF answer = 'J'.
    PERFORM execute_program_function.
  ENDIF.
*
TOP-OF-PAGE.
  PERFORM process_top_of_page.

* forms
*---------------------------------------------------------------------*
*       FORM CHECK_TABLE_EXISTS                                      *
*---------------------------------------------------------------------*
FORM check_table_exists.
  SELECT SINGLE * FROM dd02l
  INTO CORRESPONDING FIELDS OF dd02l
  WHERE tabname = tabname.
  CHECK syst-subrc NE 0.
  MESSAGE e402(mo) WITH tabname.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM INIT_REPORT_TEXTS                                        *
*---------------------------------------------------------------------*
FORM init_report_texts.
  READ TEXTPOOL syst-repid
  INTO textpool_tab LANGUAGE syst-langu.
  LOOP AT textpool_tab
  WHERE id EQ 'R' OR id EQ 'T'.
    REPLACE '&1............................'
    WITH tabname INTO textpool_tab-entry.
    MODIFY textpool_tab.
  ENDLOOP.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM REQUEST_CONFIRMATION                                     *
*---------------------------------------------------------------------*
FORM request_confirmation.

* import selected, confirm action
  IF p_imp = 'X'.
*   build message text for popup
    CONCATENATE 'Data for table'
                 tabname
                 'will be imported' INTO w_text1 SEPARATED BY space.
*   check if delete existing selected, and change message text
    IF p_clear = ' '.
      w_text2 = 'and appended to the end of existing data'.
    ELSE.
      w_text2 = 'Existing Data will be deleted'.
    ENDIF.

    CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
         EXPORTING
              defaultoption  = 'N'
              textline1      = w_text1
              textline2      = w_text2
              titel          = 'Confirm Import of Data'
              cancel_display = ' '
         IMPORTING
              answer         = answer
         EXCEPTIONS
              OTHERS         = 1.
  ELSE.
*   export selected, set answer to yes so export can continue
    answer = 'J'.
  ENDIF.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM EXECUTE_PROGRAM_FUNCTION                                 *
*---------------------------------------------------------------------*
FORM execute_program_function.
  PERFORM build_file_name.
  CLEAR: q_return,err_flag.

  IF p_imp = 'X'.
    PERFORM check_file_exists.
    CHECK err_flag = ' '.
    PERFORM func_import.
  ELSE.
    PERFORM func_export.
  ENDIF.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM BUILD_FILE_NAME                                          *
*---------------------------------------------------------------------*
FORM build_file_name.
  MOVE path TO winfile.
  WRITE '\' TO winfile+30.
  WRITE tabname TO winfile+31.
  WRITE '.TAB' TO winfile+61(4).
  CONDENSE winfile NO-GAPS.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM CHECK_FILE_EXISTS                                        *
*---------------------------------------------------------------------*
FORM check_file_exists.

  CALL FUNCTION 'WS_QUERY'
       EXPORTING
            filename = winfile
            query    = 'FE'
       IMPORTING
            return   = q_return
       EXCEPTIONS
            OTHERS   = 1.

  IF syst-subrc NE 0 OR q_return NE 1.
    err_flag = 'X'.
  ENDIF.
ENDFORM.
*---------------------------------------------------------------------*
*     FORM func_export                                              *
*---------------------------------------------------------------------*
FORM func_export.
  CLEAR itab. REFRESH itab.

  APPEND 'PROGRAM SUBPOOL.' TO itab.

  APPEND 'FORM DOWNLOAD.' TO itab.
  APPEND 'DATA: BEGIN OF IT_TAB OCCURS 0.' TO itab.
  CONCATENATE 'INCLUDE STRUCTURE'
              tabname
              '.' INTO w_line SEPARATED BY space.
  APPEND w_line TO itab.
  APPEND 'DATA: END OF IT_TAB.' TO itab.

  CONCATENATE 'SELECT * FROM'
              tabname
              'INTO TABLE IT_TAB.' INTO w_line  SEPARATED BY space.
  APPEND w_line TO itab.

  APPEND 'CALL FUNCTION ''WS_DOWNLOAD''' TO itab.
  APPEND 'EXPORTING' TO itab.
  CONCATENATE 'filename = ' ''''
              winfile '''' INTO w_line SEPARATED BY space.
  APPEND w_line TO itab.
  APPEND 'filetype = ''DAT''' TO itab.
  APPEND 'TABLES' TO itab.
  APPEND 'DATA_TAB = IT_TAB.' TO itab.

  APPEND 'DESCRIBE TABLE IT_TAB LINES sy-index.' TO itab.

  APPEND 'FORMAT COLOR COL_NORMAL INTENSIFIED OFF.' TO itab.
  APPEND 'WRITE: /1 syst-vline,' TO itab.
  APPEND '''EXPORT'',' TO itab.
  APPEND '15 ''data line(s) have been exported'',' TO itab.
  APPEND '68 syst-index,' TO itab.
  APPEND '80 syst-vline.' TO itab.
  APPEND 'ULINE.' TO itab.

  APPEND 'ENDFORM.' TO itab.

  GENERATE SUBROUTINE POOL itab NAME zname.
  PERFORM download IN PROGRAM (zname).
ENDFORM.
*---------------------------------------------------------------------*
*       FORM func_import                                              *
*---------------------------------------------------------------------*
FORM func_import.
  CLEAR itab. REFRESH itab.
  APPEND 'PROGRAM SUBPOOL.' TO itab.

  APPEND 'FORM UPLOAD.' TO itab.
  APPEND 'DATA: BEGIN OF IT_TAB OCCURS 0.' TO itab.
  CONCATENATE 'INCLUDE STRUCTURE'
              tabname
              '.' INTO w_line SEPARATED BY space.
  APPEND w_line TO itab.
  APPEND 'DATA: END OF IT_TAB.' TO itab.
  APPEND 'DATA: BEGIN OF IT_TAB2 OCCURS 0.' TO itab.
  CONCATENATE 'INCLUDE STRUCTURE'
              tabname
              '.' INTO w_line SEPARATED BY space.
  APPEND w_line TO itab.
  APPEND 'DATA: END OF IT_TAB2.' TO itab.

  APPEND 'CALL FUNCTION ''WS_UPLOAD''' TO itab.
  APPEND 'EXPORTING' TO itab.
  CONCATENATE 'filename = ' ''''
              winfile '''' INTO w_line SEPARATED BY space.
  APPEND w_line TO itab.
  APPEND 'filetype = ''DAT''' TO itab.
  APPEND 'TABLES' TO itab.
  APPEND 'DATA_TAB = IT_TAB.' TO itab.

  IF p_clear = 'X'.
    CONCATENATE 'SELECT * FROM'
                tabname
                'INTO TABLE IT_TAB2.' INTO w_line SEPARATED BY space.
    APPEND w_line TO itab.

    APPEND 'LOOP AT IT_TAB2.' TO itab.
    CONCATENATE 'DELETE'
                tabname
                'FROM IT_TAB2.' INTO w_line SEPARATED BY space.
    APPEND w_line TO itab.
    APPEND 'ENDLOOP.' TO itab.
    APPEND 'COMMIT WORK.' TO itab.
  ENDIF.

  APPEND 'LOOP AT IT_TAB.' TO itab.
  CONCATENATE 'MODIFY'
              tabname
              'FROM IT_TAB.' INTO w_line SEPARATED BY space.
  APPEND w_line TO itab.
  APPEND 'ENDLOOP.' TO itab.

  APPEND 'DESCRIBE TABLE IT_TAB LINES sy-index.' TO itab.

  APPEND 'FORMAT COLOR COL_NORMAL INTENSIFIED OFF.' TO itab.
  APPEND 'WRITE: /1 syst-vline,' TO itab.
  APPEND '''IMPORT'',' TO itab.
  APPEND '15 ''data line(s) have been imported'',' TO itab.
  APPEND '68 syst-index,' TO itab.
  APPEND '80 syst-vline.' TO itab.
  APPEND 'ULINE.' TO itab.

  APPEND 'ENDFORM.' TO itab.

  GENERATE SUBROUTINE POOL itab NAME zname.
  PERFORM upload IN PROGRAM (zname).
ENDFORM.
*---------------------------------------------------------------------*
*       Form  CHECK_SYSTEM
*            Check users workstation is running
*            WINDOWS 95, or WINDOWS NT.
*            OS/2 uses 8.3 file names which are no good for
*            this application as filenames created are 30 char
*            same as table name.
*            You could change the logic to only use the first 8 chars
*            of the table name for the filename, but you could possibly
*            get problems if users had exported already with a table
*            with the same first 8 chars.
*            As an alternate method you could request the user to input
*            the full path including filename and remove the logic to
*            build the path using the table name.
*---------------------------------------------------------------------*
FORM check_system.
  CALL FUNCTION 'WS_QUERY'
       EXPORTING
            query  = 'WS'
       IMPORTING
            return = winsys.

  IF winsys NE 'WN32_95'.
    WRITE: 'Windows NT or Windows 95/98 is required'.
    EXIT.
  ENDIF.

ENDFORM.                               " CHECK_SYSTEM
*---------------------------------------------------------------------*
*       FORM PROCESS_TOP_OF_PAGE                                      *
*---------------------------------------------------------------------*
FORM process_top_of_page.
  FORMAT COLOR COL_HEADING INTENSIFIED ON.
  ULINE.

  CONCATENATE syst-sysid
              syst-saprl
              syst-host INTO w_system SEPARATED BY space.

  WRITE : AT /1(syst-linsz) w_system CENTERED.
  WRITE : AT 1 syst-vline, syst-uname.
  syst-linsz = syst-linsz - 11.
  WRITE : AT syst-linsz syst-repid(008).
  syst-linsz = syst-linsz + 11.
  WRITE : AT syst-linsz syst-vline.

  LOOP AT textpool_tab WHERE id EQ 'R'.
    WRITE : AT /1(syst-linsz) textpool_tab-entry CENTERED.
  ENDLOOP.
  WRITE : AT 1 syst-vline, syst-datum.
  syst-linsz = syst-linsz - 11.
  WRITE : AT syst-linsz syst-tcode(004).
  syst-linsz = syst-linsz + 11.
  WRITE : AT syst-linsz syst-vline.

  LOOP AT textpool_tab WHERE id EQ 'T'.
    WRITE : AT /1(syst-linsz) textpool_tab-entry CENTERED.
  ENDLOOP.
  WRITE : AT 1 syst-vline, syst-uzeit.
  syst-linsz = syst-linsz - 11.
  WRITE : AT syst-linsz 'Page', syst-pagno.
  syst-linsz = syst-linsz + 11.
  WRITE : AT syst-linsz syst-vline.
  ULINE.

  FORMAT COLOR COL_HEADING INTENSIFIED OFF.
  LOOP AT textpool_tab WHERE id EQ 'H'.
    WRITE : AT /1(syst-linsz) textpool_tab-entry.
  ENDLOOP.

  ULINE.
ENDFORM.