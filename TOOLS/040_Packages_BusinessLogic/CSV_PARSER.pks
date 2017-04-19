CREATE OR REPLACE PACKAGE csv_parser
AS
   /*

   Purpose:      Package handles comma-separated values (CSV)

   Remarks:

   Who     Date        Description
   ------  ----------  --------------------------------
   MBR     31.03.2010  Created

   */



   g_default_separator   CONSTANT VARCHAR2 (1) := ',';

   -- convert CSV line to array of values
   FUNCTION csv_to_array (p_csv_line    IN VARCHAR2,
                          p_separator   IN VARCHAR2 := g_default_separator)
      RETURN t_str_array;

   -- convert array of values to CSV
   FUNCTION array_to_csv (p_values      IN t_str_array,
                          p_separator   IN VARCHAR2 := g_default_separator)
      RETURN VARCHAR2;

   -- get value from array by position
   FUNCTION get_array_value (p_values        IN t_str_array,
                             p_position      IN NUMBER,
                             p_column_name   IN VARCHAR2 := NULL)
      RETURN VARCHAR2;

   -- convert clob to CSV
   FUNCTION clob_to_csv (p_csv_clob    IN CLOB,
                         p_separator   IN VARCHAR2 := g_default_separator,
                         p_skip_rows   IN NUMBER := 0)
      RETURN t_csv_tab
      PIPELINED;
END csv_parser;
/