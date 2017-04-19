--> drop table

BEGIN
   tools.model_pkg.drop_object( p_object_type => 'table'
                              , p_object_name => 'generic_change_log' );
END;

BEGIN
   tools.model_pkg.drop_object( p_object_type => 'table'
                              , p_object_name => 'test_model' );
END;

--> create table

BEGIN
   --> tools.model_pkg.drop_object( 'table', 'test_model' );
   tools.model_pkg.add_column( p_table_name     => 'test_model'
                             , p_column_name    => 'test_id'
                             , p_data_type      => 'number'
                             , p_length         => 22
                             , p_column_comment => 'test_model ID column' );
   --
   tools.model_pkg.add_column( p_table_name     => 'test_model'
                             , p_column_name    => 'test_number'
                             , p_data_type      => 'number'
                             , p_length         => 5
                             , p_column_comment => 'test_model number column' );
   --
   tools.model_pkg.add_column( p_table_name     => 'test_model'
                             , p_column_name    => 'test_varchar2'
                             , p_data_type      => 'varchar2'
                             , p_length         => 100
                             , p_column_comment => 'test_model varchar2 column' );
   --
   tools.model_pkg.add_column( p_table_name     => 'test_model'
                             , p_column_name    => 'test_date'
                             , p_data_type      => 'date'
                             , p_column_comment => 'test_model date column' );
   --
   tools.model_pkg.add_column( p_table_name     => 'test_model'
                             , p_column_name    => 'test_timestamp'
                             , p_data_type      => 'timestamp'
                             , p_column_comment => 'test_model timestamp column' );
   --
   tools.model_pkg.add_column( p_table_name     => 'test_model'
                             , p_column_name    => 'test_clob'
                             , p_data_type      => 'clob'
                             , p_column_comment => 'test_model clob column' );
   --
   tools.model_pkg.add_column( p_table_name     => 'test_model'
                             , p_column_name    => 'test_blob'
                             , p_data_type      => 'blob'
                             , p_column_comment => 'test_model blob column' );
   --
   tools.model_pkg.add_column( p_table_name     => 'test_model'
                             , p_column_name    => 'test_active_yn'
                             , p_data_type      => 'varchar2'
                             , p_length         => 1 --> fixme: muß ohne diese Angabe auf 1 stellen
                             , p_column_comment => 'test_model - Active Yes/No'
                             , p_default        => q'['Y']'
                             , p_nullable       => FALSE );
   --
   tools.model_pkg.add_constraint( p_table_name      => 'test_model'
                                 , p_constraint_name => 'test_varchar2_uq'
                                 , p_constraint_type => 'uq'
                                 , p_uq_columns      => 'test_varchar2' );
   --
   tools.model_pkg.add_constraint( p_table_name      => 'test_model'
                                 , p_constraint_name => 'test_active_yn_ck'
                                 , p_constraint_type => 'ck'
                                 , p_ck_condition    => q'[test_active_yn IN ('Y','N')]' );

   tools.model_pkg.add_column( p_table_name     => 'test_model'
                             , p_column_name    => 'test_long_column_name1234'
                             , p_data_type      => 'varchar2'
                             , p_length         => 10 --> fixme: muß ohne diese Angabe auf 1 stellen
                             , p_column_comment => 'test_model - Test if API can handle long names'
                             , p_default        => NULL
                             , p_nullable       => TRUE );

   tools.model_pkg.add_column( p_table_name     => 'test_model'
                             , p_column_name    => 'test_xmltype'
                             , p_data_type      => 'XMLTYPE'
                             , p_length         => NULL
                             , p_column_comment => 'test_model - Test if API can handle XMLTypes'
                             , p_default        => NULL
                             , p_nullable       => TRUE );
END;

--> generate API

BEGIN
   tools.model_pkg.generate_api( p_table_name                 => 'TEST_MODEL'
                               , p_enable_generic_logging     => TRUE
                               , p_col_prefix_in_method_names => FALSE );
END;

-- DML

TRUNCATE TABLE tools.generic_change_log;

BEGIN
   test_model_api.create_or_update_row( p_test_id                   => 1
                                      , p_test_number               => 3
                                      , p_test_varchar2             => '1'
                                      , p_test_date                 => TO_DATE( '01.01.2001'
                                                                              , 'dd.mm.yyyy' )
                                      , p_test_timestamp            => TO_TIMESTAMP( '01.01.2001'
                                                                                   , 'dd.mm.yyyy' )
                                      , p_test_clob                 => TO_CLOB( 'abc' )
                                      , p_test_blob                 => NULL
                                      , p_test_active_yn            => 'Y'
                                      , p_test_long_column_name1234 => '2'
                                      , p_test_xmltype              => xmltype( '<test/>' ) );
END;