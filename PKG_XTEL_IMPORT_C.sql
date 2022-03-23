CREATE OR REPLACE PACKAGE "PKG_XTEL_IMPORT_C" AS

  -- ---------------------------------------------------------
  -- SM1 VERSION 6.0
  -- ---------------------------------------------------------

  -- ---------------------------------------------------------
  -- NOTES FOR MERGE AND CHANGE OF RELEASE
  -- This Package is version SM1 VERSION 6.0

  -- DO NOT MERGE IT TO PREVIOUS VERSIONS WITHOUT ASKING XTEL TEAM

  -- This Package reads and works only with its configuration set on
     --T904TABHEADX_INT
     --T906TABROWSX_INT

     --T904TABHEADX where CODTAB In ("REFDAT|FIELD_INFO", "REFDAT|WF_STATUS", "REFDAT|XIN_TABLES", "REFDAT|XOUT_TABLES")
     --T906TABROWSX where CODTAB In ("REFDAT|FIELD_INFO", "REFDAT|WF_STATUS", "REFDAT|XIN_TABLES", "REFDAT|XOUT_TABLES")

  -- ---------------------------------------------------------

  -- ---------------------------------------------------------
  -- History
  -- ---------------------------------------------------------

  -- 2014 12 19: 026; Mbandiera; WI 33433; Enhancement: common; calls PKG_UTILS.get_optinfo_as_string specify source table
  --                                                               T906TABROWSX_INT in order to gain performance in P_INIT_FIELD_ARRAY procedure
  -- 2014 12 19: 026; Mbandiera; WI 33433; Fixes : T062; fixed error on updating T062UMCONV
  -- 2014 12 19: 025; Mbandiera; WI 33433; Fixes : Orders; product hier; f_check_format_d
  -- 2014 11 13; 024: AZumbo   ; WI 33433; Fix trim dati in input nelle F_CHECK_FORMAT_X
  -- 2014 10 23; 023: MBandiera; WI 33433; Enhancement T920EXCHANGERATES import
  -- 2014 10 07; 022: MBandiera; WI 33200; TA5152_PROMOARTICLE_LISTfixed a bug on deleting no more present promo price ( it has not to compare DTEFROM field)
  -- 2014 08 08; 021: Mbandiera; WI 32462;  some changes in T064PARTLIST import
                      -- 1. T064 loading has been splitted from T060 import

  -- 2014 07 14; 020: Mbandiera; WI 32087;  some changes in T078WHSBALANCE import
                      -- 1. T078 loading will be splitted from T060 import . it will be a loading procedure  aside the article one.
                      -- 2. T078 will load only warehouse of type "PHISICAL WAREHOUSES" and it will not touch the "VAN SALES " ones.    see  t078.codwhs= T902[WHS].codtab -->  T902[WHS].optinfo = 0 (phisical); T902[WHS].optinfo = 1 (van sales)
                      -- 3. before deleting T078WHSBALANCE we need to delete first child table T078WHSBALANCE_BATCH records ( it is for van sales only so it should contain zero records for phisical wharehouses )

  -- 2014 07 14; 019: Mbandiera; WI 32070;
  --                             1. bugfix T064 kit, for each article when an error is found on a kit record it skips all other kit records on the same article
  --                             2. bugfix T902 , if T900.CODCONFIG is set to 'SM1' then it has to skip T902 loading
  -- 2014 05 16; 018: Mbandiera; WI 29729; Added record initialization in order not to get error if some new "not null" field will be added on master data
  -- 2014 04 04; 017: Mbandiera; WI 29729; Added Projected Invoices T661REAL
  -- 2014 02 26; 016: Mbandiera; WI 28211; Passive invoices, Products, Promo --> Added external configuration for first workflow status
  -- 2014 02 20; 015: Mbandiera; WI 28211; Changed Passive invoices loading bug on FLGFAKE maintenance
  -- 2014 02 13; 014: Mbandiera; WI 28211; Changed Passive invoices loading logig from UPDATE/INSERT to DELETE/INSERT
  -- 2014 02 13; 013: Mbandiera; WI 28211; Added SUPPLIER flow
  -- 2013 12 04; 012; Mbandiera; WI 28211; TA5150/TA5151/TA5152 + Added fields allignment +
  -- 2013 11 15; 012; Mbandiera; WI 28211; Added fields allignment
  -- 2013 11 15; 012; Mbandiera; WI 28211; PRICELIST; Changed the closure of details that are no more loaded from ERP ( it closes the dtetodetail and set no more flgann=-1)
  -- 2013 10 07; 011: Mbandiera;  New Format Check enhancement
  -- 2013 09 18; 010: Mbandiera;  Added new DSD fields on T030, T041, T060
  -- 2013 05 16; 010: Mbandiera;  modified check on T035LOGGEDUSER when starting mainload ;
  -- 2013 03 19; 009: Mbandiera;  added check on T035LOGGEDUSER when record seems to be locked
  -- 2013 02 06; 008; Mbandiera;  F_CHECK_FORMAT_S; Changed call from LENGTH(CHAR Unit of measure) to LENGTHB( BYTE Unit of measure)
  --                              because we could have different parameter NLS_LENGTH_SEMANTICS (BYTE or CHAR) and the default in COL table is
  --                              always in BYTE unit of measure.
  -- 2013 02 01; 007; IVasilescu;  LOAD_TA500X_PROMO ; Added Promo Loader
  -- 2013 01 03; 006; Mbandiera;  LOAD_TA019X_SURVEYS ; Added Activities Loader

  -- 2012 12 31; 005; Mbandiera;  P_INIT_SM1_FIELD_ARRAY ;Moved the configuratio of SM1 Fields from T906TABROWSX to T906TABROWSX_INT
  --                              F_CHECK_FORMAT_N; Added Check on numeric data length
  -- 2012 12 27; 004; Mbandiera;  P_T062_UPD_UMCONV ; Added PI_CODART/PI_CODDIV As optional input
  --                              LOAD_T06X_PRODUCTS ; calls P_T062_UPD_UMCONV only for modified articles

  -- 2012 12 27; 003; Mbandiera; LOAD_T04X_CUSTOMERS; added new fields to T049PVCATEGORY ( CODPARTY_CLUSTER  VARCHAR2(30),
  --                                                                  CODLEV_CLUSTER    VARCHAR2(30),
  --                                                                  CODHIER_CLUSTER   VARCHAR2(30),
  --                                                                  CODASSORTMENTTYPE_CLUSTER VARCHAR2(30))
  -- 2012 12 24; 002; Mbandiera; maintenance of default value for each field
  -- 2012 12 19; 001; Mbandiera; LOAD_T07X_PRICELIST; Added T073CUSTOMERTOAPPLY maintenance
  -- P R O C E D U R E
  /*============================================================================*/
  /*         Main Procedure  for Data Load                                      */
  /*============================================================================*/


  PROCEDURE MAINLOAD(PI_OPERATION    IN VARCHAR2,
                   PO_CODPROCESS    OUT NUMBER,
                   PO_MSG           OUT VARCHAR2,
                   PO_STATUS        OUT NUMBER,
                   PI_CODE_CHAR_A IN VARCHAR2 DEFAULT NULL,
                   PI_CODE_CHAR_B  IN VARCHAR2 DEFAULT NULL,
                   PI_CODE_NUM_A IN NUMBER DEFAULT NULL,
                   PI_CODE_NUM_B  IN NUMBER DEFAULT NULL,
                   PI_DATE_A       IN DATE DEFAULT NULL,
                   PI_DATE_B        IN DATE DEFAULT NULL);



  --
   PROCEDURE P_T062_UPD_UMCONV(PI_PROGR_H         IN NUMBER,
                                 PI_PROGR_D         IN NUMBER,
                                 PI_CODART          IN VARCHAR2 DEFAULT NULL,
                                 PI_CODDIV          IN VARCHAR2 DEFAULT NULL);

   PROCEDURE LOAD_TA5150_PROMO_HIER(pi_progr_h  IN NUMBER,
                                   po_msg      OUT VARCHAR2,
                                   po_status   OUT NUMBER);



   /*
CREATE OR REPLACE TYPE "X_FIELD_INFO_T"                                          AS OBJECT (
   FIELD_NAME             VARCHAR2(60),
   FIELD_LENGTH           NUMBER(9),
   FLG_DB_NULLABLE        NUMBER(1),
   FLG_SM1_NULLABLE       NUMBER(1),
   FLG_SM1                NUMBER(1),
   FIELD_DEF_DB_VALUE     VARCHAR2(255),
   FIELD_DEF_SM1_VALUE    VARCHAR2(255),
   FIELD_QTAB             VARCHAR2(60),
   FIELD_QTAB_MANDATORY   NUMBER(1),
   FIELD_RANGE            VARCHAR2(60),
   FIELD_TYPE             VARCHAR2(2))*/


   TYPE X_FIELD_INFO_ARRAY IS table of X_FIELD_INFO_T index by VARCHAR2(255);

   PROCEDURE P_INIT_SM1_FIELD_ARRAY ( PI_TABLE_NAME    IN VARCHAR2,
                                    PO_F_INFO          OUT X_FIELD_INFO_ARRAY,
                                    PO_STATUS          OUT NUMBER,
                                    PO_MESSAGE         OUT VARCHAR2);

   FUNCTION F_CHECK_FORMAT_S ( PI_CODDIV        IN VARCHAR2,
                              PI_DATA_VALUE    IN VARCHAR2,
                              PI_DATA_NAME     IN VARCHAR2,
                              PI_FIELD_INFO    IN X_FIELD_INFO_ARRAY,
                              PIO_STATUS       IN OUT NUMBER,
                              PIO_MSG          IN OUT VARCHAR2) RETURN VARCHAR2;

    FUNCTION F_CHECK_FORMAT_N ( PI_CODDIV        IN VARCHAR2,
                              PI_DATA_VALUE    IN VARCHAR2,
                              PI_DATA_NAME     IN VARCHAR2,
                              PI_FIELD_INFO    IN X_FIELD_INFO_ARRAY,
                              PIO_STATUS       IN OUT NUMBER,
                              PIO_MSG          IN OUT VARCHAR2) RETURN NUMBER;
    FUNCTION F_CHECK_FORMAT_D ( PI_CODDIV        IN VARCHAR2,
                              PI_DATA_VALUE    IN VARCHAR2,
                              PI_DATA_NAME     IN VARCHAR2,
                              PI_FIELD_INFO    IN X_FIELD_INFO_ARRAY,
                              PIO_STATUS       IN OUT NUMBER,
                              PIO_MSG          IN OUT VARCHAR2) RETURN DATE ;
END PKG_XTEL_IMPORT_C;
